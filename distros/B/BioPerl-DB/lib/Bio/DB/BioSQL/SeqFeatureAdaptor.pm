# $Id$
#
# BioPerl module for Bio::DB::BioSQL::SeqFeatureAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# 
# Completely rewritten by Hilmar Lapp, hlapp at gmx.net
#
# Version 1.16 and beyond is also
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioSQL::SeqFeatureAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  bioperl-l@bio.perl.org

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Ewan Birney, Hilmar Lapp

Email birney@ebi.ac.uk
Email hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::SeqFeatureAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::Persistent::SeqFeature;
use Bio::DB::Persistent::PersistentObjectFactory;
use Bio::SeqFeature::Generic;
use Bio::SeqFeature::AnnotationAdaptor;
use Bio::Location::Split;
use Bio::Ontology::Ontology;
use Bio::Ontology::Term;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);

my %slot_cat_map = ("primary_tag" => "SeqFeature Keys",
		    "source_tag"  => "SeqFeature Sources");

# new inherited from base adaptor.
#
# if we wanted caching we'd have to override new here - but don't do caching
# for features

=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its respective
           entity in the datastore.

           Slots should be methods callable without an argument.

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ("display_name","rank");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

           The reason this method is here is that sometimes the actual slot
           values need to be post-processed to yield the value that gets
           actually stored in the database. E.g., slots holding arrays
           will need some kind of join function applied. Another example is if
           the method call needs additional arguments. Supposedly the
           adaptor for a specific interface knows exactly what to do here.

           Since there is also populate_from_row() the adaptor has full
           control over mapping values to a version that is actually stored.
 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_persistent_slot_values {
    my ($self,$obj,$fkobjs) = @_;
    my @vals = ($obj->display_name(),
		$obj->can('rank') ? $obj->rank() || 0 : 0
		);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           A Bio::SeqFeatureI references a namespace with authority.
 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.


=cut

sub get_foreign_key_objects{
    my ($self,$obj) = @_;
    my ($bioentry,$sfkey, $sfsrc);

    if (defined($obj)) {
	$bioentry = $obj->entire_seq();
	if(! ($bioentry && $bioentry->isa("Bio::DB::PersistentObjectI") &&
	      $bioentry->primary_key())) {
	    $bioentry = "Bio::PrimarySeqI";
	}
	if ($obj->primary_tag()) {
	    $sfkey = $self->_ontology_term_fk("primary_tag",
					      $obj->primary_tag());
	} else {
	    $sfkey = ref($self)."::primary_tag";
	}
	if ($obj->source_tag()) {
	    $sfsrc = $self->_ontology_term_fk("source_tag",
					      $obj->source_tag());
	} else {
	    $sfsrc = ref($self)."::source_tag";
	}
    } else {
	$bioentry = "Bio::PrimarySeqI";
	$sfkey = ref($self)."::primary_tag";
	$sfsrc = ref($self)."::source_tag";
    }
    return ($bioentry, $sfkey, $sfsrc);
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for
           INSERTs or UPDATEs.

           SeqFeatureIs have a bioentry, a key and a source as foreign
           keys (the two latter are ontology terms). We don''t fetch
           the bioentry for seqfeatures, as that may easily result in
           infinite loops (because the seq will look for its
           features).

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    my $ok = 1;
    
    # retrieve feature key and feature source by key
    my $fadp = $self->_term_adaptor();
    my $term;
    if($fks->[1]) {
	$term = $fadp->find_by_primary_key($fks->[1]);
	$obj->primary_tag($term->name()) if $term;
	$ok = $term && $ok;
    }
    if($fks->[2]) {
	$term = $fadp->find_by_primary_key($fks->[2]);
	$obj->source_tag($term->name()) if $term;
	$ok = $term && $ok;
    }
    return $ok ? 1 : 0;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           Bio::SeqFeatureI has a location, annotation, and possibly
           sub-seqfeatures as children. The latter is not implemented yet.
 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.


=cut

sub store_children{
    my ($self,$obj) = @_;
    my $ok = 1;
    
    # store the location(s)
    my $i = 0;
    my $loc = $obj->location();
    my @locs =
	$loc->isa("Bio::Location::SplitLocationI") ?
	$loc->sub_Location() : ($loc);
    foreach $loc (@locs) {
	$loc->rank(++$i) if $loc->can('rank');
	$ok = $loc->store(-fkobjs => [$obj]) && $ok;
    }
    # store the annotation and associate ourselves with it; we use an adaptor
    # to transparently access all annotation through the AnnotationCollectionI
    # interface
    my $ac = $self->_featann_adaptor();
    $ac->feature($obj);
    # we need to get an adaptor to store it (or make it persistent, which is
    # unnecessary overhead since $ac will go out of scope at the end of this
    # method)
    if($ac->get_num_of_annotations() > 0) {
	my $acadp = $self->_anncoll_adaptor();
	$ok = $acadp->create($ac) && $ok;
	$acadp->add_association(-objs => [$ac, $obj]);
    }    
    # done
    return $ok;
}

=head2 attach_children

 Title   : attach_children
 Usage   :
 Function: Possibly retrieve and attach child objects of the given object.

           This is needed when whole object trees are supposed to be
           built when a base object is queried for and returned. An
           example would be Bio::SeqI objects and all the annotation
           objects that hang off of it.

           This is called by the find_by_XXXX() methods once the base
           object has been built.

           For Bio::SeqFeatureIs, we need to get the location,
           tag/value pairs and other annotation, and possibly
           sub-seqfeatures. The latter is not implemented yet.

 Example :
 Returns : TRUE on success, and FALSE otherwise.

 Args    : The object for which to find and to which to attach the child
           objects.


=cut

sub attach_children{
    my ($self,$obj) = @_;
    my $ok = 1;

    # look up the location(s) for this feature by FK
    my $query = Bio::DB::Query::BioQuery->new(
                                   -datacollections => ["Bio::LocationI t1"],
		                   -where => ["t1.Bio::SeqFeatureI = ?"]);
    my $qres = $self->_loc_adaptor()->find_by_query(
				   $query,
				   -name => "FIND LOCATION BY FEATURE",
				   -values => [$obj->primary_key()]);
    my $locs = $qres->each_Object();
    if(@$locs == 1) {
	$obj->location($locs->[0]);
    } elsif(@$locs > 1) {
	$obj->location(Bio::Location::Split->new(-locations => $locs));
    }
    $ok = @$locs > 0;
    #
    # look up annotation for this feature by association
    #
    my $annadp = $self->_anncoll_adaptor();
    # we use an adaptor to transparently add all annotation through the
    # AnnotationCollectionI interface
    my $ac = $self->_featann_adaptor();
    $ac->feature($obj);
    # now have the adaptor find by association
    $qres = $annadp->find_by_association(-objs => [$ac,$obj]);
    # no need to attach the annotation collection to the feature - the
    # annotation adaptor added everything to the feature transparently
    $qres->next_object(); # remove it from the stack, just to be sure
    # done
    return $ok;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.

           We need to undefine the primary keys of location objects
           here.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object that was just removed from the database.
           Additional (named) parameter, as passed to remove().


=cut

sub remove_children{
    my $self = shift;
    my $obj = shift;
    my $loc = $obj->location();
    my @locs = 
	$loc->isa("Bio::Location::SplitLocationI") ?
	$loc->sub_Location() : ($loc);
    foreach (@locs) {
	$_->primary_key(undef) if $_->isa("Bio::DB::PersistentObjectI");
    }
    return 1;
}

=head2 instantiate_from_row

 Title   : instantiate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

           This implementation calls populate_from_row() to do the real job.
 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : A reference to an array of column values. The first column
           is the primary key, the other columns are expected to be in
           the order returned by get_persistent_slots().  Optionally,
           a Bio::Factory::SequenceFactoryI compliant object to be
           used for creating the object.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if($fact) {
	    $obj = $fact->create_object();
	} else {
	    $obj = Bio::DB::Persistent::SeqFeature->new(
                                 -object => Bio::SeqFeature::Generic->new(),
				 -adaptor => $self);
	}
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Populates the object with values from columns of the row.

 Example :
 Returns : The object populated, or undef, if the row contains no values
 Args    : The object to be populated.
           A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,$obj,$rows) = @_;

    if(! ref($obj)) {
	$self->throw("\"$obj\" is not an object. Probably internal error.");
    }
    if($rows && @$rows) {
	$obj->display_name($rows->[1]) if $rows->[1];
	$obj->rank($rows->[2]) if $rows->[2] && $obj->can('rank');
	if($obj->isa("Bio::DB::PersistentObjectI")) {
	    $obj->primary_key($rows->[0]);
	}
	return $obj;
    }
    return undef;
}

=head2 get_unique_key_query

 Title   : get_unique_key_query
 Usage   :
 Function: Obtain the suitable unique key slots and values as determined by the
           attribute values of the given object and the additional foreign
           key objects, in case foreign keys participate in a UK. 

 Example :
 Returns : One or more references to hash(es) where each hash
           represents one unique key, and the keys of each hash
           represent the names of the object's slots that are part of
           the particular unique key and their values are the values
           of those slots as suitable for the key.
 Args    : The object with those attributes set that constitute the chosen
           unique key (note that the class of the object will be suitable for
           the adaptor).
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.


=cut

sub get_unique_key_query{
    my ($self,$obj,$fkobjs) = @_;
    my $uk_h = {};

    # UKs for SeqFeatureIs are (sequence,feature key,feature source,rank)
    my ($seq,$sfkey);
    if (defined($obj->entire_seq())) {
	$seq = $obj->entire_seq();
    } elsif($fkobjs) {
	($seq) = grep { $_->isa("Bio::PrimarySeqI"); } @$fkobjs;
    }
    if (ref($seq) &&
       (! ($seq->isa("Bio::DB::PersistentObjectI") && $seq->primary_key()))) {
	$seq = $self->_seq_adaptor()->find_by_unique_key($seq);
    }
    # we only need to continue with the sequence FK in hand
    if (ref($seq)) {
	$uk_h->{'entire_seq'} = $seq->primary_key();
	# now look up the term for the seqfeature key and seqfeature source
	my $fkterm;
	my @ukslots = qw(primary_tag source_tag);
	foreach my $ukslot (@ukslots) {
	    if($obj->$ukslot()) {
		($fkterm) = grep {
		    $_->isa("Bio::Ontology::TermI") &&
			$_->foreign_key_slot() =~ /$ukslot$/;
		} @$fkobjs;
		$fkterm = $self->_term_adaptor()->find_by_unique_key($fkterm)
		    unless $fkterm->primary_key();
	    }
	    $uk_h->{$ukslot} = $fkterm ? $fkterm->primary_key() : undef;
	}
	# rank if possible
	if($obj->can('rank') && defined($obj->rank())) {
	    $uk_h->{'rank'} = $obj->rank();
	}
    }

    return $uk_h;
}

=head1 Internal methods

 These are mostly private or 'protected.' Methods which are in the
 latter class have this explicitly stated in their
 documentation. 'Protected' means you may call these from derived
 classes, but not from outside.

 Most of these methods cache certain adaptors or otherwise reduce call
 path and object creation overhead. There's no magic here.

=cut

=head2 _seq_adaptor

 Title   : _seq_adaptor
 Usage   : $obj->_seq_adaptor($newval)
 Function: Get/set cached persistence adaptor for a bioperl seq object.

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _seq_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _seq_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_seq_adaptor'} = $adp;
    }
    if(! exists($self->{'_seq_adaptor'})) {
	$self->{'_seq_adaptor'} =
	    $self->db()->get_object_adaptor("Bio::SeqI");
    }
    return $self->{'_seq_adaptor'};
}

=head2 _term_adaptor

 Title   : _term_adaptor
 Usage   : $obj->_term_adaptor($newval)
 Function: Get/set cached persistence adaptor for an Ontology::TermI object

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _term_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _term_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_term_adaptor'} = $adp;
    }
    if(! exists($self->{'_term_adaptor'})) {
	$self->{'_term_adaptor'} =
	    $self->db()->get_object_adaptor("Bio::Ontology::TermI");
    }
    return $self->{'_term_adaptor'};
}

=head2 _loc_adaptor

 Title   : _loc_adaptor
 Usage   : $obj->_loc_adaptor($newval)
 Function: Get/set cached persistence adaptor for a bioperl location object.

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _loc_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _loc_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_loc_adaptor'} = $adp;
    }
    if(! exists($self->{'_loc_adaptor'})) {
	$self->{'_loc_adaptor'} =
	    $self->db()->get_object_adaptor("Bio::LocationI");
    }
    return $self->{'_loc_adaptor'};
}

=head2 _anncoll_adaptor

 Title   : _anncoll_adaptor
 Usage   : $obj->_anncoll_adaptor($newval)
 Function: Get/set cached persistence adaptor for a bioperl
           AnnotationCollectionI object.

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _anncoll_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _anncoll_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_anncoll_adaptor'} = $adp;
    }
    if(! exists($self->{'_anncoll_adaptor'})) {
	$self->{'_anncoll_adaptor'} =
	    $self->db()->get_object_adaptor("Bio::AnnotationCollectionI");
    }
    return $self->{'_anncoll_adaptor'};
}

=head2 _ontology_term_fk

 Title   : _ontology_term_fk
 Usage   : $term_fk = $obj->_ontology_term_fk($slot, $value)
 Function: Obtain the persistent ontology term representation of certain 
           slots that map to ontology terms (e.g. source tag, primary tag).

           This is an internal method.
 Example : 
 Returns : A persistent Bio::Ontology::TermI object
 Args    : The slot for which to obtain the FK term object.
           The value of the slot.


=cut

sub _ontology_term_fk{
    my ($self,$slot,$val) = @_;
    my $term;

    if(! exists($self->{'_ontology_term_fks'})) {
	$self->{'_ontology_term_fks'} = {};
    }

    if(! exists($self->{'_ontology_term_fks'}->{$slot})) {
	my $ont = Bio::Ontology::Ontology->new(-name => $slot_cat_map{$slot});
	$term = Bio::Ontology::Term->new(-name => "dummy",
					 -ontology => $ont);
	$self->{'_ontology_term_fks'}->{$slot} = $term;
    } else {
	$term = $self->{'_ontology_term_fks'}->{$slot};
    }
    # always create a new persistence wrapper for it - otherwise we run the
    # risk of messing with cached objects
    $term->name($val);
    $term = $self->db()->create_persistent($term);
    $term->foreign_key_slot(ref($self) ."::". $slot);
    return $term;
}

=head2 _featann_adaptor

 Title   : _featann_adaptor
 Usage   : $anncoll = $obj->_featann_adaptor()
 Function: Obtains the adaptor that adapts SeqFeatureI objects to annotation
           collections.

           This is an internal method.
 Example : 
 Returns : A Bio::AnnotationI compliant object that adapts a feature''s
           annotation
 Args    : none


=cut

sub _featann_adaptor{
    my ($self) = shift;

    if(! exists($self->{'_featann_adaptor'})) {
	my $ac = Bio::SeqFeature::AnnotationAdaptor->new();
	# we need to establish a SimpleValue object factory that creates
	# persistent objects
	my $svadp =
	    $self->db()->get_object_adaptor("Bio::Annotation::SimpleValue");
	my $fact = Bio::DB::Persistent::PersistentObjectFactory->new(
	                            -type => "Bio::Annotation::SimpleValue",
				    -adaptor => $svadp);
	$ac->tagvalue_object_factory($fact);
	$self->{'_featann_adaptor'} = $ac;
    }
    return $self->{'_featann_adaptor'};
}

1;
