#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(App::cpantested));
};

diag(qq(App::cpantested v$App::cpantested::VERSION, Perl $], $^X));
