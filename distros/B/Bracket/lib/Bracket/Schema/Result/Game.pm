package Bracket::Schema::Result::Game;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Game

=cut

__PACKAGE__->table("game");

=head1 ACCESSORS

=head2 id

  data_type: INT
  default_value: undef
  is_nullable: 0
  size: 11

=head2 winner

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: 11

=head2 round

  data_type: TINYINT
  default_value: 1
  is_nullable: 0
  size: 4

=head2 lower_seed

  data_type: TINYINT
  default_value: 0
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "winner",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => 11,
  },
  "round",
  { data_type => "TINYINT", default_value => 1, is_nullable => 0, size => 4 },
  "lower_seed",
  { data_type => "TINYINT", default_value => 0, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 winner

Type: belongs_to

Related object: L<Bracket::Schema::Result::Team>

=cut

__PACKAGE__->belongs_to(
  "winner",
  "Bracket::Schema::Result::Team",
  { id => "winner" },
  { join_type => "LEFT" },
);

=head2 picks

Type: has_many

Related object: L<Bracket::Schema::Result::Pick>

=cut

__PACKAGE__->has_many(
  "picks",
  "Bracket::Schema::Result::Pick",
  { "foreign.game" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-07 15:22:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kdG47fAPyic/y4+PvlM5SQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
