use utf8;

package AuditTest::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AuditTest::Schema::Result::User

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<audit_test.user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 phone

  data_type: 'varchar'
  is_nullable: 1
  size: 30

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "varchar", is_nullable => 1, size => 100 },
    "phone",
    { data_type => "varchar", is_nullable => 1, size => 30 },
    "email",
    { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-02-13 15:52:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I6IyqTkjKebY+VQoOcIYqA

# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->load_components(qw/ AuditLog /);

__PACKAGE__->add_columns( "+email", { audit_log_column => 0, } );

1;
