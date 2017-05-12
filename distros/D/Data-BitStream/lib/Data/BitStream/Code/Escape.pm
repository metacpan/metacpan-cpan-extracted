package Data::BitStream::Code::Escape;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Escape::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Escape::VERSION = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'Escape',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {put_escape(shift,[split('-',shift)], @_)},
                  decodesub => sub {get_escape(shift,[split('-',shift)], @_)}, };

use Moo::Role;
requires qw(read write maxbits);

# Escape code.  Similar to Start/Stop codes, but rather than encoding the
# prefix in unary, a maximum value in a block (binary all 1's) indicates we
# move to the next block.
#
# The parameter comes in as an array.  Hence:
#
# $stream->put_escape( [3,5,9,32], $value );
#
# $stream->get_escape( [3,5,9,32], $value );
#
# A parameter of undef means maxbits.

sub put_escape {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $p = shift;
  $self->error_code('param', 'p must be an array') unless (ref $p eq 'ARRAY') && scalar @$p >= 1;

  my $maxbits = $self->maxbits;
  my @parray = map { (defined $_ && $_ <= $maxbits) ? $_ : $maxbits } @$p;
  foreach my $p (@parray) {
    $self->error_code('param', 'p entries must be > 0') if $p <= 0;
  }

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    my @bitarray = @parray;
    my $bits = shift @bitarray;
    my $min = 0;
    my $maxval = ($bits < $maxbits) ? (1<<$bits)-2 : ~0-1;
    my $onebits = 0;

    #print "[$onebits]: $bits bits  range $min - ", $min+$maxval, "\n";
    while ( ($val-$min) > $maxval ) {
      $onebits += $bits;
      $min += $maxval+1;
      $self->error_code('range', $val, 0, $maxval) if scalar @bitarray == 0;
      $bits = shift @bitarray;
      $maxval = ($bits < $maxbits) ? (1<<$bits)-2 : ~0-1;
      $maxval++ if scalar @bitarray == 0;
      #print "[$onebits]: $bits bits  range $min - ", $min+$maxval, "\n";
    }
    while ($onebits > 32) { $self->write(32, 0xFFFFFFFF); $onebits -= 32; }
    if ($onebits > 0)     { $self->write($onebits, 0xFFFFFFFF); }
    $self->write($bits, $val-$min) if $bits > 0;
  }
  1;
}

sub get_escape {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $p = shift;
  $self->error_code('param', 'p must be an array') unless (ref $p eq 'ARRAY') && scalar @$p >= 1;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my $maxbits = $self->maxbits;
  my @parray = map { (defined $_ && $_ <= $maxbits) ? $_ : $maxbits } @$p;
  foreach my $p (@parray) {
    $self->error_code('param', 'p entries must be > 0') if $p <= 0;
  }

  my @vals;
  while ($count-- > 0) {
    my @bitarray = @parray;
    my($min,$maxval,$bits,$v) = (-1,0,0,0);
    do {
      $min += $maxval+1;
      $self->error_code('overflow') if scalar @bitarray == 0;
      $bits = shift @bitarray;
      $maxval = ($bits < $maxbits) ? (1<<$bits)-2 : ~0-1;
      $maxval++ if scalar @bitarray == 0;
      $v = $self->read($bits);
      last unless defined $v;
      #print "read $bits bits, maxval = $maxval, v = $v, val = ", $v+$min, "\n";
    } while ($v == ($maxval+1));
    push @vals, $min+$v;
  }
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Escape codes

=pod

=head1 NAME

Data::BitStream::Code::Escape - A Role implementing Escape codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Escape codes.  The role applies to a stream object.

An Escape code is a code where a binary value is read using C<m> bits
(C<m E<gt>= 1>), and if the read value is equal to C<2^m-1>,
then another C<n> bits is read (C<n E<gt>= 1>), etc.  They are somewhat similar
to Start/Stop codes, though use an escape value inside each block instead of
a unary indicator.  For example a 3-7 code would look like:

  0     000
  1     001
  2     010
  ...
  6     110
  7     1110000000
  8     1110000001
  ...
  134   1111111111

These codes are not uncommon in a variety of applications where extremely
simple variable length coding is desired, but for various reasons none of
the more sophisticated methods are used.  These codes can be quite useful
for some cases such as a 8-32 code which encodes 0-254 in one byte and
values greater than 254 in five bytes.  Based on the frequencies and
implementation, this may be more desirable than other methods such as a
startstop(7-25) code which encodes 0-127 in one byte and values greater
than 127 in four bytes.

For many cases, and almost all where more than two parameters are used,
Start/Stop codes will be more space efficient.


=head1 EXAMPLES

  use Data::BitStream;
  my $stream = Data::BitStream->new;
  my @array = (4, 2, 0, 3, 7, 72, 0, 1, 13);

  $stream->put_escape( [3,7], @array );
  $stream->rewind_for_read;
  my @array2 = $stream->get_escape( [3,7], -1);

  # @array equals @array2

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_escape([@m], $value) >

=item B< put_escape([@m], @values) >

Insert one or more values as Escape codes.  Returns 1.

=item B< get_escape([@m]) >

=item B< get_escape([@m], $count) >

Decode one or more Escape codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The Escape parameters are passed as a array reference.

There must be at least one parameter.  Each parameter must be greater than
or equal to zero.  Each value is the number of bits in the block.  

=head2 Required Methods

=over 4

=item B< maxbits >

=item B< read >

=item B< write >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item L<Data::BitStream::Code::StartStop>

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
