package MyApp::SchemaVanilla::Result::Artist;

use warnings;
use strict;

use base qw(DBIO::Core);

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  artistid => {
    data_type         => 'integer',
    is_auto_increment => 1,
  },
  name => {
    data_type => 'text',
  },
);

__PACKAGE__->set_primary_key('artistid');

__PACKAGE__->add_unique_constraint([qw(name)]);

__PACKAGE__->has_many('cds' => 'MyApp::SchemaVanilla::Result::Cd', 'artistid');

1;
