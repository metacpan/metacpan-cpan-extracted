package Test::NonNullTzSchema::Result::Tz;

use base 'DBIx::Class::Core';

__PACKAGE__->table('tz');
__PACKAGE__->load_components('InflateColumn::DateTime::WithTimeZone');

__PACKAGE__->add_columns(
    dt => {
        data_type   => 'timestamp',
        timezone    => 'America/Chicago',
        is_nullable => 1,
    },
    tz => { data_type => 'varchar', is_nullable => 0 },
);

1;
