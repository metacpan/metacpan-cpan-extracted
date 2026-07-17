package TestSchema::Result::NoAgingCache;
use base 'DBIx::Class::Core';

__PACKAGE__->table('no_aging_cache');
__PACKAGE__->add_columns(
    uuid     => { data_type => 'text' },
    metadata => { data_type => 'text' },
    data     => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('uuid');

1;
