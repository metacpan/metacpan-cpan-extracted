use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Tag

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tags>

=cut

__PACKAGE__->table("tags");

=head1 ACCESSORS

=head2 tagid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 cd

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tag

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "tagid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "cd",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tag",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tagid>

=back

=cut

__PACKAGE__->set_primary_key("tagid");

=head1 UNIQUE CONSTRAINTS

=head2 C<tagid_cd_tag_unique>

=over 4

=item * L</tagid>

=item * L</cd>

=item * L</tag>

=back

=cut

__PACKAGE__->add_unique_constraint("tagid_cd_tag_unique", ["tagid", "cd", "tag"]);

=head2 C<tagid_cd_unique>

=over 4

=item * L</tagid>

=item * L</cd>

=back

=cut

__PACKAGE__->add_unique_constraint("tagid_cd_unique", ["tagid", "cd"]);

=head2 C<tagid_tag_cd_unique>

=over 4

=item * L</tagid>

=item * L</tag>

=item * L</cd>

=back

=cut

__PACKAGE__->add_unique_constraint("tagid_tag_cd_unique", ["tagid", "tag", "cd"]);

=head2 C<tagid_tag_unique>

=over 4

=item * L</tagid>

=item * L</tag>

=back

=cut

__PACKAGE__->add_unique_constraint("tagid_tag_unique", ["tagid", "tag"]);

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


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:K3pX+E25uQOnXOJ/8MDtTQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
