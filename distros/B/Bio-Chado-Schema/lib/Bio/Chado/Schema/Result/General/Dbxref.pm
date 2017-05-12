package Bio::Chado::Schema::Result::General::Dbxref;
BEGIN {
  $Bio::Chado::Schema::Result::General::Dbxref::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::General::Dbxref::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::General::Dbxref

=head1 DESCRIPTION

A unique, global, public, stable identifier. Not necessarily an external reference - can reference data items inside the particular chado instance being used. Typically a row in a table can be uniquely identified with a primary identifier (called dbxref_id); a table may also have secondary identifiers (in a linking table <T>_dbxref). A dbxref is generally written as <DB>:<ACCESSION> or as <DB>:<ACCESSION>:<VERSION>.

=cut

__PACKAGE__->table("dbxref");

=head1 ACCESSORS

=head2 dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'dbxref_dbxref_id_seq'

=head2 db_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 accession

  data_type: 'varchar'
  is_nullable: 0
  size: 255

The local part of the identifier. Guaranteed by the db authority to be unique for that db.

=head2 version

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "dbxref_dbxref_id_seq",
  },
  "db_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "accession",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "version",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("dbxref_id");
__PACKAGE__->add_unique_constraint("dbxref_c1", ["db_id", "accession", "version"]);

=head1 RELATIONS

=head2 arraydesigns

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesigns",
  "Bio::Chado::Schema::Result::Mage::Arraydesign",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assays

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Assay>

=cut

__PACKAGE__->has_many(
  "assays",
  "Bio::Chado::Schema::Result::Mage::Assay",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterials

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Biomaterial>

=cut

__PACKAGE__->has_many(
  "biomaterials",
  "Bio::Chado::Schema::Result::Mage::Biomaterial",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialDbxref>

=cut

__PACKAGE__->has_many(
  "biomaterial_dbxrefs",
  "Bio::Chado::Schema::Result::Mage::BiomaterialDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineDbxref>

=cut

__PACKAGE__->has_many(
  "cell_line_dbxrefs",
  "Bio::Chado::Schema::Result::CellLine::CellLineDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm

Type: might_have

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->might_have(
  "cvterm",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::CvtermDbxref>

=cut

__PACKAGE__->has_many(
  "cvterm_dbxrefs",
  "Bio::Chado::Schema::Result::Cv::CvtermDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 db

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::General::Db>

=cut

__PACKAGE__->belongs_to(
  "db",
  "Bio::Chado::Schema::Result::General::Db",
  { db_id => "db_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 dbxrefprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Dbxrefprop>

=cut

__PACKAGE__->has_many(
  "dbxrefprops",
  "Bio::Chado::Schema::Result::Cv::Dbxrefprop",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 elements

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Element>

=cut

__PACKAGE__->has_many(
  "elements",
  "Bio::Chado::Schema::Result::Mage::Element",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 features

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvterm_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureCvtermDbxref>

=cut

__PACKAGE__->has_many(
  "feature_cvterm_dbxrefs",
  "Bio::Chado::Schema::Result::Sequence::FeatureCvtermDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureDbxref>

=cut

__PACKAGE__->has_many(
  "feature_dbxrefs",
  "Bio::Chado::Schema::Result::Sequence::FeatureDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryDbxref>

=cut

__PACKAGE__->has_many(
  "library_dbxrefs",
  "Bio::Chado::Schema::Result::Library::LibraryDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentDbxref>

=cut

__PACKAGE__->has_many(
  "nd_experiment_dbxrefs",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stock_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stock_dbxrefs",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organism_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Organism::OrganismDbxref>

=cut

__PACKAGE__->has_many(
  "organism_dbxrefs",
  "Bio::Chado::Schema::Result::Organism::OrganismDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonode_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::PhylonodeDbxref>

=cut

__PACKAGE__->has_many(
  "phylonode_dbxrefs",
  "Bio::Chado::Schema::Result::Phylogeny::PhylonodeDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylotrees

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::Phylotree>

=cut

__PACKAGE__->has_many(
  "phylotrees",
  "Bio::Chado::Schema::Result::Phylogeny::Phylotree",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocols

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Protocol>

=cut

__PACKAGE__->has_many(
  "protocols",
  "Bio::Chado::Schema::Result::Mage::Protocol",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::PubDbxref>

=cut

__PACKAGE__->has_many(
  "pub_dbxrefs",
  "Bio::Chado::Schema::Result::Pub::PubDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stocks

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stock>

=cut

__PACKAGE__->has_many(
  "stocks",
  "Bio::Chado::Schema::Result::Stock::Stock",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockDbxref>

=cut

__PACKAGE__->has_many(
  "stock_dbxrefs",
  "Bio::Chado::Schema::Result::Stock::StockDbxref",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studies

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Study>

=cut

__PACKAGE__->has_many(
  "studies",
  "Bio::Chado::Schema::Result::Mage::Study",
  { "foreign.dbxref_id" => "self.dbxref_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DH06/5V4IKTYucfk2dsWHA


=head1 MANY-TO-MANY RELATIONSHIPS

=head2 biomaterials_mm

Relation to L<Bio::Chado::Schema::Result::Mage::Biomaterial> (i.e. C<biomaterial> table)
via the C<organism_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'biomaterials_mm',
     'biomaterial_dbxrefs' => 'biomaterial',
    );

=head2 cell_lines_mm

Relation to L<Bio::Chado::Schema::Result::CellLine::CellLine> (i.e. C<cell_line> table)
via the C<cell_line_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'cell_lines_mm',
     'cell_line_dbxrefs' => 'cell_line',
    );

=head2 cvterms_mm

Relation to L<Bio::Chado::Schema::Result::Cv::Cvterm> (i.e. C<cvterm> table)
via the C<cvterm_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'cvterms_mm',
     'cvterm_dbxrefs' => 'cvterm',
    );

=head2 features_mm

Relation to L<Bio::Chado::Schema::Result::Sequence::Feature> (i.e. C<feature> table)
via the C<feature_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'features_mm',
     'feature_dbxrefs' => 'feature',
    );

=head2 libraries_mm

Relation to L<Bio::Chado::Schema::Result::Library::LibraryDbxref> (i.e. C<library> table)
via the C<library_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'libraries_mm',
     'library_dbxrefs' => 'library',
    );

=head2 organisms_mm

Relation to L<Bio::Chado::Schema::Result::Organism::Organism> (i.e. C<organism> table)
via the C<organism_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'organisms_mm',
     'organism_dbxrefs' => 'organism',
    );

=head2 phylonodes_mm

Relation to L<Bio::Chado::Schema::Result::Phylogeny::Phylonode> (i.e. C<phylonode> table)
via the C<phylonode_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'phylonodes_mm',
     'phylonode_dbxrefs' => 'phylonode',
    );

=head2 pubs_mm

Relation to L<Bio::Chado::Schema::Result::Pub::Pub> (i.e. C<pub> table)
via the C<pub_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'pubs_mm',
     'pub_dbxrefs' => 'pub',
    );

=head2 stocks_mm

Relation to L<Bio::Chado::Schema::Result::Stock::Stock> (i.e. C<stock> table)
via the C<stock_dbxrefs> table.

=cut

__PACKAGE__->many_to_many
    (
     'stocks_mm',
     'stock_dbxrefs' => 'stock',
    );


# You can replace this text with custom content, and it will be preserved on regeneration
1;
