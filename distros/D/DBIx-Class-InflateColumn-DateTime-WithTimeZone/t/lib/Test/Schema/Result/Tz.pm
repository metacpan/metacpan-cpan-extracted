package Test::Schema::Result::Tz;

use base 'DBIx::Class::Core';

__PACKAGE__->table('tz');
__PACKAGE__->load_components('InflateColumn::DateTime::WithTimeZone');

__PACKAGE__->add_columns(
    id      => { data_type => 'integer' },
    dt      => { data_type => 'timestamp', timezone_source => 'tz' },
    tz      => { data_type => 'varchar' },
    tz_utc  => { data_type => 'varchar' },
    dt_utc  => { data_type => 'timestamp', timezone_source => 'tz_utc', timezone => 'UTC' },
    dt_null => { data_type => 'timestamp', timezone_source => 'tz_null', is_nullable => 1 },
    tz_null => { data_type => 'varchar', is_nullable => 1 },
);

# need primary key so discard_changes works
__PACKAGE__->set_primary_key('id');

1;
