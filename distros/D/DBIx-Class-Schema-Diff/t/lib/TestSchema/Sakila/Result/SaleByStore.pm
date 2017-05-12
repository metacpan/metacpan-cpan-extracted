package # Hide from pause
     TestSchema::Sakila::Result::SaleByStore;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

TestSchema::Sakila::Result::SaleByStore

=cut

__PACKAGE__->table("sales_by_store");

=head1 ACCESSORS

=head2 store

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 101

=head2 manager

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 91

=head2 total_sales

  data_type: 'decimal'
  is_nullable: 1
  size: [27,2]

=cut

__PACKAGE__->add_columns(
  "store",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 101 },
  "manager",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 91 },
  "total_sales",
  { data_type => "decimal", is_nullable => 1, size => [27, 2] },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-17 16:15:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BsxPCrkJhgDiEUysLJkoEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
