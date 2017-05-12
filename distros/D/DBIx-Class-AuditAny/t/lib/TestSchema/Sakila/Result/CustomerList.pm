package TestSchema::Sakila::Result::CustomerList;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila::Result::CustomerList

=cut

__PACKAGE__->table("customer_list");

=head1 ACCESSORS

=head2 id

  data_type: 'smallint'
  default_value: 0
  extra: {unsigned => 1}
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 91

=head2 address

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 zip code

  accessor: 'zip_code'
  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 phone

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 city

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 country

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 notes

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 6

=head2 sid

  data_type: 'tinyint'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "smallint",
    default_value => 0,
    extra => { unsigned => 1 },
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 91 },
  "address",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "zip code",
  {
    accessor => "zip_code",
    data_type => "varchar",
    is_nullable => 1,
    size => 10,
  },
  "phone",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "city",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "country",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "notes",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 6 },
  "sid",
  { data_type => "tinyint", extra => { unsigned => 1 }, is_nullable => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RiYgaIvkfu7a+fxu2Cp+8g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
