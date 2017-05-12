use utf8;
package Sample::Schema::Result::OrderItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::OrderItem

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

=head1 TABLE: C<order_item>

=cut

__PACKAGE__->table("order_item");

=head1 ACCESSORS

=head2 order_item_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 item_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 order_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 price

  data_type: 'real'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "order_item_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "item_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "order_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "price",
  { data_type => "real", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</order_item_id>

=back

=cut

__PACKAGE__->set_primary_key("order_item_id");

=head1 RELATIONS

=head2 item

Type: belongs_to

Related object: L<Sample::Schema::Result::Item>

=cut

__PACKAGE__->belongs_to(
  "item",
  "Sample::Schema::Result::Item",
  { item_id => "item_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 order

Type: belongs_to

Related object: L<Sample::Schema::Result::Order>

=cut

__PACKAGE__->belongs_to(
  "order",
  "Sample::Schema::Result::Order",
  { order_id => "order_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-13 13:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aS3kPAgFW5JByq5i0GhGbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
