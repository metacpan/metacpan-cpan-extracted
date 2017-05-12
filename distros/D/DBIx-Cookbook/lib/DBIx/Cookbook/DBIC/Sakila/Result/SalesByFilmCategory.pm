package DBIx::Cookbook::DBIC::Sakila::Result::SalesByFilmCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBIx::Cookbook::DBIC::Sakila::Result::SalesByFilmCategory

=cut

__PACKAGE__->table("sales_by_film_category");

=head1 ACCESSORS

=head2 category

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 25

=head2 total_sales

  data_type: DECIMAL
  default_value: undef
  is_nullable: 1
  size: 27

=cut

__PACKAGE__->add_columns(
  "category",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 25,
  },
  "total_sales",
  {
    data_type => "DECIMAL",
    default_value => undef,
    is_nullable => 1,
    size => 27,
  },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-24 17:44:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N803QqzQM31uTZaYqf0fpA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
