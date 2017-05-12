#!perl

use strict;
use warnings;

use Test::More tests => 2 * 8 * ((8 * 7) / 2);

use CPANPLUS::Dist::Gentoo::Atom;

sub A () { 'CPANPLUS::Dist::Gentoo::Atom' }

my $a0 = A->new(
 category => 'test',
 name     => 'a',
);

my $a1 = A->new(
 category => 'test',
 name     => 'a',
 version  => '1.0',
 range    => '=',
);

my $a2 = A->new(
 category => 'test',
 name     => 'a',
 version  => '1.0',
 range    => '<',
);

my $a3 = A->new(
 category => 'test',
 name     => 'a',
 version  => '1.0',
 range    => '<=',
);

my $a4 = A->new(
 category => 'test',
 name     => 'a',
 version  => '2.0',
 range    => '=',
);

my $a5 = A->new(
 category => 'test',
 name     => 'a',
 version  => '2.0',
 range    => '>=',
);

my $a6 = A->new(
 category => 'test',
 name     => 'a',
 version  => '2.0',
 range    => '>',
);

my @tests = (
 [ $a0, $a0 =>  0 ],
 [ $a0, $a1 => -1 ],
 [ $a0, $a2 => -1 ],
 [ $a0, $a3 => -1 ],
 [ $a0, $a4 => -1 ],
 [ $a0, $a5 => -1 ],
 [ $a0, $a6 => -1 ],

 [ $a1, $a1 =>  0 ],
 [ $a1, $a2 =>  0 ],
 [ $a1, $a3 =>  0 ],
 [ $a1, $a4 => -1 ],
 [ $a1, $a5 => -1 ],
 [ $a1, $a6 => -1 ],

 [ $a2, $a2 =>  0 ],
 [ $a2, $a3 =>  0 ],
 [ $a2, $a4 => -1 ],
 [ $a2, $a5 => -1 ],
 [ $a2, $a5 => -1 ],

 [ $a3, $a3 =>  0 ],
 [ $a3, $a4 => -1 ],
 [ $a3, $a5 => -1 ],
 [ $a3, $a6 => -1 ],

 [ $a4, $a4 =>  0 ],
 [ $a4, $a5 =>  0 ],
 [ $a4, $a6 =>  0 ],

 [ $a5, $a5 =>  0 ],
 [ $a5, $a6 =>  0 ],

 [ $a6, $a6 =>  0 ],
);

sub compare_ok {
 my ($a, $cmp, $b, $exp) = @_;

 my $desc = join " $cmp ", map "'$_'", $a, $b;

 my ($err, $c);
 {
  local $@;
  $c   = eval "\$a $cmp \$b";
  $err = $@;
 }

 if (ref $exp eq 'Regexp') {
  like $err, $exp, "$desc should fail";
 } elsif ($err) {
  fail "$desc failed but shouldn't: $err";
 } else {
  is $c, $exp, "$desc == '$exp'";
 }
}

for my $t (@tests) {
 my ($a, $b, $exp) = @$t;

 for my $r (0 .. 1) {
  if ($r) {
   ($a, $b) = ($b, $a);
   $exp = -$exp;
  }

  compare_ok($a, '<=>', $b, $exp);

  my $bs = "$b";
  compare_ok($a, '<=>', $bs, $exp);

  my $bv = $b->version;
  if (defined $bv) {
   compare_ok($a, '<=>', $bv,   $exp);
   compare_ok($a, '<=>', "$bv", $exp);
  } else {
   pass("$bs has no version part ($_)") for 1, 2;
  }

  compare_ok($a, 'cmp', $b, $exp);

  my $bz = $b->qualified_name;
  $bz   .= "-$bv" if defined $bv;
  compare_ok($a, 'cmp', $bz, $exp);

  $bz  = "test/zzz";
  $bz .= "-$bv" if defined $bv;
  compare_ok($a,  'cmp', $bz, -1);
  compare_ok($bz, 'cmp', $b,  1);
 }
}
