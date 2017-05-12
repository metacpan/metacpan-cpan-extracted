package Data::BitStream::Code::Comma;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Comma::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Comma::VERSION = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'Comma',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {shift->put_comma(@_)},
                  decodesub => sub {shift->get_comma(@_)}, };

use Moo::Role;
requires qw(read write);

sub put_comma {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $bits = shift;
  $self->error_code('param', 'bits must be in range 1-16') unless $bits >= 1 && $bits <= 16;

  return $self->put_unary(@_) if $bits == 1;
  my $comma = ~(~0 << $bits);   # 1 x $bits is the terminator
  my $base = 2**$bits - 1;      # The base of the digits we're writing

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;

    if ($val == 0) { $self->write(   $bits, $comma );  next; }  # c

    my $v = $val;
    my @stack = ($comma);
    while ($v > 0) {
      push @stack, $v % $base;
      $v = int($v / $base);
    }
    # Write the stack.  Simple way:
    #    $self->write($bits, pop @stack) while @stack;
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

sub get_comma {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $bits = shift;
  $self->error_code('param', 'bits must be in range 1-16') unless $bits >= 1 && $bits <= 16;

  return $self->get_unary(@_) if $bits == 1;
  my $comma = ~(~0 << $bits);   # 1 x $bits is the terminator
  my $base = 2**$bits - 1;      # The base of the digits we're writing

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Comma');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $tval = $self->read($bits);
    last unless defined $tval;

    my $val = 0;
    while ($tval != $comma) {
      $val = $base * $val + $tval;
      $tval = $self->read($bits);
      $self->error_off_stream unless defined $tval;
    }
    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}

no Moo::Role;
1;

# ABSTRACT: A Role implementing Comma codes

=pod

=head1 NAME

Data::BitStream::Code::Comma - A Role implementing Comma codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Comma codes.  The role applies to a stream object.

Comma codes are described in many sources.  The codes are written in C<k>-bit
chunks, where a chunk consisting of all 1 bits indicates the end of the code.
The number to be encoded is stored in base C<2^k-1>.  The case of 1-bit comma
codes degenerates into unary codes.  The most common comma code in current use
is the ternary comma code which uses 2-bit chunks and stores the number in
base 3 (hence why it is called ternary comma).  Example for ternary comma:

      value        code          binary         bits
          0           c                    11    2
          1          1c                  0111    4
          2          2c                  1011    4
          3         10c                010011    6
          4         11c                010111    6
  ..      8         22c                101011    6
          9        100c              01000011    8
  ..     64       2101c            1001000111   10
  ..  10000  111201101c  01010110000101000111   20

Comma codes using larger chunks compact larger numbers better, but the
terminator also grows.  This means smaller values take more bits to encode,
and all codes have many wasted bits after the information.

Also note that skipping the leading C<0>s for all codes results in a large
waste of space.  For instance, the codes C<0xc>, C<0xxc>, C<0xxxc>, etc. are
all not used, even though they are uniquely decodable.  Note that Fenwick's
table 6 (p6) shows C<0c> being used, but no other leading zero.  This is not
the case in Sayood's table 3.19 (p71) where no entry has a leading zero.

These codes are a special case of the block-based taboo codes (Pigeon 2001).
The taboo codes fully utilize all the bits.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_comma($bits, $value) >

=item B< put_comma($bits, @values) >

Insert one or more values as Comma codes using C<$bits> bits.  Returns 1.

=item B< get_comma($bits) >

=item B< get_comma($bits, $count) >

Decode one or more Comma codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The parameter C<bits> must be an integer between 1 and 16.  This indicates
the number of bits used per chunk.

If C<bits> is 1, then unary coding is used.

Ternary comma coding is the special case of comma coding with C<bits=2>.

Byte coding is the special case of comma coding with C<bits=8>.

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers", Technical Report 137, Department of Computer Science, University of Auckland, December 1996.

=item Peter Fenwick, "Ziv-Lempel encoding with multi-bit flags", Proc. Data Compression Conference (IEEE DCC), Snowbird, Utah, pp 138-147, March 1993.

=item Khalid Sayood (editor), "Lossless Compression Handbook", 2003.

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2012 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
