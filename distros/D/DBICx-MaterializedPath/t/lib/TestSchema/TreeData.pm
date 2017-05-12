package TestSchema::TreeData;
use warnings;
use strict;
use parent qw( DBIx::Class );

__PACKAGE__->load_components(qw(
                                +DBICx::MaterializedPath
                                Core
                                ));

__PACKAGE__->table("tree_data");

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 10,
  },
  "parent",
  {
    data_type => "INT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 1,
    size => 10,
  },
  "content",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "path",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "created",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
                        parent => __PACKAGE__,
                        { id => "parent" },
                        { join_type => "LEFT" },
                        );

__PACKAGE__->has_many(
                      children => __PACKAGE__,
                      { "foreign.parent" => "self.id" },
                      );

# We override only one of the defaults-
__PACKAGE__->mk_classdata( path_column => "path" ); # otherwise materialized_path

1;

__END__

