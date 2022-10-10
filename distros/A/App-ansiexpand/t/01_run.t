use v5.14;
use warnings;

use Test::More;

use lib '.';
use t::Util;

is(ansiexpand('/dev/null')->run->{result} >> 8, 0, "/dev/null");
is(ansiexpand('--tabstop', '4', '/dev/null')->run->{result} >> 8, 0, "valid --tabstop");
is(ansiexpand('-t', '4', '/dev/null')->run->{result} >> 8, 0, "valid -t 4");
is(ansiexpand('-t4', '/dev/null')->run->{result} >> 8, 0, "valid -t4");
is(ansiexpand('-4', '/dev/null')->run->{result} >> 8, 0, "valid -4");
is(ansiexpand('--ambiguous', 'narrow', '/dev/null')->run->{result} >> 8, 0, "valid --ambiguous");

is(ansiexpand('--undefined')->run->{result} >> 8, 2, "undefined option");
is(ansiexpand('-t', '0', '/dev/null')->run->{result} >> 8, 2, "valid -t 4");
is(ansiexpand('-0', '/dev/null')->run->{result} >> 8, 2, "invalid -0");
is(ansiexpand('--4', '/dev/null')->run->{result} >> 8, 2, "invalid --4");
is(ansiexpand('--tabstop', '0')->run->{result} >> 8, 2, "invalid --tabstop");
is(ansiexpand('--ambiguous', 'big', '/dev/null')->run->{result} >> 8, 2, "invalid --ambiguous");

done_testing;
