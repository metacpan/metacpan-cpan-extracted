#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Bundle::SYP));
};

diag(qq(Bundle::SYP v$Bundle::SYP::VERSION, Perl $], $^X));
