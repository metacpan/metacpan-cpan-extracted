use utf8;
package GnuCash::Schema::Result::Invoice;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Invoice

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

=head1 TABLE: C<invoices>

=cut

__PACKAGE__->table("invoices");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 id

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 date_opened

  data_type: 'text'
  is_nullable: 1
  size: 19

=head2 date_posted

  data_type: 'text'
  is_nullable: 1
  size: 19

=head2 notes

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

=head2 owner_type

  data_type: 'integer'
  is_nullable: 1

=head2 owner_guid

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 terms

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 billing_id

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 post_txn

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 post_lot

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 post_acc

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 billto_type

  data_type: 'integer'
  is_nullable: 1

=head2 billto_guid

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 charge_amt_num

  data_type: 'bigint'
  is_nullable: 1

=head2 charge_amt_denom

  data_type: 'bigint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "id",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "date_opened",
  { data_type => "text", is_nullable => 1, size => 19 },
  "date_posted",
  { data_type => "text", is_nullable => 1, size => 19 },
  "notes",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "active",
  { data_type => "integer", is_nullable => 0 },
  "currency",
  { data_type => "text", is_nullable => 0, size => 32 },
  "owner_type",
  { data_type => "integer", is_nullable => 1 },
  "owner_guid",
  { data_type => "text", is_nullable => 1, size => 32 },
  "terms",
  { data_type => "text", is_nullable => 1, size => 32 },
  "billing_id",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "post_txn",
  { data_type => "text", is_nullable => 1, size => 32 },
  "post_lot",
  { data_type => "text", is_nullable => 1, size => 32 },
  "post_acc",
  { data_type => "text", is_nullable => 1, size => 32 },
  "billto_type",
  { data_type => "integer", is_nullable => 1 },
  "billto_guid",
  { data_type => "text", is_nullable => 1, size => 32 },
  "charge_amt_num",
  { data_type => "bigint", is_nullable => 1 },
  "charge_amt_denom",
  { data_type => "bigint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+SSju8SYqUUcUTKSWxaiGg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
