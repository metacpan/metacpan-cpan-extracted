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
use TestUtils;

use BSON;
use BSON::Types ':all';

my $c = BSON->new;

my $from_array = $c->encode_one( [ a => 23 ] );
my $from_hash = $c->encode_one( { a => 23 } );

bytes_are( $from_array, $from_hash, "encode_one( [...] )" );

done_testing;

#
# This file is part of BSON
#
# This software is Copyright (c) 2019 by Stefan G. and MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
#
# vim: set ts=4 sts=4 sw=4 et tw=75:

