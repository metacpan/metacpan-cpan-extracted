package Bio::Chado::Schema::Result::MyPlugin::Foo;
use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("myapp_foo");

__PACKAGE__->add_columns(

  "myapp_foo_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "myapp_foo_myapp_foo_id_seq",
  },

  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },

);
__PACKAGE__->set_primary_key( "myapp_foo_id" );

__PACKAGE__->belongs_to(
  "organism",
  "Bio::Chado::Schema::Result::Organism::Organism",
  { organism_id => "organism_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

Bio::Chado::Schema->plugin_add_relationship(
    'Organism::Organism' => 'has_many',
    "myplugin_foos",
    "Bio::Chado::Schema::Result::MyPlugin::Foo",
    { "foreign.organism_id" => "self.organism_id" },
    { cascade_copy => 0, cascade_delete => 0 },
  );


1;

