package Business::Cart::Generic::Schema::Result::EmailAddress;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::EmailAddress

=cut

__PACKAGE__->table("email_addresses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'email_addresses_id_seq'

=head2 email_address_type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 address

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
    sequence          => "email_addresses_id_seq",
  },
  "email_address_type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "address",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 email_address_type

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::EmailAddressType>

=cut

__PACKAGE__->belongs_to(
  "email_address_type",
  "Business::Cart::Generic::Schema::Result::EmailAddressType",
  { id => "email_address_type_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 email_lists

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::EmailList>

=cut

__PACKAGE__->has_many(
  "email_lists",
  "Business::Cart::Generic::Schema::Result::EmailList",
  { "foreign.email_address_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HrgkW94sOwGwijXkC7L2iQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
