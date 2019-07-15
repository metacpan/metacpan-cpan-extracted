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

use BSON qw/encode decode/;
use BSON::Types ':all';

# Undeprecated BSON type wrappers need to be API compatible with previous
# versions and with MongoDB::* equivalents. Added 'TO_JSON' for all
# wrapper classes to ensure they all serialize.

my %apis = (
    "BSON::Bool" => {
        "BSON::Bool" => [ qw/true false value op_eq TO_JSON/ ],
    },
    "BSON::Bytes" => {
        "BSON::Bytes" => [ qw/TO_JSON/ ],
        "MongoDB::BSON::Binary" => [ qw/data subtype/ ],
    },
    "BSON::Code" => {
        "BSON::Code" => [ qw/code scope length TO_JSON/ ],
        "MongoDB::Code" => [ qw/code scope/ ],
    },
    "BSON::Double" => {
        "BSON::Double" => [ qw/TO_JSON/ ],
    },
    "BSON::Int32" => {
        "BSON::Int32" => [ qw/TO_JSON/ ],
    },
    "BSON::Int64" => {
        "BSON::Int64" => [ qw/TO_JSON/ ],
    },
    "BSON::MaxKey" => {
        "BSON::MaxKey" => [ qw/TO_JSON/ ],
    },
    "BSON::MinKey" => {
        "BSON::MinKey" => [ qw/TO_JSON/ ],
    },
    "BSON::OID" => {
        "BSON::OID" => [ qw/TO_JSON/ ],
        "MongoDB::OID" => [ qw/value to_string get_time TO_JSON/ ],
    },
    "BSON::Regex" => {
        "BSON::Regex" => [ qw/TO_JSON/ ],
        "MongoDB::BSON::Regexp" => [ qw/pattern flags try_compile/ ],
    },
    "BSON::String" => {
        "BSON::String" => [ qw/value TO_JSON/ ],
    },
    "BSON::Time" => {
        "BSON::Time" => [ qw/value epoch op_eq TO_JSON/ ],
    },
    "BSON::Timestamp" => {
        "BSON::Timestamp" => [ qw/seconds increment TO_JSON/ ],
        "MongoDB::Timestamp" => [ qw/sec inc/ ],
    },
);

for my $k ( sort keys %apis ) {
    for my $t ( sort keys %{$apis{$k}} ) {
        can_ok( $k, @{$apis{$k}{$t}} );
    }
}

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

