use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Lyric;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Lyric

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<lyrics>

=cut

__PACKAGE__->table("lyrics");

=head1 ACCESSORS

=head2 lyric_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 track_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "lyric_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "track_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</lyric_id>

=back

=cut

__PACKAGE__->set_primary_key("lyric_id");

=head1 RELATIONS

=head2 lyric_versions

Type: has_many

Related object: L<CDTest::Schema::Result::LyricVersion>

=cut

__PACKAGE__->has_many(
  "lyric_versions",
  "CDTest::Schema::Result::LyricVersion",
  { "foreign.lyric_id" => "self.lyric_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 track

Type: belongs_to

Related object: L<CDTest::Schema::Result::Track>

=cut

__PACKAGE__->belongs_to(
  "track",
  "CDTest::Schema::Result::Track",
  { trackid => "track_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YMxJoGMTZ+sg2JL3BfkuzQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
