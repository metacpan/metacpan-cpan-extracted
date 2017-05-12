use utf8;
package t::lib::Schema1::Result::Group;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

t::lib::Schema1::Result::Group

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<groups>

=cut

__PACKAGE__->table("groups");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 group_name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "group_name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<group_name_unique>

=over 4

=item * L</group_name>

=back

=cut

__PACKAGE__->add_unique_constraint("group_name_unique", ["group_name"]);

=head1 RELATIONS

=head2 memberships

Type: has_many

Related object: L<t::lib::Schema1::Result::Membership>

=cut

__PACKAGE__->has_many(
  "memberships",
  "t::lib::Schema1::Result::Membership",
  { "foreign.group_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-04-01 11:38:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cbfROCT5/5jkcwNTB7H4ng


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
