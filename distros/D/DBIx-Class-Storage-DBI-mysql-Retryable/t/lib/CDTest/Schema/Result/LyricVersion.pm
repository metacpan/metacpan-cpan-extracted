use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::LyricVersion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::LyricVersion

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<lyric_versions>

=cut

__PACKAGE__->table("lyric_versions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 lyric_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 text

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "lyric_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "text",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<lyric_id_text_unique>

=over 4

=item * L</lyric_id>

=item * L</text>

=back

=cut

__PACKAGE__->add_unique_constraint("lyric_id_text_unique", ["lyric_id", "text"]);

=head1 RELATIONS

=head2 lyric

Type: belongs_to

Related object: L<CDTest::Schema::Result::Lyric>

=cut

__PACKAGE__->belongs_to(
  "lyric",
  "CDTest::Schema::Result::Lyric",
  { lyric_id => "lyric_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PCtYPqsqz/Tc+uOS8cL9UA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
