#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More;

eval " use YAML ";
plan skip_all => "YAML is not installed." if $@;
plan 'no_plan';

use MyClass;
my $obj = MyClass->new({ load_plugins => [qw/ ExtAttribute /] });

sub IS {
    is $_[0], $_[1];
}

IS $obj->call( 'args_0' );
IS $obj->call( args_1 => 'hoge' );
IS $obj->call( args_1_2 => 'hoge' );
IS $obj->call( args_2 => ['hoge1', 'hoge2'] );
IS $obj->call( args_2_2 => ['hoge1', 'hoge2'] );
IS $obj->call( args_2_3 => ['hoge1', 'hoge2'] );
IS $obj->call( args_2_4 => ['hoge1', 'hoge2'] );
IS $obj->call( args_2_5 => ['hoge1', 'hoge2'] );
IS $obj->call( args_2_6 => ['hoge1', 'hoge2'] );

IS $obj->call( ref_array_1 => [1,2,3,4] );
IS $obj->call( ref_array_2 => [1,2,3,4] );
IS $obj->call( ref_array_3 => [1,2,3,4] );
IS $obj->call( ref_array_4 => [1,2,3,4] );
IS $obj->call( ref_array_5 => [1,2,3,4] );
IS $obj->call( ref_array_6 => [1,2,3,4] );

IS $obj->call( hash_1 => [key => 'value'] );

IS $obj->call( ref_hash_1 => { key => 'value'} );
IS $obj->call( ref_hash_2 => { key => { key => 'value'} } );

IS $obj->call( ref_hash_array => { key => ['foo', 'bar', 'baz'] } );

IS $obj->call( ref_array_hash_1 => [ 'foo', { key => 'value' }, 'baz' ] );
IS $obj->call( ref_array_hash_2 => [ 'foo', { key => 'value' }, 'baz' ] );

IS $obj->call( ref_code_1 => 'code' );
IS $obj->call( ref_code_2 => '_code' );
IS $obj->call( ref_code_3 => 20 );

IS $obj->call( run_code_1 => 'code' );
IS $obj->call( run_code_2 => '_code' );
IS $obj->call( run_code_3 => 20 );
