package Test::MissingTzSchema::Result::Example;

use base 'DBIx::Class::Core';

__PACKAGE__->table('example');
__PACKAGE__->load_components('InflateColumn::DateTime::WithTimeZone');

__PACKAGE__->add_columns(
    dt => { data_type => 'timestamp', timezone_source => 'tz' },
);

1;
