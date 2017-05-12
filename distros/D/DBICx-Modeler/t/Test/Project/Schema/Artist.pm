package t::Test::Project::Schema::Artist;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(qw/ id name insert_datetime /);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many('cds' => 't::Test::Project::Schema::Cd');

1;
