#!perl

use strict;
use warnings;
use lib qw/./;

use Test::More qw/no_plan/;

use t::Bag;

eval {
    &t::Bag::A::a;
};
like($@, qr/^\Qt::Bag::A::a(): Break! at $0\E/);

eval {
    &t::Bag::A::b;
};
like($@, qr/^\Qt::Bag::A::b(): Break! at $0\E/);
