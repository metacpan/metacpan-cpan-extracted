package Schema::RBAC::Result::Typeobj;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components;

=head1 NAME

Schema::RBAC::Result::Typeobj

=cut

__PACKAGE__->table("typeobj");


=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: undef

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0 },
  "active",
  { data_type => "integer", default => 1, is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

1;
