#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Password::Top10000 qw(is_in_top10000);

my %passwords = (
    explore => 1,
    boulder => 1,

    data_password_top10000 => '',
);

for my $password ( sort keys %passwords ) {
    is is_in_top10000( $password ), $passwords{$password};
}

done_testing;
