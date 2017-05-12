# $Id$
#
# BioPerl module for Bio::DB::BioSQL::OBDA
#
# Copyright Brian Osborne
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioSQL::OBDA

=head1 SYNOPSIS

This module is meant to be used a part of the OBDA system, e.g.:

  use Bio::DB::Registry;

  my $registry = Bio::DB::Registry->new;
  my $db = $registry->get_database('biosql');
  my $seq = $db->get_Seq_by_acc('P41932');

=head1 DESCRIPTION

This module connects code that uses OBDA to the bioperl-db package
and the underlying BioSQL database.

The Open Biological Database Access (OBDA) system was designed so that one 
could use the same application code to access data from multiple database 
types by simply changing a few lines in a configuration file. See
L<http://www.bioperl.org/wiki/HOWTO:OBDA> for more information.

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

  http://redmine.open-bio.org/projects/bioperl

=head1 AUTHOR - Brian Osborne

Email bosborne at alum.mit.edu

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal 
methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::DB::BioSQL::OBDA;
use strict;
use Bio::DB::Query::BioQuery;
use Bio::DB::BioDB;
use base qw(Bio::Root::Root Bio::DB::RandomAccessI);

=head2 new_from_registry

 Title   : new_from_registry
 Usage   : 
 Function: Create a database object that can be used by OBDA
 Returns : 
 Args    : Hash containing connection parameters read from an OBDA
           registry file

=cut

sub new_from_registry {
   my ($class, %conf) = @_;
	my $self = $class->SUPER::new();
	my ($host,$port);
        #  prevent warning msg by allowing location to be undef for postgresql 'ident sameuser' login)
        if (defined $conf{'location'}) {
                ($host,$port) = split ":", $conf{'location'};
        }
	my $db = Bio::DB::BioDB->new( -database => 'biosql',
										  -host     => $host,
										  -port     => $port,
										  -dbname   => $conf{'dbname'},
										  -driver   => $conf{'driver'},
                                      -user     => $conf{'user'  },
										  -pass     => $conf{'passwd'} );
	$self->_db($db);
	$self;
}

=head1 Methods inherited from Bio::DB::RandomAccessI

=head2 get_Seq_by_id

 Title   : get_Seq_by_id
 Usage   : $seq = $db->get_Seq_by_id(12345)
 Function:
 Example :
 Returns : One or more Sequence objects
 Args    : An identifier

=cut

sub get_Seq_by_id {
    my ($self,$id) = @_;
    my $db = $self->_db;
    my @seqs = ();
    $self->throw("No identifier given") unless $id;
    
    my $query = $self->{'_byId_Query'};
    if (! $query) {
        $query = Bio::DB::Query::BioQuery->new(
            -datacollections => ['Bio::SeqI seq'],
            -where => ["seq.primary_id = ?"]);
        $self->{'_byId_Query'} = $query;
    }
    my $seq_adaptor = $db->get_object_adaptor('Bio::SeqI');
    my $result = $seq_adaptor->find_by_query($query, 
                                             '-name' => 'OBDA get_Seq_by_id',
                                             '-values' => [$id]);
    
    for my $seq ($result->next_object) {
        push @seqs,$seq;
    }
    return wantarray ? @seqs : $seqs[0];
}

=head2 get_Seq_by_acc

 Title   : get_Seq_by_acc
 Usage   : $seq = $db->get_Seq_by_acc('A12345')
 Function:
 Example :
 Returns : One or more Sequence objects
 Args    : An accession number

=cut

sub get_Seq_by_acc {
    my ($self,$acc) = @_;
    my $db = $self->_db;
    my @seqs = ();
    $self->throw("No accession given") unless $acc;

    my $query = $self->{'_byAcc_Query'};
    if (! $query) {
        $query = Bio::DB::Query::BioQuery->new(
            -datacollections => ['Bio::SeqI seq'],
            -where => ["seq.accession_number = ?"]);
        $self->{'_byAcc_Query'} = $query;
    }
    my $seq_adaptor = $db->get_object_adaptor('Bio::SeqI');
    my $result = $seq_adaptor->find_by_query($query,
                                             '-name' => "OBDA get_Seq_by_acc",
                                             '-values' => [$acc]);

    for my $seq ($result->next_object) {
        push @seqs,$seq;
    }
    return wantarray ? @seqs : $seqs[0];
}

=head2 get_Seq_by_version

 Title   : get_Seq_by_version
 Usage   : $seq = $db->get_Seq_by_version('A12345.3')
 Function:
 Example :
 Returns : One or more Sequence objects
 Args    : A versioned accession number

=cut

sub get_Seq_by_version {
    my ($self,$vacc) = @_;
    my $db = $self->_db;
    my @seqs = ();
    my @comps = split(/\./, $vacc); # split into components on period
    $self->throw("Must supply a versioned accession: <accession>.<version>")
        unless @comps >= 2;
    my $ver = pop(@comps);      # the last one is the version
    my $acc = join(".",@comps); # the preceding rest is the accession
    
    my $query = $self->{'_byAccVersion_Query'};
    if (! $query) {
        $query = Bio::DB::Query::BioQuery->new(
            -datacollections => ['Bio::SeqI seq'],
            -where => ["seq.accession_number = ?",
                       "seq.version = ?"]);
        $self->{'_byAccVersion_Query'} = $query;
    }    
    my $seq_adaptor = $db->get_object_adaptor('Bio::SeqI');
    my $result = $seq_adaptor->find_by_query($query,
                                             '-name' => "OBDA get_Seq_by_version",
                                             '-values' => [$acc,$ver]);
    
    for my $seq ($result->next_object) {
        push @seqs,$seq;
    }
    return wantarray ? @seqs : $seqs[0];
}

=head1 Private methods

=head2 _db

 Title   : _db
 Usage   : 
 Function: Get or set the BioDB object
 Example :
 Returns : 
 Args    : 

=cut

sub _db {
	my ($self,$db) = @_;
	$self->{_db} = $db if ($db);
	$self->{_db};
}

1;

__END__
