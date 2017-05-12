package Business::Cart::Generic::Schema::Result::ManufacturersInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::ManufacturersInfo

=cut

__PACKAGE__->table("manufacturers_info");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'manufacturers_info_id_seq'

=head2 language_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 manufacturer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_last_click

  data_type: 'timestamp'
  default_value: '1900-01-01 00:00:00'
  is_nullable: 0

=head2 url

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 url_clicked

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "manufacturers_info_id_seq",
  },
  "language_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "manufacturer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_last_click",
  {
    data_type     => "timestamp",
    default_value => "1900-01-01 00:00:00",
    is_nullable   => 0,
  },
  "url",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "url_clicked",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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

=head2 manufacturer

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Manufacturer>

=cut

__PACKAGE__->belongs_to(
  "manufacturer",
  "Business::Cart::Generic::Schema::Result::Manufacturer",
  { id => "manufacturer_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w45KHOtOaC1jxmQkz5MYHA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
