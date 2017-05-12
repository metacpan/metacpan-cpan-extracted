package MyApp::Schema::Disabled; {
use base 'DBIx::Class';

__PACKAGE__->load_components(qw[
    Indexed
    Core
    TimeStamp
]);

__PACKAGE__->set_indexer('WebService::Dezi', { server => 'http://unknown.unknown.pl:5000', content_type => 'application/json', disabled => 1});

__PACKAGE__->table('disabled');

__PACKAGE__->add_columns(
    id => {
        data_type       => 'varchar',
        size            => '36',
        is_nullable     => 0,
    },
    name => {
        data_type       => 'varchar',
        is_nullable     => 0,
        indexed         => 1 
    },
    created => {
        data_type       => 'timestamp',
        set_on_create   => 1,
        is_nullable     => 0,
    },
);
__PACKAGE__->set_primary_key('id');

} 
1;
