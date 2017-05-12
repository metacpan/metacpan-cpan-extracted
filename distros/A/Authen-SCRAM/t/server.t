use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings -allow_deps => 1;
use Test::Fatal;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use TestSCRAM qw/get_server/;

require_ok("Authen::SCRAM::Server");

subtest "constructors" => sub {
    my $server = get_server;
    is( $server->digest,     'SHA-1', "default digest" );
    is( $server->nonce_size, 192,     "nonce size attribute" );

    for my $d (qw/1 224 256 384 512/) {
        my $obj = get_server( digest => "SHA-$d" );
        is( $obj->digest, "SHA-$d", "digest set correctly to SHA-$d" );
    }
};

subtest "RFC 5802 example" => sub {
    # force server nonce to match RFC5802 example
    my $server = get_server( _nonce_generator => sub { "3rfcNHYJY1ZVvWVs7j" } );
    my $result = $server->first_msg("n,,n=user,r=fyko+d2lbbFgONRv9qkxdawL");
    is(
        $result,
        "r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,s=QSXCR+Q6sek8bf92,i=4096",
        "RFC 5802 example server first message",
    );

    my $final = $server->final_msg(
        "c=biws,r=fyko+d2lbbFgONRv9qkxdawL3rfcNHYJY1ZVvWVs7j,p=v0X8v3Bz2T0CJGbJQyF0X+HI4Ts="
    );
    is(
        $final,
        "v=rmF9pqV8S7suAoZWja4dJRkFsKQ=",
        "RFC 5802 example server final message",
    );

    is( $server->authorization_id, 'user',
        "RFC 5802 example user authentication successful" );

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
