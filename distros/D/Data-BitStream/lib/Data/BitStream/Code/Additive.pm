package Data::BitStream::Code::Additive;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Escape::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Escape::VERSION = '0.08';
}

our $CODEINFO = [ { package   => __PACKAGE__,
                    name      => 'Additive',
                    universal => 0,
                    params    => 1,
                    encodesub => sub {shift->put_additive_seeded([split('-',shift)], @_)},
                    decodesub => sub {shift->get_additive_seeded([split('-',shift)], @_)},
                  },
                  { package   => __PACKAGE__,
                    name      => 'GoldbachG1',
                    universal => 1,
                    params    => 0,
                    encodesub => sub {shift->put_goldbach_g1(@_)},
                    decodesub => sub {shift->get_goldbach_g1(@_)},
                  },
                  { package   => __PACKAGE__,
                    name      => 'GoldbachG2',
                    universal => 1,
                    params    => 0,
                    encodesub => sub {shift->put_goldbach_g2(@_)},
                    decodesub => sub {shift->get_goldbach_g2(@_)},
                  },
                ];



#use List::Util qw(max);
use Moo::Role;
requires qw(read write);

# Precalculate the lengths for small values.
my @_agl = (1,3,3,(5)x4,(7)x8,(9)x16,(11)x32,(13)x64,(15)x128,(17)x256);
sub _push_more_agls { push @_agl, (19)x512,(21)x1024,(23)x2048,(25)x4096,(27)x8192; }
sub _additive_gamma_len {
  my($n) = @_;
  return $_agl[$n] if $n <= $#_agl;
  _push_more_agls if $n < 16383;
  my $gammalen = 1;
  $gammalen += 2 while $n >= ((2 << ($gammalen>>1))-1);
  $gammalen;
}

# Determine the best 2-ary sum over the basis p to use for this value.
sub _find_best_pair {
  my($p, $val, $pairsub) = @_;

  # Determine how far to look in the basis
  my $maxbasis = 0;
  $maxbasis+=100 while exists $p->[$maxbasis+101] && $val > $p->[$maxbasis+100];
  $maxbasis+=10  while exists $p->[$maxbasis+ 11] && $val > $p->[$maxbasis+ 10];
  $maxbasis++    while exists $p->[$maxbasis+  1] && $val > $p->[$maxbasis    ];
  # Or we could do binary search:
  #  my $lo = 0;
  #  my $hi = $#$p;
  #  while ($lo < $hi) {
  #    my $mid = int(($lo + $hi) / 2);
  #    if ($p->[$mid] <= $val) { $lo = $mid+1; }
  #    else                    { $hi = $mid; }
  #  }
  #  my $maxbasis = $lo;

  my @best_pair;
  my $best_pair_len = 100000000;
  my $i = 0;
  my $j = $maxbasis;
  my $pi = $p->[$i];
  my $pj = $p->[$j];
  while ($i <= $j) {
    my $sum = $pi + $pj;
    if    ($sum < $val) { $pi = $p->[++$i]; }
    elsif ($sum > $val) { $pj = $p->[--$j]; }
    else {
      my($p1, $p2) = $pairsub->($i, $j);  # How i,j are stored
      my $glen = _additive_gamma_len($p1) + _additive_gamma_len($p2);
      #print "poss: $pi + $pj = $val.  Indices $i,$j.  Pair $p1,$p2.  Len $glen.\n";
      if ($glen < $best_pair_len) {
        @best_pair = ($p1, $p2);
        $best_pair_len = $glen;
      }
      $pi = $p->[++$i];
    }
  }
  @best_pair;
}

# 2-ary additive code.
#
# The parameter comes in as an array.  Hence:
#
# $stream->put_additive( [0,1,3,5,7,8,10,16,22,28,34,40], $value );
#
# $stream->get_additive( [0,1,3,5,7,8,10,16,22,28,34,40], $value );
#
# You can optionally put a sub in the first arg.
#
# This array must be sorted and non-negative.

sub put_additive {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $sub = shift if ref $_[0] eq 'CODE';  ## no critic
  my $p = shift;
  $self->error_code('param', 'p must be an array') unless (ref $p eq 'ARRAY') && scalar @$p >= 1;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;

    # Expand the basis if necessary and possible.
    $sub->($p, $val) if defined $sub  &&  $p->[-1] < $val;

    my @best_pair = _find_best_pair($p, $val, sub { ($_[0], $_[1]-$_[0]) } );

    $self->error_code('range', $val) unless @best_pair;
    $self->put_gamma(@best_pair);
  }
  1;
}

sub get_additive {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $sub = shift if ref $_[0] eq 'CODE';  ## no critic
  my $p = shift;
  $self->error_code('param', 'p must be an array') unless (ref $p eq 'ARRAY') && scalar @$p >= 1;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Additive');
  while ($count-- > 0) {
    $self->code_pos_set;
    # Read the two gamma-encoded values
    my ($i,$j) = $self->get_gamma(2);
    last unless defined $i;
    $self->error_off_stream unless defined $j;
    $j += $i;
    my $pi = $p->[$i];
    my $pj = $p->[$j];
    if ( (!defined $pj) && (defined $sub) ) {
      $sub->($p, -$j);   # Generate the basis through j
      $pi = $p->[$i];
      $pj = $p->[$j];
    }
    $self->error_code('overflow') unless defined $pi && defined $pj;
    push @vals, $pi+$pj;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}


##########  Additive codes using seeds

my $expand_additive_basis = sub {
  my $p = shift;
  my $maxval = shift;

  push @{$p}, 0, 1  unless @{$p};

  # Assume the basis is sorted and complete to $p->[-1].
  my %sumhash;
  my @sums;
  foreach my $b1 (@{$p}) {
    foreach my $b2 (@{$p}) {
      $sumhash{$b1+$b2} = 1;
    }
  }
  my $lastp = $p->[-1];
  delete $sumhash{$_} for (grep { $_ <= $lastp } keys %sumhash);
  @sums = sort { $a <=> $b } keys %sumhash;
  my $n = $lastp;

  while (1) {
    if ($maxval >= 0) {  last if  $maxval <= $n;  }
    else              {  last if -$maxval < scalar @{$p};  }
    $n++;
    if (!@sums || ($sums[0] > $n)) {
      push @{$p}, $n;                               # add $n to basis
      $sumhash{$n+$_} = 1  for @{$p};               # calculate new sums
      delete $sumhash{$n};                          # sums from $n+1 up
      @sums = sort { $a <=> $b } keys %sumhash;
    } else {
      shift @sums if @sums && $sums[0] <= $n;       # remove obsolete sums
      delete $sumhash{$n};
    }
  }
  1;
};

# Give a maximum range and some seeds (even numbers).  You can then take the
# resulting basis and hand it to get_additive() / put_additive().
#
# Examples:
#      99, 8, 10, 16
#     127, 8, 20, 24
#     249, 2, 16, 46
#     499, 2, 34, 82
#     999, 2, 52, 154
sub generate_additive_basis {
  my $self = shift;
  my $max = shift;

  my @basis = (0, 1);
  # Perhaps some checking of defined, even, >= 2, no duplicates.
  foreach my $seed (sort {$a<=>$b} @_) {
    # Expand basis to $seed-1
    $expand_additive_basis->(\@basis, $seed-1) if $seed > ($basis[-1]+1);
    # Add seed to basis
    push @basis, $seed if $seed > $basis[-1];
    last if $seed >= $max;
  }
  $expand_additive_basis->(\@basis, $max) if $max > $basis[-1];
  @basis;
}


# More flexible seeded functions.  These take the seeds and expand the basis
# as needed to construct the desired values.  They also cache the constructed
# bases.

my %_cached_bases;

sub put_additive_seeded {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $p = shift;
  $self->error_code('param', 'p must be an array') unless (ref $p eq 'ARRAY') && scalar @$p >= 1;

  my $handle = join('-', @{$p});
  if (!defined $_cached_bases{$handle}) {
    my @basis = $self->generate_additive_basis($p->[-1], @{$p});
    $_cached_bases{$handle} = \@basis;
  }
  $self->put_additive($expand_additive_basis, $_cached_bases{$handle}, @_);
}

sub get_additive_seeded {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $p = shift;
  $self->error_code('param', 'p must be an array') unless (ref $p eq 'ARRAY') && scalar @$p >= 1;

  my $handle = join('-', @$p);
  if (!defined $_cached_bases{$handle}) {
    my @basis = $self->generate_additive_basis($p->[-1], @{$p});
    $_cached_bases{$handle} = \@basis;
  }
  $self->get_additive($expand_additive_basis, $_cached_bases{$handle}, @_);
}


##########  Support code for Goldbach codes

my $expand_primes_sub;

# Performance options, in order:
#
#    1. Install Data::BitStream::XS.
#
#       Whether you use it directly or install it and let Data::BitStream
#       use it behind the curtains, this is BY FAR the best solution.
#       20-50x faster overall.
#
#    2. Install Math::Prime::Util.
#
#       Fast prime basis formation.  If you're installing modules, you may as
#       well install DBXS though, as it gets you much more.  With large codes
#       this can be 1.5x faster.
#
#    3. Use this pure perl code.
#
# There really are three parts that let one efficiently produce Goldbach codes
# for large inputs.
#
#    - Fast prime basis formation.  Both options 1 and 2 will do this well.
#      Since switching to a segmented sieve in Perl, this isn't much of a
#      bottleneck any more.  Version 0.01 of this module was MUCH slower.
#
#    - Fast best-pair search.  Doing this in Data::BitStream::XS is a 10-50x
#      speedup for large numbers.  For very large numbers (over 32-bit), a
#      different algorithm would be needed, as that module uses the normal
#      array scan method.  Honestly these codes were meant for tiny inputs.
#
#    - Generic coding speedup.  Having the XS module installed gives a 10-100x
#      reduction in overhead.  This will have a big impact if inserting many
#      small codes.
#
# You can find lots of benchmarks and results for prime generation in the
# Math::Prime::Util module.  That module is by far the fastest on CPAN
# (2012-2014).  Math::Prime::FastSieve is fast enough if you start at 2.
# For non-Perl solutions, I recommend primesieve -- it is faster than MPU,
# yafu, primegen, or TOeS's code.

if (eval {require Math::Prime::Util; Math::Prime::Util->import(qw(primes nth_prime_upper next_prime)); 1;}) {

  $expand_primes_sub = sub {
    my $p = shift;
    my $maxval = shift;

    $maxval = nth_prime_upper(-$maxval) if $maxval < 0;
    $maxval += 100;

    push @$p, @{primes($p->[-1]+1, $maxval)};
    push @$p, next_prime($p->[-1]) if $p->[-1] < $maxval;
    1;
  };

} else {

sub _dj_pp_string_sieve {
  my($end) = @_;
  return '0' if $end < 2;
  return '1' if $end < 3;
  $end-- if ($end & 1) == 0;
  my $s_end = $end >> 1;

  my $whole = int( ($end>>1) / 15);  # prefill with 3 and 5 marked
  my $sieve = '100010010010110' . '011010010010110' x $whole;
  substr($sieve, ($end>>1)+1) = '';
  my ($n, $limit) = ( 7, int(sqrt($end)) );
  while ( $n <= $limit ) {
    for (my $s = ($n*$n) >> 1; $s <= $s_end; $s += $n) {
      substr($sieve, $s, 1) = '1';
    }
    do { $n += 2 } while substr($sieve, $n>>1, 1);
  }
  return \$sieve;
}
sub _dj_pp_segment_sieve {
  my($beg,$end) = @_;
  my $range = int( ($end - $beg) / 2 ) + 1;
  # Prefill with 3 and 5 already marked, and offset to the segment start.
  my $whole = int( ($range+14) / 15);
  my $startp = ($beg % 30) >> 1;
  my $sieve = substr("011010010010110", $startp) . "011010010010110" x $whole;
  # Set 3 and 5 to prime if we're sieving them.
  substr($sieve,0,2) = "00" if $beg == 3;
  substr($sieve,0,1) = "0"  if $beg == 5;
  # Get rid of any extra we added.
  substr($sieve, $range) = '';

  # If the end value is below 7^2, then the pre-sieve is all we needed.
  return \$sieve if $end < 49;

  my $limit = int(sqrt($end)) + 1;
  # For large value of end, it's a huge win to just walk primes.
  my $primesieveref = _dj_pp_string_sieve($limit);
  my $p = 7-2;
  foreach my $s (split("0", substr($$primesieveref, 3), -1)) {
    $p += 2 + 2 * length($s);
    my $p2 = $p*$p;
    last if $p2 > $end;
    if ($p2 < $beg) {
      $p2 = int($beg / $p) * $p;
      $p2 += $p if $p2 < $beg;
      $p2 += $p if ($p2 % 2) == 0;   # Make sure p2 is odd
    }
    # With large bases and small segments, it's common to find we don't hit
    # the segment at all.  Skip all the setup if we find this now.
    if ($p2 <= $end) {
      # Inner loop marking multiples of p
      # (everything is divided by 2 to keep inner loop simpler)
      my $fend = ($end - $beg) >> 1;
      for (my $fp2  = ($p2  - $beg) >> 1; $fp2 <= $fend; $fp2 += $p) {
        substr($sieve, $fp2, 1) = '1';
      }
    }
  }
  \$sieve;
}
sub _dj_pp_sieve {
  my($low, $high) = @_;

  my $sref = [];
  return $sref if ($low > $high) || ($high < 2);
  push @$sref, 2  if ($low <= 2) && ($high >= 2);
  push @$sref, 3  if ($low <= 3) && ($high >= 3);
  push @$sref, 5  if ($low <= 5) && ($high >= 5);
  $low = 7 if $low < 7;
  $low++ if ($low % 2) == 0;
  $high-- if ($high % 2) == 0;
  return $sref if $low > $high;

  my($n, $s, $sieveref) = ($low == 7)
     ? ($low-2, 3, _dj_pp_string_sieve($high))
     : ($low-2, 0, _dj_pp_segment_sieve($low,$high));
  while ( (my $nexts = 1 + index($$sieveref, "0", $s)) > 0 ) {
    $n += 2 * ($nexts - $s);
    $s = $nexts;
    push @$sref, $n;
  }
  $sref;
}

  $expand_primes_sub = sub {
    my $p = shift;
    my $maxval = shift;
    if ($maxval < 0) {     # We need $p->[-$maxval] defined.
      # Inequality:  p_n  <  n*ln(n)+n*ln(ln(n)) for n >= 6
      my $n = ($maxval > -6)  ?  6  :  -$maxval;
      $n++;   # Because we skip 2 in our basis.
      $maxval = int($n * log($n) + $n * log(log($n))) + 1;
    }

    # We want to ensure there is a prime >= $maxval on our list.
    # Use maximal gap, so this loop ought to run exactly once.
    my $adder = ($maxval <= 0xFFFFFFFF)  ?  336  :  2000;
    while ($p->[-1] < $maxval) {
      push @{$p}, @{_dj_pp_sieve($p->[-1]+1, $maxval+$adder)};
      $adder *= 2;  # Ensure success
    }
    1;
  };
}


##########  Goldbach G1 codes using the 2N form, and modified for 0-based.

my @_pbasis = (1, 3, 5, 7, 11, 13, 17, 19, 23, 29);

sub put_goldbach_g1 {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  $self->put_additive($expand_primes_sub,
                      \@_pbasis,
                      map { ($_+1)*2 } @_);
}

sub get_goldbach_g1 {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;

  my @vals = map { int($_/2)-1 }  $self->get_additive($expand_primes_sub,
                                                      \@_pbasis,
                                                      @_);
  wantarray ? @vals : $vals[-1];
}

##########  Goldbach G2 codes modified for 0-based.

sub put_goldbach_g2 {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  foreach my $v (@_) {
    $self->error_code('zeroval') unless defined $v and $v >= 0;

    if ($v == 0) { $self->write(3, 6); next; }
    if ($v == 1) { $self->write(3, 7); next; }

    my $val = $v+1;     # $val >= 3    (note ~0 will not encode)

    # Expand prime list as needed
    $expand_primes_sub->(\@_pbasis, $val) if $_pbasis[-1] < $val;
    $self->error_code('assert', "Basis not expanded to $val") unless $_pbasis[-1] >= $val;

    # Check to see if $val is prime
    if ( (($val%2) != 0) && (($val == 3) || (($val%3) != 0)) ) {
      # Not a multiple of 2 or 3, so look for it in _pbasis
      my $spindex = 0;
      $spindex += 200 while exists $_pbasis[$spindex+200]
                         && $val > $_pbasis[$spindex+200];
      $spindex++ while $val > $_pbasis[$spindex];
      if ($val == $_pbasis[$spindex]) {
        # We store the index (noting that value 3 is index 1 for us)
        $self->put_gamma($spindex);
        $self->write(1, 1);
        next;
      }
    }

    # Odd integer.
    if ( ($val % 2) == 1 ) {
      $self->write(1, 1);
      $val--;
    }

    # Encode the even value $val as the sum of two primes
    my @best_pair = _find_best_pair(\@_pbasis, $val,
                       sub { my($i,$j) = @_;  ($i+1,$j-$i+1); } );

    $self->error_code('range', $v) unless @best_pair;
    $self->put_gamma(@best_pair);
  }
  1;
}

sub get_goldbach_g2 {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  my $p = \@_pbasis;
  $self->code_pos_start('Goldbach G2');
  while ($count-- > 0) {
    $self->code_pos_set;

    # Look at the start 3 values
    my $look = $self->read(3, 'readahead');
    last unless defined $look;

    if ($look == 6) {  $self->skip(3);  push @vals, 0;  next;  }
    if ($look == 7) {  $self->skip(3);  push @vals, 1;  next;  }

    my $val = -1;   # Take into account the +1 for 1-based

    if ($look >= 4) {  # First bit is a 1  =>  Odd number
      $val++;
      $self->skip(1);
    }

    my ($i,$j) = $self->get_gamma(2);
    $self->error_off_stream unless defined $i && defined $j;

    my $maxindex = ($j == 0)  ?  $i  :  $j + ($i-1) - 1;
    $expand_primes_sub->(\@_pbasis, -$maxindex) unless defined $p->[$maxindex];
    $self->error_code('overflow') unless defined $p->[$maxindex];
    if ($j == 0) {
      $val += $p->[$i];
    } else {
      $i = $i - 1;
      $j = $j + $i - 1;
      $val += $p->[$i] + $p->[$j];
    }

    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}


no Moo::Role;
1;

# ABSTRACT: A Role implementing Additive codes

=pod

=head1 NAME

Data::BitStream::Code::Additive - A Role implementing Additive codes

=head1 VERSION

version 0.08


=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
Additive codes.  The role applies to a stream object.

If you use the Goldbach codes for inputs more than ~1000, I highly recommend
installing L<Data::BitStream::XS> for better performance.  While these codes
were not designed for large inputs, they work fine, however at large
computational costs.


=head1 EXAMPLES

  use Data::BitStream;

  my @array = (4, 2, 0, 3, 7, 72, 0, 1, 13);

  $stream->put_goldbach_g1( @array );
  $stream->rewind_for_read;
  my @array2 = $stream->get_goldbach_g1( -1 );

  my @seeds = (2, 16, 46);
  $stream->erase_for_write;
  $stream->put_additive_seeded( \@seeds, @array );
  $stream->rewind_for_read;
  my @array2 = $stream->get_additive_seeded( \@seeds, -1 );

  my @basis = (0,1,3,5,7,8,10,16,22,28,34,40,46,52,58,64,70,76,82,88,94);
  $stream->erase_for_write;
  $stream->put_additive( \@basis, @array );
  $stream->rewind_for_read;
  my @array2 = $stream->get_additive( \@basis, -1 );
=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_goldbach_g1($value) >

=item B< put_goldbach_g1(@values) >

Insert one or more values as Goldbach G1 codes.  Returns 1.
The Goldbach conjecture claims that any even number is the sum of two primes.
This coding finds, for any value, the shortest pair of gamma-encoded prime
indices that form C<2*($value+1)>.

=item B< get_goldbach_g1() >

=item B< get_goldbach_g1($count) >

Decode one or more Goldbach G1 codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=item B< put_goldbach_g2($value) >

=item B< put_goldbach_g2(@values) >

Insert one or more values as Goldbach G2 codes.  Returns 1.  Uses a different
coding than G1 that should yield slightly smaller codes for large values.  They
will also be almost twice as fast to encode and decode.

=item B< get_goldbach_g2() >

=item B< get_goldbach_g2($count) >

Decode one or more Goldbach G2 codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=item B< put_additive_seeded(\@seeds, $value) >

=item B< put_additive_seeded(\@seeds, @values) >

Insert one or more values as Additive codes.  Returns 1.  Arbitrary values
may be given as input, with the basis constructed as needed using the seeds.
The seeds should be sorted and not contain duplicates.  They will typically
be even numbers.  Examples include
C<[2,16,46]>, C<[2,34,82]>, C<[2,52,154,896]>.  Each generated basis is
cached, so successive put/get calls using the same seeds will run quickly.

=item B< get_additive_seeded(\@seeds) >

=item B< get_additive_seeded(\@seeds, $count) >

Decode one or more Additive codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=item B< generate_additive_basis($maxval, @seeds) >

Construct an additive basis from C<0> to C<$maxval> using the given seeds.
This allows construction of bases as shown in Fenwick's 2002 paper.  The
basis is returned as an array.  The bases will be identical to those used
with the C<get/put_additive_seeded> routines, though the latter allows the
basis to be expanded as needed.

=item B< put_additive(\@basis, $value) >

=item B< put_additive(\@basis, @values) >

Insert one or more values as 2-ary additive codes.  Returns 1.  An arbitrary
basis to be used is provided.  This basis should be sorted and consist of
non-negative integers.  For each value, all possible pairs C<(i,j)> are found
where C<i + j = value>, with the pair having the smallest sum of Gamma
encoding for C<i> and C<j> being chosen.  This pair is then Gamma encoded.
If no two values in the basis sum to the requested value, a range error results.

=item B< put_additive(sub { ... }, \@basis, @values) >

Insert one or more values as 2-ary additive codes, as above.  The provided
subroutine is used to expand the basis as needed if a value is too large for
the current basis.  As before, the basis should be sorted and consist of
non-negative integers.  It is assumed the basis is complete up to the last
element (that is, the basis will only be expanded).  The argument to the sub
is a reference to the basis array and a value.  When returned, the last entry
of the basis should be greater than or equal to the value.

=item B< get_additive(\@basis) >

=item B< get_additive(\@basis, $count) >

Decode one or more 2-ary additive codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=item B< get_additive(sub { ... }, \@basis, @values) >

Decode one or more values as 2-ary additive codes, as above.  The provided
subroutine is used to expand the basis as needed if an index is too large for
the current basis.  The argument to the sub is a reference to the basis array
and a negative index.  When returned, index C<-$index> of the basis must be
defined as a non-negative integer.

=back

=head2 Parameters

Both the basis and seed arrays are passed as array references.  The basis
array may be modified if a sub is given (since its job is to expand the basis).
It is possible to use a tied array as the basis, but using an expansion
callback sub is typically faster.

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

=item L<Data::BitStream::Code::Fibonacci>

=item L<Data::BitStream::Code::Gamma>

=item L<Math::Prime::XS>

=item Peter Fenwick, "Variable-Length Integer Codes Based on the Goldbach Conjecture, and Other Additive Codes", IEEE Trans. Information Theory 48(8), pp 2412-2417, Aug 2002.

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2012 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
