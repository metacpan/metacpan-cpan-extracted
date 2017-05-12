#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Bash qw(point);
use Test::Exception;
use Test::More;

dies_ok { point("") } "no marker -> dies";
is_deeply([point("^a")], ["a", 0]);
is_deeply([point("a^")], ["a", 1]);
is_deeply([point("a*", "*")], ["a", 1]);

done_testing;
