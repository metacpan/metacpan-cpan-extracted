use utf8;
package GnuCash::Schema::Result::Split;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Split

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

=head1 TABLE: C<splits>

=cut

__PACKAGE__->table("splits");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 tx_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 account_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 memo

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 action

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 reconcile_state

  data_type: 'text'
  is_nullable: 0
  size: 1

=head2 reconcile_date

  data_type: 'text'
  is_nullable: 1
  size: 19

=head2 value_num

  data_type: 'bigint'
  is_nullable: 0

=head2 value_denom

  data_type: 'bigint'
  is_nullable: 0

=head2 quantity_num

  data_type: 'bigint'
  is_nullable: 0

=head2 quantity_denom

  data_type: 'bigint'
  is_nullable: 0

=head2 lot_guid

  data_type: 'text'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "tx_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "account_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "memo",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "action",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "reconcile_state",
  { data_type => "text", is_nullable => 0, size => 1 },
  "reconcile_date",
  { data_type => "text", is_nullable => 1, size => 19 },
  "value_num",
  { data_type => "bigint", is_nullable => 0 },
  "value_denom",
  { data_type => "bigint", is_nullable => 0 },
  "quantity_num",
  { data_type => "bigint", is_nullable => 0 },
  "quantity_denom",
  { data_type => "bigint", is_nullable => 0 },
  "lot_guid",
  { data_type => "text", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tVwjS1Bxjv+g9esUHhRNSw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
