use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings -allow_deps => 1;
use Test::Fatal;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use TestSCRAM qw/get_client get_server/;

subtest "RFC 5802 example" => sub {
    my $client = get_client( _nonce_generator => sub { "fyko+d2lbbFgONRv9qkxdawL" } );
    my $server = get_server;

    my ( $c1, $c2, $s1, $s2 );

    is( exception { $c1 = $client->first_msg() },    undef, "client first message" );
    is( exception { $s1 = $server->first_msg($c1) }, undef, "server first message" );
    is( exception { $c2 = $client->final_msg($s1) }, undef, "client final message" );
    is( exception { $s2 = $server->final_msg($c2) }, undef, "server final message" );
    is( exception { $client->validate($s2) }, undef, "client validation" );
    is( $server->authorization_id, 'user', "server authz" );
};

subtest "generated example" => sub {
    my $client = get_client( username => 'johndoe', password => 'passPASSpass' );
    my $server = get_server;

    my ( $c1, $c2, $s1, $s2 );

    is( exception { $c1 = $client->first_msg() },    undef, "client first message" );
    is( exception { $s1 = $server->first_msg($c1) }, undef, "server first message" );
    is( exception { $c2 = $client->final_msg($s1) }, undef, "client final message" );
    is( exception { $s2 = $server->final_msg($c2) }, undef, "server final message" );
    is( exception { $client->validate($s2) }, undef, "client validation" );
    is( $server->authorization_id, 'johndoe', "server authz" );
};

subtest "generated example with authz" => sub {
    my $client = get_client(
        username         => 'johndoe',
        password         => 'passPASSpass',
        authorization_id => 'admin'
    );
    my $server = get_server;

    my ( $c1, $c2, $s1, $s2 );

    is( exception { $c1 = $client->first_msg() },    undef, "client first message" );
    is( exception { $s1 = $server->first_msg($c1) }, undef, "server first message" );
    is( exception { $c2 = $client->final_msg($s1) }, undef, "client final message" );
    is( exception { $s2 = $server->final_msg($c2) }, undef, "server final message" );
    is( exception { $client->validate($s2) }, undef, "client validation" );
    is( $server->authorization_id, 'admin', "server authz" );
};

subtest "generated example with Unicode user/pass/authz" => sub {
    my $client = get_client(
        username         => "johnd\N{U+110B}oe",
        password         => "pass\N{U+110B}PASSpass",
        authorization_id => "admi\N{U+110B}n"
    );
    my $server = get_server;

    my ( $c1, $c2, $s1, $s2 );

    is( exception { $c1 = $client->first_msg() },    undef, "client first message" );
    is( exception { $s1 = $server->first_msg($c1) }, undef, "server first message" );
    is( exception { $c2 = $client->final_msg($s1) }, undef, "client final message" );
    is( exception { $s2 = $server->final_msg($c2) }, undef, "server final message" );
    is( exception { $client->validate($s2) }, undef, "client validation" );
    is( $server->authorization_id, "admi\N{U+110B}n", "server authz" );
};

subtest "generated example with bad user" => sub {
    my $client = get_client(
        username => 'janedoe',
        password => 'password',
    );
    my $server = get_server;

    my ( $c1, $c2, $s1, $s2 );

    is( exception { $c1 = $client->first_msg() }, undef, "client first message" );
    like(
        exception { $s1 = $server->first_msg($c1) },
        qr/unknown user 'janedoe'/,
        "auth fails for unknown user"
    );

    is( $server->authorization_id, '', "server authz empty after error" );
};

subtest "generated example with bad password" => sub {
    my $client = get_client(
        username => 'johndoe',
        password => 'not the right one',
    );
    my $server = get_server;

    my ( $c1, $c2, $s1, $s2 );

    is( exception { $c1 = $client->first_msg() },    undef, "client first message" );
    is( exception { $s1 = $server->first_msg($c1) }, undef, "server first message" );
    is( exception { $c2 = $client->final_msg($s1) }, undef, "client final message" );

    like(
        exception { $s2 = $server->final_msg($c2) },
        qr/authentication for user 'johndoe' failed/,
        "auth fails for bad password"
    );

    is( $server->authorization_id, '', "server authz empty after error" );
};

subtest "generated example with failed authz" => sub {
    my $client = get_client(
        username         => 'johndoe',
        password         => 'passPASSpass',
        authorization_id => 'johnmac'
    );
    my $server = get_server;

    my ( $c1, $c2, $s1, $s2 );

    is( exception { $c1 = $client->first_msg() },    undef, "client first message" );
    is( exception { $s1 = $server->first_msg($c1) }, undef, "server first message" );
    is( exception { $c2 = $client->final_msg($s1) }, undef, "client final message" );

    like(
        exception { $s2 = $server->final_msg($c2) },
        qr/not authorized to act as/,
        "proxy auth not allowed"
    );

    is( $server->authorization_id, '', "server authz empty after error" );
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
