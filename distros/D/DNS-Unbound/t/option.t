#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use DNS::Unbound ();

my $dns = DNS::Unbound->new();

is(
    $dns->set_option( verbosity => 3 ),
    $dns,
    'set_option() returns the object',
);

is(
    $dns->get_option('verbosity'),
    3,
    '… and get_option() returns what was just set',
);

$dns->set_option( verbosity => 2 );

is(
    $dns->get_option('verbosity'),
    2,
    '… and it wasn’t just a default setting',
);

done_testing();
