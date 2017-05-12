package Bracket::Schema::Result::Pick;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Pick

=cut

__PACKAGE__->table("pick");

=head1 ACCESSORS

=head2 id

  data_type: INT
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 11

=head2 player

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 game

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 pick

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 11

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
  "player",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "game",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "pick",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 game

Type: belongs_to

Related object: L<Bracket::Schema::Result::Game>

=cut

__PACKAGE__->belongs_to("game", "Bracket::Schema::Result::Game", { id => "game" }, {});

=head2 pick

Type: belongs_to

Related object: L<Bracket::Schema::Result::Team>

=cut

__PACKAGE__->belongs_to("pick", "Bracket::Schema::Result::Team", { id => "pick" }, {});

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


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-15 11:45:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3y+D7eOEFq574St+fKk+zw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
