package Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref - Cross-reference experiment_stock to accessions, images, etc

=cut

__PACKAGE__->table("nd_experiment_stock_dbxref");

=head1 ACCESSORS

=head2 nd_experiment_stock_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_experiment_stock_dbxref_nd_experiment_stock_dbxref_id_seq'

=head2 nd_experiment_stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "nd_experiment_stock_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_experiment_stock_dbxref_nd_experiment_stock_dbxref_id_seq",
  },
  "nd_experiment_stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("nd_experiment_stock_dbxref_id");

=head1 RELATIONS

=head2 nd_experiment_stock

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock>

=cut

__PACKAGE__->belongs_to(
  "nd_experiment_stock",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock",
  { nd_experiment_stock_id => "nd_experiment_stock_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 dbxref

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::General::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Bio::Chado::Schema::Result::General::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tRph0dUDfv4ZevFBgPDBTw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
