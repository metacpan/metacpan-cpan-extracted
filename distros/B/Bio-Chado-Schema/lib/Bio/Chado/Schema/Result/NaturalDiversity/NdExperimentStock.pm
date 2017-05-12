package Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock

=head1 DESCRIPTION

Part of a stock or a clone of a stock that is used in an experiment

=cut

__PACKAGE__->table("nd_experiment_stock");

=head1 ACCESSORS

=head2 nd_experiment_stock_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_stock_nd_experiment_stock_id_seq'

=head2 nd_experiment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

stock used in the extraction or the corresponding stock for the clone

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_stock_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_stock_nd_experiment_stock_id_seq",
  },
  "nd_experiment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("nd_experiment_stock_id");

=head1 RELATIONS

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

=head2 nd_experiment

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment>

=cut

__PACKAGE__->belongs_to(
  "nd_experiment",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment",
  { nd_experiment_id => "nd_experiment_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 nd_experiment_stock_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stock_dbxrefs",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref",
  {
    "foreign.nd_experiment_stock_id" => "self.nd_experiment_stock_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stockprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockprop>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stockprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockprop",
  {
    "foreign.nd_experiment_stock_id" => "self.nd_experiment_stock_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A5rjtFxP/735qGsASzZs6w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
