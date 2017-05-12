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

subtest "constructors" => sub {

    like(
        exception { get_client( digest => 'MD5' ) },
        qr/did not pass type constraint/,
        "client: bad digest type throws exception"
    );

    like(
        exception { get_server( digest => 'MD5' ) },
        qr/did not pass type constraint/,
        "server: bad digest type throws exception"
    );

};

subtest "bad client first message" => sub {
    my $server = get_server;

    #<<< No perltidy
    my @bad_messages = (
        '',
        'n,,',
        ',,n=user,r=salt',
        'x,,n=user,r=salt',
        'n,,user',
        'n,,=user',
        'n,,n=user',
        'n,,a=b,c=d,d=3',
        'n,,r=salt,n=user',
    );
    #>>>

    for my $bad (@bad_messages) {
        like(
            exception { $server->first_msg($bad) },
            qr/SCRAM client-first-message could not be parsed/,
            "parse error: <$bad>",
        );
    }

};

subtest "bad server first message" => sub {
    my $client = get_client( _nonce_generator => sub { "fyko+d2lbbFgONRv9qkxdawL" } );

    $client->first_msg;
    my $nonce = $client->_session->{r};

    #<<< No perltidy
    my @bad_messages = (
        '',
        ",r=${nonce}abc,i=99",
        "r=${nonce}abc,s=dlkfakdf",
        "r=${nonce}abc,s=dlkfakdf,i=",
        "r=${nonce}abc,i=1000,s=dsfadks",
    );
    #>>>

    for my $bad (@bad_messages) {
        $client->first_msg;
        like(
            exception { $client->final_msg($bad) },
            qr/SCRAM server-first-message could not be parsed/,
            "parse error: <$bad>",
        );
    }

    #<<< No perltidy
    my @bad_nonce = (
        "r=sadkasdllk,s=akdjad,i=99",
        "r=$nonce,s=akdjad,i=99",
    );
    #>>>

    for my $bad (@bad_nonce) {
        $client->first_msg;
        like(
            exception { $client->final_msg($bad) },
            qr/SCRAM server-first-message nonce invalid/,
            "nonce error: <$bad>",
        );
    }

    #<<< No perltidy
    my @bad_iters = (
        "r=${nonce}abc,s=def,i=-1000",
        "r=${nonce}abc,s=def,i=-1.00",
        "r=${nonce}abc,s=def,i=afdkj",
    );
    #>>>

    for my $bad (@bad_iters) {
        $client->first_msg;
        like(
            exception { $client->final_msg($bad) },
            qr/SCRAM iteration parameter '[^']+' invalid/,
            "iterator error: <$bad>",
        );
    }

};

subtest "unsupported features" => sub {
    my $client = get_client;
    $client->first_msg;
    like(
        exception { $client->final_msg("m=1234,r=adlskjas,s=ldkjfalfdj,i=1000") },
        qr/mandatory extension 'm=1234', but we do not support it/,
        "mandatory extension receiving server-first-message",
    );

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
