#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'Testing collisions only upon release'
        unless $ENV{RELEASE_TESTING};
}

use Sub::Util;

use Data::Cuid;

my $max = 1_200_000;
plan tests => $max * 2;

my $test = sub {
    my $fn = shift;
    my %ids;

    my $fn_name = Sub::Util::subname $fn;
    for ( my $i = 0; $i < $max; $i++ ) {
        my $id = $fn->();

        ok !$ids{$id}, "$id is unique in $i iterations ($fn_name)";
        ++$ids{$id};
    }
};

$test->( \&Data::Cuid::cuid );

TODO: {
    local $TODO = 'slug() can easily get collisions due to less precision';

    $test->( \&Data::Cuid::slug );
}
