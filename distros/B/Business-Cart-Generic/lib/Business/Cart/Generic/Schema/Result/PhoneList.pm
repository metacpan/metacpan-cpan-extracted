package Business::Cart::Generic::Schema::Result::PhoneList;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::PhoneList

=cut

__PACKAGE__->table("phone_lists");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phone_lists_id_seq'

=head2 customer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phone_number_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phone_lists_id_seq",
  },
  "customer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phone_number_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 customer

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Customer>

=cut

__PACKAGE__->belongs_to(
  "customer",
  "Business::Cart::Generic::Schema::Result::Customer",
  { id => "customer_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 phone_number

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::PhoneNumber>

=cut

__PACKAGE__->belongs_to(
  "phone_number",
  "Business::Cart::Generic::Schema::Result::PhoneNumber",
  { id => "phone_number_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zrONTEbOIeWGNE5lWMKmzA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
