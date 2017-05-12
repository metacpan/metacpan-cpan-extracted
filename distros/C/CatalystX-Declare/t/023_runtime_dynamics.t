#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More; 
use Catalyst::Test 'TestApp';

is get('/df_foo/msg'), 'foo', 'dynamic final with active final';
is get('/df_bar/msg/wrapped'), 'wrapped[bar]', 'dynamic final with non-final and attached actions';

my $make_counter = sub {
    my ($ctrl, $counter) = @_;
    return sub { scalar get(sprintf '/df_%s/counter/%s', $ctrl, $counter) };
};

my $foo_x = $make_counter->(qw( foo x ));
my $foo_y = $make_counter->(qw( foo y ));
my $bar_y = $make_counter->(qw( bar y ));
my $bar_z = $make_counter->(qw( bar z ));

for (0 .. 3) {
    is $foo_x->(), $_, "foo closure state test x $_";
    is $foo_y->(), $_, "foo closure state test y $_";
}

for (0 .. 3) {
    is $bar_y->(), $_, "bar closure state test y $_";
    is $bar_z->(), $_, "bar closure state test z $_";
}

for (4 .. 6) {
    is $foo_x->(), $_, "foo closure state test x $_";
    is $bar_y->(), $_, "bar closure state test y $_";
}

for (4 .. 6) {
    is $foo_y->(), $_, "foo closure state test y $_";
    is $bar_z->(), $_, "bar closure state test z $_";
}

done_testing;

