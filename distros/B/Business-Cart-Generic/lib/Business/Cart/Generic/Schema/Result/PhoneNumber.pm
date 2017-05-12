package Business::Cart::Generic::Schema::Result::PhoneNumber;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::PhoneNumber

=cut

__PACKAGE__->table("phone_numbers");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phone_numbers_id_seq'

=head2 phone_number_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 number

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
    sequence          => "phone_numbers_id_seq",
  },
  "phone_number_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "number",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 phone_lists

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::PhoneList>

=cut

__PACKAGE__->has_many(
  "phone_lists",
  "Business::Cart::Generic::Schema::Result::PhoneList",
  { "foreign.phone_number_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phone_number_type

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::PhoneNumberType>

=cut

__PACKAGE__->belongs_to(
  "phone_number_type",
  "Business::Cart::Generic::Schema::Result::PhoneNumberType",
  { id => "phone_number_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rvY7fr4+NJosqq7ITYuX/g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
