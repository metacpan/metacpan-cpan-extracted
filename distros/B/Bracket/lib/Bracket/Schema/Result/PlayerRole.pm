package Bracket::Schema::Result::PlayerRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::PlayerRole

=cut

__PACKAGE__->table("player_role");

=head1 ACCESSORS

=head2 player

  data_type: INT
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 role

  data_type: INT
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=cut

__PACKAGE__->add_columns(
  "player",
  {
    data_type => "INT",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "role",
  {
    data_type => "INT",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
);
__PACKAGE__->set_primary_key("player", "role");

=head1 RELATIONS

=head2 player

Type: belongs_to

Related object: L<Bracket::Schema::Result::Player>

=cut

__PACKAGE__->belongs_to(
  "player",
  "Bracket::Schema::Result::Player",
  { id => "player" },
  {},
);

=head2 role

Type: belongs_to

Related object: L<Bracket::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to("role", "Bracket::Schema::Result::Role", { id => "role" }, {});


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-02 09:36:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0lzcb/vzXr+kUZ0fJmnWkQ


# You can replace this text with custom content, and it will be preserved on regeneration

1;
