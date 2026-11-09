use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL::ScalarMap qw(for_column);

sub fake_source {
  my ($data_type) = @_;
  return bless { _col_info => { data_type => $data_type } }, 'FakeSource';
}

{
  no warnings 'once';
  *FakeSource::column_info = sub { $_[0]->{_col_info} };
}

# Boolean
for my $dt (qw( bool boolean Bool Boolean BOOLEAN tinyint(1) TINYINT(1) )) {
  is(for_column(fake_source($dt), 'col')->name, 'Boolean',
    "Boolean for data_type '$dt'");
}

# Float
for my $dt (qw( float Float FLOAT double real )) {
  is(for_column(fake_source($dt), 'col')->name, 'Float',
    "Float for data_type '$dt'");
}

# Double precision - also Float
is(for_column(fake_source('double precision'), 'col')->name, 'Float',
  "Float for 'double precision'");

# Int
for my $dt (qw( int integer INT INTEGER smallint tinyint
                TINYINT mediumint serial )) {
  is(for_column(fake_source($dt), 'col')->name, 'Int',
    "Int for data_type '$dt'");
}

# TinyInt (no suffix) must be Int, NOT Boolean
is(for_column(fake_source('tinyint'), 'col')->name, 'Int',
  'tinyint (no suffix) maps to Int, not Boolean');

# Types wider than GraphQL's Int (32-bit) or Float (double) keep their
# exact text: String
for my $dt ((qw( bigint BIGINT bigserial decimal DECIMAL numeric NUMERIC
                money )),
              'decimal(10,2)', 'numeric(20,4)' ) {
  is(for_column(fake_source($dt), 'col')->name, 'String',
    "String for data_type '$dt', not Int or Float");
}

# String fallback
for my $dt (qw( varchar text char blob date datetime timestamp json uuid )) {
  is(for_column(fake_source($dt), 'col')->name, 'String',
    "String fallback for data_type '$dt'");
}

# undef data_type also falls back to String
{
  my $source = bless { _col_info => {} }, 'FakeSource';
  is(for_column($source, 'col')->name, 'String',
    'undef data_type falls back to String');
}

done_testing;
