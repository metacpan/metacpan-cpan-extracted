#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use DBIx::Config;

my $obj = DBIx::Config->new({
    config_paths => [ ( './this', '/var/www/that' ) ],
});

is_deeply(
    $obj->config_paths,
    [ './this', '/var/www/that'  ],
    "_config_paths can be modified.");


done_testing;
