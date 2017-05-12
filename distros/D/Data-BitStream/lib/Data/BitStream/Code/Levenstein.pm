package Data::BitStream::Code::Levenstein;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Levenstein::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Levenstein::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'Levenstein',
                  aliases   => ['Levenshtein'],
                  universal => 1,
                  params    => 0,
                  encodesub => sub {shift->put_levenstein(@_)},
                  decodesub => sub {shift->get_levenstein(@_)}, };

sub _floorlog2_lev {
  my $d = shift;
  my $base = 0;
  $base++ while ($d >>= 1);
  $base;
}

use Moo::Role;
requires qw(read write get_unary1 put_unary1);

# Levenstein code (also called Levenshtein).
#
# Early variable length code (1968), rarely used.
# Compares to Elias Omega and Even-Rodeh.
#
# See:  V.E. Levenstein, "On the Redundancy and Delay of Separable Codes for the Natural Numbers," in Problems of Cybernetics v. 20 (1968), pp 173-179.
#
# Notes:
#   This uses a 1-based unary coding.  This matches the code definition,
#   though is less efficient with most BitStream implementations.
#
#   Given BitStream's 0-based Omega,
#       length(levenstein(k+1)) == length(omega(k))+1   for all k >= 0
#

sub put_levenstein {
  my $self = shift;

  foreach my $v (@_) {
    $self->error_code('zeroval') unless defined $v and $v >= 0;
    if ($v == 0) { $self->write(1, 0); next; }

    # Simpler code:
    # while ( (my $base = _floorlog2($val)) > 0) {
    #   unshift @d, [$base, $val];
    #   $val = $base;
    # }
    # $self->put_unary1(scalar @d + 1);
    # foreach my $aref (@d) {  $self->write( @{$aref} );  }

    my $val = $v;
    my @d;
if (0) {
    while ( (my $base = _floorlog2_lev($val)) > 0) {
      unshift @d, [$base, $val];
      $val = $base;
    }
    $self->put_unary1(scalar @d + 1);
} else {
    # Bundle up groups of 32-bit writes.
    my $cbits = 0;
    my $cword = 0;
    my $C = 1;
    while ( (my $base = _floorlog2_lev($val)) > 0) {
      $C++;
      my $cval = $val & ~(1 << $base);  # erase bit above base
      if (($cbits + $base) >= 32) {
        unshift @d, [$cbits, $cword] if $cbits > 0;
        $cword = $cval;
        $cbits = $base;
      } else {
        $cword |= ($cval << $cbits);
        $cbits += $base;
      }
      $val = $base;
    }
    unshift @d, [$cbits, $cword] if $cbits > 0;;
    $self->put_unary1($C);
}

    foreach my $aref (@d) {  $self->write( @{$aref} );  }
  }
  1;
}

sub get_levenstein {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  my $maxbits = $self->maxbits;
  $self->code_pos_start('Levenstein');
  while ($count-- > 0) {
    $self->code_pos_set;

    my $C = $self->get_unary1;
    last unless defined $C;

    my $val = 0;
    if ($C > 0) {
      my $N = 1;
      for (1 .. $C-1) {
        $self->error_code('overflow') if $N > $maxbits;
        my $next = $self->read($N);
        $self->error_off_stream unless defined $next;
        $N = (1 << $N) | $next;
      }
      $val = $N;
    }
    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Levenstein codes

=pod

=encoding utf8

=head1 NAME

Data::BitStream::Code::Levenstein - A Role implementing Levenstein codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
the Levenstein codes.  The role applies to a stream object.

These are also known as Levenshtein or Левенште́йн codes.  They are often used
in situations where the Elias Omega, Even-Rodeh, or Fibonacci codes would be
considered.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_levenstein($value) >

=item B< put_levenstein(@values) >

Insert one or more values as Levenstein codes.  Returns 1.

=item B< get_levenstein() >

=item B< get_levenstein($count) >

Decode one or more Levenstein codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

=item B< get_unary1 >

=item B< put_unary1 >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item V.E. Levenstein, "On the Redundancy and Delay of Separable Codes for the Natural Numbers," in Problems of Cybernetics v. 20 (1968), pp 173-179.

=back

=head1 AUTHORS

Dana Jacobsen E<lt>dana@acm.orgE<gt>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
