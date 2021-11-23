#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;

use DNS::Unbound ();

{
    my $dns = DNS::Unbound->new();

    my $got = $dns->set_option( verbosity => 3 );

    is(
        "$got",
        "$dns",
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

    throws_ok(
        sub { $dns->get_option( 'hahaha' ) },
        qr<hahaha>,
        'set_option(): handling of unrecognized argument',
    );

    throws_ok(
        sub { $dns->set_option( hahaha => 3 ) },
        qr<hahaha>,
        'set_option(): handling of unrecognized argument',
    );

    undef $dns;
}

done_testing();
