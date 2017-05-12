package Test::NonUtcSchema::Result::Tz;

use base 'DBIx::Class::Core';

__PACKAGE__->table('tz');
__PACKAGE__->load_components('InflateColumn::DateTime::WithTimeZone');

__PACKAGE__->add_columns(
    dt_oth => {
        data_type       => 'timestamp',
        timezone_source => 'tz_oth',
        timezone        => 'America/Chicago',
    },
    tz_oth => { data_type => 'varchar' },
);

1;
