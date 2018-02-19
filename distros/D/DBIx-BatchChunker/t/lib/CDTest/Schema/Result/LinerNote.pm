use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::LinerNote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::LinerNote

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<liner_notes>

=cut

__PACKAGE__->table("liner_notes");

=head1 ACCESSORS

=head2 liner_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0

=head2 notes

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "liner_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 0,
  },
  "notes",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</liner_id>

=back

=cut

__PACKAGE__->set_primary_key("liner_id");

=head1 RELATIONS

=head2 liner

Type: belongs_to

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->belongs_to(
  "liner",
  "CDTest::Schema::Result::CD",
  { cdid => "liner_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:guQIb7e7RouGNey5SEUAYg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
