use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Artist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Artist

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<artist>

=cut

__PACKAGE__->table("artist");

=head1 ACCESSORS

=head2 artistid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 rank

  data_type: 'integer'
  default_value: 13
  is_nullable: 0

=head2 charfield

  data_type: 'char'
  is_nullable: 1
  size: 10

=cut

__PACKAGE__->add_columns(
  "artistid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "rank",
  { data_type => "integer", default_value => 13, is_nullable => 0 },
  "charfield",
  { data_type => "char", is_nullable => 1, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</artistid>

=back

=cut

__PACKAGE__->set_primary_key("artistid");

=head1 UNIQUE CONSTRAINTS

=head2 C<charfield_rank_unique>

=over 4

=item * L</charfield>

=item * L</rank>

=back

=cut

__PACKAGE__->add_unique_constraint("charfield_rank_unique", ["charfield", "rank"]);

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 artwork_to_artists

Type: has_many

Related object: L<CDTest::Schema::Result::ArtworkToArtist>

=cut

__PACKAGE__->has_many(
  "artwork_to_artists",
  "CDTest::Schema::Result::ArtworkToArtist",
  { "foreign.artist_id" => "self.artistid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cds

Type: has_many

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->has_many(
  "cds",
  "CDTest::Schema::Result::CD",
  { "foreign.artist" => "self.artistid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 artwork_cds

Type: many_to_many

Composing rels: L</artwork_to_artists> -> artwork_cd

=cut

__PACKAGE__->many_to_many("artwork_cds", "artwork_to_artists", "artwork_cd");


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/QXsqYUpe46E+nYOtOagAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
