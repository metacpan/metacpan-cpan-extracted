package Data::BitStream::Code::Fibonacci;
use strict;
use warnings;
BEGIN {
  $Data::BitStream::Code::Fibonacci::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Code::Fibonacci::VERSION   = '0.08';
}

our $CODEINFO = [ { package   => __PACKAGE__,
                    name      => 'Fibonacci',
                    universal => 1,
                    params    => 0,
                    encodesub => sub {shift->put_fib(@_)},
                    decodesub => sub {shift->get_fib(@_)},
                  },
                  { package   => __PACKAGE__,
                    name      => 'FibC2',
                    universal => 1,
                    params    => 0,
                    encodesub => sub {shift->put_fib_c2(@_)},
                    decodesub => sub {shift->get_fib_c2(@_)},
                  },
                  { package   => __PACKAGE__,
                    name      => 'FibGen',
                    universal => 1,
                    params    => 1,
                    encodesub => sub {shift->put_fibgen(@_)},
                    decodesub => sub {shift->get_fibgen(@_)},
                  },
                ];

use Moo::Role;
requires qw(write put_string get_unary read);

# Fraenkel/Klein 1996 C1 code (based on work by Apostolico/Fraenkel 1985)
#
# The C2 code is also supported, though not efficiently.  C3 is not supported.
#
# While most codes we use are 'instantaneous' codes (also variously called
# prefix codes or prefix-free codes), the C2 code is not.  It has to look at
# the first bit of the next code to determine when it has ended.  This has the
# distinct disadvantage that is does not play well with other codes in the
# same stream.  For example, if a C2 code is followed by a zero-based unary
# code then incorrect parsing will ensue.
#
# The first set of methods, get_fib() and put_fib(), are specifically written
# for m=2 -- codes using the traditional Fibonacci sequence.  There are also
# generalized versions, which Klein et al. shows are useful for some
# applications.  The generalized implementation is typically slower.

# General order m >= 2 sequences.  Generate enough to encode any integer
# from 0 to ~0.  Note that the first 0,1 for all sequences are removed.
my @fibs_order;
my @fib_sums_order;
sub _calc_fibs_for_order_m {
  my $m = shift;
  die "Internal Fibonacci error" unless $m >= 2;
  my @fibm = (0) x ($m-1);
  push @fibm, 1, 1, 2;
  my $v1 = $fibm[-1];
  while ($v1 <= ~0) {
    foreach my $i (2 .. $m) { $v1 += $fibm[-$i]; }
    push(@fibm, $v1);
  }
  splice(@fibm, 0, $m);  # remove the first elements
  $fibs_order[$m] = \@fibm;

  # Calculate sums (with 0 at start)
  my @fsums = (0);
  foreach my $f (@fibm) { push @fsums, $fsums[-1] + $f; }
  $fib_sums_order[$m] = \@fsums;
}

# Since calculating the Fibonacci codes are relatively expensive, cache the
# size and code for small values.
my $fib_code_cache_size = 128;
my @fib_code_cache;

sub put_fib {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  _calc_fibs_for_order_m(2) unless defined $fibs_order[2];
  my @fibs = @{$fibs_order[2]};  # arguably we should just use the reference

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;

    if ( ($val < $fib_code_cache_size) && (defined $fib_code_cache[$val]) ) {
      $self->write( @{$fib_code_cache[$val]} );
      next;
    }

    my $d = $val+1;
    my $s =  ($d < $fibs[20])  ?  0  :  ($d < $fibs[40])  ?  21  :  41;
    $s++ while ($d >= $fibs[$s]);

    # Generate 32-bit word directly if possible
    if ($s <= 31) {
      my $word = 1;
      foreach my $f (reverse 0 .. $s) {
        if ($d >= $fibs[$f]) {
          $d -= $fibs[$f];
          $word |= 1 << ($s-$f);
        }
      }
      if ($val < $fib_code_cache_size) {
        $fib_code_cache[$val] = [ $s+1, $word ];
      }
      $self->write($s+1, $word);
      next;
    }

    # Generate the string code.
    my $r = '11';
    $d = $val - $fibs[--$s] + 1;     # (this makes $val = ~0 encode correctly)
    while ($s-- > 0) {
      if ($d >= $fibs[$s]) {
        $d -= $fibs[$s];
        $r .= '1';
      } else {
        $r .= '0';
      }
    }
    $self->put_string(scalar reverse $r);
  }
  1;
}

# We can implement get_fib a lot of different ways.
#
# Simple:
#
#   my $last = 0;
#   while (1) {
#     my $code = $self->read(1);
#     die "Read off end of fib" unless defined $code;
#     last if $code && $last;
#     $val += $fibs[$b] if $code;
#     $b++;
#     $last = $code;
#   }
#
# Exploit knowledge that we have lots of zeros and get_unary is fast.  This
# is 2-10 times faster than reading single bits.
#
#   while (1) {
#     my $code = $self->get_unary();
#     die "Read off end of fib" unless defined $code;
#     last if ($code == 0) && ($b > 0);
#     $b += $code;
#     $val += $fibs[$b];
#     $b++;
#   }
#
# Use readahead(8) and look up the result in a precreated array of all the
# first 8 bit values mapped to the associated prefix code.  While this is
# a neat idea, in practice it is slow in this framework.
#
# Use readahead to read 32-bit chunks at a time and parse them here.

sub get_fib {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;

  _calc_fibs_for_order_m(2) unless defined $fibs_order[2];
  my @fibs = @{$fibs_order[2]};  # arguably we should just use the reference

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Fibonacci');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $code = $self->get_unary;
    last unless defined $code;
    # Start with -1 here instead of subtracting it later.  No overflow issues.
    my $val = -1;
    my $b = -1;
    do {
      $b += $code+1;
      $self->error_code('overflow') unless defined $fibs[$b];
      $val += $fibs[$b];
      $code = $self->get_unary;
      $self->error_off_stream unless defined $code;
    } while ($code != 0);
    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}


########## Generalized Fibonacci codes

sub put_fibgen {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;
  my $m = shift;
  $self->error_code('param', 'm must be in range 2-16') unless $m >= 2 && $m <= 16;

  _calc_fibs_for_order_m($m) unless defined $fibs_order[$m];
  my @fibm = @{$fibs_order[$m]};
  my @fsums = @{$fib_sums_order[$m]};
  my $term = ~(~0 << $m);

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;

    if    ($val == 0) {  $self->write($m, $term); next; }
    elsif ($val == 1) {  $self->write($m+1, $term); next; }

    # The way these codes are built are a different way of thinking about it
    # than the simple m=2 case.  See Salomon VLC p. 117.
    # However, the end result is identical for m=2.

    # Determine how many bits we will encode
    my $s = 1;
    $s++ while ($val > $fsums[$s+1]);
    my $d = $val - $fsums[$s] - 1;

    # Generate 32-bit word directly if possible
    my $sm = $s + $m;
    if ($sm <= 31) {
      my $word = $term;
      foreach my $f (reverse 0 .. $s-1) {
        if ($d >= $fibm[$f]) {
          $d -= $fibm[$f];
          $word |= 1 << ($sm-$f);
        }
      }
      $self->write($sm+1, $word);
      next;
    }

    # Encode the bits using string functions
    my $r = '1' x $m . '0';
    while ($s-- > 0) {
      if ($d >= $fibm[$s]) {
        $d -= $fibm[$s];
        $r .= '1';
      } else {
        $r .= '0';
      }
    }

    $self->put_string(scalar reverse $r);
  }
  1;
}

sub get_fibgen {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $m = shift;
  $self->error_code('param', 'm must be in range 2-16') unless $m >= 2 && $m <= 16;

  _calc_fibs_for_order_m($m) unless defined $fibs_order[$m];
  my @fibm = @{$fibs_order[$m]};
  my @fsums = @{$fib_sums_order[$m]};
  my $term = ~(~0 << $m);

  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start("FibGen($m)");
  while ($count-- > 0) {
    $self->code_pos_set;

    my $code = $self->read($m);
    last unless defined $code;
    if ($code == $term) {
      push @vals, 0;
      next;
    }

    my $fullcode = $code;
    my $s = 0;
    my $val = 1;
    while (1) {

      # Count 1 bits on the left
      my $count = 0;
      $count++ while ($fullcode & (1 << $count));

      # Read as many more as we can while looking for 1 repeated $m times
      # We will be reading 1-$m bits at a time.
      my $codelen = $m-$count;
      last if $codelen == 0;
      $code = $self->read($codelen);
      $self->error_off_stream unless defined $code;

      # Add latest read to full code in progress
      $fullcode = ($fullcode << $codelen) | $code;

      # Process leftmost bits
      my $left = $fullcode >> $m;
      foreach my $c (reverse 0 .. $codelen-1) {
        $self->error_code('overflow') unless defined $fibm[$s];
        $val += $fibm[$s]  if ($left & (1 << $c));
        #my $adder = ($left & (1 << $c))  ?  $fibm[$s]  :  0;
        #print "s = $s  val = $val (added $adder)\n";
        $s++;
      }
      $fullcode &= $term;    # Done with them
    }
    #print "s = $s  val = ", $val+$fsums[$s-1], " (added $fsums[$s-1])\n";
    push @vals, $val + $fsums[$s-1];
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}


# TODO:
# Consider Sayood's NF3 code, described on pages 67-70 of his
# Lossless Compression Handbook
#
# If F(N) ends with ....01, add the terminator 110.  Final is ...01110
# If F(N) ends with ...011, add the terminator  11.  Final is ...01111



# String functions

sub _encode_fib_c1 {
  my $d = shift;
  return unless $d >= 1 and $d <= ~0;
  _calc_fibs_for_order_m(2) unless defined $fibs_order[2];
  my @fibs = @{$fibs_order[2]};
  my $s =  ($d < $fibs[20])  ?  0  :  ($d < $fibs[40])  ?  21  :  41;
  $s++ while ($d >= $fibs[$s]);
  my $r = '1';
  while ($s-- > 0) {
    if ($d >= $fibs[$s]) {
      $d -= $fibs[$s];
      $r .= "1";
    } else {
      $r .= "0";
    }
  }
  scalar reverse $r;
}

sub _decode_fib_c1 {
  my $str = shift;
  return unless $str =~ /^[01]*11$/;
  _calc_fibs_for_order_m(2) unless defined $fibs_order[2];
  my @fibs = @{$fibs_order[2]};
  my $val = 0;
  foreach my $b (0 .. length($str)-2) {
    $val += $fibs[$b]  if substr($str, $b, 1) eq '1';
  }
  $val;
}

sub _encode_fib_c2 {
  my $d = shift;
  return unless $d >= 1 and $d <= ~0;
  return '1' if $d == 1;
  my $str = _encode_fib_c1($d-1);
  return unless defined $str;
  substr($str, -1, 1) = '';
  substr($str, 0, 0) = '10';
  $str;
}

sub _decode_fib_c2 {
  my $str = shift;
  return 1 if $str eq '1';
  return unless $str =~ /^10[01]*1$/;
  $str =~ s/^10//;
  my $val = _decode_fib_c1($str . '1');
  return unless defined $val;
  $val+1;
}

sub put_fib_c2 {
  my $self = shift;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    my $c2_string = _encode_fib_c2($val+1);
    $self->error_code('value', $val) unless defined $c2_string;
    $self->put_string($c2_string);
  }
  1;
}
sub get_fib_c2 {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Fibonacci C2');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $str = '';
    if (0) {
      my $look = $self->read(8, 'readahead');
      last unless defined $look;
      if (($look & 0xC0) == 0xC0) { $self->skip(1); return 0; }
      if (($look & 0xF0) == 0xB0) { $self->skip(3); return 1; }
      if (($look & 0xF8) == 0x98) { $self->skip(4); return 2; }
      if (($look & 0xFC) == 0x8C) { $self->skip(5); return 3; }
      if (($look & 0xFC) == 0xAC) { $self->skip(5); return 4; }
      if (($look & 0xFE) == 0x86) { $self->skip(6); return 5; }
      if (($look & 0xFE) == 0xA6) { $self->skip(6); return 6; }
      if (($look & 0xFE) == 0x96) { $self->skip(6); return 7; }
    }
    my $b = $self->read(1);
    last unless defined $b;
    $str .= $b;
    my $b2 = $self->read(1, 'readahead');
    while ( (defined $b2) && ($b2 != 1) ) {
      my $skip = $self->get_unary;
      $self->error_off_stream unless defined $skip;
      $str .= '0' x $skip . '1';
      $b2 = $self->read(1, 'readahead');
    }
    my $val = _decode_fib_c2($str);
    $self->error_code('string', "Not a Fibonacci C2 code") unless defined $val;
    push @vals, $val-1;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}
no Moo::Role;
1;

# ABSTRACT: A Role implementing Fibonacci codes

=pod

=head1 NAME

Data::BitStream::Code::Fibonacci - A Role implementing Fibonacci codes

=head1 VERSION

version 0.08

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides get and set methods for
the Fibonacci codes.  The role applies to a stream object.

=head1 METHODS

=head2 Provided Object Methods

=over 4

=item B< put_fib($value) >

=item B< put_fib(@values) >

Insert one or more values as Fibonacci C1 codes.  Returns 1.

=item B< get_fib() >

=item B< get_fib($count) >

Decode one or more Fibonacci C1 codes from the stream.  If count is omitted,
one value will be read.  If count is negative, values will be read until
the end of the stream is reached.  In scalar context it returns the last
code read; in array context it returns an array of all codes read.

=item B< put_fibgen($m, @values) >

Insert one or more values as generalized Fibonacci C1 codes with order C<m>.
Returns 1.

=item B< get_fibgen($m) >

=item B< get_fib($m, $count) >

Decode one or more generalized Fibonacci C1 codes with order C<m> from the
stream.  If count is omitted, one value will be read.  If count is negative,
values will be read until the end of the stream is reached.  In scalar context
it returns the last code read; in array context it returns an array of all
codes read.

=item B< put_fib_c2(@values) >

Insert one or more values as Fibonacci C2 codes.  Returns 1.

Note that the C2 codes are not prefix-free codes, so will not work well with
other codes.  That is, these codes rely on the bit _after_ the code to be a 1
(or the end of the stream).  Other codes may not meet this requirement.

=item B< get_fib_c2() >

=item B< get_fib_c2($count) >

Decode one or more Fibonacci C2 codes from the stream.

=back

=head2 Required Methods

=over 4

=item B< read >

=item B< write >

=item B< get_unary >

=item B< put_string >

These methods are required for the role.

=back

=head1 SEE ALSO

=over 4

=item Alberto Apostolico and Aviezri S. Fraenkel, "Robust Transmission of Unbounded Strings Using Fibonacci Representations", Computer Science Technical Reports, Paper 464, Purdue University, 14 October 1985.  L<http://docs.lib.purdue.edu/cstech/464/>

=item A.S. Fraenkel and S.T. Klein, "Robust Universal Complete Codes for Transmission and Compression", Discrete Applied Mathematics, Vol 64, pp 31-55, 1996.  L<http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.37.3064>

These papers introduce and describe the order C<mE<gt>=2> Fibonacci codes C1, C2, and C3.  The C<m=2> C1 codes are what most people call Fibonacci codes.

=item L<http://en.wikipedia.org/wiki/Fibonacci_coding>

A description of the C<m=2> C1 code.

=item Shmuel T. Klein and Miri Kopel Ben-Nissan, "On the Usefulness of Fibonacci Compression Codes", The Computer Journal, Vol 53, pp 701-716, 2010.  L<http://u.cs.biu.ac.il/~tomi/Postscripts/fib-rev.pdf>

More information on Fibonacci codes, including C<mE<gt>2> codes.

=back

=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011-2012 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
