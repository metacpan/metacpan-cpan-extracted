package Bracket::Schema::Result::Team;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Team

=cut

__PACKAGE__->table("team");

=head1 ACCESSORS

=head2 id

  data_type: INT
  default_value: undef
  is_nullable: 0
  size: 11

=head2 seed

  data_type: TINYINT
  default_value: undef
  extra: HASH(0x249d388)
  is_nullable: 0
  size: 3

=head2 name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 32

=head2 region

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 round_out

  data_type: TINYINT
  default_value: 7
  is_nullable: 0
  size: 4

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "seed",
  {
    data_type => "TINYINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_nullable => 0,
    size => 3,
  },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "region",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "round_out",
  { data_type => "TINYINT", default_value => 7, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 games

Type: has_many

Related object: L<Bracket::Schema::Result::Game>

=cut

__PACKAGE__->has_many(
  "games",
  "Bracket::Schema::Result::Game",
  { "foreign.winner" => "self.id" },
);

=head2 picks

Type: has_many

Related object: L<Bracket::Schema::Result::Pick>

=cut

__PACKAGE__->has_many(
  "picks",
  "Bracket::Schema::Result::Pick",
  { "foreign.pick" => "self.id" },
);

=head2 region

Type: belongs_to

Related object: L<Bracket::Schema::Result::Region>

=cut

__PACKAGE__->belongs_to(
  "region",
  "Bracket::Schema::Result::Region",
  { id => "region" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-17 12:15:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uFLHHEtHCDiKQkJf0XTrNg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
