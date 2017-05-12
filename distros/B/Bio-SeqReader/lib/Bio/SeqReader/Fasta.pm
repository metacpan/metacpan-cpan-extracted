#! /usr/bin/perl

package Bio::SeqReader::Fasta;

=head1 NAME

Bio::SeqReader::Fasta - Class providing a reader for files in FASTA format.

=head1 SYNOPSIS

  use Bio::SeqReader::Fasta;
  my $in1 = new Bio::SeqReader::Fasta();             # from stdin
  my $fh = ...
  my $in2 = new Bio::SeqReader::Fasta( fh => $fh );  # from filehandle

=head1 DESCRIPTION

Bio::SeqReader::Fasta provides a method for reading a file or stream in FASTA format.

=head1 CLASS METHODS

Bio::SeqReader::Fasta provides no class methods.

=head1 INSTANCE METHODS

Bio::SeqReader::Fasta provides the following instance methods.

=cut

use strict;
use IO::Handle;
use Bio::SeqReader::FastaRecord;

=over 12

=item B<new()>

Returns a new Bio::SeqReader::Fasta object associated with stdin or with a filehandle.

  # From an IO::File filehandle
  my $fh1 = new IO::File( 'in.fq' );
  my $in1 = new Bio::SeqReader::Fasta( fh => $fh1);

  # From an IO::Uncompress::AnyUncompress filehandle
  my $fh2 = new IO::File( 'in.fq.gz' );
  my $in2 = new Bio::SeqReader::Fasta( fh => $fh2);

  # From stdin
  my $in3 = new Bio::SeqReader::Fasta();

A specified filehandle must be compatible with those produced by IO::File filehandle; for example,

  $fh1 = new IO::File( 'in.fasta' )
  $fh2 = new IO::Uncompress::AnyUncompress( 'in.fasta.gz' )
  $fh3 = new IO::Uncompress::AnyUncompress( 'in.fasta' ).

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

Returns the next sequence as a Bio::SeqReader::FastaRecord object.

  while ( my $so = $in->next() ) {
      ... work with $so here ...
  }

=back

=cut

sub next {
    my $self = shift;

    # undef $self->{ _CURRENT_HEADER };

    my $seq;    # undefined to support the "while (my $so = $in->next_seq())" idiom

    my $seqtext;

    while ( my $line = $self->{ _FH }->getline() ) {

        if ( $line =~ /^\s*[>;]/ ) {


            $seq = new Bio::SeqReader::FastaRecord();

            $seq->seq( $seqtext );

            $self->{ _CURRENT_HEADER } =~ s/^\s*[>;]\s*//;

            my ( $id, $description ) = split( /\s+/, $self->{ _CURRENT_HEADER }, 2 );

            $seq->display_id( $id );
            $seq->desc( $description );

            $self->{ _CURRENT_HEADER } = $line;

            next if $seqtext =~ /^\s*$/;
            return $seq;
        }

        else {
            $seqtext .= $line;
        }
    }

    if ( $seqtext !~ /^\s*$/ ) {
        $seq = new Bio::SeqReader::FastaRecord();

        $seq->seq( $seqtext );

        $self->{ _CURRENT_HEADER } =~ s/^\s*[>;]\s*//;

        my ( $id, $description ) = split( /\s+/, $self->{ _CURRENT_HEADER }, 2 );
        $seq->display_id( $id );
        $seq->desc( $description );
    }

    return $seq;
}

1;

=head1 EXTERNAL DEPENDENCIES

Perl core.

=head1 EXAMPLES

  # Open and read a file in FASTA format
  my $fh = new IO::File( 'foo.fasta' );
  my $in = new Bio::SeqReader( fh => $fh );
  while ( my $so = $in->next() ) {
      my $s = $so->seq();   # $so is a Bio::SeqReader::FastaRecord
      . . .
  }

  # Open and read a gzipped file in FASTA format
  my $fh = new IO::Uncompress::AnyUncompress( 'foo.fasta.gz' );
  my $in = new Bio::SeqReader( fh => $fh );
  while ( my $so = $in->next() ) {
      my $s = $so->seq();   # $so is a Bio::SeqReader::FastaRecord
      . . .
  }

=head1 BUGS

None reported yet, but let me know.

=head1 SEE ALSO

Bio::SeqReader::FastaRecord, Bio::SeqReader.

=head1 AUTHOR

John A. Crow E<lt>jac_at_cpan_dot_orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

  Copyright (C) 2012 by John A. Crow
  Copyright (C) 2012 by National Center for Genome Resources

=cut

