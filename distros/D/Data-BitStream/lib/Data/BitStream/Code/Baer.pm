package Data::BitStream::Code::Baer;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Baer::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Baer::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'Baer',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {shift->put_baer(@_)},
                  decodesub => sub {shift->get_baer(@_)}, };

use Moo::Role;
requires 'read', 'write', 'put_unary', 'get_unary';

# Baer codes.
#
# Used for efficiently encoding data with a power law distribution.
#
# See:  Michael B. Baer, "Prefix Codes for Power Laws," in IEEE International Symposium on Information Theory 2008 (ISIT 2008), pp 2464-2468, Toronto ON.
# https://hkn.eecs.berkeley.edu/~calbear/research/ISITuni.pdf

sub put_baer {
  my $self = shift;
  my $k = shift;
  $self->error_code('param', 'k must be between -32 and 32') if $k > 32 || $k < -32;
  my $mk = ($k < 0) ? int(-$k) : 0;

  foreach my $v (@_) {
    $self->error_code('zeroval') unless defined $v and $v >= 0;
    if ($v < $mk) {
      $self->put_unary1($v);
      next;
    }
    my $val = ($k==0)  ?  $v+1  :  ($k < 0)  ?  $v-$mk+1  :  1+($v>>$k);
    my $C = 0;
    my $postword = 0;

    # This fixes range issues with k=0 and v=~0.  Run one cycle using v.
    if ( ($k == 0) && ($v >= 3) ) {
      if (($v & 1) == 0) { $val = ($v - 2) >> 1; $postword = 1; }
      else               { $val = ($v - 1) >> 1; }
      $C = 1;
    }

    while ($val >= 4) {
      if (($val & 1) == 0) { $val = ($val - 2) >> 1; }
      else                 { $val = ($val - 3) >> 1; $postword |= (1 << $C); }
      $C++;
    }

    $self->put_unary1($C + $mk);
    if    ($val == 1) { $self->write(1, 0); }
    else              { $self->write(2, $val); }
    $self->write($C, $postword) if $C > 0;
    $self->write($k, $v) if $k > 0;
  }
  1;
}

sub get_baer {
  my $self = shift;
  my $k = shift;
  $self->error_code('param', 'k must be between -32 and 32') if $k > 32 || $k < -32;
  my $mk = ($k < 0) ? int(-$k) : 0;

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  my $maxbits = $self->maxbits;
  $self->code_pos_start('Baer');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $C = $self->get_unary1;
    last unless defined $C;
    if ($C < $mk) {
      push @vals, $C;
      next;
    }
    $C -= $mk;
    $self->error_code('overflow') if $C > $maxbits;
    my $val = ($self->read(1) == 0)  ?  1  :  2 + $self->read(1);

    # Code following the logic in the paper:
    #
    #   while ($C-- > 0) {  $val = 2 * $val + 2 + $self->read(1);  }
    #   $val += $mk;
    #   if ($k > 0) { $val = ( (($val-1) << $k) | $self->read($k) ); }
    #   $val -= 1;  # to get back to 0-base from paper's 1-base;
    #
    # We can unroll the while loop, and be careful with overflow of ~0

    $val = ($val << $C) + $mk - 1;
    if ($C > 0) { $val += ((1 << ($C+1)) - 2) + $self->read($C); }
    if ($k > 0) { $val = ( ($val << $k) | $self->read($k) ); }

    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Michael B. Baer's power law codes

=pod

=head1 NAME

Data::BitStream::Code::Baer - A Role implementing Baer codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
the power law codes of Michael B. Baer.  The role applies to a stream object.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_baer($k, $value) >

=item B< put_baer($k, @values) >

Insert one or more values as Baer c_k codes.  Returns 1.

=item B< get_baer($k) >

=item B< get_baer($k, $count) >

Decode one or more Baer c_k codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The parameter k cannot be more than 32.

C<k=0> is the base c_0 code.

C<kE<lt>0> performs unary (1-based) coding of small values followed
by c_0 coding the remainder (C<c_o(value+k)>) for large values.  This works well
when the probability of small values is much higher than larger values.

C<kE<gt>0> is similar to a Rice(k) code in that we encode
C<c_o(valueE<gt>E<gt>k)> followed by encoding the bottom k bits of value.
This works well when most values are medium-sized.

Typical k values are between -6 and 6.

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

=item Michael B. Baer, "Prefix Codes for Power Laws," in IEEE International Symposium on Information Theory 2008 (ISIT 2008), pp 2464-2468, Toronto ON.

=item L<https://hkn.eecs.berkeley.edu/~calbear/research/ISITuni.pdf>

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
