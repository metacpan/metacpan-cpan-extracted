#_{ Encoding and name
=encoding utf8
=head1 NAME

Csound::Orchestra

=cut
#_}
package Csound::Orchestra;

use warnings;
use strict;

use Carp;

our $VERSION = $Csound::VERSION;
#_{ Synopsis

=head1 SYNOPSIS

    use Csound::Orchestra;

    my $orchestra=Csound::Orchestra->new();

=cut
#_}
#_{ Description
=head1 DESCRIPTION

An orchestra consists of L<instruments|Csound::Instrument>

An orchestra should be created by a L<Csound::Score>.

=over

=item * a header section

The L<header section|http://www.csounds.com/manual/html/OrchTop.html#OrchHeader> specifies global options for instrument performance. It is written with L</_write_header>.

=item * an optional list of user defined opcodes

L<User defined opcodes|http://www.csounds.com/manual/html/OrchUDO.html> are built with the I<opcodes> C<< L<opcode|http://www.csounds.com/manual/html/opcode.html> >> and
C<< L<endop|http://www.csounds.com/manual/html/endop.html> >>.

=item * instrument definitions

=back

=cut
#_}
#_{ Methods
=head1 METHODS
=cut
sub new { #_{
#_{ POD
=head2 new

An orchestra should not be created by the end user. The user should rather use a L<Csound::Score>.

=cut
#_}

  my $class = shift;

  my $self  = {};

  bless $self, $class;

  die unless $self->isa('Csound::Orchestra');

# An orchestra requires some instruments.
# The key of the hash is the instrument number.
# The instruments are added with the L</UseInstrument>() method.
  $self->{instruments} = {};

  return $self;

} #_}
sub use_instrument {
#_{ POD
=head2 use_instrument

    $orc -> use_instrument($instr);

Add $instr to the instruments. An instrument can be added multiple times, for example by L<Csound::Score/play>.

=cut
#_}

  my $self  = shift;
  my $instr = shift;

  croak "Not an orchestra " unless $self ->isa('Csound::Orchestra');
  croak "Not an instrument" unless $instr->isa('Csound::Instrument');

  $self->{instruments}{$instr->{nr}} = $instr unless exists $self->{instruments}{$instr->{nr}};

}
sub write { #_{
#_{ POD
=head2 write

    $orc->write('filename.orc', $score);

This method should not be called directly by the end user. The end user should call L<Csound::Score/write> instead.

C<$score> is needed because some instruments need access to the score (notably for the table functions C<f1 8192 10 …>).

=cut
#_}

  my $self                    = shift;
  my $filename_without_suffix = shift;
  my $score                   = shift;

  croak "$self is a " . ref($self) unless $self->isa('Csound::Orchestra');
  croak "score is not defined" unless defined $score;
  croak "score is not a Csound::Score but a $score" unless $score->isa('Csound::Score');

  croak "No filename specified" unless $filename_without_suffix;

  open (my $orc_fh, '>', "$filename_without_suffix.orc") or croak "Could not open $filename_without_suffix.orc";

  $self->_write_header     ($orc_fh);
  $self->_write_instruments($orc_fh, $score);

  close $orc_fh;
  
} #_}
sub _write_header { #_{
#_{ POD
=head2 _write_header

An internal function.

L<http://www.csounds.com/manual/html/OrchTop.html#OrchHeader>

=cut
#_}

  my $self   = shift;
  croak unless $self->isa('Csound::Orchestra');

  my $fh_orc = shift;

  print $fh_orc <<HEADER;
sr     = 44100
kr     =  4410
ksmps  =    10
nchnls =     2
;0dbfs =     1
HEADER

} #_}
sub _write_instruments { #_{
#_{ POD
=head2 _write_instruments

An internal function.


=cut
#_}

  my $self   = shift;
  croak 'self is not a Csound::Orchestra' unless $self->isa('Csound::Orchestra');

  my $fh_orc = shift;

  my $score  = shift;
  croak "score needed, but is undefined" unless defined $score;
  croak "score needed" unless $score -> isa('Csound::Score');

  for my $instr_no (sort keys %{$self->{instruments}}) {
    print $fh_orc "\n" . $self->{instruments}{$instr_no}->orchestra_text($score);
  }


} #_}
#_}
#_{ POD: Copyright

=head1 Copyright

Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

#_}

'tq84';
