# $Id$
#
# BioPerl module for Bio::DB::BioSQL::BiosequenceAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

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

Bio::DB::BioSQL::BiosequenceAdaptor - DESCRIPTION of Object

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


package Bio::DB::BioSQL::BiosequenceAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::PrimarySeq;

@ISA = qw(Bio::DB::BioSQL::BasePersistenceAdaptor);

# new inherited from base adaptor.
#
# if we wanted caching we'd have to override new here

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
    
    return ("seq_version", "length", "alphabet", "crc", "seq");
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
    my ($self,$obj,$fkobjs) = @_;
    my @vals = (undef);
    $vals[0] = $obj->seq_version() if $obj->isa("Bio::Seq::RichSeqI");
    $self->warn("seq_version is an empty string") if
        defined($vals[0]) && (!$vals[0]);
    my $seq = $obj->seq_has_changed() ? $obj->seq() : undef;
    push(@vals,
	 $obj->length(),
	 $obj->alphabet(),
         defined($seq) ? $self->crc64($seq) : undef,
	 $seq);
    return \@vals;
}

=head2 get_foreign_key_objects

 Title   : get_foreign_key_objects
 Usage   :
 Function: Gets the objects referenced by this object, and which therefore need
           to be referenced as foreign keys in the datastore.

           A Bio::PrimarySeqI references a namespace with authority.
 Example :
 Returns : an array of Bio::DB::PersistentObjectI implementing objects
 Args    : The object about to be inserted or updated, or undef if the call
           is for a SELECT query. In the latter case return class or interface
           names that are mapped to the foreign key tables.


=cut

sub get_foreign_key_objects{
    my ($self,$obj) = @_;
    my @fks = ();

    # we only support FK objects for INSERT/UPDATEs, not SELECTs (i.e., you're
    # not supposed to build an object from biosequence, it's rather a property)
    if($obj) {
	# if the object is-a IdentifiableI, then it is its own foreign key
	# object
	push(@fks, $obj) if $obj->isa("Bio::IdentifiableI");
    }
    return @fks;
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
	    $obj = Bio::PrimarySeq->new();
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
	if($obj->isa("Bio::Seq::RichSeqI")) {
	    $obj->seq_version($rows->[1]) if $rows->[1];
	}
	$obj->length($rows->[2]) if $rows->[2];
        # Note: Biojava uses upper-case terms for alphabet, so we
        # need to change to all-lower in case the sequence was
        # manipulated by Biojava.
	$obj->alphabet(lc($rows->[3])) if $rows->[3];
	$obj->seq($rows->[5]) if $rows->[5];
	if($obj->isa("Bio::DB::PersistentObjectI") &&
	   (! $obj->isa("Bio::PrimarySeqI"))) {
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

           This method MUST be overridden by a derived class. Alternatively,
           a derived class may choose to override find_by_unique_key() instead,
           as that one calls this method.
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
    my $fk;

    # UK for biosequence is the bioentry FK
    foreach (($obj, $fkobjs ? @$fkobjs : ())) {
	if($_->isa("Bio::PrimarySeqI") &&
	   $_->isa("Bio::DB::PersistentObjectI")) {
	    $fk = $_->primary_key();
	    last;
	}
    }
    if($fk) {
	$uk_h->{'primary_seq'} = $fk;
    }

    return $uk_h;
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

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

=head2 get_biosequence

 Title   : get_biosequence
 Usage   :
 Function: Returns the actual sequence for a bioentry, or a substring of it.
 Example :
 Returns : A string (the sequence or subsequence)
 Args    : The primary key of the bioentry for which to obtain the sequence.
           Optionally, start and end position if only a subsequence is to be
           returned (for long sequences, obtaining the subsequence from the
           database may be much faster than obtaining it from the complete
           in-memory string, because the latter has to be retrieved first).


=cut

sub get_biosequence{
    my ($self,@args) = @_;

    # since this is driver-specific, we delegate to the driver-specific peer
    return $self->dbd()->get_biosequence($self,@args);
}

1;
