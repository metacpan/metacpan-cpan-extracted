#!perl

use strict;
use warnings;

use Test::More tests => 2 * (2 + (8 * 7) / 2 + 2) + 3 * 4;

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

my $x_ver   = qr/Version mismatch/;
my $x_range = qr/Incompatible ranges/;

my @tests = (
 [ [ $a0 ] => $a0 ],
 [ [ $a1 ] => $a1 ],

 [ [ $a0, $a0 ] => $a0 ],
 [ [ $a0, $a1 ] => $a1 ],
 [ [ $a0, $a2 ] => $a2 ],
 [ [ $a0, $a3 ] => $a3 ],
 [ [ $a0, $a4 ] => $a4 ],
 [ [ $a0, $a5 ] => $a5 ],
 [ [ $a0, $a6 ] => $a6 ],

 [ [ $a1, $a1 ] => $a1 ],
 [ [ $a1, $a2 ] => $x_ver ],
 [ [ $a1, $a3 ] => $a1 ],
 [ [ $a1, $a4 ] => $x_ver ],
 [ [ $a1, $a5 ] => $x_ver ],
 [ [ $a1, $a6 ] => $x_ver ],

 [ [ $a2, $a2 ] => $a2 ],
 [ [ $a2, $a3 ] => $a2 ],
 [ [ $a2, $a4 ] => $x_ver ],
 [ [ $a2, $a5 ] => $x_range ],
 [ [ $a2, $a5 ] => $x_range ],

 [ [ $a3, $a3 ] => $a3 ],
 [ [ $a3, $a4 ] => $x_ver ],
 [ [ $a3, $a5 ] => $x_range ],
 [ [ $a3, $a6 ] => $x_range ],

 [ [ $a4, $a4 ] => $a4 ],
 [ [ $a4, $a5 ] => $a4 ],
 [ [ $a4, $a6 ] => $x_ver ],

 [ [ $a5, $a5 ] => $a5 ],
 [ [ $a5, $a6 ] => $a6 ],

 [ [ $a6, $a6 ] => $a6 ],

 [ [ ($a1) x 3 ] => $a1 ],
 [ [ ($a2) x 4 ] => $a2 ],
);

for my $t (@tests) {
 my ($args, $exp) = @$t;

 for my $r (0 .. 1) {
  my @a = @$args;
  @a = reverse @a if $r;

  my $desc = join ' AND ', map "'$_'", @a;

  my $a   = eval { A->and(@a) };
  my $err = $@;

  if (ref $exp eq 'Regexp') {
   like $err, $exp, "$desc should fail";
  } elsif ($err) {
   fail "$desc failed but shouldn't: $err";
  } else {
   ok +($a == $exp), "$desc == '$exp'";
  }
 }
}

my $a1b = A->new(
 category => 'test',
 name     => 'a',
 version  => '1.0',
);

my $b1 = A->new(
 category => 'test',
 name     => 'b',
 version  => '1.0',
 range    => '<',
);

my $b2 = A->new(
 category => 'test',
 name     => 'b',
 version  => '3.0',
 range    => '<',
);

my @folded = eval { A->fold($a1b, $a5, $b1, $b2) };
is $@,      '', 'aabb: no error';
is @folded, 2,  'aabb: fold results in two atoms';
ok $folded[0] == $a5, 'aabb: first result is >=test/a-2.0';
ok $folded[1] == $b1, 'aabb: second result is <test/b-1.0';

@folded = eval { A->fold($a1b, $b1, $b2, $a5) };
is $@,      '', 'abba: no error';
is @folded, 2,  'abba: fold results in two atoms';
ok $folded[0] == $a5, 'abba: first result is >=test/a-2.0';
ok $folded[1] == $b1, 'abba: second result is <test/b-1.0';

@folded = eval { A->fold($a1b, $b1, $a5, $b2) };
is $@,      '', 'abab: no error';
is @folded, 2,  'abab: fold results in two atoms';
ok $folded[0] == $a5, 'abab: first result is >=test/a-2.0';
ok $folded[1] == $b1, 'abab: second result is <test/b-1.0';
