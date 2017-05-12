#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    $ENV{NOCACHE} = 1;
    use_ok(q(Acme::TLDR));
};

diag(qq(Acme::TLDR v$Acme::TLDR::VERSION, Perl $], $^X));
