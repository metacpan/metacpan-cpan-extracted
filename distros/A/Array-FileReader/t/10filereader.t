#!/usr/local/bin/perl -w
use strict;
use Test::More 'no_plan';

# no, I'm not happy about the lack of tests.  This module
# has been taken over from Simon Cozens and I'll eventually
# add some tests, but for the time being I want to get this
# out on the CPAN so people at least know that it's still
# being maintained.

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib/', '../blib/lib';
    use_ok('Array::FileReader') or die;
}
