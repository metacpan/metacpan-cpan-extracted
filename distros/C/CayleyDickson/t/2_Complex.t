#!/usr/bin/perl -wT
#
# t/Complex.t
#
#
use strict;
use Test::More tests => 14;

use CayleyDickson;
use Data::Dumper;
use utf8;
use constant DEBUG      => 0;
use constant VERBOSE    => 1; # default 1
use constant PRECISION  => 10 ** -9;
use constant LOOPS      => 10000;
use constant DIMENSIONS => 2;

diag('Complex tests');

my ($x, $y, $z);
my ($o, $i, $j, $k);
my ($a, $b, $c, $d, $e, $f, $g, $h);
my $result = {
   norm_x      => 1,
   norm_y      => 1,
   norm_z      => 1,
   weak_a      => 1,
   weak_b      => 1,
   moufang_a   => 1,
   moufang_b   => 1,
   moufang_c   => 1,
   moufang_d   => 1,
   commutative => 1,
};

diag('Multiplication Table tests ...') if VERBOSE;

$o = CayleyDickson->new(1,0);
$i = CayleyDickson->new(0,1);
ok((($o*$o - $o)->norm <= PRECISION), sprintf ' 1 * 1 = %s', $o*$o);
ok((($o*$i - $i)->norm <= PRECISION), sprintf ' 1 * i = %s', $o*$i);
ok((($i*$o - $i)->norm <= PRECISION), sprintf ' i * 1 = %s', $i*$o);
ok((($i*$i + $o)->norm <= PRECISION), sprintf ' i * i = %s', $i*$i);

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

ok(($result->{'commutative'}), sprintf('check x * y = y * x'));

diag('Weak Association tests ...') if VERBOSE;

# weak alternative condition ...
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

ok($result->{'moufang_a'}, sprintf('check z*(x*(z*y)) == ((z*x)*z)*y'));
ok($result->{'moufang_b'}, sprintf('check x*(z*(y*z)) == ((x*z)*y)*z'));
ok($result->{'moufang_c'}, sprintf('check (z*x)*(y*z) == (z*(x*y))*z'));
ok($result->{'moufang_d'}, sprintf('check (z*x)*(y*z) == z*((x*y)*z)'));

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

ok($result->{'norm_x'}, sprintf('norm x is 1'));
ok($result->{'norm_y'}, sprintf('norm y is 1'));
ok($result->{'norm_z'}, sprintf('norm z is 1'));


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

