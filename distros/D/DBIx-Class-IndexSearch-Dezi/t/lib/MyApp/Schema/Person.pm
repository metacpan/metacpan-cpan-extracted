package MyApp::Schema::Person; {
use base 'DBIx::Class';

__PACKAGE__->load_components(qw[
    IndexSearch::Dezi
    PK::Auto
    Core
    TimeStamp
]);

__PACKAGE__->table('person');

__PACKAGE__->add_columns(
    person_id => {
        data_type       => 'varchar',
        size            => '36',
        is_nullable     => 0,
    },
    name => {
        data_type => 'varchar',
        is_nullable => 0,
        indexed => 1 
    },
    age => {
        data_type => 'integer',
        is_nullable => 0,
    },
    email => {
        data_type => 'varchar',
        size=>'128',
    },
    created => {
        data_type => 'timestamp',
        set_on_create => 1,
        is_nullable => 0,
    },
);

__PACKAGE__->resultset_class('DBIx::Class::IndexSearch::ResultSet::Dezi');
__PACKAGE__->belongs_to_index('FooClient', { server => 'http://localhost:6000', map_to => 'person_id' });


} 
1;
