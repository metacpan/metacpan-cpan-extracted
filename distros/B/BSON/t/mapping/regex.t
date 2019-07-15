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

my ($bson, $expect, $hash);

my $pattern = '\w\d+';
my $flags = 'mix';
my $sorted_flags = 'imx';
my $qr = qr/\w\d+/xim;

# test constructor
is( bson_regex()->pattern,         '',       "empty bson_regex()" );
is( bson_regex()->flags,           '',       "empty bson_regex()" );
is( bson_regex($pattern)->pattern, $pattern, "bson_regex(PATTERN)->pattern" );
is( bson_regex($pattern)->flags  , '',       "bson_regex(PATTERN)->flags" );
is( bson_regex( $pattern, $flags )->pattern, $pattern, "bson_regex(PATTERN, FLAGS)->pattern" );
is( bson_regex( $pattern, $flags )->flags  , $sorted_flags, "bson_regex(PATTERN, FLAGS)->flags" );

is( BSON::Regex->new()->pattern, '', "empty BSON::Regex->new()" );
is( BSON::Regex->new()->flags,   '', "empty BSON::Regex->new()" );
is( BSON::Regex->new( pattern => $pattern )->pattern, $pattern, "BSON::Regex->new(PATTERN)->pattern" );
is( BSON::Regex->new( pattern => $pattern )->flags, '', "BSON::Regex->new(PATTERN)->flags" );
is( BSON::Regex->new( pattern => $pattern, flags => $flags )->pattern, $pattern, "BSON::Regex->new(PATTERN, FLAGS)->pattern" );
is( BSON::Regex->new( pattern => $pattern, flags => $flags )->flags  , $sorted_flags, "BSON::Regex->new(PATTERN, FLAGS)->flags" );

# BSON::Regex -> BSON::Regex
$bson = $expect = encode( { A => bson_regex($pattern, $flags) } );
$hash = decode( $bson );
is( ref( $hash->{A} ), 'BSON::Regex', "BSON::Regex->BSON::Regex" );
is( $hash->{A}->pattern, $pattern, "pattern correct" );
is( $hash->{A}->flags, $sorted_flags, "flags correct" );

# qr// -> BSON::Regex
$bson = encode( { A => $qr } );
$hash = decode( $bson );
is( ref( $hash->{A} ), 'BSON::Regex', "qr//->BSON::Regex" );
is( $hash->{A}->pattern, $pattern, "pattern correct" );
is( $hash->{A}->flags, $sorted_flags, "flags correct" );
is( $bson, $expect, "BSON correct" );

# MongoDB::BSON::Regexp (deprecated) -> BSON::Regex
SKIP: {
    $ENV{PERL_MONGO_NO_DEP_WARNINGS} = 1;
    eval { require MongoDB::BSON::Regexp };
    skip( "MongoDB::BSON::Regexp not installed", 2 )
      unless $INC{'MongoDB/BSON/Regexp.pm'};
    $bson = encode( { A => MongoDB::BSON::Regexp->new( pattern => $pattern, flags => $flags ) } );
    $hash = decode( $bson  );
    is( ref( $hash->{A} ), 'BSON::Regex', "MongoDB::BSON::Regexp->BSON::Regex" );
    is( $hash->{A}->pattern, $pattern, "pattern correct" );
    is( $hash->{A}->flags, $sorted_flags, "flags correct" );
    is( $bson, $expect, "BSON correct" );
}

# to JSON
eval { to_myjson({a=>bson_regex()}) };
like( $@, qr/illegal in JSON/, 'json throws: bson_regex()' );

# to extended JSON
(my $pattern_json = $pattern) =~ s{\\}{\\\\}g;
is(
    to_extjson( { a => bson_regex( $pattern, $flags ) } ),
    qq[{"a":{"\$regularExpression":{"pattern":"$pattern_json","options":"$sorted_flags"}}}],
    'extjson: bson_regex(<pattern>,<flags>)'
);

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
