package Bracket::Schema::Result::Region;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Region

=cut

__PACKAGE__->table("region");

=head1 ACCESSORS

=head2 id

  data_type: INT
  default_value: undef
  is_nullable: 0
  size: 11

=head2 name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 region_scores

Type: has_many

Related object: L<Bracket::Schema::Result::RegionScore>

=cut

__PACKAGE__->has_many(
  "region_scores",
  "Bracket::Schema::Result::RegionScore",
  { "foreign.region" => "self.id" },
);

=head2 teams

Type: has_many

Related object: L<Bracket::Schema::Result::Team>

=cut

__PACKAGE__->has_many(
  "teams",
  "Bracket::Schema::Result::Team",
  { "foreign.region" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-02 09:36:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZvJypnGpz1chQKLdGt/Gyg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
