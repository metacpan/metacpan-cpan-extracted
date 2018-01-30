use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings -allow_deps => 1;
use Test::Fatal;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use TestSCRAM qw/get_client/;

require_ok("Authen::SCRAM::Client");

subtest "constructors" => sub {
    my $client = get_client;
    is( $client->digest,     'SHA-1',  "default digest" );
    is( $client->username,   'user',   "username attribute" );
    is( $client->password,   'pencil', "password attribute" );
    is( $client->nonce_size, 192,      "nonce size attribute" );

    for my $d (qw/1 224 256 384 512/) {
        my $obj = get_client( username => 'user', password => 'pencil', digest => "SHA-$d" );
        is( $obj->digest, "SHA-$d", "digest set correctly to SHA-$d" );
    }

};

subtest "client first message" => sub {
    my $client = get_client;
    like(
        my $first = $client->first_msg,
        qr{^n,,n=user,r=[a-zA-Z0-9+/=]{32}$},
        "message structure"
    );
    isnt( $first, $client->first_msg, "repeat calls are different" );

    like( get_client( username => 'us,e=r' )->first_msg,
        qr{^n,,n=us=2ce=3dr}, "user name , and = encoding" );

    like(
        get_client( authorization_id => 'other,me' )->first_msg,
        qr{^n,a=other=2cme,n=user,r=.+},
        "authorization_id with encoding"
    );
};

subtest "RFC 5802 example" => sub {
    # force client nonce to match RFC5802 example
    my $client = get_client( _nonce_generator => sub { "fyko+d2lbbFgONRv9qkxdawL" } );
    my $first = $client->first_msg();
    is( $first, "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL", "client first message" )
      or diag explain $client;

    # RFC5802 example server-first-message
    my $server_first =
      "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096";
    my $final = $client->final_msg($server_first);
    is(
        $final,
        "c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts=",
        "client final message"
    ) or diag explain $client;

    ok( $client->validate("v=rmF9pqV8S7suAoZWja4dJRkFsKQ="),
        "server message validated" );

    # Repeat to check credential caching by hooking the digest method,
    # which is called to pass to 'derive'.
    {
        no warnings 'redefine';
        my $digest_called;
        my $orig = \&Authen::SCRAM::Client::digest;
        local *Authen::SCRAM::Client::digest = sub {
            $digest_called = 1;
            &$orig;
        };

        # Reuse earlier client (recall that nonce is forced constant)
        my $first = $client->first_msg();
        is( $first, "n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL", "client first message" )
          or diag explain $client;

        # RFC5802 example server-first-message
        my $server_first =
          "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096";
        my $final = $client->final_msg($server_first);
        is(
            $final,
            "c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts=",
            "client final message"
        ) or diag explain $client;

        ok( !$digest_called, "cached credentials used" );
    }

};

subtest "RFC 7677 example (SHA256)" => sub {
    # force client nonce to match RFC7677 example
    my $client = get_client(
        digest           => 'SHA-256',
        _nonce_generator => sub { "rOprNGfwEbeRWgbNEkqO" }
    );
    my $first = $client->first_msg();
    is( $first, "n,,n=user,r=rOprNGfwEbeRWgbNEkqO", "client first message" )
      or diag explain $client;

    # RFC7677 example server-first-message
    my $server_first =
      'r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,s=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096';
    my $final = $client->final_msg($server_first);
    is(
        $final,
        'c=biws,r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,p=dHzbZapWIk4jUhN+Ute9ytag9zjfMHgsqmmiz7AndVQ=',
        "client final message"
    ) or diag explain $client;

    ok( $client->validate("v=6rriTRBi23WpRR/wtup+mMhUZUn/dB5nLTJRsjl95G4="),
        "server message validated" );

};

subtest "Minimum iteration count" => sub {
    {
        # force client nonce to match RFC5802 example
        my $client = get_client( _nonce_generator => sub { "fyko+d2lbbFgONRv9qkxdawL" } );
        my $first = $client->first_msg();

        # RFC5802 example server-first-message, with too low iteration count
        my $server_first =
          "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4095";
        like(
            exception { $client->final_msg($server_first) },
            qr/requested 4095 iterations, less than/,
            "Default iteration count"
        );
    }

    {
        # force client nonce to match RFC5802 example
        my $client = get_client(
            _nonce_generator        => sub { "fyko+d2lbbFgONRv9qkxdawL" },
            minimum_iteration_count => 8192
        );
        my $first = $client->first_msg();

        # RFC5802 example server-first-message, with too low iteration count
        my $server_first =
          "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=8191";
        like(
            exception { $client->final_msg($server_first) },
            qr/requested 8191 iterations, less than/,
            "Custom iteration count"
        );
    }
};

done_testing;
#
# This file is part of Authen-SCRAM
#
# This software is Copyright (c) 2014 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: ts=4 sts=4 sw=4 et:
