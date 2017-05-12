package Bio::MLST::Blast::Database;
# ABSTRACT: Wrapper around NCBIs makeblastdb command
$Bio::MLST::Blast::Database::VERSION = '2.1.1706216';


package Bio::MLST::Blast::Database;
use Moose;
use File::Temp;
use Bio::MLST::Types;
use Cwd;

# input variables
has 'fasta_file'         => ( is => 'ro', isa => 'Str', required => 1 ); 
has 'exec'               => ( is => 'ro', isa => 'Bio::MLST::Executable', default  => 'makeblastdb' ); 

# Generated
has '_working_directory' => ( is => 'ro', isa => 'File::Temp::Dir', default => sub { File::Temp->newdir(DIR => getcwd, CLEANUP => 1); });
has 'location'           => ( is => 'ro', isa => 'Str', lazy => 1,  builder => '_build_location' ); 

sub _build_location
{
  my($self) = @_;

  my $output_database = join('/',($self->_working_directory->dirname(),'output_contigs'));
  my $makeblastdb_cmd  = join(" ",($self->exec, '-in', $self->fasta_file,  '-dbtype nucl', '-parse_seqids', '-out', $output_database));
  # FIXME: run this command in a more sensible fashion
  `$makeblastdb_cmd`;
  return $output_database;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::MLST::Blast::Database - Wrapper around NCBIs makeblastdb command

=head1 VERSION

version 2.1.1706216

=head1 SYNOPSIS

Take in a fasta file and create a temporary blast database.

   use Bio::MLST::Blast::Database;
   
   my $blast_database= Bio::MLST::Blast::Database->new(
     fasta_file => 'contigs.fa',
     exec => 'makeblastdb'
   );
   
   $blast_database->location();

=head1 METHODS

=head2 location

Returns the path to the temporary blast database files

=head1 SEE ALSO

=over 4

=item *

L<Bio::MLST::Blast::BlastN>

=back

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
