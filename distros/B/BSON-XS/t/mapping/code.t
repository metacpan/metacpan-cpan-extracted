use 5.008001;
use strict;
use warnings;
use utf8;

use Test::More 0.96;
use Test::Deep '!blessed';

binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;
use TestUtils;

use BSON qw/encode decode/;
use BSON::Types ':all';

my ($bson, $expect, $hash);

my $code = 'alert("Hello World");';
my $scope = { x => 1 };

# test constructor
is( bson_code()->code,         '',       "empty bson_code()" );
is( bson_code()->scope,          undef,       "empty bson_code()" );
is( bson_code($code)->code, $code, "bson_code(code)->code" );
is( bson_code($code)->scope  , undef,       "bson_code(code)->scope" );
is( bson_code( $code, $scope )->code, $code, "bson_code(code, scope)->code" );
is( bson_code( $code, $scope )->scope  , $scope, "bson_code(code, scope)->scope" );

is( BSON::Code->new()->code, '', "empty BSON::Code->new()" );
is( BSON::Code->new()->scope,   undef, "empty BSON::Code->new()" );
is( BSON::Code->new( code => $code )->code, $code, "BSON::Code->new(code)->code" );
is( BSON::Code->new( code => $code )->scope, undef, "BSON::Code->new(code)->scope" );
is( BSON::Code->new( code => $code, scope => $scope )->code, $code, "BSON::Code->new(code, scope)->code" );
is( BSON::Code->new( code => $code, scope => $scope )->scope  , $scope, "BSON::Code->new(code, scope)->scope" );

subtest "BSON type CODE" => sub { 
    $bson = $expect = encode( { A => bson_code($code) } );
    $hash = decode( $bson );
    is( ref( $hash->{A} ), 'BSON::Code', "BSON::Code->BSON::Code" );
    is( $hash->{A}->code, $code, "code correct" );
    cmp_deeply( $hash->{A}->scope, undef, "scope correct" );

    # MongoDB::Code (deprecated) -> BSON::Code
    SKIP: {
        $ENV{PERL_MONGO_NO_DEP_WARNINGS} = 1;
        eval { require MongoDB::Code };
        skip( "MongoDB::Code not installed", 2 )
        unless $INC{'MongoDB/Code.pm'};
        $bson = encode( { A => MongoDB::Code->new( code => $code ) } );
        $hash = decode( $bson  );
        is( ref( $hash->{A} ), 'BSON::Code', "MongoDB::Code->BSON::Code" );
        is( $hash->{A}->code, $code, "code correct" );
        cmp_deeply( $hash->{A}->scope, undef, "scope correct" );
        is( $bson, $expect, "BSON correct" );
    }
};

subtest "BSON type CODEWSCOPE" => sub { 
    $bson = $expect = encode( { A => bson_code($code, $scope) } );
    $hash = decode( $bson );
    is( ref( $hash->{A} ), 'BSON::Code', "BSON::Code->BSON::Code" );
    is( $hash->{A}->code, $code, "code correct" );
    cmp_deeply( $hash->{A}->scope, $scope, "scope correct" );

    # CODEWSCOPE: BSON::Code -> BSON::Code

    # MongoDB::Code (deprecated) -> BSON::Code
    SKIP: {
        $ENV{PERL_MONGO_NO_DEP_WARNINGS} = 1;
        eval { require MongoDB::Code };
        skip( "MongoDB::Code not installed", 2 )
        unless $INC{'MongoDB/Code.pm'};
        $bson = encode( { A => MongoDB::Code->new( code => $code, scope => $scope ) } );
        $hash = decode( $bson  );
        is( ref( $hash->{A} ), 'BSON::Code', "MongoDB::Code->BSON::Code" );
        is( $hash->{A}->code, $code, "code correct" );
        cmp_deeply( $hash->{A}->scope, $scope, "scope correct" );
        is( $bson, $expect, "BSON correct" );
    }
};

# to JSON
eval { to_myjson({a=>bson_code()}) };
like( $@, qr/illegal in JSON/, 'json throws: bson_code()' );

# to extended JSON
(my $code_json = $code) =~ s{"}{\\"}g;
my $scope_json = to_extjson({%$scope});
is( to_extjson({a=>bson_code($code)}), qq[{"a":{"\$code":"$code_json"}}], 'extjson: bson_code(<code>)' );
is(
    to_extjson( { a => bson_code( $code, $scope ) } ),
    qq[{"a":{"\$code":"$code_json","\$scope":$scope_json}}],
    'extjson: bson_code(<code>,<scope>)'
);

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
