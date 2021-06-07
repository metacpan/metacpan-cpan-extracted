use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::CD;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::CD

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cd>

=cut

__PACKAGE__->table("cd");

=head1 ACCESSORS

=head2 cdid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 artist

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 year

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 genreid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 prev_cdid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cdid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "artist",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "year",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "genreid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "prev_cdid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cdid>

=back

=cut

__PACKAGE__->set_primary_key("cdid");

=head1 UNIQUE CONSTRAINTS

=head2 C<artist_title_unique>

=over 4

=item * L</artist>

=item * L</title>

=back

=cut

__PACKAGE__->add_unique_constraint("artist_title_unique", ["artist", "title"]);

=head1 RELATIONS

=head2 artist

Type: belongs_to

Related object: L<CDTest::Schema::Result::Artist>

=cut

__PACKAGE__->belongs_to(
  "artist",
  "CDTest::Schema::Result::Artist",
  { artistid => "artist" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 cd_artwork

Type: might_have

Related object: L<CDTest::Schema::Result::CDArtwork>

=cut

__PACKAGE__->might_have(
  "cd_artwork",
  "CDTest::Schema::Result::CDArtwork",
  { "foreign.cd_id" => "self.cdid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cd_to_producers

Type: has_many

Related object: L<CDTest::Schema::Result::CDToProducer>

=cut

__PACKAGE__->has_many(
  "cd_to_producers",
  "CDTest::Schema::Result::CDToProducer",
  { "foreign.cd" => "self.cdid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genreid

Type: belongs_to

Related object: L<CDTest::Schema::Result::Genre>

=cut

__PACKAGE__->belongs_to(
  "genreid",
  "CDTest::Schema::Result::Genre",
  { genreid => "genreid" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 prev_cd

Type: belongs_to

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->belongs_to(
  "prev_cd",
  "CDTest::Schema::Result::CD",
  { prev_cdid => "cd" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 liner_note

Type: might_have

Related object: L<CDTest::Schema::Result::LinerNote>

=cut

__PACKAGE__->might_have(
  "liner_note",
  "CDTest::Schema::Result::LinerNote",
  { "foreign.liner_id" => "self.cdid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tags

Type: has_many

Related object: L<CDTest::Schema::Result::Tag>

=cut

__PACKAGE__->has_many(
  "tags",
  "CDTest::Schema::Result::Tag",
  { "foreign.cd" => "self.cdid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tracks

Type: has_many

Related object: L<CDTest::Schema::Result::Track>

=cut

__PACKAGE__->has_many(
  "tracks",
  "CDTest::Schema::Result::Track",
  { "foreign.cd" => "self.cdid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r+u4NXXBsMauFoURBiMYpw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
