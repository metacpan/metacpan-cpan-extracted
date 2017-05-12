# $Id$
#
# BioPerl module for Bio::DB::BioSQL::LocationAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# 
# The previous Location adaptor was SeqLocationAdaptor by Ewan Birney. This
# module evidently is similar in purpose ...
#
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

Bio::DB::BioSQL::LocationAdaptor - DESCRIPTION of Object

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
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Hilmar Lapp

Email hlapp at gmx.net

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::LocationAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::Ontology::Term;
use Bio::Location::Simple;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);

#our %slot_cat_map = ();

# new inherited from base adaptor.
#
# if we wanted caching we'd have to override new here - but don't do caching
# for locations of features ...

=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its respective
           entity in the datastore.

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ("start","end","strand","rank");
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
    my @vals = ($obj->start(),
		$obj->end(),
		defined($obj->strand) ? $obj->strand : 0,
		$obj->can('rank') ? $obj->rank() : undef
		);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           A Bio::LocationI references a Bio::SeqFeatureI.
 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.
           Additional named parameters, with -fkobjs being recognized and
           pointing to a reference to an array of foreign key objects (the
	   Bio::SeqFeatureI object) not retrievable from the object itself.


=cut

sub get_foreign_key_objects{
    my ($self,$obj,@args) = @_;
    my ($feat,$dblink);

    # Bio::LocationI doesn't have a pointer to the feature. Hence, we need to
    # get this from the arguments.
    my ($fkobjs) = $self->_rearrange([qw(FKOBJS)], @args);
    if($fkobjs && @$fkobjs) {
	($feat) = grep { ref($_) && $_->isa("Bio::SeqFeatureI"); } @$fkobjs;
	if(ref($obj) && $obj->is_remote()) {
	    # construct DBLink on-the-fly
	    $dblink = $self->_seq_id_as_dblink($obj, $feat);
	}
    }
    $feat = "Bio::SeqFeatureI" unless $feat;
    # default for dblink is this is not a remote location
    $dblink = "Bio::Annotation::DBLink" unless $dblink;

    return ($feat,$dblink);
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for
           INSERTs or UPDATEs.

           LocationIs don''t really have a foreign key object attached
           -- it would be the SeqFeatureI if they had one.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order
           of foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    my $ok = 1;

    # remote location reference?
    if($fks->[1]) {
	my $dbl = $self->_dblink_adaptor->find_by_primary_key($fks->[1]);
	$obj->is_remote(1);
	$obj->seq_id($dbl->namespace_string) if $dbl;
	$ok = $dbl && $ok;
    }

    return $ok;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           Bio::LocationI may have qualifier/value pairs as children. This is
           not implemented yet.
 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.


=cut

sub store_children{
    my ($self,$obj) = @_;

    return 1;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.

           We just return TRUE here.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object that was just removed from the database.
           Additional (named) parameter, as passed to remove().


=cut

sub remove_children{
    return 1;
}

=head2 attach_children

 Title   : attach_children
 Usage   :
 Function: Possibly retrieve and attach child objects of the given object.

           This is needed when whole object trees are supposed to be built
           when a base object is queried for and returned. An example would
           be Bio::SeqI objects and all the annotation objects that hang off
           of it.

           This is called by the find_by_XXXX() methods once the base object
           has been built. 

           For Bio::LocationIs, we need to get the qualifier/value pairs
           possibly associated with it. Not implemented yet.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object for which to find and to which to attach the child
           objects.


=cut

sub attach_children{
    my ($self,$obj) = @_;

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
 Args    : A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().
           Optionally, a Bio::Factory::SequenceFactoryI compliant object to
           be used for creating the object.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if($fact) {
	    $obj = $fact->create_object();
	} else {
	    $obj = Bio::Location::Simple->new();
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
	$obj->start($rows->[1]) if $rows->[1];
	$obj->end($rows->[2]) if $rows->[2];
	$obj->strand($rows->[3]) if $rows->[3];
	$obj->rank($rows->[4]) if $rows->[4] && $obj->can('rank');
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

    # UK for LocationIs is (seqfeature,rank)
    # that is, we need the seqfeature or otherwise there's no point
    my $feat;
    if($fkobjs && @$fkobjs) {
	($feat) = grep { $_->isa("Bio::SeqFeatureI"); } @$fkobjs;
	if($feat &&
	   (! ($feat->isa("Bio::DB::PersistentObjectI") &&
	       $feat->primary_key()))) {
	    $feat = $self->_feat_adaptor()->find_by_unique_key($feat);
	}
    }
    # we only need to continue with the feature FK in hand
    if($feat) {
	$uk_h->{'Bio::SeqFeatureI'} = $feat->primary_key();
	$uk_h->{'rank'} = $obj->rank() if $obj->can('rank');
    }

    return $uk_h;
}

=head2 _seq_id_as_dblink

 Title   : _seq_id_as_dblink
 Usage   :
 Function: 
 Example :
 Returns : L<Bio::Annotation::DBLink> object
 Args    : L<Bio::LocationI> object, L<Bio::SeqFeatureI> object


=cut

sub _seq_id_as_dblink{
    my ($self,$loc,$feat) = @_;
    my $seqid = $loc->seq_id;
    my ($ns,$v);

    if( # this is an Ensembl artifact
        $seqid !~ /^Chr(X|Y|Un|\d+|Chr)/) {
	if($seqid =~ /^(\w+?):(.+)/) {
	    $ns = $1;
	    $seqid = $2;
	}
    }
    if($seqid =~ /^([0-9\w]+)\.([0-9]{1,3})\s*$/) {
	$seqid = $1;
	$v = $2;
    }
    if(! $ns) {
	if(! $feat) {
	    $self->throw("need feature FK for remote location on ".
			 $loc->seq_id());
	}
	# default namespace is the one from the attached seq
	$ns = $feat->entire_seq()->namespace();
    }
    # create DBLink object
    my $dblink =  Bio::Annotation::DBLink->new(-database   => $ns,
					       -primary_id => $seqid,
					       -version    => $v);
    # return the persistent version of it
    return $self->_dblink_adaptor->create_persistent($dblink);
}

=head2 _feat_adaptor

 Title   : _feat_adaptor
 Usage   : $obj->_feat_adaptor($newval)
 Function: Get/set cached persistence adaptor for a bioperl feature object.

           In OO speak, consider the access class of this method
           protected.  I.e., call from descendants, but not from
           outside.

 Example : 
 Returns : value of _feat_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _feat_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_feat_adaptor'} = $adp;
    }
    if(! exists($self->{'_feat_adaptor'})) {
	$self->{'_feat_adaptor'} =
	    $self->db()->get_object_adaptor("Bio::SeqFeatureI");
    }
    return $self->{'_feat_adaptor'};
}

=head2 _dblink_adaptor

 Title   : _dblink_adaptor
 Usage   : $obj->_dblink_adaptor($newval)
 Function: Get/set cached persistence adaptor for a bioperl DBLink object.

           In OO speak, consider the access class of this method
           protected.  I.e., call from descendants, but not from
           outside.

 Example : 
 Returns : value of _dblink_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _dblink_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_dblink_adaptor'} = $adp;
    }
    if(! exists($self->{'_dblink_adaptor'})) {
	$self->{'_dblink_adaptor'} =
	    $self->db()->get_object_adaptor("Bio::Annotation::DBLink");
    }
    return $self->{'_dblink_adaptor'};
}

1;
