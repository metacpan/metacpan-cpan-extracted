package Bracket::Schema::Result::RegionScore;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::RegionScore

=cut

__PACKAGE__->table("region_score");

=head1 ACCESSORS

=head2 player

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 region

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 points

  data_type: INT
  default_value: undef
  is_nullable: 0
  size: 11

=cut

__PACKAGE__->add_columns(
  "player",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "region",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "points",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("player", "region");

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


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-15 11:45:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UiBOetVBSxDOkCf4HJpl2g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
