#! /usr/bin/env perl

package Bio::SeqReader;

use 5.010000;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [qw( )] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{ 'all' } } );
our @EXPORT      = qw( );
our $VERSION     = '0.1.3';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Bio::SeqReader - Classes for reading sequence data.

=head1 SYNOPSIS

  use Bio::SeqReader;

  # Read a FASTA file from stdin
  my $in = new Bio::SeqReader::Fasta();
  while ( my $so = $in->next() ) {
      . . .
  }

  # Read a FASTQ file from an IO::File filehandle
  my $fh = new IO::File( 'foo.fastq' );
  my $in = new Bio::SeqReader::Fastq( fh => $fh );
  while ( my $so = $in->next() ) {
      . . .
  }

  # Filehandles created by IO::Uncompress::AnyUncompress are compatible with
  # IO::File filehandles.
  my $fh = new IO::Uncompress::AnyUncompress( 'foo.fastq.gz' );
  my $in = new Bio::SeqReader::Fastq( fh => $fh );
  while ( my $so = $in->next() ) {
      . . .
  }


=head1 DESCRIPTION

The Bio::SeqReader package provides classes specifically for reading sequence data.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Bio::SeqReader::Fasta, Bio::SeqReader::FastaRecord, Bio::SeqReader::Fastq, Bio::SeqReader::FastqRecord

=head1 AUTHOR

John A. Crow, E<lt>jac_at_cpan_dot_orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

  Copyright (C) 2012 by John A. Crow.
  Copyright (C) 2012 by National Center for Genome Resources.

=cut
