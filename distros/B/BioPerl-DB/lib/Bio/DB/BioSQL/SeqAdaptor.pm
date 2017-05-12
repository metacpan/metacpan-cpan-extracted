# $Id$

#
# BioPerl module for Bio::DB::BioSQL::SeqAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# 
# Version 1.42 and up are also
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

Bio::DB::BioSQL::SeqAdaptor - DESCRIPTION of Object

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
the bugs and their resolution. Bug reports can be submitted via the web:

  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Ewan Birney, Hilmar Lapp

Email birney@ebi.ac.uk
Email hlapp at gmx.net

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::SeqAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::Persistent::PrimarySeq;
use Bio::DB::BioSQL::PrimarySeqAdaptor;
use Bio::DB::Query::BioQuery;
use Bio::Seq::SeqFactory;

@ISA = qw(Bio::DB::BioSQL::PrimarySeqAdaptor);

# new is inherited

=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its
           respective entity in the datastore.

           Slots should be methods callable without an argument.

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my $self = shift;

    return ($self->SUPER::get_persistent_slots(@_), "division");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

 Example :
 Returns : A reference to an array of values for the persistent slots of this
           object. Individual values may be undef.
 Args    : The object about to be serialized.
           A reference to an array of foreign key objects if not retrievable 
           from the object itself.

=cut

sub get_persistent_slot_values {
    my $self = shift;
    my $obj = shift;

    my $vals = $self->SUPER::get_persistent_slot_values($obj, @_);
    push(@$vals, $obj->isa("Bio::Seq::RichSeqI") ? $obj->division() : undef);
    return $vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore
           need to be referenced as foreign keys in the datastore.

           This implementation takes care of the species.
 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.


=cut

sub get_foreign_key_objects{
    my ($self,$obj) = @_;
    my @fkobjs = $self->SUPER::get_foreign_key_objects($obj);

    # we have an additional optional FK object, namely species.
    push(@fkobjs, ($obj && $obj->species() ?
		   $obj->species() : "Bio::Species"));
    return @fkobjs;
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

           SeqIs have Species in addition.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    
    # do what we inherit from PrimarySeqAdaptor
    my $ok = $self->SUPER::attach_foreign_key_objects($obj, $fks);
    # there's also possibly a species
    if($ok && $fks && $fks->[1]) {
	my $adp = $self->db()->get_object_adaptor("Bio::Species");
	my $species = $adp->find_by_primary_key($fks->[1]);
	$ok = $species ? 1 : 0;
	$obj->species($species);
    }
    return $ok;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           A Bio::SeqI has annotation and seqfeatures as children.

 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.


=cut

sub store_children{
    my ($self,$obj) = @_;

    my $ok = $self->SUPER::store_children($obj);
    # we need to store the annotations, and associate ourselves with them
    my $ac = $obj->annotation();
    # the annotation object might just have been created on the fly, and hence
    # may not be a PersistentObjectI (if that's the case we'll assume it's
    # empty, and there's no point storing anything)
    if($ac->isa("Bio::DB::PersistentObjectI")) {
	$ok = $ac->store(-fkobjs => [$obj]) && $ok;
	$ac->adaptor()->add_association(-objs => [$ac, $obj]);
    }
    # store the features
    # re-sync the attached seq of the features with this seq object
    if(! $obj->primary_seq->isa("Bio::DB::PersistentObjectI")) {
	$self->throw("PrimarySeq object is not a persistent object. ".
		     "This is alarming - probably an internal bug.");
    }
    $obj->add_SeqFeature($obj->remove_SeqFeatures());
    # loop over the seqfeatures and store
    my $i = 0;
    foreach my $feat ($obj->get_SeqFeatures()) {
	# we need to assign a rank if there isn't one already -- likewise,
	# if there is one already make sure we don't clash with that
	if(my $rank = $feat->rank()) {
	    $i = $rank+1 if $i <= $rank;
	} else {
	    $feat->rank(++$i);
	}
	$ok = $feat->store() && $ok;
    }
    # done
    return $ok;
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

           A Bio::SeqI has annotation and seqfeatures as children.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object for which to find and to which to attach the child
           objects.


=cut

sub attach_children{
    my ($self,$obj) = @_;

    my $ok = $self->SUPER::attach_children($obj);
    # we need to associate annotation
    my $annadp = $self->db()->get_object_adaptor("Bio::AnnotationCollectionI");
    my $qres = $annadp->find_by_association(-objs => [$annadp,$obj]);
    my $ac = $qres->next_object();
    if($ac) {
	$obj->annotation($ac);
    }
    # there may be features for this seq: search for those having a FK to
    # the seq
    my $query = Bio::DB::Query::BioQuery->new(
                            -datacollections => ["Bio::SeqFeatureI t1"],
		                    -where => ["t1.entire_seq = ?"],
                            -order => ["t1.rank"],
                            );
    $qres = $self->_feat_adaptor()->find_by_query(
				   $query,
				   -name => "FIND FEATURE BY SEQ",
				   -values => [$obj->primary_key()]);
    while(my $feat = $qres->next_object()) {
	$obj->add_SeqFeature($feat);
	# try to cleanup a possibly redundant namespace in remote location
	# seq IDs - we don't usually print that although we should
	if(my $ns = $obj->namespace()) {
	    my @locs = $feat->location->each_Location();
	    foreach my $subloc (@locs) {
		if($subloc->is_remote()) {
		    my $seqid = $subloc->seq_id();
		    if($seqid =~ s/^$ns://) {
			$subloc->seq_id($seqid);
		    }
		}
	    }
	    # set top object seqid
	    my $toploc = $feat->location();
	    if($toploc && 
	       (! $toploc->is_remote()) && (! $toploc->seq_id())) {
		$toploc->seq_id($obj->accession_number().
				($obj->version ? ".".$obj->version : ""));
	    }
	}
    }
    # done
    return $ok;
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
	if(! $fact) {
	    # we need to create at least Bio::SeqI implementing objects here;
	    # as a default catch-all we upgrade that to Bio::Seq::RichSeqI
	    $fact = Bio::Seq::SeqFactory->new(-type => "Bio::Seq::RichSeq");
	}
	$obj = $fact->create_object();
	$self->populate_from_row($obj, $row);
    }

    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Populates an object with values from columns of the row.

 Example :
 Returns : The object populated, or undef, if the row contains no values
 Args    : The object to be populated.
           A reference to an array of column values. The first column is the
           primary key, the other columns are expected to be in the order 
           returned by get_persistent_slots().


=cut

sub populate_from_row{
    my ($self,$obj,$rows) = @_;

    $obj = $self->SUPER::populate_from_row($obj,$rows);
    if($obj && $rows && @$rows && $obj->isa("Bio::Seq::RichSeqI")) {
	$obj->division($rows->[6]) if $rows->[6];
    }
    return $obj;
}

=head2 remove_children

 Title   : remove_children
 Usage   :
 Function: This method is to cascade deletes in maintained objects.

           We need to undefine the primary keys of all contained
           feature objects here.

 Example :
 Returns : TRUE on success and FALSE otherwise
 Args    : The persistent object that was just removed from the database.
           Additional (named) parameter, as passed to remove().


=cut

sub remove_children{
    my $self = shift;
    my $obj = shift;

    # features
    foreach my $feat ($obj->top_SeqFeatures()) {
	if($feat->isa("Bio::DB::PersistentObjectI")) {
	    $feat->primary_key(undef);
	    # cascade to feature's children
	    $self->_feat_adaptor->remove_children($feat);
	}
    }
    # annotation collection
    my $ac = $obj->annotation();
    if($ac->isa("Bio::DB::PersistentObjectI")) {
	$ac->primary_key(undef);
	$ac->adaptor()->remove_children($ac);
    }
    # done
    return 1;
}

=head1 Internal methods

 These are mostly private or 'protected.' Methods which are in the
 latter class have this explicitly stated in their
 documentation. 'Protected' means you may call these from derived
 classes, but not from outside.

 Most of these methods cache certain adaptors or otherwise reduce call
 path and object creation overhead. There's no magic here.

=cut

=head2 _feat_adaptor

 Title   : _feat_adaptor
 Usage   : $obj->_feat_adaptor($newval)
 Function: Get/set cached persistence adaptor for a Bio::SeqFeatureI object

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
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


1;
