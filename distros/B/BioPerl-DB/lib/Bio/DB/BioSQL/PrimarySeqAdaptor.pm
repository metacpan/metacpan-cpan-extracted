# $Id$
#
# BioPerl module for Bio::DB::BioSQL::PrimarySeqAdaptor
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Ewan Birney  <birney@ebi.ac.uk>
#
# Copyright Ewan Birney 
#
# You may distribute this module under the same terms as perl itself

# 
# Completely rewritten by Hilmar Lapp, hlapp at gmx.net
#
# Version 1.14 and beyond is also
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

Bio::DB::BioSQL::PrimarySeqAdaptor - DESCRIPTION of Object

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

  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Ewan Birney, Hilmar Lapp

Email birney@ebi.ac.uk
Email hlapp at gmx.net

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::BioSQL::PrimarySeqAdaptor;
use vars qw(@ISA);
use strict;

use Bio::DB::BioSQL::BasePersistenceAdaptor;
use Bio::DB::Persistent::BioNamespace;
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

           Slots should be methods callable without an argument.

 Example :
 Returns : an array of method names constituting the serializable slots
 Args    : the object about to be inserted or updated


=cut

sub get_persistent_slots{
    my ($self,@args) = @_;

    return ("display_id", "primary_id", "accession_number",
	    "desc", "version");
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
    my @vals = ($obj->display_id(),
		$obj->primary_id() =~ /=(HASH|ARRAY)\(0x/ ?
		    undef : $obj->primary_id(),
		$obj->accession_number(),
		$obj->description(),
		$obj->version() || 0);
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
    my $ns;

    if($obj) {
	# there is no "namespace" or Bio::Identifiable object in bioperl, so
	# we need to create one here
	$ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $obj);
	$ns->adaptor($self->_bionamespace_adaptor());
    } else {
	$ns = "Bio::DB::Persistent::BioNamespace";
    }
    return ($ns);
}

=head2 attach_foreign_key_objects

 Title   : attach_foreign_key_objects
 Usage   :
 Function: Attaches foreign key objects to the given object as far as
           necessary.

           This method is called after find_by_XXX() queries, not for INSERTs
           or UPDATEs.

           PrimarySeqIs have a BioNamespace as foreign key.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object to which to attach foreign key objects.
           A reference to an array of foreign key values, in the order of
           foreign keys returned by get_foreign_key_objects().


=cut

sub attach_foreign_key_objects{
    my ($self,$obj,$fks) = @_;
    
    # retrieve namespace by primary key
    my $nsadp = $self->_bionamespace_adaptor();
    my $ns = $nsadp->find_by_primary_key($fks->[0]);
    if($ns) {
	$obj->namespace($ns->namespace()) if $ns->namespace();
	$obj->authority($ns->authority()) if $ns->authority();
	return 1;
    }
    return 0;
}

=head2 store_children

 Title   : store_children
 Usage   :
 Function: Inserts or updates the child entities of the given object in the 
           datastore.

           Bio::PrimarySeqI has a sequence as child.
 Example :
 Returns : TRUE on success, and FALSE otherwise
 Args    : The Bio::DB::PersistentObjectI implementing object for which the
           child objects shall be made persistent.


=cut

sub store_children{
    my ($self,$obj) = @_;

    # delegate to Biosequence adaptor
    return $self->_bioseq_adaptor()->store($obj);
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

           For Bio::PrimarySeqIs, we need to get the biosequence attributes
           as well.
 Example :
 Returns : TRUE on success, and FALSE otherwise.
 Args    : The object for which to find and to which to attach the child
           objects.


=cut

sub attach_children{
    my ($self,$obj) = @_;

    my $adp = $self->_bioseq_adaptor();
    # This will find the biosequence by its foreign key to bioentry, since
    # that's the UK. Subsequently, it will populate the biosequence-specific
    # slots of $obj with the found record.
    my $o = $adp->find_by_unique_key($obj);
    # on success, $o == $obj, and $o == undef otherwise
    # however, some SeqI objects may legally lack any of those attributes
    # and hence may not have an entry here, so we'll have to be permissive
    return 1; #$o ? 1 : 0;
}

=head2 instantiate_from_row

 Title   : instantiate_from_row
 Usage   :
 Function: Instantiates the class this object is an adaptor for, and populates
           it with values from columns of the row.

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
	    $obj = Bio::PrimarySeq->new();
	}
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

    if(! ref($obj)) {
	$self->throw("\"$obj\" is not an object. Probably internal error.");
    }
    if($rows && @$rows) {
	$obj->display_id($rows->[1]) if $rows->[1];
	$obj->primary_id($rows->[2]) if $rows->[2];
	$obj->accession_number($rows->[3]) if $rows->[3];
	$obj->desc($rows->[4]) if $rows->[4];
	$obj->version($rows->[5]) if $rows->[5];
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
    my @ukqueries = ();

    # UKs for PrimarySeqIs are (accession number,namespace,version)
    # and (primary_id,namespace).

    # all of the UKs include the namespace if provided, so get
    # this right away.
    my $ns;
    if($obj->namespace()) {
        $ns = Bio::BioEntry->new(-namespace => $obj->namespace());
        $ns = $self->_bionamespace_adaptor()->find_by_unique_key($ns);
    }
    if($obj->primary_id() && ($obj->primary_id() !~ /=(HASH|ARRAY)\(0x/)) {
        my $uk_h = { 'primary_id' => $obj->primary_id(), };
        # For the identifier we'll be graceful if the namespace was not
        # provided, as in some earlier definitions of the schema the
        # namespace wasn't necessarily part of the UK constraint. OTOH, if
        # the namespace was provided but not found, we won't silently allow
        # for typos etc.
        if ($obj->namespace()) {
            $uk_h->{'bionamespace'} = $ns ? $ns->primary_key() : undef;
        }
	push(@ukqueries, $uk_h);
    }
    if($obj->accession_number()) {
        my $uk_h = { 'accession_number' => $obj->accession_number(),};
        # we'll be graceful on the version if it was omitted, allowing any
        # version to be matched, as opposed to only version 0 (the equivalent
        # in the schema of 'no version')
        $uk_h->{'version'} = $obj->version() if defined($obj->version);
        $uk_h->{'bionamespace'} = $ns ? $ns->primary_key() : undef;
	push(@ukqueries, $uk_h);
    }

    return @ukqueries;
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

    # delegate to Biosequence adaptor
    return $self->_bioseq_adaptor()->get_biosequence(@args);
}

=head1 Internal methods

 These are mostly private or 'protected.' Methods which are in the
 latter class have this explicitly stated in their
 documentation. 'Protected' means you may call these from derived
 classes, but not from outside.

 Most of these methods cache certain adaptors or otherwise reduce call
 path and object creation overhead. There's no magic here.

=cut

=head2 _bioseq_adaptor

 Title   : _bioseq_adaptor
 Usage   : $obj->_bioseq_adaptor($newval)
 Function: Get/set cached persistence adaptor for the biosequence.

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _bioseq_adaptor (a Bio::DB::PersistenceAdaptorI
	        instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _bioseq_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_bioseq_adaptor'} = $adp;
    }
    if(! exists($self->{'_bioseq_adaptor'})) {
	$self->{'_bioseq_adaptor'} =
	    $self->db()->get_object_adaptor("Biosequence");
    }
    return $self->{'_bioseq_adaptor'};
}

=head2 _bionamespace_adaptor

 Title   : _bionamespace_adaptor
 Usage   : $obj->_bionamespace_adaptor($newval)
 Function: Get/set cached persistence adaptor for the bionamespace.

           In OO speak, consider the access class of this method protected.
           I.e., call from descendants, but not from outside.
 Example : 
 Returns : value of _bionamespace_adaptor (a Bio::DB::PersistenceAdaptorI
	   instance)
 Args    : new value (a Bio::DB::PersistenceAdaptorI instance, optional)


=cut

sub _bionamespace_adaptor{
    my ($self,$adp) = @_;
    if( defined $adp) {
	$self->{'_bions_adaptor'} = $adp;
    }
    if(! exists($self->{'_bions_adaptor'})) {
	$self->{'_bions_adaptor'} =
	    $self->db->get_object_adaptor("BioNamespace");
    }
    return $self->{'_bions_adaptor'};
}

1;
