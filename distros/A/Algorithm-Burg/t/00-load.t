#!perl
use strict;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Algorithm::Burg));
};

diag(qq(Algorithm::Burg v$Algorithm::Burg::VERSION, Perl $], $^X));
