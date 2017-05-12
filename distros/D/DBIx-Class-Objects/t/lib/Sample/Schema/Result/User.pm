use utf8;
package Sample::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "username",
  { data_type => "varchar", is_nullable => 0, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->set_primary_key("username");

=head1 RELATIONS

=head2 sessions

Type: has_many

Related object: L<Sample::Schema::Result::Session>

=cut

__PACKAGE__->has_many(
  "sessions",
  "Sample::Schema::Result::Session",
  { "foreign.username" => "self.username" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-21 15:10:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zXnVRzmM41+ADiMb/Ecopw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
