package Bio::Chado::Schema::Result::Stock::StockcollectionStock;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::StockcollectionStock::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::StockcollectionStock::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Stock::StockcollectionStock

=head1 DESCRIPTION

stockcollection_stock links
a stock collection to the stocks which are contained in the collection.

=cut

__PACKAGE__->table("stockcollection_stock");

=head1 ACCESSORS

=head2 stockcollection_stock_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stockcollection_stock_stockcollection_stock_id_seq'

=head2 stockcollection_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stockcollection_stock_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stockcollection_stock_stockcollection_stock_id_seq",
  },
  "stockcollection_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("stockcollection_stock_id");
__PACKAGE__->add_unique_constraint(
  "stockcollection_stock_c1",
  ["stockcollection_id", "stock_id"],
);

=head1 RELATIONS

=head2 stock

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Stock::Stock>

=cut

__PACKAGE__->belongs_to(
  "stock",
  "Bio::Chado::Schema::Result::Stock::Stock",
  { stock_id => "stock_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 stockcollection

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Stock::Stockcollection>

=cut

__PACKAGE__->belongs_to(
  "stockcollection",
  "Bio::Chado::Schema::Result::Stock::Stockcollection",
  { stockcollection_id => "stockcollection_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lQLmoIqkMDUkgrc13pY6Mg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
