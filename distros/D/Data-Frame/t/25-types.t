#!perl

use Data::Frame::Setup;

use Test2::V0;

use Data::Frame::Types qw(:all);

isa_ok( DataFrame, ['Type::Tiny'], 'DataFrame type' );

isa_ok( DataType, ['Type::Tiny'], 'DataType type' );
ok( DataType->validate( { "date" => 'datetime' } ) );

done_testing;
