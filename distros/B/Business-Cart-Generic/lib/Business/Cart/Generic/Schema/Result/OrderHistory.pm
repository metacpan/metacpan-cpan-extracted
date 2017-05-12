package Business::Cart::Generic::Schema::Result::OrderHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::OrderHistory

=cut

__PACKAGE__->table("order_history");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'order_history_id_seq'

=head2 order_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 order_status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 customer_notified_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 date_added

  data_type: 'timestamp'
  is_nullable: 0

=head2 date_modified

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "order_history_id_seq",
  },
  "order_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "order_status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "customer_notified_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "date_added",
  { data_type => "timestamp", is_nullable => 0 },
  "date_modified",
  { data_type => "timestamp", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 order

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Order>

=cut

__PACKAGE__->belongs_to(
  "order",
  "Business::Cart::Generic::Schema::Result::Order",
  { id => "order_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 order_status

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::OrderStatuse>

=cut

__PACKAGE__->belongs_to(
  "order_status",
  "Business::Cart::Generic::Schema::Result::OrderStatuse",
  { id => "order_status_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 customer_notified

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::YesNo>

=cut

__PACKAGE__->belongs_to(
  "customer_notified",
  "Business::Cart::Generic::Schema::Result::YesNo",
  { id => "customer_notified_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YfCmbuWuQ5HI0SLn+spnAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
