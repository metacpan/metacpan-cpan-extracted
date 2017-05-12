use utf8;
package t::lib::Schema2::Result::Mygroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

t::lib::Schema2::Result::Mygroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mygroups>

=cut

__PACKAGE__->table("mygroups");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 mygroup_name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "mygroup_name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<mygroup_name_unique>

=over 4

=item * L</mygroup_name>

=back

=cut

__PACKAGE__->add_unique_constraint("mygroup_name_unique", ["mygroup_name"]);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-04-01 11:38:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vNKirhTdbtKQ/4YQeu0iFg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
