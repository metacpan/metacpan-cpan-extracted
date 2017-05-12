package t::Test::Project::Schema::Track;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('track');
__PACKAGE__->add_columns(qw/ id cd title/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('cd' => 't::Test::Project::Schema::Cd');

1;
