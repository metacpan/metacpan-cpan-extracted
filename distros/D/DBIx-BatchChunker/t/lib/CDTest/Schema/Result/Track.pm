use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Track;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Track

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<track>

=cut

__PACKAGE__->table("track");

=head1 ACCESSORS

=head2 trackid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 cd

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 position

  data_type: 'int'
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 last_updated_on

  data_type: 'datetime'
  is_nullable: 1

=head2 last_updated_at

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "trackid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cd",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "position",
  { data_type => "int", is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "last_updated_on",
  { data_type => "datetime", is_nullable => 1 },
  "last_updated_at",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</trackid>

=back

=cut

__PACKAGE__->set_primary_key("trackid");

=head1 UNIQUE CONSTRAINTS

=head2 C<cd_position_unique>

=over 4

=item * L</cd>

=item * L</position>

=back

=cut

__PACKAGE__->add_unique_constraint("cd_position_unique", ["cd", "position"]);

=head2 C<cd_title_unique>

=over 4

=item * L</cd>

=item * L</title>

=back

=cut

__PACKAGE__->add_unique_constraint("cd_title_unique", ["cd", "title"]);

=head1 RELATIONS

=head2 cd

Type: belongs_to

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->belongs_to(
  "cd",
  "CDTest::Schema::Result::CD",
  { cdid => "cd" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 cds

Type: has_many

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->has_many(
  "cds",
  "CDTest::Schema::Result::CD",
  { "foreign.single_track" => "self.trackid" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lyrics

Type: has_many

Related object: L<CDTest::Schema::Result::Lyric>

=cut

__PACKAGE__->has_many(
  "lyrics",
  "CDTest::Schema::Result::Lyric",
  { "foreign.track_id" => "self.trackid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JwCBbH6n7o6gp4G0597XLA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
