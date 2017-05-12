#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


use 5.010;
use strict;
use warnings;
use Memoize;
use List::Util qw(min max);
use List::MoreUtils;
use Math::BigRat try => 'GMP';
use lib '/home/gg/perl/math-polynomial/004-modified';
use Math::Polynomial;

use constant DEBUG => 0;
$| = 1;


#------------------------------------------------------------------------------
Math::Polynomial->verbose(1);
Math::Polynomial->configure (VARIABLE => '$x');

package Math::Polynomial;
use List::Util qw(min max);

use overload '==' => \&equal, '!=' => \&not_equal;
sub not_equal { return ! equal(@_); }
sub equal {
  my ($left, $right) = @_;

  unless (ref($right) && $right->isa('Math::Polynomial')) {
    $right = [ $right ];
  }
  foreach my $i (0 .. max ($#$left, $#$right)) {
    unless (($i < @$left ? $left->[$#$left-$i] : 0)
            ==
            ($i < @$right ? $right->[$#$right-$i] : 0)) {
      return 0;
    }
  }
  return 1;
}

my %CONFIG = (PLUS => ' + ',
	      MINUS => ' - ',
	      TIMES => '*',
	      POWER => '**',
	      VARIABLE => '$x');

sub to_string_for_eval {
  my ($poly) = @_;
  my $i = $poly->degree;
  if ($i < 0) {
    return '0';
  }

  # build in @ret to avoid O(N^2) string copying from a ".=" append
  my @ret = (undef);
  my $need_parens = 0;
  my $open_parens = 0;
  my $times = '';
  my $xpow = 0;

  {
    my $coeff = $poly->coeff($i);
    if ($coeff == 1 && $i > 0) {
      # just "$X" to start
    } elsif ($coeff == -1 && $i > 0) {
      my $minus = $CONFIG{MINUS};
      $minus =~ tr/ //d; # no spaces on leading '-$X'
      push @ret, $minus;
    } else {
      push @ret, "$coeff";  # stringize
      $times = $CONFIG{TIMES};
    }
  }

  for (;;) {
    $i--;
    my $coeff;
    if ($i >= 0) {
      $xpow++;
      $coeff = $poly->coeff($i);
      if ($coeff == 0) {
        next;
      }
    }
    if ($xpow != 0) {
      if ($need_parens) {
        $open_parens++;
        push @ret, ')';
      }
      push @ret, "$times$CONFIG{VARIABLE}";
      $times = $CONFIG{TIMES};
      if ($xpow > 1) {
        push @ret, "$CONFIG{POWER}$xpow";
      }
      $xpow = 0;
    }
    if ($i < 0) {
      last;
    }

    push @ret, ($coeff > 0 ? $CONFIG{PLUS}.$coeff : $CONFIG{MINUS}.-$coeff);
    $need_parens = 1;
  }
  $ret[0] = '(' x $open_parens;
  return join('', @ret);
}

package main;


#------------------------------------------------------------------------------

sub print_ma_terms {
  my ($name) = @_;
  print "$name\n";
  my $term_proc = do { no strict; \&$name };
  foreach my $k (0 .. 20) {
    say "  p[$k] * (@{[$term_proc->($k)]})";
  }
}

my $poly_0 = Math::Polynomial->new;

# {
#   say Math::Polynomial->new()->to_string_for_eval;
#   say Math::Polynomial->new(1)->to_string_for_eval;
#   say Math::Polynomial->new(-1)->to_string_for_eval;
#   say Math::Polynomial->new(1,0)->to_string_for_eval;
#   say Math::Polynomial->new(-1,0)->to_string_for_eval;
#   say Math::Polynomial->new(-1,0,1)->to_string_for_eval;
#   say Math::Polynomial->new(123,0,-456)->to_string_for_eval;
#   say Math::Polynomial->new(-1,-1,-456)->to_string_for_eval;
#   say Math::Polynomial->new(1,1,1,1,1)->to_string_for_eval;
#   say Math::Polynomial->new(1,1,1,1,0)->to_string_for_eval;
#   say Math::Polynomial->new(1,1,1,0,0)->to_string_for_eval;
#   say Math::Polynomial->new(0,1,1,1,0,0)->to_string_for_eval;
#   exit 0;
# }

# per Knuth vol 2 sect 4.3.3
sub interpolate_successive {
  my $start = 0;
  if (! ref $_[0] && $_[0] eq 'start') {
    shift;
    $start = shift;
  }

  my @data = @_;
  my @divisor;
  my $divisor = 1;
  foreach my $i (1 .. $#data) {
    push @divisor, ($divisor *= $i);
    for (my $j = $#data; $j >= $i; $j--) {
      $data[$j] -= $data[$j-1];
    }
    if (DEBUG) { require Data::Dumper;
                 print Data::Dumper->Dump([\@data],['data']); }
  }
  if (DEBUG) { require Data::Dumper;
               print Data::Dumper->Dump([\@divisor],['divisor']); }

  my $ret = Math::Polynomial->new((pop @data) / (pop @divisor));
  while (@data > 2) {
    $ret->mul1c ($#data + $start);
    $ret->[-1] += (pop @data) / (pop @divisor);
  }
  # $data[1]
  $ret->mul1c (1 + $start);
  $ret->[-1] += pop @data;
  # $data[0]
  if ($start) { $ret->mul1c ($start) }
  push @$ret, pop @data;

  return $ret;
}

# sub interpolate_faster {
#   my (@x, @y);
#   while (@_) {
#     push @x, shift;
#     push @y, shift;
#   }
#   my @nums;
#   my $numerator = Math::Polynomial->new(1);
#   for (my $i = $#x; $i > 0; $i--) {
#     $numerator->mul1c($x[$i]);
#     push @nums, $numerator->clone;
#   }
# 
#   my $result = Math::Polynomial->new(0);
#   foreach my $i (0 .. $#x-1) {
#     $numerator = shift @nums;
#         print "num ",$numerator,"\n";
#   my $constant = pop(@y) / $numerator->eval($_);
#     $result += $numerator * $constant;
#   }
#   return $result;
# }


{
  say interpolate_successive(10, 304, 1980, 7084, 18526);
  say interpolate_successive(0,1,4);
  say interpolate_successive(1,2,3);
  say interpolate_successive(1, 4, 9, 16);

  my $triangle = sub {
    my ($n) = @_;
    return List::Util::sum (1 .. $n);
  };
  my $sum_squares = sub {
    my ($n) = @_;
    return List::Util::sum (map {$_**2} (1 .. $n));
  };
  my $yden = sub {
    my ($n) = @_;
    return $n * $sum_squares->($n) - ($triangle->($n))**2;
  };
  require Math::Polynomial;
  require Math::BigRat;
  Math::Polynomial->verbose(1);
  Math::Polynomial->configure(VARIABLE => '$N');
  my $poly = Math::Polynomial::interpolate (map {
    ($_, Math::BigRat->new(12 * $yden->($_)))} (1..10));
  say "yfactor 1/12 * ($poly)";

  $poly = Math::Polynomial::interpolate (map {
    ($_, 1*2*3*4*5*6*7*12 * $yden->($_))} (1..10));
  say "yfactor 1/12 * ($poly)";

  #   print "\n\n";
  #   $poly = interpolate_faster (map {
  #     ($_, Math::BigRat->new(12 * $yden->($_)))} (1..10));
  #   say "yfactor 1/12 * ($poly)";

  #   print "\n\n";
  #   $poly = interpolate_successive (map {12 * $yden->($_)} (0..10));
  #   say "yfactor 1/12 * ($poly)";

  #  exit 0;
}

sub high_power {
  my ($data) = @_;
  my $power = 0;
  my $deriv = 1;
  for (;;) {
    say "$power $deriv ",@$data;
    if (List::MoreUtils::all {$_ == $data->[0]} @$data) {
      return ($data->[0] / $deriv, $power);
    }
    $data = [ map {$data->[$_] - $data->[$_-1]} (1 .. $#$data) ];
    $power++;
    $deriv *= ($power + 1);
  }
}


#------------------------------------------------------------------------------
print "EMA\n";

# ema_term() returns a polynomial in f=1-alpha which is the coefficient of
# the f^k term.  This is simply (1-f)*f^k = 1*f^k + -1*f^(k+1).
sub ema_term {
  my ($k) = @_;
  #print "ema_term $k\n";

  if ($k < 0) {
    return $poly_0;
  } else {
    # Math::BigRat->new(-1),
    #                                   Math::BigRat->new(1),
    return Math::Polynomial->new (-1, 1,
                                  (0) x $k);
  }
}
memoize 'ema_term';

print_ma_terms ("ema_term");
ema_term(0) == Math::Polynomial->new(-1,1) or die;
ema_term(1) == Math::Polynomial->new(-1,1,0) or die;

# return a procedure $weight_proc which called $weight_proc->($k) calculates
# the total weight of the terms up to and including the p[k] input price
# term.
#
# $term_proc->($k) should return a polynomial in f which is the coefficient
# of the f^k term.  The created $weight_proc function simply adds them up.
#
sub make_weight_proc {
  my ($term_proc) = @_;
  my $weight_proc;
  $weight_proc = memoize
    (sub {
       my ($k) = @_;
       # say "weight_to_proc $k";
       return $term_proc->($k) + ($k > 0 ? $weight_proc->($k-1) : $poly_0);
     });
  return $weight_proc;
}

# ema_weight_to($k) returns a polynomial in f which is the total weight of
# terms up to and including the p[k] input.
*ema_weight_to = make_weight_proc(\&ema_term);
say "ema_weight_to(4) ", ema_weight_to(4);

# ema_omitted_after($k) returns a polynomial in f which is the total weight
# omitted by stopping at (and including) the p[k] input.
sub ema_omitted_after {
  my ($k) = @_;
  return 1 - ema_weight_to($k);
}
say "ema_omitted_after(4)  ",ema_omitted_after(4);


#------------------------------------------------------------------------------
print "\n\nEMA x 2\n";

use vars qw($a $b);
sub sum {
  return List::Util::reduce {$a+$b} @_;
}

# $term_proc->($i) should return a polynomial in f which is the weight of the
# p[i] input term in some weighted mean series.
# ema_of_term_proc() returns a new procedure $smoothed_proc which called
# $smoothed_proc->($i) similarly returns a polynomial in f, but representing
# the result of smoothing $term_proc with an EMA.
#
sub ema_of_term_proc {
  my ($term_proc) = @_;
  return memoize
    (sub {
       my ($k) = @_;
       # print "ema_of_term $k\n";
       sum (map {
         # ema_term($_) * $term_proc->($k-$_)
         #          say "T=", $term_proc->($k-$_);
         #          say "#=", ema_term($_);
         #          say "P ", ema_term($_) * $term_proc->($k-$_);

         my $prod = $term_proc->($k-$_);
         # say "N ", $prod;
         $prod = -$prod;   # now *(1-f)
         $prod->mul1c (1); # *(f-1)
         # say "M ", $prod;
         push @$prod, (0)x$_;  # *f^e
         # say "X ", $prod;

         $prod
       } (0 .. $k));
     });
}

# ema2_term() returns a polynomial in f=1-alpha which is the coefficient of
# the f^k term.  This is simply (1-f)*f^k = 1*f^k + -1*f^(k+1).
*ema2_term = ema_of_term_proc(\&ema_term);

print_ma_terms ("ema2_term");
# ema2_term(0) == Math::Polynomial->new(-1,1) or die;
# ema2_term(1) == Math::Polynomial->new(-1,1,0) or die;

*ema2_weight_to = make_weight_proc(\&ema2_term);
say "ema2_weight_to(4) ", ema2_weight_to(4);
sub ema2_omitted_after {
  my ($k) = @_;
  return 1 - ema2_weight_to($k);
}
memoize 'ema2_omitted_after';
say "ema2_omitted_after(4)  ",ema2_omitted_after(4);

# `omitted-fk' returns the coefficient (a number) of the f^(k+offset) term
# in the p[k] omitted polynomial of OMITTED-POLY-PROC.  This is meant for
# finding closed-form expressions (a poly in k) for that f^(k+offset)
# coefficient.
#
# OMITTED-POLY-PROC returns a polynomial in f which is the weight omitted
# from some weighted average by stopping at (and including) the p[k] term.
#
sub omitted_fk {
  my ($omitted_proc, $offset) = @_;
  return memoize (sub {
                    my ($k) = @_;
                    # say "omitted_fk $omitted_proc $offset $k";
                    my $poly = $omitted_proc->($k);
                    my $i = $k+$offset;
                    if ($i > $poly->degree) {
                      return 0;
                    } else {
                      return $poly->coeff($i);
                    }
                  });
}
memoize('omitted_fk');

sub Xclosed_form {
  my ($proc) = @_;
  say "closed_form $proc";
  my @data;
  my @x = (20 .. 25);
  foreach my $i (0 .. $#x) {
    $data[$i] = $proc->($x[$i]);
  }
}


sub closed_form {
  my ($proc) = @_;

#   my @data = map {
#     ($_, Math::BigRat->new($proc->($_)))
#   } (20 .. 30);
#   print "  interpolate_successive ...\n";
#   return interpolate_successive (start => 20, @data);

  return Math::Polynomial::interpolate (map {
    # say $_;
    # say $proc->($_);

    (Math::BigRat->new ($_),
     Math::BigRat->new($proc->($_)))
  } (20 .. 30));
}
memoize 'closed_form';

sub omitted_fk_closed_form {
  my ($name, $offset) = @_;
  my $proc = do { no strict; \&$name };
  my $poly = closed_form(omitted_fk($proc, $offset));
  say "$name k+$offset  ", $poly;
}

sub omitted_expr {
  my ($name) = @_;
  print "omitted_expr $name ...\n";
  my $proc = do { no strict; \&$name };
  my %a;
  foreach my $offset (-8 .. 20) {
    my $poly = closed_form(omitted_fk($proc, $offset));
    $a{$offset} = $poly;
    if ($poly != 0) {
      printf "f^(k%+d) * (%s)\n", $offset, "$poly";
    }
  }

  while (my ($key, $value) = each %a) {
    if ($value == 0) { delete $a{$key}; }
  }
  if (! %a) {
    die "Oops, omitted_expr all zeros";
  }
  my $start = min(keys %a);
  my $end   = max(keys %a);
  my $level = 1;
  say "\$f ** ",offset_k_form($start);
  foreach my $offset ($start .. $end) {
    if ($offset != $start) {
      say '  'x$level, "+ (\$f      # f^",offset_k_form($offset);
      $level++;
    }
    my $poly = $a{$offset} // $poly_0;
    say '  'x$level, "* (", $poly->to_string_for_eval;
    $level++;
  }
  say '  'x$level,")"x$level;
}
sub offset_k_form {
  my ($offset) = @_;
  if ($offset == 0) {
    return '$k';
  } else {
    return sprintf "(\$k%+d)", $offset;
  }
}

# 	    (begin
# 	      (format #t "~a  (* f   
# 		      (make-string level #\space)
# 		      offset)
# 	      (set! level (1+ level))))
# 	(set! level (1+ level)))

omitted_fk_closed_form('ema2_omitted_after', 0);
omitted_fk_closed_form('ema2_omitted_after', 1);
omitted_fk_closed_form('ema2_omitted_after', 2);
omitted_fk_closed_form('ema2_omitted_after', 3);
omitted_expr('ema2_omitted_after');

#------------------------------------------------------------------------------
print "\n\nEMA x 3\n";

# ema3_term() returns a polynomial in f=1-alpha which is the coefficient of
# the f^k term.  This is simply (1-f)*f^k = 1*f^k + -1*f^(k+1).
*ema3_term = ema_of_term_proc(\&ema2_term);

print_ma_terms ("ema3_term");

*ema3_weight_to = make_weight_proc(\&ema3_term);
say "ema3_weight_to(4) ", ema3_weight_to(4);

sub ema3_omitted_after {
  my ($k) = @_;
  return 1 - ema3_weight_to($k);
}
memoize 'ema3_omitted_after';
say "ema3_omitted_after(4)  ",ema3_omitted_after(4);

# omitted_fk_closed_form('ema3_omitted_after', 0);
# omitted_fk_closed_form('ema3_omitted_after', 1);
# omitted_fk_closed_form('ema3_omitted_after', 2);
# omitted_fk_closed_form('ema3_omitted_after', 3);
# omitted_fk_closed_form('ema3_omitted_after', 4);
omitted_expr('ema3_omitted_after');


#------------------------------------------------------------------------------
print "\n\nLaguerre\n";

# From
#
#     L1 = -(1-alpha)*L0 + L0prev + (1-alpha)*L1prev
#
# rearrange to show it's an EMA,
#
#                  L0prev - f*L0
#     L1 = alpha * ------------- + (1-alpha)*L1prev
#                      (1-f)
#
# of the term
#
#     L0prev - f*L0
#     -------------
#         (1-f)
#

# (define (L1-pre-ema-term k)
#   (poly-div (poly-sub (if (zero? k)
# 			  '()
# 			  (L0-term (1- k)))
# 		      (poly-shift (L0-term k) 1))
# 	    '(1 -1)))

# poly equal to $X
my $poly_X = Math::Polynomial->new(Math::BigRat->new(1),
                                   Math::BigRat->new(0));
# poly equal to 1-$X
my $poly_1_minus_X = Math::Polynomial->new(Math::BigRat->new(-1),
                                           Math::BigRat->new(1));

sub make_laguerre_for_ema {
  my ($term_proc) = @_;
  return memoize
    (sub {
       my ($k) = @_;
       # say "make_laguerre_for_ema $k";
       my $L0prev = ($k <= 0 ? $poly_0 : $term_proc->($k-1));
       my $L0_times_f = $term_proc->($k) * $poly_X;
       my $diff = $L0_times_f - $L0prev;
       $diff->div1c (1); # (x-1) instead of (1-x)
       # say "l done";
       return $diff;
     });
}

sub L0_term {
  my ($k) = @_;
  # say "L0_term $k";
  if ($k < 0) {
    return Math::BigRat->new(0);
  } else {
    return Math::Polynomial->new (Math::BigRat->new(-1),
                                  Math::BigRat->new(1),
                                  (0) x $k);
  }
}
memoize 'L0_term';
print_ma_terms ('L0_term');

*L1_pre_ema_term = make_laguerre_for_ema(\&L0_term);
*L1_term = ema_of_term_proc (\&L1_pre_ema_term);
print_ma_terms ('L1_term');

*L2_pre_ema_term = make_laguerre_for_ema(\&L1_term);
*L2_term = ema_of_term_proc (\&L2_pre_ema_term);
print_ma_terms ('L2_term');

*L3_pre_ema_term = make_laguerre_for_ema(\&L2_term);
*L3_term = ema_of_term_proc (\&L3_pre_ema_term);
print_ma_terms ('L3_term');

sub laguerre_term {
  my ($k) = @_;
  return (L0_term($k) + 2*L1_term($k) + 2*L2_term($k) + L3_term($k))
    / 6;
}
memoize ('laguerre_term');
print_ma_terms ('laguerre_term');

*laguerre_weight_to = make_weight_proc(\&laguerre_term);
say "laguerre_weight_to(4) ", laguerre_weight_to(4);

sub laguerre_omitted_after {
  my ($k) = @_;
  # say "laguerre_omitted_after $k";
  return 1 - laguerre_weight_to($k);
}
memoize 'laguerre_omitted_after';
say "laguerre_omitted_after(4)  ",laguerre_omitted_after(4);

# omitted_fk_closed_form('laguerre_omitted_after', -2);
# omitted_fk_closed_form('laguerre_omitted_after', -1);
# omitted_fk_closed_form('laguerre_omitted_after', 0);
# omitted_fk_closed_form('laguerre_omitted_after', 1);
# omitted_fk_closed_form('laguerre_omitted_after', 2);
# omitted_fk_closed_form('laguerre_omitted_after', 3);
# omitted_fk_closed_form('laguerre_omitted_after', 4);
omitted_expr('laguerre_omitted_after');

exit 0;
