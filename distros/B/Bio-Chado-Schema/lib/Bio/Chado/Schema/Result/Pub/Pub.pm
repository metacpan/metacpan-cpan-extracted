package Bio::Chado::Schema::Result::Pub::Pub;
BEGIN {
  $Bio::Chado::Schema::Result::Pub::Pub::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Pub::Pub::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Pub::Pub

=head1 DESCRIPTION

A documented provenance artefact - publications,
documents, personal communication.

=cut

__PACKAGE__->table("pub");

=head1 ACCESSORS

=head2 pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pub_pub_id_seq'

=head2 title

  data_type: 'text'
  is_nullable: 1

Descriptive general heading.

=head2 volumetitle

  data_type: 'text'
  is_nullable: 1

Title of part if one of a series.

=head2 volume

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 series_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

Full name of (journal) series.

=head2 issue

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pyear

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pages

  data_type: 'varchar'
  is_nullable: 1
  size: 255

Page number range[s], e.g. 457--459, viii + 664pp, lv--lvii.

=head2 miniref

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type of the publication (book, journal, poem, graffiti, etc). Uses pub cv.

=head2 is_obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 publisher

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pubplace

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pub_pub_id_seq",
  },
  "title",
  { data_type => "text", is_nullable => 1 },
  "volumetitle",
  { data_type => "text", is_nullable => 1 },
  "volume",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "series_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "issue",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pyear",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pages",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "miniref",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "publisher",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pubplace",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("pub_id");
__PACKAGE__->add_unique_constraint("pub_c1", ["uniquename"]);

=head1 RELATIONS

=head2 cell_line_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineCvterm>

=cut

__PACKAGE__->has_many(
  "cell_line_cvterms",
  "Bio::Chado::Schema::Result::CellLine::CellLineCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_features

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineFeature>

=cut

__PACKAGE__->has_many(
  "cell_line_features",
  "Bio::Chado::Schema::Result::CellLine::CellLineFeature",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_libraries

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineLibrary>

=cut

__PACKAGE__->has_many(
  "cell_line_libraries",
  "Bio::Chado::Schema::Result::CellLine::CellLineLibrary",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lineprop_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLinepropPub>

=cut

__PACKAGE__->has_many(
  "cell_lineprop_pubs",
  "Bio::Chado::Schema::Result::CellLine::CellLinepropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLinePub>

=cut

__PACKAGE__->has_many(
  "cell_line_pubs",
  "Bio::Chado::Schema::Result::CellLine::CellLinePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineSynonym>

=cut

__PACKAGE__->has_many(
  "cell_line_synonyms",
  "Bio::Chado::Schema::Result::CellLine::CellLineSynonym",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::ExpressionPub>

=cut

__PACKAGE__->has_many(
  "expression_pubs",
  "Bio::Chado::Schema::Result::Expression::ExpressionPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureCvterm>

=cut

__PACKAGE__->has_many(
  "feature_cvterms",
  "Bio::Chado::Schema::Result::Sequence::FeatureCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvterm_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureCvtermPub>

=cut

__PACKAGE__->has_many(
  "feature_cvterm_pubs",
  "Bio::Chado::Schema::Result::Sequence::FeatureCvtermPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_expressions

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::FeatureExpression>

=cut

__PACKAGE__->has_many(
  "feature_expressions",
  "Bio::Chado::Schema::Result::Expression::FeatureExpression",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featureloc_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeaturelocPub>

=cut

__PACKAGE__->has_many(
  "featureloc_pubs",
  "Bio::Chado::Schema::Result::Sequence::FeaturelocPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featuremap_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Map::FeaturemapPub>

=cut

__PACKAGE__->has_many(
  "featuremap_pubs",
  "Bio::Chado::Schema::Result::Map::FeaturemapPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featureprop_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeaturepropPub>

=cut

__PACKAGE__->has_many(
  "featureprop_pubs",
  "Bio::Chado::Schema::Result::Sequence::FeaturepropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeaturePub>

=cut

__PACKAGE__->has_many(
  "feature_pubs",
  "Bio::Chado::Schema::Result::Sequence::FeaturePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationshipprop_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureRelationshippropPub>

=cut

__PACKAGE__->has_many(
  "feature_relationshipprop_pubs",
  "Bio::Chado::Schema::Result::Sequence::FeatureRelationshippropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationship_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureRelationshipPub>

=cut

__PACKAGE__->has_many(
  "feature_relationship_pubs",
  "Bio::Chado::Schema::Result::Sequence::FeatureRelationshipPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureSynonym>

=cut

__PACKAGE__->has_many(
  "feature_synonyms",
  "Bio::Chado::Schema::Result::Sequence::FeatureSynonym",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryCvterm>

=cut

__PACKAGE__->has_many(
  "library_cvterms",
  "Bio::Chado::Schema::Result::Library::LibraryCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraryprop_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibrarypropPub>

=cut

__PACKAGE__->has_many(
  "libraryprop_pubs",
  "Bio::Chado::Schema::Result::Library::LibrarypropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryPub>

=cut

__PACKAGE__->has_many(
  "library_pubs",
  "Bio::Chado::Schema::Result::Library::LibraryPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibrarySynonym>

=cut

__PACKAGE__->has_many(
  "library_synonyms",
  "Bio::Chado::Schema::Result::Library::LibrarySynonym",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPub>

=cut

__PACKAGE__->has_many(
  "nd_experiment_pubs",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phendescs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Phendesc>

=cut

__PACKAGE__->has_many(
  "phendescs",
  "Bio::Chado::Schema::Result::Genetic::Phendesc",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparisons

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparisons",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparison",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparisonCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_cvterms",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparisonCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Bio::Chado::Schema::Result::Genetic::Phenstatement",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonode_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::PhylonodePub>

=cut

__PACKAGE__->has_many(
  "phylonode_pubs",
  "Bio::Chado::Schema::Result::Phylogeny::PhylonodePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylotree_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::PhylotreePub>

=cut

__PACKAGE__->has_many(
  "phylotree_pubs",
  "Bio::Chado::Schema::Result::Phylogeny::PhylotreePub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::ProjectPub>

=cut

__PACKAGE__->has_many(
  "project_pubs",
  "Bio::Chado::Schema::Result::Project::ProjectPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocols

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Protocol>

=cut

__PACKAGE__->has_many(
  "protocols",
  "Bio::Chado::Schema::Result::Mage::Protocol",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 pubauthors

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::Pubauthor>

=cut

__PACKAGE__->has_many(
  "pubauthors",
  "Bio::Chado::Schema::Result::Pub::Pubauthor",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::PubDbxref>

=cut

__PACKAGE__->has_many(
  "pub_dbxrefs",
  "Bio::Chado::Schema::Result::Pub::PubDbxref",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pubprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::Pubprop>

=cut

__PACKAGE__->has_many(
  "pubprops",
  "Bio::Chado::Schema::Result::Pub::Pubprop",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::PubRelationship>

=cut

__PACKAGE__->has_many(
  "pub_relationship_objects",
  "Bio::Chado::Schema::Result::Pub::PubRelationship",
  { "foreign.object_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::PubRelationship>

=cut

__PACKAGE__->has_many(
  "pub_relationship_subjects",
  "Bio::Chado::Schema::Result::Pub::PubRelationship",
  { "foreign.subject_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockCvterm>

=cut

__PACKAGE__->has_many(
  "stock_cvterms",
  "Bio::Chado::Schema::Result::Stock::StockCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockprop_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockpropPub>

=cut

__PACKAGE__->has_many(
  "stockprop_pubs",
  "Bio::Chado::Schema::Result::Stock::StockpropPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockPub>

=cut

__PACKAGE__->has_many(
  "stock_pubs",
  "Bio::Chado::Schema::Result::Stock::StockPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationshipCvterm>

=cut

__PACKAGE__->has_many(
  "stock_relationship_cvterms",
  "Bio::Chado::Schema::Result::Stock::StockRelationshipCvterm",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationshipPub>

=cut

__PACKAGE__->has_many(
  "stock_relationship_pubs",
  "Bio::Chado::Schema::Result::Stock::StockRelationshipPub",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studies

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Study>

=cut

__PACKAGE__->has_many(
  "studies",
  "Bio::Chado::Schema::Result::Mage::Study",
  { "foreign.pub_id" => "self.pub_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IREmDNM5PFZA6eqAwr7Pqg

=head2 create_pubprops

  Usage: $set->create_pubprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create pubprop properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given pubprop name.  Default false.

            cv_name => cv.name to use for the given pubprops.
                       Defaults to 'pub_property',

            db_name => db.name to use for autocreated dbxrefs,
                       default 'null',

            dbxref_accession_prefix => optional, default
                                       'autocreated:',
            definitions => optional hashref of:
                { cvterm_name => definition,
                }
             to load into the cvterm table when autocreating cvterms

             rank => force numeric rank. Be careful not to pass ranks that already exist
                     for the property type. The function will die in such case.

             allow_duplicate_values => default false.
                If true, allow duplicate instances of the same cvterm
                and value in the properties of the pubprop.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new pubprop object }

=cut

sub create_pubprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'pub_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'pubprops',
        );
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
