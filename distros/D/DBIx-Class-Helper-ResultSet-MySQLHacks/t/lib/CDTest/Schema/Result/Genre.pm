use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Genre;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Genre

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<genre>

=cut

__PACKAGE__->table("genre");

=head1 ACCESSORS

=head2 genreid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "genreid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</genreid>

=back

=cut

__PACKAGE__->set_primary_key("genreid");

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name_unique", ["name"]);

=head1 RELATIONS

=head2 cds

Type: has_many

Related object: L<CDTest::Schema::Result::CD>

=cut

__PACKAGE__->has_many(
  "cds",
  "CDTest::Schema::Result::CD",
  { "foreign.genreid" => "self.genreid" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JcHHpJkZtHLA3BuC3mkXUA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
