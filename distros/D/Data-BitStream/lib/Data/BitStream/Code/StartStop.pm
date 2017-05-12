package Data::BitStream::Code::StartStop;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::StartStop::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::StartStop::VERSION   = '0.08';
}

our $CODEINFO = [
    { package   => __PACKAGE__,
      name      => 'StartStop',
      universal => 1,
      params    => 1,
      encodesub => sub {shift->put_startstop([split('-',shift)], @_)},
      decodesub => sub {shift->get_startstop([split('-',shift)], @_)}, },
    { package   => __PACKAGE__,
      name      => 'StartStepStop',
      universal => 1,
      params    => 1,
      encodesub => sub {shift->put_startstepstop([split('-',shift)], @_)},
      decodesub => sub {shift->get_startstepstop([split('-',shift)], @_)}, },
                ];

use Moo::Role;
requires qw(maxbits read skip write put_unary put_binword put_rice);

# Start/Stop and Start-Step-Stop codes.
#
# See:  Steven Pigeon, "Start/Stop Codes", Universite de Montreal.
#
# See:  E.R. Fiala, D.H. Greene, "Data Compression with Finite Windows", Comm ACM, Vol 32, No 4, pp 490-505 , April 1989
#
# See: Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers", Technical Report 137, Department of Computer Science, University of Auckland, December 1996
#
# Note that we keep the same unary convention as the rest of BitStream, which
# is that unary codes are written with 0's followed by a 1.  The original
# paper by Fiala and Greene use 1's followed by a 0.
#
# The S/S parameters come in as an array.  Hence:
#
# $stream->put_startstop( [0,3,2,0], $value );
# $stream->put_startstepstop( [3,2,9], $value );
#
# $stream->get_startstop( [0,3,2,0], $value );
# $stream->get_startstepstop( [3,2,9], $value );
#
# A stop parameter of undef means infinity.

sub _verify_p_array {
  my $p = shift;
  return 0 unless defined $p && ref $p eq 'ARRAY' && scalar @$p >= 2;
  foreach my $step (@$p) {
    return 0 unless (!defined $step) || ($step >= 0);
  }
  1;
}
sub _make_prefix_map {
  my $p = shift;
  my $maxbits = shift;

  my @pmap;        # [prefix bits, prefix cmp, min, max, read bits]

  my $prefix_size = scalar @$p - 1;
  my $prefix_cmp = 1 << $prefix_size;
  my $prefix = 0;
  my $bits = 0;
  my $minval = -1;
  my $maxval = 0;
  foreach my $step (@$p) {
    $bits += (defined $step) ? $step : $maxbits;
    $bits = $maxbits if $bits > $maxbits;
    $minval += $maxval+1;
    $maxval = ($bits < $maxbits) ? (1<<$bits)-1 : ~0;
    $prefix++;
    $prefix_cmp >>= 1;
    push @pmap, [$prefix, $prefix_cmp, $minval, $minval+$maxval, $bits];
  }
  # Patch the last value
  $pmap[-1]->[0]--;
#foreach my $m (@pmap) { ($prefix,$prefix_cmp,$minval,$maxval,$bits)=@$m; print "[$prefix]: $prefix_cmp cmp $bits bits  range $minval - $maxval\n"; }
  return @pmap;
}

# class method -- returns the maximum storable value for a given ss(...) code
sub max_code_for_startstop {
  my $p = shift;
  return unless _verify_p_array($p);
  my @pmap = _make_prefix_map($p, Data::BitStream::Base::maxbits);
  return $pmap[-1]->[3];
}

sub get_startstop {
  my $self = shift;
  my $p = shift;
  $self->error_code('param', 'malformed step array') unless _verify_p_array($p);
  my @pmap = _make_prefix_map($p, $self->maxbits);
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my $looksize = $pmap[-1]->[0];

  my @vals;
  while ($count-- > 0) {
    my $look = $self->read($looksize, 'readahead');
    last unless defined $look;
    my $prefix = 0;
    $prefix++ while ($look < $pmap[$prefix]->[1]);
    my($prefix_bits,$prefix_cmp,$minval,$maxval,$bits) = @{$pmap[$prefix]};
    $self->skip($prefix_bits);
    my $val = $minval;
    $val += $self->read($bits) if $bits > 0;
    push @vals, $val;
  }
  wantarray ? @vals : $vals[-1];
}
sub put_startstop {
  my $self = shift;
  my $p = shift;
  $self->error_code('param', 'malformed step array') unless _verify_p_array($p);
  my @pmap = _make_prefix_map($p, $self->maxbits);
  my $global_maxval = $pmap[-1]->[3];
  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    $self->error_code('range', $val, 0,$global_maxval) if $val > $global_maxval;
    my $prefix = 0;
    $prefix++ while ($val > $pmap[$prefix]->[3]);
    my($prefix_bits,$prefix_cmp,$minval,$maxval,$bits) = @{$pmap[$prefix]};

    if (($prefix_bits + $bits) <= 32) {
      # Single write
      my $v = ($prefix_cmp == 0) ? $val-$minval : ($val-$minval) | (1<<$bits);
      $self->write($prefix_bits + $bits, $v);
    } else {
      if ($prefix_cmp == 0) { $self->write($prefix_bits, 0); }
      else                  { $self->put_unary($prefix_bits-1); }
      $self->write($bits, $val - $minval) if $bits > 0;
    }
  }
}

sub _extract_p {
  my $self = shift;
  my $p = shift;

  $self->error_code('param', 'p must be an array')
               unless (defined $p) && (ref $p eq 'ARRAY') && scalar @$p >= 3;
  my($start, $step, $stop) = @$p;
  my $maxstop = $self->maxbits;
  $stop = $maxstop if (!defined $stop) || ($stop > $maxstop);

  $self->error_code('param', "start must be in range 0-$maxstop") unless ($start >= 0) && ($start <= $maxstop);
  $self->error_code('param', 'step must be >= 0') unless $step >= 0;
  $self->error_code('param', 'stop must be >= start') unless $stop >= $start;

  ($start, $step, $stop, $maxstop);
}
sub _map_sss_to_ss {
  my($start, $step, $stop, $maxstop) = @_;

  my @pmap = ($start);
  my $blen = $start;
  while ($blen < $stop) {
    $blen += $step;
    $blen = $stop if $blen > $stop;
    push @pmap, $step;
  }
  @pmap;
}

sub put_startstepstop {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my ($start, $step, $stop, $maxstop) = _extract_p($self, shift);

  return $self->put_binword($start, @_) if $start == $stop;
  return $self->put_rice($start, @_)    if $step == 0;

  my @pmap = _map_sss_to_ss($start, $step, $stop, $maxstop);
  $self->error_code('assert', "unknown array condition") if scalar @pmap < 2;
  #print "Turning sss($start-$step-$stop) into ss(", join("-",@pmap), ")\n";

  $self->put_startstop( [@pmap], @_ );
}
sub get_startstepstop {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my ($start, $step, $stop, $maxstop) = _extract_p($self, shift);

  return $self->get_binword($start, @_) if $start == $stop;
  return $self->get_rice($start, @_)    if $step == 0;

  my @pmap = _map_sss_to_ss($start, $step, $stop, $maxstop);
  $self->error_code('assert', "unknown array condition") if scalar @pmap < 2;

  return $self->get_startstop( [@pmap], @_ );
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Start/Stop and Start-Step-Stop codes

=pod

=head1 NAME

Data::BitStream::Code::StartStop - A Role implementing Start/Stop and Start-Step-Stop codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Start/Stop and Start-Step-Stop codes.  The role applies to a stream object.

Start-Step-Stop codes are described in Fiala and Greene (1989).  The Start/Stop
codes are described in Steven Pigeon (2001) and are a generalization of the
S-S-S codes.  This implementation turns the Start-Step-Stop parameters into
Start/Stop codes.

=head1 EXAMPLES

  use Data::BitStream;
  my $stream = Data::BitStream->new;
  my @array = (4, 2, 0, 3, 7, 72, 0, 1, 13);

  $stream->put_startstop( [0,3,2,0], @array );
  $stream->rewind_for_read;
  my @array2 = $stream->get_startstop( [0,3,2,0], -1);

  $stream->erase_for_write;
  $stream->put_startstepstop( [3,2,9], @array );
  $stream->rewind_for_read;
  my @array3 = $stream->get_startstepstop( [3,2,9], -1);

  # @array equals @array2 equals @array3

=head1 METHODS

=head2 Provided Class Methods

=over 4

=item B< max_code_for_startstop([@m]) >

Given a set of parameters @m, returns the maximum integer that can be encoded
with those parameters (the minimum is always 0, like other codes).  For
example, for two example the C<{0,3,2,0}> parameters from Pigeon's paper:

  $maxval = Data::BitStream::Code::StartStop::max_code_for_startstop([0,3,2,0]);
  # $maxval will be 72
  $maxval = Data::BitStream::Code::StartStop::max_code_for_startstop([3,3,3,0]);
  # $maxval will be 1095

=back

=head2 Provided Object Methods

=over 4

=item B< put_startstop([@m], $value) >

=item B< put_startstop([@m], @values) >

Insert one or more values as Start/Stop codes.  Returns 1.

=item B< put_startstepstop([$start, $step, $stop], $value) >

=item B< put_startstepstop([$start, $step, $stop], @values) >

Insert one or more values as Start-Step-Stop codes.  Returns 1.

=item B< get_startstop([@m]) >

=item B< get_startstop([@m], $count) >

Decode one or more Start/Stop codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=item B< get_startstepstop([$start, $step, $stop]) >

=item B< get_startstepstop([$start, $step, $stop], $count) >

Decode one or more Start-Step-Stop codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The Start/Stop and Start-Step-Stop parameters are passed as a array reference.

For Start-Step-Stop codes, there must be exactly three entries.  All three
parameters must be greater than or equal to zero.  These are turned into
Start/Stop codes.

There must be a minimum of two Start/Stop parameters.  Each parameter must be
greater than or equal to zero.  A parameter of undef will be treated as equal
to the maximum supported bits in an integer.

=head2 Required Methods

=over 4

=item B< maxbits >

=item B< read >

=item B< write >

=item B< skip >

=item B< put_unary >

=item B< put_binword >

=item B< put_rice >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item Steven Pigeon, "Start/Stop Codes", in Proceedings of the 2001 Data
      Compression Conference, 2001.

=item E.R. Fiala, D.H. Greene, "Data Compression with Finite Windows", Comm ACM, Vol 32, No 4, pp 490-505 , April 1989

=item Peter Fenwick, "Punctured Elias Codes for variable-length coding of the integers", Technical Report 137, Department of Computer Science, University of Auckland, December 1996

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011-2012 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
