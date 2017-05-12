#! /usr/bin/perl

package Bio::SeqReader::Fastq;

=head1 NAME

Bio::SeqReader::Fastq - Class providing a reader for files in FASTQ format.

=head1 SYNOPSIS

  use Bio::SeqReader::Fastq;
  my $in1 = new Bio::SeqReader::Fastq();             # from stdin
  my $fh = ...
  my $in2 = new Bio::SeqReader::Fastq( fh => $fh );  # from filehandle

=head1 DESCRIPTION

Bio::SeqReader::Fastq provides a method for reading a file or stream in FASTQ format.

This format is described in P. J. A. Cock, C. J. Fields, N. Goto, M. L. Heuer,
P. M. Rice. (2010) I<The Sanger FASTQ file format for sequences with quality scores, and
the Solexa/Illumina FASTQ variants>, Nucleic Acids Research 38. It specifically allows for multiline
sequence and quality score information, which are handled correctly by this class.

=head1 CLASS METHODS

Bio::SeqReader::Fastq provides no class methods.

=head1 INSTANCE METHODS

Bio::SeqReader::Fastq provides the following instance methods.

=cut

use strict;
use IO::Handle;
use Bio::SeqReader::FastqRecord;

=over 12

=item B<new()>

Constructor. Returns a new Bio::SeqReader::Fastq object associated with stdin (by default)
or with a filehandle. Understands optional specification of an IO::File-compatible filehandle
via C<< fh => $fh >>.

  # From an IO::File filehandle
  my $fh1 = new IO::File( 'in.fq' );
  my $in1 = new Bio::SeqReader::Fastq( fh => $fh1);

  # From an IO::Uncompress::AnyUncompress filehandle
  my $fh2 = new IO::File( 'in.fq.gz' );
  my $in2 = new Bio::SeqReader::Fastq( fh => $fh2);

  # From stdin
  my $in3 = new Bio::SeqReader::Fastq();

A specified filehandle must be compatible with those produced by IO::File filehandle; for example,

  $fh1 = new IO::File( 'in.fastq' )
  $fh2 = new IO::Uncompress::AnyUncompress( 'in.fastq.gz' )
  $fh3 = new IO::Uncompress::AnyUncompress( 'in.fastq' ).

=back

=cut

sub new {
    my ( $class, %parms ) = @_;

    my $self = {};
    bless( $self, $class );

    if ( exists $parms{ fh } ) {
        $self->{ _FH } = $parms{ fh };
    }

    else {
        $self->{ _FH } = \*STDIN;
    }

    $self->{ _READER_STATE } = 'start';

    return $self;
}

=over 12

=item B<next()>

Returns the next sequence as a Bio::SeqReader::FastqRecord object.

  while ( my $so = $in->next() ) {
      ... work with $so here ...
  }

=back

=cut

sub next {
    my $self = shift;

    undef $self->{ _HEADER1 };
    undef $self->{ _SEQTEXT };
    undef $self->{ _HEADER2 };
    undef $self->{ _QUALTEXT };
    $self->{ _READER_STATE } = 'start';

    while ( my $line = $self->{ _FH }->getline() ) {

        #print "$line\n";
        chomp $line;
        next if $line =~ /^\s*$/;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        if ( $self->{ _READER_STATE } eq 'start' ) {
            die if $line !~ /^\@/;
            $line =~ s/^\@//;
            $self->{ _HEADER1 }      = $line;
            $self->{ _READER_STATE } = 'seqtext';
        }

        elsif ( $self->{ _READER_STATE } eq 'seqtext' ) {

            if ( $line =~ /^\+/ ) {
                $line =~ s/^\+//;
                $self->{ _HEADER2 }      = $line;
                $self->{ _READER_STATE } = 'qualtext';
            }

            else {
                $self->{ _SEQTEXT } .= $line;
            }
        }

        elsif ( $self->{ _READER_STATE } eq 'qualtext' ) {

            $self->{ _QUALTEXT } .= $line;

            die if length $self->{ _QUALTEXT } > length $self->{ _SEQTEXT };

            if ( length $self->{ _QUALTEXT } == length $self->{ _SEQTEXT } ) {
                my $id = $self->{ _HEADER1 };
                $id =~ s/\s+.*//;
                my $so = new Bio::SeqReader::FastqRecord();
                $so->display_id( $id );
                $so->seq( $self->{ _SEQTEXT } );
                $so->quals( $self->{ _QUALTEXT } );
                $so->header1( $self->{ _HEADER1 } );
                $so->header2( $self->{ _HEADER2 } );
                return $so;
            }
        }
    }
}

1;

=head1 EXTERNAL DEPENDENCIES

Perl core.

=head1 EXAMPLES

  # Open and read a file in FASTQ format
  my $fh = new IO::File( 'foo.fastq' );
  my $in = new Bio::SeqReader( fh => $fh );
  while ( my $so = $in->next() ) {
      my $s = $so->seq();   # $so is a Bio::SeqReader::FastqRecord
      . . .
  }

  # Open and read a gzipped file in FASTQ format
  my $fh = new IO::Uncompress::AnyUncompress( 'foo.fastq.gz' );
  my $in = new Bio::SeqReader( fh => $fh );
  while ( my $so = $in->next() ) {
      my $s = $so->seq();   # $so is a Bio::SeqReader::FastqRecord
      . . .
  }

=head1 BUGS

None reported yet, but let me know.

=head1 SEE ALSO

Bio::SeqReader::FastqRecord, Bio::SeqReader.

=head1 AUTHOR

John A. Crow E<lt>jac_at_cpan_dot_orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

  Copyright (C) 2012 by John A. Crow
  Copyright (C) 2012 by National Center for Genome Resources

=cut

