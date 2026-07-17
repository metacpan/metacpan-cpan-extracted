package TestSchema::Result::ContentCache;
use base 'DBIx::Class::Core';

__PACKAGE__->table('content_cache');
__PACKAGE__->add_columns(
    uuid => { data_type => 'text' },
    metadata => { data_type => 'text' },
    data => { data_type => 'text' },
    created_dt => { data_type => 'text', is_nullable => 1 },
    expiry_dt  => { data_type => 'text', is_nullable => 1 },
);
__PACKAGE__->set_primary_key('uuid');

1;
