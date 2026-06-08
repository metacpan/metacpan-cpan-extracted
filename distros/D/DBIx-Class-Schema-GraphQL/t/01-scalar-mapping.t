#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIx::Class::Schema::GraphQL;

sub fake_source {
    my ($data_type) = @_;

    return bless {
        _col_info => { data_type => $data_type }
    }, 'FakeSource';
}

{
    no warnings 'once';
    *FakeSource::column_info = sub {
        $_[0]->{_col_info}
    }
}

my $fn = \&DBIx::Class::Schema::GraphQL::_scalar_for_column;

# Boolean
for my $dt (qw( bool boolean Bool Boolean BOOLEAN tinyint(1) TINYINT(1) )) {
    is($fn->(fake_source($dt), 'col')->name, 'Boolean',
        "Boolean for data_type '$dt'");
}

# Float
for my $dt (qw( float Float FLOAT double real money decimal numeric
                DECIMAL NUMERIC )) {
    is($fn->(fake_source($dt), 'col')->name, 'Float',
       "Float for data_type '$dt'");
}

# Double precision - also Float
{
    is($fn->(fake_source('double precision'), 'col')->name, 'Float',
       "Float for 'double precision'");
}

# Int
for my $dt (qw( int integer INT INTEGER bigint smallint tinyint
                TINYINT mediumint serial )) {
    is($fn->(fake_source($dt), 'col')->name, 'Int',
       "Int for data_type '$dt'");
}

# TinyInt (no suffix) must be Int, NOT Boolean
is($fn->(fake_source('tinyint'), 'col')->name, 'Int',
   'tinyint (no suffix) maps to Int, not Boolean');

# Decimal must be Float, NOT Int
is($fn->(fake_source('decimal'), 'col')->name, 'Float',
   'decimal maps to Float, not Int');

# String fallback
for my $dt (qw( varchar text char blob date datetime timestamp json uuid )) {
    is($fn->(fake_source($dt), 'col')->name, 'String',
       "String fallback for data_type '$dt'");
}

# undef data_type also falls back to String
{
    my $source = bless { _col_info => {} }, 'FakeSource';
    is($fn->($source, 'col')->name, 'String',
       'undef data_type falls back to String');
}

done_testing;
