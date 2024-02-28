use utf8;
package GnuCash::Schema::Result::Employee;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Employee

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<employees>

=cut

__PACKAGE__->table("employees");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 username

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 id

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 language

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 acl

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 active

  data_type: 'integer'
  is_nullable: 0

=head2 currency

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 ccard_guid

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 workday_num

  data_type: 'bigint'
  is_nullable: 0

=head2 workday_denom

  data_type: 'bigint'
  is_nullable: 0

=head2 rate_num

  data_type: 'bigint'
  is_nullable: 0

=head2 rate_denom

  data_type: 'bigint'
  is_nullable: 0

=head2 addr_name

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 addr_addr1

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 addr_addr2

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 addr_addr3

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 addr_addr4

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 addr_phone

  data_type: 'text'
  is_nullable: 1
  size: 128

=head2 addr_fax

  data_type: 'text'
  is_nullable: 1
  size: 128

=head2 addr_email

  data_type: 'text'
  is_nullable: 1
  size: 256

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "username",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "id",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "language",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "acl",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "active",
  { data_type => "integer", is_nullable => 0 },
  "currency",
  { data_type => "text", is_nullable => 0, size => 32 },
  "ccard_guid",
  { data_type => "text", is_nullable => 1, size => 32 },
  "workday_num",
  { data_type => "bigint", is_nullable => 0 },
  "workday_denom",
  { data_type => "bigint", is_nullable => 0 },
  "rate_num",
  { data_type => "bigint", is_nullable => 0 },
  "rate_denom",
  { data_type => "bigint", is_nullable => 0 },
  "addr_name",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "addr_addr1",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "addr_addr2",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "addr_addr3",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "addr_addr4",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "addr_phone",
  { data_type => "text", is_nullable => 1, size => 128 },
  "addr_fax",
  { data_type => "text", is_nullable => 1, size => 128 },
  "addr_email",
  { data_type => "text", is_nullable => 1, size => 256 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RjpjkeIbAArlt25UgvIGHQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
