use 5.008001;
use strict;
use warnings;
use utf8;

use Test::More 0.96;

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;
use BSON::OID;

subtest 'test timestamp field' => sub {
    my %test_ts_data = (
        2147483648 => "\x80" . ("\x00" x 11),
        4294967295 => ("\xFF" x 4) . ("\x00" x 8)
    );
    while ( my ($time, $test_oid) = each %test_ts_data) {
        my $oid = BSON::OID->new(oid => $test_oid);
        ok( $time == $oid->get_time );
    }
};

sub check_counter {
    my ($oid, $counter) = @_;
    my $inc = unpack( 'a3', substr( $oid->{'oid'}, 9, 3 ) );
    is($inc, substr( pack('N', $counter), 1, 3 ),
       'check the oid has the given counter' );
}

subtest 'test counter' => sub {
    ok(my $oid = BSON->create_oid);
    isa_ok($oid, 'BSON::OID');
    ok($oid->__reset_counter); # Set internal counter to 0XFFFFFE
    check_counter( BSON->create_oid, 0xFFFFFF );
    check_counter( BSON->create_oid, 0x000000 );
};

done_testing;

#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2019 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:


