package Test::NonDateTimeSchema::Result::Example;

use base 'DBIx::Class::Core';

__PACKAGE__->table('example');
__PACKAGE__->load_components('InflateColumn::DateTime::WithTimeZone');

__PACKAGE__->add_columns(
    not_a_time => { data_type => 'varchar', timezone_source => 'tz' },
    tz         => { data_type => 'varchar' },
);

1;
