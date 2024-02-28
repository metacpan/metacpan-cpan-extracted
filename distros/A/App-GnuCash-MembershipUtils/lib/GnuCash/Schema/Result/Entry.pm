use utf8;
package GnuCash::Schema::Result::Entry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Entry

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

=head1 TABLE: C<entries>

=cut

__PACKAGE__->table("entries");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 date

  data_type: 'text'
  is_nullable: 0
  size: 19

=head2 date_entered

  data_type: 'text'
  is_nullable: 1
  size: 19

=head2 description

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 action

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 notes

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 quantity_num

  data_type: 'bigint'
  is_nullable: 1

=head2 quantity_denom

  data_type: 'bigint'
  is_nullable: 1

=head2 i_acct

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 i_price_num

  data_type: 'bigint'
  is_nullable: 1

=head2 i_price_denom

  data_type: 'bigint'
  is_nullable: 1

=head2 i_discount_num

  data_type: 'bigint'
  is_nullable: 1

=head2 i_discount_denom

  data_type: 'bigint'
  is_nullable: 1

=head2 invoice

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 i_disc_type

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 i_disc_how

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 i_taxable

  data_type: 'integer'
  is_nullable: 1

=head2 i_taxincluded

  data_type: 'integer'
  is_nullable: 1

=head2 i_taxtable

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 b_acct

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 b_price_num

  data_type: 'bigint'
  is_nullable: 1

=head2 b_price_denom

  data_type: 'bigint'
  is_nullable: 1

=head2 bill

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 b_taxable

  data_type: 'integer'
  is_nullable: 1

=head2 b_taxincluded

  data_type: 'integer'
  is_nullable: 1

=head2 b_taxtable

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 b_paytype

  data_type: 'integer'
  is_nullable: 1

=head2 billable

  data_type: 'integer'
  is_nullable: 1

=head2 billto_type

  data_type: 'integer'
  is_nullable: 1

=head2 billto_guid

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 order_guid

  data_type: 'text'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "date",
  { data_type => "text", is_nullable => 0, size => 19 },
  "date_entered",
  { data_type => "text", is_nullable => 1, size => 19 },
  "description",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "action",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "notes",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "quantity_num",
  { data_type => "bigint", is_nullable => 1 },
  "quantity_denom",
  { data_type => "bigint", is_nullable => 1 },
  "i_acct",
  { data_type => "text", is_nullable => 1, size => 32 },
  "i_price_num",
  { data_type => "bigint", is_nullable => 1 },
  "i_price_denom",
  { data_type => "bigint", is_nullable => 1 },
  "i_discount_num",
  { data_type => "bigint", is_nullable => 1 },
  "i_discount_denom",
  { data_type => "bigint", is_nullable => 1 },
  "invoice",
  { data_type => "text", is_nullable => 1, size => 32 },
  "i_disc_type",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "i_disc_how",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "i_taxable",
  { data_type => "integer", is_nullable => 1 },
  "i_taxincluded",
  { data_type => "integer", is_nullable => 1 },
  "i_taxtable",
  { data_type => "text", is_nullable => 1, size => 32 },
  "b_acct",
  { data_type => "text", is_nullable => 1, size => 32 },
  "b_price_num",
  { data_type => "bigint", is_nullable => 1 },
  "b_price_denom",
  { data_type => "bigint", is_nullable => 1 },
  "bill",
  { data_type => "text", is_nullable => 1, size => 32 },
  "b_taxable",
  { data_type => "integer", is_nullable => 1 },
  "b_taxincluded",
  { data_type => "integer", is_nullable => 1 },
  "b_taxtable",
  { data_type => "text", is_nullable => 1, size => 32 },
  "b_paytype",
  { data_type => "integer", is_nullable => 1 },
  "billable",
  { data_type => "integer", is_nullable => 1 },
  "billto_type",
  { data_type => "integer", is_nullable => 1 },
  "billto_guid",
  { data_type => "text", is_nullable => 1, size => 32 },
  "order_guid",
  { data_type => "text", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CDFv6vDarlu50rH/cMw+JQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
