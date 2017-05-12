package Test::Schema::Result::Example;

use base 'DBIx::Class::Core';

__PACKAGE__->table('examples');
__PACKAGE__->load_components(qw/ InflateColumn::DateTimeX::Immutable /);

__PACKAGE__->add_columns(
    'id' => { data_type => 'integer', },
    'dt' => { data_type => 'datetime' },
);

__PACKAGE__->set_primary_key('id');

1;
