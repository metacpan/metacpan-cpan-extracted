use utf8;
package Sample::Schema::Result::Order;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::Order

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

=head1 TABLE: C<orders>

=cut

__PACKAGE__->table("orders");

=head1 ACCESSORS

=head2 order_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 customer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 order_date

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "order_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "customer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "order_date",
  { data_type => "datetime", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</order_id>

=back

=cut

__PACKAGE__->set_primary_key("order_id");

=head1 RELATIONS

=head2 customer

Type: belongs_to

Related object: L<Sample::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "Sample::Schema::Result::Customer",
  { customer_id => "customer_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 order_items

Type: has_many

Related object: L<Sample::Schema::Result::OrderItem>

=cut

__PACKAGE__->has_many(
  "order_items",
  "Sample::Schema::Result::OrderItem",
  { "foreign.order_id" => "self.order_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-13 13:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aenC7bkKWYnrvHo2ALypQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
