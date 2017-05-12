package t::Test::Project::Schema::Cd;

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('cd');
__PACKAGE__->add_columns(qw/ id artist title insert_datetime/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('artist' => 't::Test::Project::Schema::Artist');
__PACKAGE__->has_many('tracks' => 't::Test::Project::Schema::Track');

1;
