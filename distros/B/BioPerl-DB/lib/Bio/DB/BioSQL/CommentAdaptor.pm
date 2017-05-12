# $Id$
#
# BioPerl module for Bio::DB::BioSQL::CommentAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# 
# Version 1.9 and up is also
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

Bio::DB::BioSQL::CommentAdaptor - DESCRIPTION of Object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Adaptor for Comment objects inside bioperl db 

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

=head1 AUTHOR - Ewan Birney, Hilmar Lapp

Email birney@ebi.ac.uk
Email hlapp at gmx.net


=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...

package Bio::DB::BioSQL::CommentAdaptor;

use vars qw(@ISA);
use strict;

use Bio::Annotation::Comment;
use Bio::DB::BioSQL::BasePersistenceAdaptor;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);

# new inherited from base adaptor.
#
# if we wanted caching we'd have to override new here

=head2 get_persistent_slots

 Title   : get_persistent_slots
 Usage   :
 Function: Get the slots of the object that map to attributes in its respective
           entity in the datastore.

           Slot name generally refers to a method name, but is not
           required to do so, since determining the values is under
           the control of get_persistent_slot_values().

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ("text", "rank");
}

=head2 get_persistent_slot_values

 Title   : get_persistent_slot_values
 Usage   :
 Function: Obtain the values for the slots returned by get_persistent_slots(),
           in exactly that order.

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
    my @vals = ($obj->text(),
		$obj->can('rank') ? $obj->rank() : undef,
		);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           A Bio::Annotation::Comment will reference a bioentry.
 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.
           Optionally, additional named parameters. A common parameter will
           be -fkobjs, with a reference to an array of foreign key objects
           that are not retrievable from the persistent object itself.


=cut

sub get_foreign_key_objects{
    my ($self,$obj,@args) = @_;
    my $bioentry;

    # Bio::Annotation::Comment doesn't have a pointer to the bioentry. Hence, 
    # we need to get this from the arguments.
    my ($fkobjs) = $self->_rearrange([qw(FKOBJS)], @args);
    if($fkobjs && @$fkobjs) {
	($bioentry) = grep { $_->isa("Bio::PrimarySeqI"); } @$fkobjs;
    } else {
	$bioentry = "Bio::SeqI";
    }

    return ($bioentry);
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for
           INSERTs or UPDATEs.

           Bio::Annotation::Comment objects have a Bio::SeqI as
           foreign key, but it is not referenced by the object. So we
           do nothing here.

 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
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
           Optionally, the object factory to be used for instantiating the
           proper class. The adaptor must be able to instantiate a default
           class if this value is undef.


=cut

sub instantiate_from_row{
    my ($self,$row,$fact) = @_;
    my $obj;

    if($row && @$row) {
	if($fact) {
	    $obj = $fact->create_object();
	} else {
	    $obj = Bio::Annotation::Comment->new();
	}
	$self->populate_from_row($obj, $row);
    }
    return $obj;
}

=head2 populate_from_row

 Title   : populate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

           Usually a derived class will instantiate the proper class and pass
           it on to populate_from_row().

 Example :
 Returns : An object, or undef, if the row contains no values
 Args    : The object to be populated, or the class to be instantiated.
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
	$obj->text($rows->[1]) if $rows->[1];
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

    # UKs for Comments are (FK to bioentry,rank),
    my ($seq) = grep { $_->isa("Bio::PrimarySeqI"); } @$fkobjs;
    if (defined($seq) &&
       (! ($seq->isa("Bio::DB::PersistentObjectI") && $seq->primary_key()))) {
	$seq = $self->_seq_adaptor()->find_by_unique_key($seq);
    }
    # we only need to continue with the sequence FK in hand
    if($seq) {
	$uk_h->{'Bio::PrimarySeqI'} = $seq->primary_key();
	$uk_h->{'rank'} = $obj->can('rank') ? $obj->rank() : undef;
    }

    return $uk_h;
}

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

1;
