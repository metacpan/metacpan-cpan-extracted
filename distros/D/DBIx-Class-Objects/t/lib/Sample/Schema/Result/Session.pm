use utf8;
package Sample::Schema::Result::Session;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::Session

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sessions>

=cut

__PACKAGE__->table("sessions");

=head1 ACCESSORS

=head2 session_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "session_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</session_id>

=back

=cut

__PACKAGE__->set_primary_key("session_id");

=head1 RELATIONS

=head2 username

Type: belongs_to

Related object: L<Sample::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Sample::Schema::Result::User",
  { username => "username" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-21 15:10:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RMEsfPGpYS4mPnsrBgjhbQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
