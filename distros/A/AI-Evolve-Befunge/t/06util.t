#!/usr/bin/perl
use strict;
use warnings;

BEGIN { $ENV{AIEVOLVEBEFUNGE} = 't/testconfig.conf'; };

my $num_tests;
BEGIN { $num_tests = 0; };
use Test::More;
use Test::Output;
use Test::Exception;

use AI::Evolve::Befunge::Util;


# quiet
is(get_quiet(), 0, "non-quiet by default");
push_quiet(3);
is(get_quiet(), 3, "quiet now");
stdout_is(sub { quiet("foo") }, "foo", "quiet() writes when quiet value non-zero");
stdout_is(sub { nonquiet("foo") }, "", "nonquiet() writes nothing");
pop_quiet();
pop_quiet();
is(get_quiet(), 0, "now back to non-quiet default");
stdout_is(sub { quiet("foo") }, "", "quiet() writes nothing");
stdout_is(sub { nonquiet("foo") }, "foo", "nonquiet() writes correctly");
BEGIN { $num_tests += 7 };


# verbose
is(get_verbose(), 0, "non-verbose by default");
push_verbose(3);
is(get_verbose(), 3, "verbose now");
stdout_is(sub { verbose("foo") }, "foo", "verbose() writes when verbose value non-zero");
pop_verbose();
pop_verbose();
is(get_verbose(), 0, "now back to non-verbose default");
stdout_is(sub { verbose("foo") }, "", "verbose() writes nothing");
BEGIN { $num_tests += 5 };


# debug
is(get_debug(), 0, "non-debug by default");
push_debug(3);
is(get_debug(), 3, "debug now");
stdout_is(sub { debug("foo") }, "foo", "debug() writes when debug value non-zero");
pop_debug();
pop_debug();
is(get_debug(), 0, "now back to non-debug default");
stdout_is(sub { debug("foo") }, "", "debug() writes nothing");
BEGIN { $num_tests += 5 };


# v
is(v(1, 2, 3), "(1,2,3)", "v returns a vector");
is(ref(v(1, 2, 3)), "Language::Befunge::Vector", "v the right kind of object");
BEGIN { $num_tests += 2 };


# code_print
stdout_is(sub { code_print(join("",map { chr(ord('a')+$_) } (0..24)),5,5) }, <<EOF, "code_print (ascii)");
   01234
 0 abcde
 1 fghij
 2 klmno
 3 pqrst
 4 uvwxy
EOF
stdout_is(sub { code_print(join("",map { chr(1+$_) } (0..25)),11,3) }, <<EOF, "code_print (hex)");
                                   1
     0  1  2  3  4  5  6  7  8  9  0
 0   1  2  3  4  5  6  7  8  9  a  b
 1   c  d  e  f 10 11 12 13 14 15 16
 2  17 18 19 1a  0  0  0  0  0  0  0
EOF
dies_ok(sub { code_print }, "no code");
dies_ok(sub { code_print("") }, "no sizex");
dies_ok(sub { code_print("", 1) }, "no sizey");
BEGIN { $num_tests += 5 };


# note: custom_config and global_config are thoroughally tested by 01config.t.


BEGIN { plan tests => $num_tests };
