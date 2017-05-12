package Data::BitStream::Code::BoldiVigna;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::BoldiVigna::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::BoldiVigna::VERSION   = '0.08';
}

our $CODEINFO = { package   => __PACKAGE__,
                  name      => 'BoldiVigna',
                  universal => 1,
                  params    => 1,
                  encodesub => sub {shift->put_boldivigna(@_)},
                  decodesub => sub {shift->get_boldivigna(@_)}, };

use Moo::Role;
requires qw(read write put_unary get_unary maxbits get_gamma put_gamma);

# Boldi-Vigna Zeta codes.

# Holds cached calculated parameters for each k
my @hp_cache;

# Calculates parameters for a given k and maxbits.
sub _hparam_map {
  my $k = shift;
  my $maxbits = shift;

  #my $maxh = 0;
  #$maxh++ while ($k * ($maxh+1)) < $maxbits;
  my $maxh = int( ($maxbits-1) / $k );
  my $maxhk = $maxh * $k;

  my @hparams;  # stores [s threshold] for each h
  foreach my $h (0 .. $maxh) {
    my $hk = $h*$k;
    my $interval = (1 << ($hk+$k)) - (1 << $hk) - 1;
    my $z = $interval+1;
    my $s = 1;
    { my $v = $z;  $s++ while ($v >>= 1); } # ceil log2($z)
    my $threshold = (1 << $s) - $z;
    $hparams[$h] = [ $s, $threshold ];
    #print "storing params for h=$h  [ $s, $threshold ]\n";
  }

  return $maxhk, \@hparams;
}

sub put_boldivigna {
  my $self = shift;
  my $k = shift;
  $self->error_code('param', "k must be in range 1-15") if $k < 1 || $k > 15;

  return $self->put_gamma(@_) if $k == 1;

  my($maxhk, $hparams);
  if (defined $hp_cache[$k]) {
    ($maxhk, $hparams) = @{$hp_cache[$k]};
  } else {
    ($maxhk, $hparams) = _hparam_map($k, $self->maxbits);
    $hp_cache[$k] = [$maxhk, $hparams];
  }
  my $maxval = $self->maxval;

  foreach my $v (@_) {
    $self->error_code('zeroval') unless defined $v and $v >= 0;

    if ($v == $maxval) {
      $self->put_unary( ($maxhk/$k)+1 );
      next;
    }

    my $hk = 0;
    $hk += $k  while ( ($hk < $maxhk) && ($v >= ((1 << ($hk+$k))-1)) );
    my $h = $hk/$k;
    $self->put_unary($h);

    my $x = $v - (1 << $hk) + 1;
    # Encode $x using "minimal binary code"
    my ($s, $threshold) = @{$hparams->[$h]};
    #print "using params for h=$h  [ $s, $threshold ]\n";
    if ($x < $threshold) {
      #print "minimal code $x in ", $s-1, " bits\n";
      $self->write($s-1, $x);
    } else {
      #print "minimal code $x => ", $x+$threshold, " in $s bits\n";
      $self->write($s, $x+$threshold);
    }
  }
  1;
}
sub get_boldivigna {
  my $self = shift;
  my $k = shift;
  $self->error_code('param', "k must be in range 1-15") if $k < 1 || $k > 15;

  return $self->get_gamma(@_) if $k == 1;

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my($maxhk, $hparams);
  if (defined $hp_cache[$k]) {
    ($maxhk, $hparams) = @{$hp_cache[$k]};
  } else {
    ($maxhk, $hparams) = _hparam_map($k, $self->maxbits);
    $hp_cache[$k] = [$maxhk, $hparams];
  }

  my @vals;
  $self->code_pos_start('BoldiVigna');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $h = $self->get_unary();
    last unless defined $h;
    if ($h > ($maxhk/$k)) {
      push @vals, $self->maxval;
      next;
    }
    my ($s, $threshold) = @{$hparams->[$h]};

    my $first = $self->read($s-1);
    $self->error_off_stream unless defined $first;
    if ($first >= $threshold) {
      my $extra = $self->read(1);
      $self->error_off_stream unless defined $extra;
      $first = ($first << 1) + $extra - $threshold;
    }
    my $val = (1 << $h*$k) + $first - 1;
    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing the Zeta codes of Boldi and Vigna

=pod

=head1 NAME

Data::BitStream::Code::BoldiVigna - A Role implementing Zeta codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Zeta codes of Paolo Boldi and Sebastiano Vigna.  These codes are useful for
integers distributed as a power law with small exponent (smaller than 2).
The role applies to a stream object.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_boldivigna($k, $value) >

=item B< put_boldivigna($k, @values) >

Insert one or more values as Zeta_k codes.  Returns 1.

=item B< get_boldivigna($k) >

=item B< get_boldivigna($k, $count) >

Decode one or more Zeta_k codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=back

=head2 Parameters

The parameter k must be between 1 and maxbits (32 or 64).

C<k=1> is equivalent to Elias Gamma coding.

For values of C<k E<gt> 6> the Elias Delta code will be better.

Typical k values are between 2 and 6.

=head2 Required Methods

=over 4

=item B< maxbits >

=item B< read >

=item B< write >

=item B< get_unary >

=item B< put_unary >

=item B< get_gamma >

=item B< put_gamma >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item Paolo Boldi and Sebastiano Vigna, "Codes for the World Wide Web", Internet Math, Vol 2, No 4, pp 407-429, 2005.

=item L<http://projecteuclid.org/DPubS/Repository/1.0/Disseminate?view=body&id=pdf_1&handle=euclid.im/1150477666>

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
