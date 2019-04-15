#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 13;

{
  my $data = ptp([qw(--substitute o a)], 'default_small.txt');
  is($data, "faabar\nfaabaz\n\nlast\n", 'substitute');
}{
  my $data = ptp([qw(-L -s o a)], 'default_small.txt');
  is($data, "faobar\nfaobaz\n\nlast\n", 'local substitute');
}{
  my $data = ptp([qw(-L -G -s o a)], 'default_small.txt');
  is($data, "faabar\nfaabaz\n\nlast\n", 'global substitute');
}{
  my $data = ptp([qw(-s o([^o]) ${1}a)], 'default_small.txt');
  is($data, "fobaar\nfobaaz\n\nlast\n", 'substitute with capture');
}{
  my $data = ptp([qw(-s oo o'o)], 'default_small.txt');
  is($data, "fo'obar\nfo'obaz\n\nlast\n", 'add quote');
}{
  my $data = ptp([qw(-s oo o"o\")], 'default_small.txt');
  is($data, "fo\"o\"bar\nfo\"o\"baz\n\nlast\n", 'add double quote');
}{
  my $data = ptp([qw(-Q -s oo o"o\")], 'default_small.txt');
  is($data, "fo\"o\\\"bar\nfo\"o\\\"baz\n\nlast\n", 'add double quote quoted');
}{
  # A '\\' in the string is evaluated like a single 'real' \ when building the
  # string, which then become an escape character when the regex is evaluated.
  my ($data, $err) = ptp(['-s', 'oo(.)', 'oo\\\\$1'], 'default_small.txt');
  is($data, "foo\\bar\nfoo\\baz\n\nlast\n", 'add backslash') or diag $err;
}{
  my $data = ptp([qw(-s oo(.) oo/$1)], 'default_small.txt');
  is($data, "foo/bar\nfoo/baz\n\nlast\n", 'add slash');
}{
  # Same here. Funily (...), /o, \/o, \\/o an \\\/o are all equivalent, but then
  # \\\\/o starts becoming something else...
  my $data = ptp([qw(-s oo(.) o\\\\/o/$1)], 'default_small.txt');
  is($data, "fo\\/o/bar\nfo\\/o/baz\n\nlast\n", 'add slashes');
}{
  my $data = ptp([qw(-s / a)], \'a/b');
  is($data, "aab", 'slash in re');
}{
  my $data = ptp([qw(-e $a='z' -s $a w)], 'default_small.txt');
  is($data, "foobar\nfoobaw\n\nlast\n", 'match variable');
}{
  my $data = ptp([qw(-e $a='z' -s oo(.) o$a$1)], 'default_small.txt');
  is($data, "fozbar\nfozbaz\n\nlast\n", 'replace variable');
}
