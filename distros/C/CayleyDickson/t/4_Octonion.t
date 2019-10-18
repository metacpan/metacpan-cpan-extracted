#!/usr/bin/perl -wT
#
# t/Octonion.t
#
#
use strict;
use Test::More tests => 48;

use CayleyDickson;
use Data::Dumper;
use utf8;
use constant DEBUG      => 0;
use constant VERBOSE    => 1; # default 1
use constant PRECISION  => 10 ** -9;
use constant LOOPS      => 400;
use constant DIMENSIONS => 8;

diag('Octonion tests');

my ($x, $y, $z);
my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l, $m, $n, $o);
my $result = {
   norm_x        => 1,
   norm_y        => 1,
   norm_z        => 1,
   associative_a => 1,
   associative_b => 1,
   associative_c => 1,
   associative_d => 1,
   associative_e => 1,
   associative_f => 1,
   weak_a        => 1,
   weak_b        => 1,
   moufang_a     => 1,
   moufang_b     => 1,
   moufang_c     => 1,
   moufang_d     => 1,
   commutative   => 1,
};

diag('Multiplication Table tests ...') if VERBOSE;

$a = CayleyDickson->new(1,0,0,0,0,0,0,0);
$i = CayleyDickson->new(0,1,0,0,0,0,0,0);
$j = CayleyDickson->new(0,0,1,0,0,0,0,0);
$k = CayleyDickson->new(0,0,0,1,0,0,0,0);
$l = CayleyDickson->new(0,0,0,0,1,0,0,0);
$m = CayleyDickson->new(0,0,0,0,0,1,0,0);
$n = CayleyDickson->new(0,0,0,0,0,0,1,0);
$o = CayleyDickson->new(0,0,0,0,0,0,0,1);

ok((($a*$a - $a)->norm <= PRECISION), sprintf ' 1 * 1 = %s', $a*$a);
ok((($a*$i - $i)->norm <= PRECISION), sprintf ' 1 * i = %s', $a*$i);
ok((($a*$j - $j)->norm <= PRECISION), sprintf ' 1 * j = %s', $a*$j);
ok((($a*$k - $k)->norm <= PRECISION), sprintf ' 1 * k = %s', $a*$k);
ok((($a*$l - $l)->norm <= PRECISION), sprintf ' 1 * l = %s', $a*$l);
ok((($a*$m - $m)->norm <= PRECISION), sprintf ' 1 * m = %s', $a*$m);
ok((($a*$n - $n)->norm <= PRECISION), sprintf ' 1 * n = %s', $a*$n);
ok((($a*$o - $o)->norm <= PRECISION), sprintf ' 1 * o = %s', $a*$o);

ok((($i*$a - $i)->norm <= PRECISION), sprintf ' i * 1 = %s', $i*$a);
ok((($i*$i + $a)->norm <= PRECISION), sprintf 'i * i = %s', $i*$i);
ok((($i*$j - $k)->norm <= PRECISION), sprintf 'i * j = %s', $i*$j);
ok((($i*$k + $j)->norm <= PRECISION), sprintf 'i * k = %s', $i*$k);
ok((($i*$l - $m)->norm <= PRECISION), sprintf 'i * l = %s', $i*$l);
ok((($i*$m + $l)->norm <= PRECISION), sprintf 'i * m = %s', $i*$m);
ok((($i*$n + $o)->norm <= PRECISION), sprintf 'i * n = %s', $i*$n);
ok((($i*$o - $n)->norm <= PRECISION), sprintf 'i * o = %s', $i*$o);

ok((($j*$a - $j)->norm <= PRECISION), sprintf 'j * 1 = %s', $j*$a);
ok((($j*$i + $k)->norm <= PRECISION), sprintf 'j * i = %s', $j*$i);
ok((($j*$j + $a)->norm <= PRECISION), sprintf 'j * j = %s', $j*$j);
ok((($j*$k - $i)->norm <= PRECISION), sprintf 'j * k = %s', $j*$k);
ok((($j*$l - $n)->norm <= PRECISION), sprintf 'j * l = %s', $j*$l);
ok((($j*$m - $o)->norm <= PRECISION), sprintf 'j * m = %s', $j*$m);
ok((($j*$n + $l)->norm <= PRECISION), sprintf 'j * n = %s', $j*$n);
ok((($j*$o + $m)->norm <= PRECISION), sprintf 'j * o = %s', $j*$o);

ok((($k*$a - $k)->norm <= PRECISION), sprintf 'k * 1 = %s', $k*$a);
ok((($k*$i - $j)->norm <= PRECISION), sprintf 'k * i = %s', $k*$i);
ok((($k*$j + $i)->norm <= PRECISION), sprintf 'k * j = %s', $k*$j);
ok((($k*$k + $a)->norm <= PRECISION), sprintf 'k * k = %s', $k*$k);
ok((($k*$l - $o)->norm <= PRECISION), sprintf 'k * l = %s', $k*$l);
ok((($k*$m + $n)->norm <= PRECISION), sprintf 'k * m = %s', $k*$m);
ok((($k*$n - $m)->norm <= PRECISION), sprintf 'k * n = %s', $k*$n);
ok((($k*$o + $l)->norm <= PRECISION), sprintf 'k * o = %s', $k*$o);


diag(sprintf 'Run %d test loops on ...', LOOPS) if VERBOSE;

diag('Commutative product tests ...') if VERBOSE;

# Commutative products Tests ...
for (1 .. LOOPS) {
   $x = random_vector();
   $y = random_vector();

   d(     x  => $x     ) if DEBUG;
   d(     y  => $y     ) if DEBUG;
   d('x * y' => $x * $y) if DEBUG;
   d('y * x' => $y * $x) if DEBUG;

   $result->{commutative} &= ( $x * $y - $y * $x )->norm <= PRECISION;
}
if (VERBOSE) {
   warn sprintf <<END

  Commutative: 
              x = %s
              y = %s
          x * y = %s
          y * x = %s
     Difference = %s

END
   , $x, $y, $x * $y, $y * $x, ( $x * $y - $y * $x )->norm;
}

ok((not $result->{'commutative'}), sprintf('deny  x * y = y * x'));


# 
# associative condion ...
# 

diag('Associative tests ...') if VERBOSE;
for (1 .. LOOPS) {
   $x = random_vector();
   $y = random_vector();
   $z = random_vector();

   $a = ($x *  $y) * $z;
   $b =  $x * ($y  * $z);
   $result->{associative_a} &= ($a-$b)->norm <= PRECISION;

   $c = ($x *  $z) * $y;
   $d =  $x * ($z  * $y);
   $result->{associative_b} &= ($c-$d)->norm <= PRECISION;

   $e = ($y *  $x) * $z;
   $f =  $y * ($x  * $z);
   $result->{associative_c} &= ($e-$f)->norm <= PRECISION;

   $g = ($y *  $z) * $x;
   $h =  $y * ($z  * $x);
   $result->{associative_d} &= ($g-$h)->norm <= PRECISION;

   $i = ($z *  $x) * $y;
   $j =  $z * ($x  * $y);
   $result->{associative_e} &= ($i-$j)->norm <= PRECISION;

   $k = ($z *  $y) * $x;
   $l =  $z * ($y  * $x);
   $result->{associative_f} &= ($k-$l)->norm <= PRECISION;
}

if (VERBOSE) {
   warn sprintf <<END

  Associative identity 1: 
                  (x*y)*z = %s
                  x*(y*z) = %s
        (x*y)*z - x*(y*z) = %s
               Difference = %s

  Associative identity 1: 
               ($x*$z)*$y = %s
               $x*($z*$y) = %s
  ($x*$z)*$y - $x*($z*$y) = %s
         Difference = %s

  Associative identity 1: 
               ($y*$x)*$z = %s
               $y*($x*$z) = %s
  ($y*$x)*$z - $y*($x*$z) = %s
         Difference = %s

  Associative identity 1: 
               ($y*$z)*$x = %s
               $y*($z*$x) = %s
  ($y*$z)*$x - $y*($z*$x) = %s
         Difference = %s

  Associative identity 1: 
               ($z*$x)*$y = %s
               $z*($x*$y) = %s
  ($z*$x)*$y - $z*($x*$y) = %s
         Difference = %s

  Associative identity 1: 
              ($z*$y)*$x  = %s
              $z*($y*$x)  = %s
  ($z*$y)*$x - $z*($y*$x) = %s
         Difference = %s

END
   , $a, $b, $a-$b, ($a-$b)->norm,
   , $c, $d, $c-$d, ($c-$d)->norm,
   , $e, $f, $e-$f, ($e-$f)->norm,
   , $g, $h, $g-$h, ($g-$h)->norm,
   , $i, $j, $i-$j, ($i-$j)->norm,
   , $k, $l, $k-$l, ($k-$l)->norm,
}

ok((not $result->{associative_a}), sprintf('deny (x*y)*z - x*(y*z)'));
ok((not $result->{associative_b}), sprintf('deny (x*z)*y - x*(z*y)'));
ok((not $result->{associative_c}), sprintf('deny (y*x)*z - y*(x*z)'));
ok((not $result->{associative_d}), sprintf('deny (y*z)*x - y*(z*x)'));
ok((not $result->{associative_e}), sprintf('deny (z*x)*y - z*(x*y)'));
ok((not $result->{associative_f}), sprintf('deny (z*y)*x - z*(y*x)'));


# 
# weak associative condion. alternative algebra ...
# 

diag('Weak Association tests ...') if VERBOSE;
for (1 .. LOOPS) {
   $x = unit_vector();
   $y = unit_vector();

   $a = ($x *  $x) * $y;
   $b =  $x * ($x  * $y);
   $result->{weak_a} &= ($a-$b)->norm <= PRECISION;

   $c = ($x *  $y) * $y;
   $d =  $x * ($y  * $y);
   $result->{weak_b} &= ($c-$d)->norm <= PRECISION;
}

if (VERBOSE) {
   warn sprintf <<END

  Weak Identity 1: 
            (x*x)*y = %s
            x*(x*y) = %s
  (x*x)*y - x*(x*y) = %s
         Difference = %s

  Weak Identity 2:
            (x*y)*y = %s
            x*(y*y) = %s
  (x*x)*y - x*(x*y) = %s
         Difference = %s

END
   , $a, $b, $a-$b, ($a-$b)->norm, $c, $d, $c-$d, ($c-$d)->norm;
}

ok($result->{weak_a}, sprintf('check (x*x)*y = x*(x*y)'));
ok($result->{weak_b}, sprintf('check (x*y)*y = x*(y*y)'));


diag('Moufang condition tests ...') if VERBOSE;

# Moufang condition ...
for (1 .. LOOPS) {
   my $x = unit_vector();
   my $y = unit_vector();
   my $z = unit_vector();
   $a =   $z * ($x  * ($z  * $y));
   $b = (($z *  $x) *  $z) * $y;
   $result->{'moufang_a'} &= (($a-$b)->norm <= PRECISION);
              
   $c =   $x * ($z  * ($y * $z));
   $d = (($x *  $z) * $y) * $z;
   $result->{'moufang_b'} &= (($c-$d)->norm <= PRECISION);

   $e = ($z *  $x) * ($y   * $z);
   $f = ($z * ($x  *  $y)) * $z;
   $result->{'moufang_c'} &= (($e-$f)->norm <= PRECISION);

   $g = ($z *   $x) * ($y  * $z);
   $h =  $z * (($x  *  $y) * $z);
   $result->{'moufang_d'} &= (($g-$h)->norm <= PRECISION);
}

if (VERBOSE) {
   warn sprintf <<END

  Moufang condition 1: 
                 z*(x*(z*y)) = %s
                 ((z*x)*z)*y = %s
   x*(z*(y*z)) - ((x*z)*y)*z = %s
                  Difference = %s

  Moufang condition 2:
                 x*(z*(y*z)) = %s
                 ((x*z)*y)*z = %s
   x*(z*(y*z)) - ((x*z)*y)*z = %s
                  Difference = %s

  Moufang condition 3:
                 (z*x)*(y*z) = %s
                 (z*(x*y))*z = %s
   (z*x)*(y*z) - (z*(x*y))*z = %s
                  Difference = %s

  Moufang condition 4:
                 (z*x)*(y*z) = %s
                 z*((x*y)*z) = %s
   (z*x)*(y*z) - z*((x*y)*z) = %s
                  Difference = %s

END
   , $a, $b, $a-$b, ($a-$b)->norm,
   , $c, $d, $c-$d, ($c-$d)->norm,
   , $e, $f, $e-$f, ($e-$f)->norm,
   , $g, $h, $g-$h, ($g-$h)->norm;
}

ok($result->{'moufang_a'}, sprintf('check z*(x*(z*y)) = ((z*x)*z)*y'));
ok($result->{'moufang_b'}, sprintf('check x*(z*(y*z)) = ((x*z)*y)*z'));
ok($result->{'moufang_c'}, sprintf('check (z*x)*(y*z) = (z*(x*y))*z'));
ok($result->{'moufang_d'}, sprintf('check (z*x)*(y*z) = z*((x*y)*z)'));

diag('Power Associative tests ...') if VERBOSE;

# Simgple Norm 1 products Tests ...
for (1 .. LOOPS) {
   $x = unit_vector();
   $y = unit_vector();
   $z = $x * $y;

   d(x => $x) if DEBUG;
   d(y => $y) if DEBUG;
   d(z => $z) if DEBUG;
   warn sprintf "Norm x: %s\n", $x->norm if DEBUG;
   warn sprintf "Norm y: %s\n", $x->norm if DEBUG;
   warn sprintf "Norm z: %s\n", $x->norm if DEBUG;

   $result->{'norm_x'} &= ($x->norm - 1 < PRECISION);
   $result->{'norm_y'} &= ($y->norm - 1 < PRECISION);
   $result->{'norm_z'} &= ($z->norm - 1 < PRECISION);
   #ok($z->norm - 1 < PRECISION, sprintf('norm z: %s == 1', $z->norm));

}

if (VERBOSE) {
   warn sprintf <<END

  vector x: %s
    norm x: %s
  vector y: %s
    norm y: %s
  vector z: %s
    norm z: %s

END
   , $x, $x->norm, $y, $y->norm, $z, $z->norm;
}

ok($result->{'norm_x'}, sprintf('check x is norm 1'));
ok($result->{'norm_y'}, sprintf('check y is norm 1'));
ok($result->{'norm_z'}, sprintf('check z is norm 1'));


# function tools ...

sub unit_vector {
   my $v = random_vector();
   $v / $v->norm
}

sub random_vector {
   CayleyDickson->new(map rand $_, (1) x DIMENSIONS)
}

sub d {
   my %a = @_;
   my @k = keys %a;
   my $d = Data::Dumper->new([@a{@k}],[@k]); $d->Purity(1)->Deepcopy(1); 
   print $d->Dump;
}



1;

__END__

