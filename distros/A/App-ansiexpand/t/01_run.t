use v5.14;
use warnings;

use Test::More;

use lib '.';
use t::Util;

is(ansiexpand('/dev/null')->run->{result} >> 8, 0, "/dev/null");
is(ansiexpand('--undefined')->run->{result} >> 8, 2, "undefined option");

is(ansiexpand('--tabstop', '4', '/dev/null')->run->{result} >> 8, 0, "valid --tabstop");
is(ansiexpand('--tabstop', '0')->run->{result} >> 8, 2, "invalid --tabstop");

is(ansiexpand('--ambiguous', 'narrow', '/dev/null')->run->{result} >> 8, 0, "valid --ambiguous");
is(ansiexpand('--ambiguous', 'big', '/dev/null')->run->{result} >> 8, 2, "invalid --ambiguous");

done_testing;
