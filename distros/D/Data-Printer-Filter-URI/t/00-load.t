#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(Data::Printer::Filter::URI));
};

diag(qq(Data::Printer::Filter::URI v$Data::Printer::Filter::URI::VERSION, Perl $], $^X));
