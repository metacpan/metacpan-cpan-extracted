use strict;
use warnings;

use Test::More;
use DBIO::Test::Schema;

# Load EventSmallDT via the demand-load path (same as dbio-sybase/t/30-datetime-sybase.t)
DBIO::Test::Schema->load_classes('EventSmallDT');

# Load ComputedColumn via require + register_class (same as dbio-sybase/t/10-sybase.t)
require DBIO::Test::Schema::ComputedColumn;
DBIO::Test::Schema->register_class(
  ComputedColumn => 'DBIO::Test::Schema::ComputedColumn'
);

# ---- EventSmallDT ----

my $esdt_source = DBIO::Test::Schema->source('EventSmallDT');
ok $esdt_source, 'EventSmallDT source is registered';

is $esdt_source->from, 'event_small_dt', 'EventSmallDT table name is event_small_dt';

my @esdt_cols = $esdt_source->columns;
ok((grep { $_ eq 'id' }       @esdt_cols), 'EventSmallDT has column id');
ok((grep { $_ eq 'small_dt' } @esdt_cols), 'EventSmallDT has column small_dt');

my $esdt_info = $esdt_source->columns_info;

is $esdt_info->{id}{data_type},          'integer', 'EventSmallDT id data_type is integer';
ok $esdt_info->{id}{is_auto_increment},             'EventSmallDT id is_auto_increment';

is $esdt_info->{small_dt}{data_type},    'smalldatetime', 'EventSmallDT small_dt data_type is smalldatetime';
ok $esdt_info->{small_dt}{datetime_undef_if_invalid}, 'EventSmallDT small_dt datetime_undef_if_invalid set';

my @esdt_pk = $esdt_source->primary_columns;
is_deeply \@esdt_pk, ['id'], 'EventSmallDT primary key is id';

# ---- ComputedColumn ----

my $cc_source = DBIO::Test::Schema->source('ComputedColumn');
ok $cc_source, 'ComputedColumn source is registered';

is $cc_source->from, 'computed_column_test', 'ComputedColumn table name is computed_column_test';

my @cc_cols = $cc_source->columns;
ok((grep { $_ eq 'id' }                @cc_cols), 'ComputedColumn has column id');
ok((grep { $_ eq 'a_computed_column' } @cc_cols), 'ComputedColumn has column a_computed_column');
ok((grep { $_ eq 'a_timestamp' }       @cc_cols), 'ComputedColumn has column a_timestamp');
ok((grep { $_ eq 'charfield' }         @cc_cols), 'ComputedColumn has column charfield');

my $cc_info = $cc_source->columns_info;

is $cc_info->{id}{data_type},          'integer', 'ComputedColumn id data_type is integer';
ok $cc_info->{id}{is_auto_increment},             'ComputedColumn id is_auto_increment';

ok !defined($cc_info->{a_computed_column}{data_type}),  'ComputedColumn a_computed_column data_type is undef';
is $cc_info->{a_computed_column}{is_nullable}, 0,       'ComputedColumn a_computed_column is_nullable is 0';
is ref($cc_info->{a_computed_column}{default_value}), 'SCALAR',
  'ComputedColumn a_computed_column default_value is a scalar ref';
is ${ $cc_info->{a_computed_column}{default_value} }, 'getdate()',
  'ComputedColumn a_computed_column default_value is getdate()';

is $cc_info->{a_timestamp}{data_type},   'timestamp', 'ComputedColumn a_timestamp data_type is timestamp';
is $cc_info->{a_timestamp}{is_nullable}, 0,           'ComputedColumn a_timestamp is_nullable is 0';

is $cc_info->{charfield}{data_type},     'varchar',   'ComputedColumn charfield data_type is varchar';
is $cc_info->{charfield}{size},          20,          'ComputedColumn charfield size is 20';
is $cc_info->{charfield}{default_value}, 'foo',       'ComputedColumn charfield default_value is foo';
is $cc_info->{charfield}{is_nullable},   0,           'ComputedColumn charfield is_nullable is 0';

my @cc_pk = $cc_source->primary_columns;
is_deeply \@cc_pk, ['id'], 'ComputedColumn primary key is id';

done_testing;
