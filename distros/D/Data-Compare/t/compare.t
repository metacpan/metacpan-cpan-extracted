# -*- Mode: Perl -*-

BEGIN { unshift @INC, "lib", "../lib" }
use strict;
use warnings;
# use diagnostics;

use Data::Compare;

local $^W = 1;
print "1..45\n";

my $t = 1;

my $s0 = undef;
my $s1 = 0;
my $s2 = 10;

# 1 .. 4
&comp($s0, $s0, 1);
&comp($s1, $s1, 1);
&comp($s2, $s2, 1);
&comp($s0, $s1, 0);

my $s3 = \$s2;
my $s4 = \$s1;
my $s5 = "$s4";
my $s6 = 0;
my $s7 = \$s6;

# 5 .. 8
&comp($s3, $s3, 1);
&comp($s3, $s4, 0);
&comp($s4, $s5, 0);
&comp($s4, $s7, 1);

my $a1 = [];
my $a2 = [ 0 ];
my $a3 = [ '' ];
my $a4 = [ 1, 2, 3 ];
my $a5 = [ 1, 2, 4 ];
my $a6 = [ 1, 2, 3, 5 ];

# 9 .. 13
&comp($a1, $a1, 1);
&comp($a1, $a2, 0);
&comp($a2, $a3, 0);
&comp($a4, $a5, 0);
&comp($a4, $a6, 0);

my $h1 = {};
my $h2 = { 'foo' => 'bar' };
my $h3 = { 'foo' => 'bar' };
my $h4 = { 'foo' => 'bar', 'bar' => 'foo' };

# 14 .. 19
&comp($h1, $s0, 0);
&comp($h1, $h1, 1);
&comp($h2, $h2, 1);
&comp($h2, $h3, 1);
&comp($h1, $h2, 0);
&comp($h3, $h4, 0);

my $o1 = bless [ 'FOO', 'BAR' ], 'foo';
my $o2 = bless [ 'FOO', 'BAR' ], 'foo';
my $o3 = bless [ 'FOO', 'BAR' ], 'fool';
my $o4 = bless [ 'FOO', 'BAR', 'BAZ' ], 'foo';

# 20 .. 22
&comp($o1, $o2, 1);
&comp($o1, $o3, 0);
&comp($o1, $o4, 0);

my $o5 = bless { 'FOO' => 'BAR' }, 'foo';
my $o6 = bless { 'FOO' => 'BAR' }, 'foo';
my $o7 = bless { 'FOO' => 'BAR' }, 'fool';
my $o8 = bless { 'FOO' => 'BAR', 'foo' => 'BAZ' }, 'foo';

# 23 .. 25
&comp($o5, $o6, 1);
&comp($o5, $o7, 0);
&comp($o5, $o8, 0);

my $s8  = 0;
my $o9  = bless \$s0, 'foo';
my $o10 = bless \$s8, 'foo';
my $o11 = bless \$s1, 'foo';

# 26 .. 27
&comp($o9,  $o10, 0);
&comp($o10, $o11, 1);

my $g1 = \*STDIN;
my $g2 = \*STDOUT;

# 28 .. 29
&comp($g1, $g1, 1);
&comp($g1, $g2, 0);

my $o12 = bless $g1, 'foo';
my $o13 = bless $g2, 'foo';

# 30 .. 31
&comp($o12, $o12, 1);
&comp($o12, $o13, 0);

my $o16 = bless sub { print "foo\n" }, 'foo';
my $o17 = bless sub { print "foo\n" }, 'foo';

# 32
&comp($o16, $o17, 0); # :(

my $v1 = { 'foo' => [ 1, { 'bar' => 'baz' }, 3 ] };
my $v2 = { 'bar' => 'baz' };
my $v3 = [ 1, $v2, 3 ];
my $v4 = { 'foo' => $v3 };

# 33
&comp($v1, $v4, 1);

# 34 .. 37
&comp(\\1, \\1, 1);
&comp(\\1, \\2, 0);
&comp(\\1, 1, 0);
&comp(\\1, \1, 0);

# 38 .. 40
&comp(qr/abc/i, qr/abc/i, 1, "Identical regexen");
&comp(qr/abc/i, qr/[aA][bB][cC]/, 0, "Non-identical regexen");
&comp(qr/abc/i, '(?i-xsm:abc)', 0, "Regex and scalar which stringify the same");

# 41 .. 43
# scalar cross
$a = [];
my($x, $y);
$x=\$y; 
$y=\$x; 
$a->[0]=\$a->[1]; 
$a->[1]=\$a->[0]; 
&comp([$x, $y], $a, 1, "two parallel circular structures compare the same");

# these two are probably superfluous, as they test referential equality
# rather than any of the stuff we added to do with circles and recursion
&comp([$x, $y], [$y, $x], 1, "looking at a circle from two different starting points compares the same");
&comp([$x, $y], [$x, $y], 1, "a circular structure compares to itself");

$a = [];
$b = [];
$a->[0] = { foo => { bar => $a } };
$b->[0] = { foo => { bar => $b } };
$a->[1] = $b->[1] = 5;
comp($a, $b, 1, "structure of a circle plus same data compares the same");

$a->[1] = 6;
comp($a, $b, 0, "structure of a circle plus different data compares different");
sub comp {
  my $a = shift;
  my $b = shift;
  my $expect = shift;
  my $comment = shift;

  print Compare ($a, $b) == $expect ? "" : "not ", "ok ", $t++,
    ($comment) ? " $comment\n" : "\n";
}
