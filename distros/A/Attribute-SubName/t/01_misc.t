#!/usr/bin/env perl
use warnings;
use strict;
use Attribute::SubName;
use Test::More tests => 2;
my $x = sub  : Name(foo) {
    2 * $_[0];
};
is($x->(23), 46, 'called as code ref');
is(foo(44),  88, 'called by name');
