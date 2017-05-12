package Bracket::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Role

=cut

__PACKAGE__->table("role");

=head1 ACCESSORS

=head2 id

  data_type: INT
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 11

=head2 role

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
  "role",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("role_name_UNIQ", ["role"]);

=head1 RELATIONS

=head2 player_roles

Type: has_many

Related object: L<Bracket::Schema::Result::PlayerRole>

=cut

__PACKAGE__->has_many(
  "player_roles",
  "Bracket::Schema::Result::PlayerRole",
  { "foreign.role" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-17 12:15:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wtNPV2NOLB6IEKVJm0rsTw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
