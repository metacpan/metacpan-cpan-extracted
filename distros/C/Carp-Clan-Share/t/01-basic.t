#!perl

use strict;
use warnings;
use lib qw/./;

use Test::More qw/no_plan/;

use t::Pack;

eval {
    &t::Pack::A::a;
};
like($@, qr/^\Qt::Pack::A::a(): Break! at $0\E/);

eval {
    &t::Pack::A::b;
};
like($@, qr/^\Qt::Pack::A::b(): Break! at $0\E/);
