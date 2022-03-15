#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use Test::Deep;

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
        'DNS::Unbound::X::Unbound',
        'set_option(): handling of unrecognized argument',
    );

    my $err = $@;

    cmp_deeply(
        $err,
        methods(
            get_message => re( qr<hahaha> ),
        ),
        'error message',
    );

    throws_ok(
        sub { $dns->set_option( hahaha => 3 ) },
        'DNS::Unbound::X::Unbound',
        'set_option(): handling of unrecognized argument',
    ) or diag explain $@;

    $err = $@;

    cmp_deeply(
        $err,
        methods(
            get_message => re( qr<hahaha> ),
        ),
        'error message',
    );

    undef $dns;
}

done_testing();
