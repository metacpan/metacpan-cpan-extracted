use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;

# RT#133622 / GH PR#137
# DateTime::Format::Pg and ::Oracle provide methods like:
#   format_timestamp_with_time_zone  (not format_timestamp_with_timezone)
#   parse_timestamp_without_time_zone (not parse_timestamp_without_timezone)
# Verify that DBIO generates the correct method names.

my $schema = DBIO::SQLite::Test->init_schema( dsn => 'dbi:SQLite::memory:' );

# Create a mock result source with timestamp columns to test
# the _ic_dt_method values set during register_column.
# We do this by checking the column_info after registration.

{
  package # hide from PAUSE
    DBIO::Test::Schema::TZTest;
  use base 'DBIO::Core';

  __PACKAGE__->table('tz_test');
  __PACKAGE__->load_components('InflateColumn::DateTime');

  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    ts_with_tz => { data_type => 'timestamp with time zone' },
    ts_without_tz => { data_type => 'timestamp without time zone' },
    ts_tz_short => { data_type => 'timestamptz' },
    ts_plain => { data_type => 'timestamp' },
    dt_plain => { data_type => 'datetime' },
    d_plain => { data_type => 'date' },
    ts_small => { data_type => 'smalldatetime' },
  );

  __PACKAGE__->set_primary_key('id');
}

my $rsrc = DBIO::Test::Schema::TZTest->result_source_instance;

# Check the internal _ic_dt_method values
is(
  $rsrc->column_info('ts_with_tz')->{_ic_dt_method},
  'timestamp_with_time_zone',
  'timestamp with time zone -> timestamp_with_time_zone (not timestamp_with_timezone)'
);

is(
  $rsrc->column_info('ts_without_tz')->{_ic_dt_method},
  'timestamp_without_time_zone',
  'timestamp without time zone -> timestamp_without_time_zone (not timestamp_without_timezone)'
);

is(
  $rsrc->column_info('ts_tz_short')->{_ic_dt_method},
  'timestamp_with_time_zone',
  'timestamptz -> timestamp_with_time_zone'
);

is(
  $rsrc->column_info('ts_plain')->{_ic_dt_method},
  'timestamp',
  'timestamp -> timestamp'
);

is(
  $rsrc->column_info('dt_plain')->{_ic_dt_method},
  'datetime',
  'datetime -> datetime'
);

is(
  $rsrc->column_info('d_plain')->{_ic_dt_method},
  'date',
  'date -> date'
);

is(
  $rsrc->column_info('ts_small')->{_ic_dt_method},
  'smalldatetime',
  'smalldatetime -> smalldatetime'
);

done_testing;
