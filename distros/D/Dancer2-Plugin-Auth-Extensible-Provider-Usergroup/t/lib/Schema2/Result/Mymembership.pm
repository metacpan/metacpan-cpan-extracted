use utf8;
package t::lib::Schema2::Result::Mymembership;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

t::lib::Schema2::Result::Mymembership

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mymemberships>

=cut

__PACKAGE__->table("mymemberships");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 myuser_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 mygroup_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "myuser_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "mygroup_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<myuser_id_mygroup_id_unique>

=over 4

=item * L</myuser_id>

=item * L</mygroup_id>

=back

=cut

__PACKAGE__->add_unique_constraint("myuser_id_mygroup_id_unique", ["myuser_id", "mygroup_id"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-04-01 11:38:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BG6pietpN2IqNvxuXpHkBw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
