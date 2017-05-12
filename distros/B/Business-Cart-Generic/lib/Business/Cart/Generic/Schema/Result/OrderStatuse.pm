package Business::Cart::Generic::Schema::Result::OrderStatuse;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::OrderStatuse

=cut

__PACKAGE__->table("order_statuses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'order_statuses_id_seq'

=head2 language_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 upper_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "order_statuses_id_seq",
  },
  "language_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 order_histories

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::OrderHistory>

=cut

__PACKAGE__->has_many(
  "order_histories",
  "Business::Cart::Generic::Schema::Result::OrderHistory",
  { "foreign.order_status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 orders

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders",
  "Business::Cart::Generic::Schema::Result::Order",
  { "foreign.order_status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 language

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Language>

=cut

__PACKAGE__->belongs_to(
  "language",
  "Business::Cart::Generic::Schema::Result::Language",
  { id => "language_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9I+/gcrJgrrm6zt1CTmV7g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
