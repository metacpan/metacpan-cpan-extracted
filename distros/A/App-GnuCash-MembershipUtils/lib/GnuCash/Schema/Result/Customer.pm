use utf8;
package GnuCash::Schema::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Customer

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

=head1 TABLE: C<customers>

=cut

__PACKAGE__->table("customers");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 name

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 id

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 notes

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 active

  data_type: 'integer'
  is_nullable: 0

=head2 discount_num

  data_type: 'bigint'
  is_nullable: 0

=head2 discount_denom

  data_type: 'bigint'
  is_nullable: 0

=head2 credit_num

  data_type: 'bigint'
  is_nullable: 0

=head2 credit_denom

  data_type: 'bigint'
  is_nullable: 0

=head2 currency

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 tax_override

  data_type: 'integer'
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

=head2 shipaddr_name

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 shipaddr_addr1

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 shipaddr_addr2

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 shipaddr_addr3

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 shipaddr_addr4

  data_type: 'text'
  is_nullable: 1
  size: 1024

=head2 shipaddr_phone

  data_type: 'text'
  is_nullable: 1
  size: 128

=head2 shipaddr_fax

  data_type: 'text'
  is_nullable: 1
  size: 128

=head2 shipaddr_email

  data_type: 'text'
  is_nullable: 1
  size: 256

=head2 terms

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 tax_included

  data_type: 'integer'
  is_nullable: 1

=head2 taxtable

  data_type: 'text'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "name",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "id",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "notes",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "active",
  { data_type => "integer", is_nullable => 0 },
  "discount_num",
  { data_type => "bigint", is_nullable => 0 },
  "discount_denom",
  { data_type => "bigint", is_nullable => 0 },
  "credit_num",
  { data_type => "bigint", is_nullable => 0 },
  "credit_denom",
  { data_type => "bigint", is_nullable => 0 },
  "currency",
  { data_type => "text", is_nullable => 0, size => 32 },
  "tax_override",
  { data_type => "integer", is_nullable => 0 },
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
  "shipaddr_name",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "shipaddr_addr1",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "shipaddr_addr2",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "shipaddr_addr3",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "shipaddr_addr4",
  { data_type => "text", is_nullable => 1, size => 1024 },
  "shipaddr_phone",
  { data_type => "text", is_nullable => 1, size => 128 },
  "shipaddr_fax",
  { data_type => "text", is_nullable => 1, size => 128 },
  "shipaddr_email",
  { data_type => "text", is_nullable => 1, size => 256 },
  "terms",
  { data_type => "text", is_nullable => 1, size => 32 },
  "tax_included",
  { data_type => "integer", is_nullable => 1 },
  "taxtable",
  { data_type => "text", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:d+HMl5Ra/YJ8DxD/qT/C9w

1;
