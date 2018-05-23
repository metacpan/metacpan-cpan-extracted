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

my $oid = BSON->create_oid;
isa_ok($oid, 'BSON::OID');
is($oid->_get_pid, $$ & 0xffff, "OID PID is our PID & 0xffff");

done_testing;

#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2018 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:


