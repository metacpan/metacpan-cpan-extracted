#! /usr/bin/perl

package Bio::SeqReader::FastaRecord;

sub desc;
sub display_id;
sub new;
sub reset;
sub seq;

=head1 NAME

Bio::SeqReader::FastaRecord - Class providing methods for representing identifier,
description, and sequence information in FASTA records.

=head1 SYNOPSIS

  use Bio::SeqReader::FastaRecord;

=head1 EXAMPLES

  my $so = new Bio::SeqReader::FastaRecord();
  $so->seq( 'ACGTACGT' );
  print $so->seq();       # => ACGTACGT

=head1 DESCRIPTION

Class representing a sequence in FASTA format. Display id, description, and sequence
text are accessed by the object's getter-setter methods.

=head1 CLASS METHODS

Bio::SeqReader::FastaRecord provides no class methods.

=head1 INSTANCE METHODS

Bio::SeqReader::FastaRecord provides the following instance methods.

=cut

use strict;

=over 12

=item B<new()>

Returns a new Bio::SeqReader::FastaRecord object.

  # Void constructor
  my $so = new Bio::SeqReader::FastaRecord();

  # Constructor with initial values
  my $so = new Bio::SeqReader::FastaRecord(
                  display_id  => 'R_12345',
                  description => 'Predicted kinase gene',
                  seqtext     => 'ACGTACGT',
                  );

=back

=cut

sub new {
    my ( $class, %parms ) = @_;

    my $self = {};
    bless( $self, $class );

    $self->reset();
    $self->seq( $parms{ seqtext } )           if exists $parms{ seqtext };
    $self->display_id( $parms{ display_id } ) if exists $parms{ display_id };
    $self->desc( $parms{ description } )      if exists $parms{ description };

    return $self;
}

=over 12

=item B<desc()>

Getter-setter for the description text of a Bio::SeqReader::FastaRecord object.

  $so->desc( 'R_12345 read info ...' );
  print $so->desc();   # => R_12345 read info

=back

=cut

sub desc {
    my $self = shift;

    if ( @_ ) {
        $self->{ _DESCRIPTION } = shift;
        $self->{ _DESCRIPTION } =~ s/^\s+//g;
        $self->{ _DESCRIPTION } =~ s/\s+$//g;
    }

    return $self->{ _DESCRIPTION };
}


=over 12

=item B<display_id()>

Getter-setter for the display id of a Bio::SeqReader::FastaRecord object.

  $so->display_id( 'R_12345 read info ...' );
  print $so->display_id();   # => R_12345 read info

=back

=cut

sub display_id {
    my $self = shift;

    if ( @_ ) {
        $self->{ _DISPLAY_ID } = shift;
        $self->{ _DISPLAY_ID } =~ s/^\s+//g;
        $self->{ _DISPLAY_ID } =~ s/\s+$//g;
    }

    return $self->{ _DISPLAY_ID };
}

=over 12

=item B<reset()>

Reset a Bio::SeqReader::FastaRecord object.

=back

=cut

sub reset {
    my $self = shift;

    $self->{ _DESCRIPTION } = '';
    $self->{ _DISPLAY_ID }  = '';
    $self->{ _SEQTEXT }     = '';
}

=over 12

=item B<seq()>

Getter-setter for the sequence text from a Bio::SeqReader::FastaRecord object.

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

Bio::SeqReader::Fasta, Bio::SeqReader.

=head1 AUTHOR

John A. Crow E<lt>jac_at_cpan_dot_orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

  Copyright (C) 2012 by John A. Crow
  Copyright (C) 2012 by National Center for Genome Resources


=cut

