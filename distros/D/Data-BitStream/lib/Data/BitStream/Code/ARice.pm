package Data::BitStream::Code::ARice;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::ARice::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::ARice::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'ARice',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {shift->put_arice(@_)},
                  decodesub => sub {shift->get_arice(@_)}, };

use Moo::Role;
requires qw(read write write_close put_unary get_unary);

sub _ceillog2_arice {
  my $d = $_[0] - 1;
  my $base = 1;
  $base++ while ($d >>= 1);
  $base;
}

use constant _QLOW  => 0;
use constant _QHIGH => 7;

sub _adjust_k {
  my ($k, $q) = @_;
  return $k-1  if $q <= _QLOW  &&  $k > 0;
  return $k+1  if $q >= _QHIGH &&  $k < 60;
  $k;
}

sub put_arice {
  my $self = shift;
  my $sub = shift if ref $_[0] eq 'CODE';  ## no critic
  my $kref = \shift;
  my $k = $$kref;
  $self->error_code('param', 'k must be >= 0') unless $k >= 0;

  # If small values are common (k often 0) then this will reduce the number
  # of method calls required, which makes us run a little faster.
  my @q_list;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    if ($k == 0) {
      push @q_list, $val;
      $k++ if $val >= _QHIGH;   # _adjust_k shortcut
    } else {
      my $q = $val >> $k;
      my $r = $val - ($q << $k);
      if (@q_list) {
        push @q_list, $q;
        (defined $sub)  ?  $sub->($self, @q_list)  :  $self->put_gamma(@q_list);
        @q_list = ();
      } else {
        (defined $sub)  ?  $sub->($self, $q)  :  $self->put_gamma($q);
      }
      $self->write($k, $r);
      $k = _adjust_k($k, $q);
    }
  }
  if (@q_list) {
    (defined $sub)  ?  $sub->($self, @q_list)  :  $self->put_gamma(@q_list);
  }
  $$kref = $k;
  1;
}
sub get_arice {
  my $self = shift;
  my $sub = shift if ref $_[0] eq 'CODE';  ## no critic
  my $kref = \shift;
  my $k = $$kref;
  $self->error_code('param', 'k must be >= 0') unless $k >= 0;

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('ARice');
  while ($count-- > 0) {
    $self->code_pos_set;
    # Optimization: if possible (k==0), read two values at once.
    my($q, $q1);
    if ( ($k == 0) && ($count > 0) ) {
      ($q1, $q) = (defined $sub)  ?  $sub->($self, 2)  :  $self->get_gamma(2);
      last unless defined $q1;
      push @vals, $q1;
      $k = _adjust_k($k, $q1);
      $count--;
      $self->code_pos_set;
    } else {
      $q = (defined $sub)  ?  $sub->($self)  :  $self->get_gamma();
    }
    last unless defined $q;
    if ($k == 0) {
      push @vals, $q;
    } else {
      my $remainder = $self->read($k);
      $self->error_off_stream unless defined $remainder;
      push @vals, (($q << $k) | $remainder);
    }
    $k = _adjust_k($k, $q);
  }
  $self->code_pos_end;
  $$kref = $k;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Adaptive Rice codes

=pod

=head1 NAME

Data::BitStream::Code::ARice - A Role implementing Adaptive Rice codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Adaptive Rice codes.  The role applies to a stream object.

The default method used is to store the values using Gamma-Rice codes (also
called Exponential-Golomb codes).  The upper C<k> bits are stored in Elias
Gamma form, and the lower C<k> bits are stored in binary.  When C<k=0> this
becomes Gamma coding.

As each value is read or written, C<k> is adjusted.  If the upper value is
zero and C<k E<gt> 0>, C<k> is reduced.  If the upper value is greater than
six and C<l E<lt> 60>, C<k> is increased.  This simple method does a fairly
good job of keeping C<k> in a useful range as incoming values vary.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_arice($k, $value) >

=item B< put_arice($k, @values) >

Insert one or more values as Rice codes with parameter C<k>.  The value of
C<k> will change as values are inserted.  Returns 1.

The parameter C<$k> will be modified.  Do not attempt to use a read-only value.

=item B< put_arice(sub { ... }, $m, @values) >

Insert one or more values as Rice codes using the user provided subroutine
instead of the Gamma code for the base.  Traditional Rice codes:

  sub { shift->put_unary(@_); }

Note that since the adaptive codes would be used when the input data is
changing, care should be taken with the code used for the upper bits.  A
universal code is almost always recommended, which Unary is not.  Something
like Gamma, Delta, Omega, Fibonacci, etc. will typically be a good choice.

=item B< get_arice($k) >

=item B< get_arice($k, $count) >

Decode one or more Rice codes from the stream with adaptive C<k>.
If count is omitted, one value will be read.  If count is negative, values
will be read until the end of the stream is reached.  In scalar context it
returns the last code read; in array context it returns an array of all
codes read.

The parameter C<$k> will be modified.  Do not attempt to use a read-only value.

=item B< get_arice(sub { ... }, $k) >

Similar to the regular get method except using the user provided subroutine
instead of Gamma encoding the base.

=back

=head2 Parameters

The parameter C<k> must be an integer greater than or equal to 0.  It will
be modified by the routine, so do not use a read-only parameter.

The quotient of C<value E<gt>E<gt> k> is encoded using an Elias Gamma code
(or via the user supplied subroutine), followed by the lower C<k> bits.

The value of C<k> is modified as values are read or written to keep the
number of upper bits reasonably low as the data changes.

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

=item B< get_gamma >

=item B< put_gamma >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item L<Data::BitStream::Code::Rice>

=item L<Data::BitStream::Code::Golomb>

=item L<Data::BitStream::Code::GammaGolomb>

=item L<Data::BitStream::Code::ExponentialGolomb>

=item L<Data::BitStream::Code::Gamma>

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011-2012 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
