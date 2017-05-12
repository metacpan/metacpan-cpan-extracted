package Bio::Chado::Schema::Result::Stock::StockDbxrefprop;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::StockDbxrefprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::StockDbxrefprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Stock::StockDbxrefprop

=head1 DESCRIPTION

A stock_dbxref can have any number of
slot-value property tags attached to it. This is useful for storing properties related to dbxref annotations of stocks, such as evidence codes, and references, and metadata, such as create/modify dates. This is an alternative to
hardcoding a list of columns in the relational schema, and is
completely extensible. There is a unique constraint, stock_dbxrefprop_c1, for
the combination of stock_dbxref_id, rank, and type_id. Multivalued property-value pairs must be differentiated by rank.

=cut

__PACKAGE__->table("stock_dbxrefprop");

=head1 ACCESSORS

=head2 stock_dbxrefprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_dbxrefprop_stock_dbxrefprop_id_seq'

=head2 stock_dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_dbxrefprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_dbxrefprop_stock_dbxrefprop_id_seq",
  },
  "stock_dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("stock_dbxrefprop_id");
__PACKAGE__->add_unique_constraint("stock_dbxrefprop_c1", ["stock_dbxref_id", "type_id", "rank"]);

=head1 RELATIONS

=head2 stock_dbxref

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Stock::StockDbxref>

=cut

__PACKAGE__->belongs_to(
  "stock_dbxref",
  "Bio::Chado::Schema::Result::Stock::StockDbxref",
  { stock_dbxref_id => "stock_dbxref_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 type

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "type_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fWNuOG73Ns+Z3Ypu/ULzCA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
