package Data::BitStream::Code::Taboo;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Taboo::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Taboo::VERSION = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'BlockTaboo',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {shift->put_blocktaboo(@_)},
                  decodesub => sub {shift->get_blocktaboo(@_)}, };

use Moo::Role;
requires qw(read write);

sub put_blocktaboo {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $taboostr = shift;
  $self->error_code('param', 'taboo must be a binary string') if $taboostr =~ tr/01//c;
  my $bits = length($taboostr);
  $self->error_code('param', 'taboo length must be in range 1-16') unless $bits >= 1 && $bits <= 16;
  my $taboo = oct("0b$taboostr");

  if ($bits == 1) {
    return ($taboo == 1)  ?  $self->put_unary(@_)  :  $self->put_unary1(@_);
  }

  my $base = 2**$bits - 1;      # The base of the digits we're writing

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;

    if ($val == 0) { $self->write($bits, $taboo);  next; }

    # val         code
    #   0           00
    #   1         0100      base^0
    #   2         1000
    #   3         1100
    #   4       010100      base^1+base^0
    #  12       111100
    #  13     01010100      base^2+base^1+base^0
    #  39     11111100
    #  40   0101010100      base^3+base^2+base^1+base^0
    # 121 010101010100      base^4+base^3+base^2+base^1+base^0

    my $lbase = 0;
    my $baseval = 1;  #  $base**0
    while ($val >= ($baseval + $base**($lbase+1))) {
      $lbase++;
      $baseval += $base**$lbase;
    }
    my $v = $val - $baseval;

    # block-at-a-time way:
    #   foreach my $i (reverse 0 .. $lbase) {
    #     my $factor = $base ** $i;
    #     my $digit = int($v / $factor);
    #     $v -= $digit * $factor;
    #     $digit++ if $digit >= $taboo;  # Make room for the taboo chunk
    #     $self->write($bits, $digit);
    #   }
    #   $self->write($bits, $taboo);
    # combine blocks into 32-bit writes:
    my @stack = ($taboo);
    foreach my $i (0 .. $lbase) {
      my $digit = $v % $base;
      $digit++ if $digit >= $taboo;  # Make room for the taboo chunk
      push @stack, $digit;
      $v = int($v / $base);
    }
    my $cword = 0;
    my $cbits = 0;
    while (@stack) {
      $cword = ($cword << $bits) | pop @stack;
      $cbits += $bits;
      if (($cbits + $bits) > 32) {
        $self->write($cbits, $cword);
        $cword = 0;
        $cbits = 0;
      }
    }
    $self->write($cbits, $cword) if $cbits;
  }
  1;
}

sub get_blocktaboo {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $taboostr = shift;
  $self->error_code('param', 'taboo must be a binary string') if $taboostr =~ tr/01//c;
  my $bits = length($taboostr);
  $self->error_code('param', 'taboo length must be in range 1-16') unless $bits >= 1 && $bits <= 16;
  my $taboo = oct("0b$taboostr");

  if ($bits == 1) {
    return ($taboo == 1)  ?  $self->get_unary(@_)  :  $self->get_unary1(@_);
  }
  my $base = 2**$bits - 1;      # The base of the digits we're writing

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Block Taboo');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $tval = $self->read($bits);
    last unless defined $tval;

    my $val = 0;
    my $baseval = 0;
    my $n = 0;
    while ($tval != $taboo) {
      my $digit = ($tval > $taboo) ? $tval-1 : $tval;
      $val = $base * $val + $digit;
      $baseval += $base**$n;
      $n++;
      $self->error_code('overflow') if ($val+$baseval) > ~0;
      $tval = $self->read($bits);
      $self->error_off_stream unless defined $tval;
    }
    push @vals, $val+$baseval;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}

no Moo::Role;
1;

# ABSTRACT: A Role implementing Taboo codes

=pod

=head1 NAME

Data::BitStream::Code::Taboo - A Role implementing Taboo codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Taboo codes.  The role applies to a stream object.

Taboo codes are described in Steven Pigeon's 2001 PhD Thesis as well as his
paper "Taboo Codes: New Classes of Universal Codes."

The block methods implement a slight modification of the taboo codes, wherein
zero is encoded as the taboo pattern with no preceding bits.  This causes no
loss of generality and lowers the bit count for small values.

An example using '11' as the taboo pattern (chunk size C<n=2>):

      value        code          binary         bits
          0           t                    11    2
          1          0t                  0011    4
          2          1t                  0111    4
          3          2t                  1011    4
          4         00t                000011    6
  ..     12         22t                101011    6
         13        000t              00000011    8
  ..     64       0220t            0010100011   10
  ..  10000  000012220t  00000000011010100011   20

These codes are a more efficient version of comma codes, as they allow leading
zeros.

The unconstrained taboo codes are not implemented yet.  However, the
generalized Fibonacci codes are a special case of taboo codes (using a taboo
pattern of all ones and a different bit ordering).  The lengths of the codes
will be identical in all cases, so it is recommended to use them if possible.
What unconstrained taboo codes offer over generalized Fibonacci codes is the
ability to have any ending pattern and having the prefix be lexicographically
ordered.  For most purposes these are not important.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_blocktaboo($taboo, $value) >

=item B< put_blocktaboo($taboo, @values) >

Insert one or more values as block taboo codes using the binary string
C<$taboo> as the terminator.  Returns 1.

=item B< get_blocktaboo($taboo) >

=item B< get_blocktaboo($taboo, $count) >

Decode one or more block taboo codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The parameter C<taboo> is a binary string, meaning it is a string comprised
exclusively of C<'0'> and C<'1'> characters.  The length is the chunk size in
bits, and must be between 1 and 16.  Using C<'00'> gives the codes from
table 2 of Pigeon's paper (where the chunk size C<n=2> and the taboo pattern
is the two-bits C<'00'>).

If C<taboo> is C<'0'> then one-based unary coding is used (e.g. a string of
C<1> bits followed by a C<0>).
If C<taboo> is C<'1'> then zero-based unary coding is used (e.g. a string of
C<0> bits followed by a C<1>).

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item Steven Pigeon, "Taboo Codes: New Classes of Universal Codes", 2001.

=item L<Data::BitStream::Code::Fibonacci>

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2012 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
