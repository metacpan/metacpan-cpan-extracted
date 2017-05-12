# $Id$

#
# BioPerl module for Bio::CacheServer::SeqDB
#
# Please direct questions and support issues to <bioperl-l@bioperl.org> 
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::CacheServer::SeqDB - Caching DB object

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Bio::DB::SeqI implmenting object which implements a cache via
a bioperl-db database handle

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

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
the bugs and their resolution.  Bug reports can be submitted via 
the web:

  http://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR - Ewan Birney

Email birney@ebi.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::DB::CacheServer::SeqDB;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::Root::RootI;
use Bio::DB::SeqI;


# although we expect to be handed one of this, using
# this ensures someone runs this component
use Bio::DB::BioSQL::DBAdaptor;
@ISA = qw(Bio::DB::SeqI Bio::Root::RootI);
# new() can be inherited from Bio::Root::RootI

sub new {
    my ($class,@args) = @_;

    my $self = bless {}, ref($class) || $class;

    my($read,$write_dbadaptor,
       $dbname) = $self->_rearrange([qw(READ_DB
					WRITE_DBADAPTOR
					DBNAME)],@args);
    
    if( !defined $read || !ref $read || 
	!$read->isa('Bio::DB::SeqI')) {
	$self->throw("No read database or read database [$read] is not a Bio::DB::SeqI\n");
    }

    if( !defined $write_dbadaptor || !ref $write_dbadaptor || 
	!$write_dbadaptor->isa('Bio::DB::BioSQL::DBAdaptor')) {
	$self->throw("No write dbadaptor or write database [$write_dbadaptor] is not a Bio::DB::BioSQL::DBAdaptor\n");
    }

    if( !defined $dbname ) {
	$self->throw("No database name... can't implement without one");
    }

    $self->read_db($read);

    my $dbid = $write_dbadaptor->get_BioDatabaseAdaptor->fetch_by_name_store_if_needed($dbname);

    $self->dbid($dbid);

    $self->seq_adaptor($write_dbadaptor->get_SeqAdaptor);
    $self->db_adaptor($write_dbadaptor->get_BioDatabaseAdaptor);

    return $self;
}


=head1 Methods inherited from Bio::DB::RandomAccessI

=head2 get_Seq_by_id

 Title   : get_Seq_by_id
 Usage   : $seq = $db->get_Seq_by_id('ROA1_HUMAN')
 Function: Gets a Bio::Seq object by its name
 Returns : a Bio::Seq object
 Args    : the id (as a string) of a sequence
 Throws  : "id does not exist" exception


=cut

sub get_Seq_by_id {
    my ($self,$id) = @_;
    
    my $seq;

    eval {
	# some future implementation would check when this was stored
	# and invalidate the cache.
	$seq = $self->db_adaptor->fetch_Seq_by_display_id($self->dbid,$id);
    };
    if( $@ ) {
	# need to fetch from cache - 
	
	# we wont catch this exception - it passes up to the calling code
	$seq = $self->read_db->get_Seq_by_id($id);
	# write it back!

	# a better implementation would put this on a queue to insert
	# in a fork or at leisure

	my $dbid = $self->seq_adaptor->store($self->dbid,$seq);

	# having gone to the trouble of storing retrieve it from local
	# - the whole point is that this access is better than the other db
	$seq = $self->seq_adaptor->fetch_by_dbID($dbid);
	
    }

    # return it
    return $seq;
}


=head2 get_Seq_by_acc

 Title   : get_Seq_by_acc
 Usage   : $seq = $db->get_Seq_by_acc('X77802');
 Function: Gets a Bio::Seq object by accession number
 Returns : A Bio::Seq object
 Args    : accession number (as a string)
 Throws  : "acc does not exist" exception


=cut

sub get_Seq_by_acc {
    my ($self,$acc) = @_;


    # Ooops. Copy-and-paste. Bad Ewan! Bad Ewan!

    my $seq;

    eval {
	# some future implementation would check when this was stored
	# and invalidate the cache.
	$seq = $self->db_adaptor->fetch_Seq_by_accession($self->dbid,$acc);
    };
    if( $@ ) {
	# need to fetch from cache - 
	
	# we wont catch this exception - it passes up to the calling code
	$seq = $self->read_db->get_Seq_by_acc($acc);
	# write it back!

	# a better implementation would put this on a queue to insert
	# in a fork or at leisure

	my $dbid = $self->seq_adaptor->store($self->dbid,$seq);

	# having gone to the trouble of storing retrieve it from local
	# - the whole point is that this access is better than the other db
	$seq = $self->seq_adaptor->fetch_by_dbID($dbid);
	
    }

    # return it
    return $seq;

}

=head1 Methods [that were] specific for Bio::DB::SeqI

=head2 get_PrimarySeq_stream

 Title   : get_PrimarySeq_stream
 Usage   : $stream = get_PrimarySeq_stream
 Function: Makes a Bio::DB::SeqStreamI compliant object
           which provides a single method, next_primary_seq
 Returns : Bio::DB::SeqStreamI
 Args    : none


=cut

sub get_PrimarySeq_stream{
   my ($self) = @_;

   # we just delegate back to read - this
   # is too complicated to implement at the moment

   # (ideally have a look-ahead cach'ing mechanism)

   my $stream = $self->read_db->get_PrimarySeq_stream();

   return $stream;
}

=head2 get_all_primary_ids

 Title   : get_all_ids
 Usage   : @ids = $seqdb->get_all_primary_ids()
 Function: gives an array of all the primary_ids of the 
           sequence objects in the database. These
           maybe ids (display style) or accession numbers
           or something else completely different - they
           *are not* meaningful outside of this database
           implementation.
 Example :
 Returns : an array of strings
 Args    : none


=cut

sub get_all_primary_ids{
   my ($self,@args) = @_;


   return $self->read_db->get_all_primary_ids;
}


=head2 get_Seq_by_primary_id

 Title   : get_Seq_by_primary_id
 Usage   : $seq = $db->get_Seq_by_primary_id($primary_id_string);
 Function: Gets a Bio::Seq object by the primary id. The primary
           id in these cases has to come from $db->get_all_primary_ids.
           There is no other way to get (or guess) the primary_ids
           in a database.

           The other possibility is to get Bio::PrimarySeqI objects
           via the get_PrimarySeq_stream and the primary_id field
           on these objects are specified as the ids to use here.
 Returns : A Bio::Seq object
 Args    : accession number (as a string)
 Throws  : "acc does not exist" exception


=cut

sub get_Seq_by_primary_id {
    my ($self,$id) = @_;

    # Ooops. Copy-and-paste. Bad Ewan! Bad Ewan!
    # (Doh! Second time as well. Very Bad Ewan!)
    
    my $seq;
    
    eval {
	# some future implementation would check when this was stored
	# and invalidate the cache.
	$seq = $self->db_adaptor->get_Seq_by_primary_id($self->dbid,$id);
    };
    if( $@ ) {
	# need to fetch from cache - 
	
	# we wont catch this exception - it passes up to the calling code
	$seq = $self->read_db->get_Seq_by_acc($id);
	# write it back!
	
	# a better implementation would put this on a queue to insert
	# in a fork or at leisure
	
	my $dbid = $self->seq_adaptor->store($self->dbid,$seq);
	
	# having gone to the trouble of storing retrieve it from local
	# - the whole point is that this access is better than the other db
	$seq = $self->seq_adaptor->fetch_by_dbID($dbid);
	
    }

    # return it
    return $seq;  
}



=head2 Get/Sets for attributes stored in this object

=cut

=head2 seq_adaptor

 Title   : seq_adaptor
 Usage   : $obj->seq_adaptor($newval)
 Function: 
 Example : 
 Returns : value of seq_adaptor
 Args    : newvalue (optional)


=cut

sub seq_adaptor{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'seq_adaptor'} = $value;
    }
    return $obj->{'seq_adaptor'};

}


=head2 db_adaptor

 Title   : db_adaptor
 Usage   : $obj->db_adaptor($newval)
 Function: 
 Example : 
 Returns : value of db_adaptor
 Args    : newvalue (optional)


=cut

sub db_adaptor{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'db_adaptor'} = $value;
    }
    return $obj->{'db_adaptor'};

}


=head2 dbid

 Title   : dbid
 Usage   : $obj->dbid($newval)
 Function: 
 Example : 
 Returns : value of dbid
 Args    : newvalue (optional)


=cut

sub dbid{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'dbid'} = $value;
    }
    return $obj->{'dbid'};

}


=head2 read_db

 Title   : read_db
 Usage   : $obj->read_db($newval)
 Function: 
 Example : 
 Returns : value of read_db
 Args    : newvalue (optional)


=cut

sub read_db{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'read_db'} = $value;
    }
    return $obj->{'read_db'};

}

1;
