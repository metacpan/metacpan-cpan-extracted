#! /usr/bin/perl

package Bio::SeqReader::FastqRecord;

sub header1;
sub header2;
sub new;
sub quals;
sub reset;
sub seq;

=head1 NAME

Bio::SeqReader::FastqRecord - Class providing methods for representing header,
sequence, and quality information in FASTQ records.

=head1 SYNOPSIS

  use Bio::SeqReader::FastqRecord;

=head1 EXAMPLES

  my $so = new Bio::SeqReader::FastqRecord();
  $so->seq( 'ACGTACGT' );
  print $so->seq();       # ACGTACGT

=head1 DESCRIPTION

Class representing a sequence in FASTQ format. Headers 1 and 2, sequence text, and quality text
are accessed by the object's getter-setter methods.

=head1 CLASS METHODS

Bio::SeqReader::FastqRecord provides no class methods.

=head1 INSTANCE METHODS

Bio::SeqReader::FastqRecord provides the following instance methods.

=cut

use strict;

=over 12

=item B<new()>

Returns a new Bio::SeqReader::FastqRecord object.

  # Void constructor
  my $so = new Bio::SeqReader::FastqRecord();

  # Constructor with initial values
  my $so = new Bio::SeqReader::FastqRecord(
                  header1     => 'R_12345 read info ...',
                  seqtext     => 'ACGTACGT',
                  header2     => '',
                  qualtext    => 'A@AA?#??'
                  );

=back

=cut

sub new {
    my ( $class, %parms ) = @_;

    my $self = {};
    bless( $self, $class );

    $self->reset();
    $self->seq( $parms{ seqtext } )     if exists $parms{ seqtext };
    $self->quals( $parms{ qualtext } )  if exists $parms{ qualtext };
    $self->header1( $parms{ header1 } ) if exists $parms{ header1 };
    $self->header2( $parms{ header2 } ) if exists $parms{ header2 };

    return $self;
}

=over 12

=item B<display_id()>

Getter for the display id associated with a Bio::SeqReader::FastqRecord object.
Makes use of the current contents of header 1.

  print $so->display_id();   # => R_12345 

=back

=cut

sub display_id {
    my $self = shift;

    my $display_id = $self->{ _HEADER1 };
    $display_id =~ s/\s+.*//;

    return $display_id;

}

=over 12

=item B<header1()>

Getter-setter for the first header text from a Bio::SeqReader::FastqRecord object.

  $so->header1( 'R_12345 read info ...' );
  print $so->header1();   # => R_12345 read info

=back

=cut

sub header1 {
    my $self = shift;

    if ( @_ ) {
        $self->{ _HEADER1 } = shift;
        $self->{ _HEADER1 } =~ s/^\s+//g;
        $self->{ _HEADER1 } =~ s/\s+$//g;
    }

    return $self->{ _HEADER1 };
}

=over 12

=item B<header2()>

Getter-setter for the second header text from a Bio::SeqReader::FastqRecord object.

  $so->header2( 'second header info ...' );
  print $so->header2();   # => second header info ...

=back

=cut

sub header2 {
    my $self = shift;

    if ( @_ ) {
        $self->{ _HEADER2 } = shift;
        $self->{ _HEADER2 } =~ s/^\s+//g;
        $self->{ _HEADER2 } =~ s/\s+$//g;
    }

    return $self->{ _HEADER2 };
}

=over 12

=item B<quals()>

Getter-setter for the quality text from a Bio::SeqReader::FastqRecord object.

  $so->quals( 'A@AA?#??' );
  print $so->quals();   # => A@AA?#??

=back

=cut

sub quals {
    my $self = shift;

    if ( @_ ) {
        $self->{ _QUALTEXT } = shift;
        $self->{ _QUALTEXT } =~ s/[\000-\037\s]+//g;
    }

    return $self->{ _QUALTEXT };
}

=over 12

=item B<reset()>

Reset a Bio::SeqReader::FastqRecord object. Basically sets all internal
data to empty strings.

=back

=cut

sub reset {
    my $self = shift;

    $self->{ _SEQTEXT }  = '';
    $self->{ _QUALTEXT } = '';
    $self->{ _HEADER1 }  = '';
    $self->{ _HEADER2 }  = '';
}

=over 12

=item B<seq()>

Getter-setter for the sequence text from a Bio::SeqReader::FastqRecord object.

  $so->seq( 'ACGTACGT' );
  print $so->seq();   # => ACGTACGT

=back

=cut

sub seq {
    my $self = shift;

    if ( @_ ) {
        $self->{ _SEQTEXT } = shift;
        $self->{ _SEQTEXT } =~ s/[\000-\037\s]+//g;
    }

    return $self->{ _SEQTEXT };
}

1;

=head1 EXTERNAL DEPENDENCIES

Perl core.

=head1 BUGS

None reported yet, but let me know.

=head1 SEE ALSO

Bio::SeqReader::Fastq, Bio::SeqReader.

=head1 AUTHOR

John A. Crow E<lt>jac_at_cpan_dot_orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

  Copyright (C) 2012 by John A. Crow
  Copyright (C) 2012 by National Center for Genome Resources


=cut

