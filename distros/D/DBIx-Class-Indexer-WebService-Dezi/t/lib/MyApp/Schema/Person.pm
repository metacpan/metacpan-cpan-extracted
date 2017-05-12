package MyApp::Schema::Person; {
use base 'DBIx::Class';

__PACKAGE__->load_components(qw[
    Indexed
    PK::Auto
    Core
    TimeStamp
]);

__PACKAGE__->set_indexer('WebService::Dezi', { server => 'http://localhost:5000', content_type => 'application/json' });

__PACKAGE__->table('person');

__PACKAGE__->add_columns(
    person_id => {
        data_type       => 'varchar',
        size            => '36',
        is_nullable     => 0,
    },
    name => {
        data_type       => 'varchar',
        is_nullable     => 0,
        indexed         => 1 
    },
    age => {
        data_type       => 'integer',
        is_nullable     => 0,
    },
    image_path => {
        data_type       => 'varchar',
        size            => '128',
        indexed         => { is_binary => 1, base64_encode => 1 }
    },
    email => {
        data_type       => 'varchar',
        size            => '128',
    },
    created => {
        data_type       => 'timestamp',
        set_on_create   => 1,
        is_nullable     => 0,
    },
);
__PACKAGE__->set_primary_key('person_id');

} 
1;
