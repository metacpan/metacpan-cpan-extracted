#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Fish qw(format_completion);
use Test::More;

subtest "accepts array of str" => sub {
    is(format_completion([qw/a b c/]), "a\t\nb\t\nc\t\n");
};

subtest "accepts array of hashref" => sub {
    is(format_completion([
        {word=>'a', description=>'da'},
        {word=>'b', description=>'db'},
        {word=>'c', description=>'dc'},
    ]), "a\tda\nb\tdb\nc\tdc\n");
};

# the rest is tested by Complete::Bash

DONE_TESTING:
done_testing;
