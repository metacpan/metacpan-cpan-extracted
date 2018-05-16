# Adapted from Perl 5.18's lib/B/Deparse.t
1;
__DATA__
# A constant
1;
####
# Constants in a block
{
    no warnings;
    '???';
    2;
}
####
# Lexical and simple arithmetic
my $test;
++$test and $test /= 2;
>>>>
my $test;
$test /= 2 if ++$test;
####
# list x
# SKIP ROCKY fixme
# -((1, 2) x 2);
####
# lvalue sub
{
    my $test = sub : lvalue {
	my $x;
    };
}
####
# method
{
    my $test = sub : method {
	my $x;
    };
}
####
# lexical and package scalars
my $x;
print $main::x;
####
# lexical and package arrays
my @x;
print $main::x[1];
####
# lexical and package hashes
my %x;
$x{warn()};
####
# <>
my $foo;
$_ .= <ARGV> . <$foo>;
####
# SKIP ROCKY fixme
# \x{}
my $foo = "Ab\x{100}\200\x{200}\237Cd\000Ef\x{1000}\cA\x{2000}\cZ";
####
# block
{ my $x; }
####
# while 1
while (1) { my $k; }
####
# reverse sort
my @x;
print reverse sort(@x);
####
# [perl #81424] match against aelemfast_lex
my @s;
print /$s[1]/;
####
# SKIP ROCKY fixme
# /$#a/
print /$main::a/;
####
# y///r
tr/a/b/r;
####
# readpipe with complex expression
readpipe $a + $b;
####
# aelemfast
$b::a[0] = 1;
####
# aelemfast for a lexical
my @a;
$a[0] = 1;
####
# Feature hints
use feature 'current_sub', 'evalbytes';
print;
use 1;
print;
use 5.014;
print;
no feature 'unicode_strings';
print;
>>>>
use feature 'current_sub', 'evalbytes';
print $_;
no feature ':all';
use feature ':default';
print $_;
no feature ':all';
use feature ':5.12';
print $_;
no feature 'unicode_strings';
print $_;
####
# $#- $#+ $#{%} etc.
my @x;
@x = ($#{`}, $#{~}, $#{!}, $#{@}, $#{$}, $#{%}, $#{^}, $#{&}, $#{*});
@x = ($#{(}, $#{)}, $#{[}, $#{{}, $#{]}, $#{}}, $#{'}, $#{"}, $#{,});
@x = ($#{<}, $#{.}, $#{>}, $#{/}, $#{?}, $#{=}, $#+, $#{\}, $#{|}, $#-);
@x = ($#{;}, $#{:});
####
# ()[...]
my(@a) = ()[()];
####
# sort(foo(bar))
# sort(foo(bar)) is interpreted as sort &foo(bar)
# sort foo(bar) is interpreted as sort foo bar
# parentheses are not optional in this case
print sort(foo('bar'));
>>>>
print sort(foo('bar'));
####
# substr assignment
substr(my $a, 0, 0) = (foo(), bar());
$a++;
####
# Precedence conundrums with argument-less function calls
() = (eof) + 1;
() = (return) + 1;
() = (return, 1);
() = warn;
() = warn() + 1;
() = setpgrp() + 1;
####
# [perl #63558] open local(*FH)
open local *FH;
pipe local *FH, local *FH;
####
# require <binop>
require 'a' . $1;
####
# 'my' works with padrange op
my($z, @z);
my $m1;
$m1 = 1;
$z = $m1;
my $m2 = 2;
my($m3, $m4);
($m3, $m4) = (1, 2);
@z = ($m3, $m4);
my($m5, $m6) = (1, 2);
my($m7, undef, $m8) = (1, 2, 3);
@z = ($m7, undef, $m8);
($m7, undef, $m8) = (1, 2, 3);
####
# 'our/local' works with padrange op
no strict;
our($z, @z);
our $o1;
local $o11;
$o1 = 1;
local $o1 = 1;
$z = $o1;
$z = local $o1;
our $o2 = 2;
our($o3, $o4);
($o3, $o4) = (1, 2);
local($o3, $o4) = (1, 2);
@z = ($o3, $o4);
@z = local($o3, $o4);
our($o5, $o6) = (1, 2);
our($o7, undef, $o8) = (1, 2, 3);
@z = ($o7, undef, $o8);
@z = local($o7, undef, $o8);
($o7, undef, $o8) = (1, 2, 3);
local($o7, undef, $o8) = (1, 2, 3);
####
# 'state' works with padrange op
no strict;
use feature 'state';
state($z, @z);
state $s1;
$s1 = 1;
$z = $s1;
state $s2 = 2;
state($s3, $s4);
($s3, $s4) = (1, 2);
@z = ($s3, $s4);
# assignment of state lists isn't implemented yet
#state($s5, $s6) = (1, 2);
#state($s7, undef, $s8) = (1, 2, 3);
#@z = ($s7, undef, $s8);
($s7, undef, $s8) = (1, 2, 3);
####
# slices with padrange
my($a, $b);
my(@x, %y);
@x = @x[$a, $b];
@x = @y{$a, $b};
####
# 'x' with padrange
my($a, $b, $c, $d, @e);
$c = $a x $b;
$a x= $b;
@e = ($a) x $d;
@e = ($a, $b) x $d;
@e = ($a, $b, $c) x $d;
@e = ($a, 1) x $d;
####
# @_ with padrange
my($a, $b, $c) = @_;
####
# SKIP ?$] < 5.017004 && "lexical subs not implemented on this Perl version"
# TODO unimplemented in B::Deparse; RT #116553
# lexical subroutine
use feature 'lexical_subs';
no warnings "experimental::lexical_subs";
my sub f {}
print f();
# Elements of %# should not be confused with $#{ array }
() = ${#}{'foo'};
####
# SKIP ?$] < 5.017004 && "lexical subs not implemented on this Perl version"
# TODO unimplemented in B::Deparse; RT #116553
# lexical "state" subroutine
use feature 'state', 'lexical_subs';
no warnings 'experimental::lexical_subs';
state sub f {}
print f();
