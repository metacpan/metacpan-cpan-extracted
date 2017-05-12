#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Algorithm::SlopeOne));
};

diag(qq(Algorithm::SlopeOne v$Algorithm::SlopeOne::VERSION, Perl $], $^X));
