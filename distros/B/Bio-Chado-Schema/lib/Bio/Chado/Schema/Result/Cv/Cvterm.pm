package Bio::Chado::Schema::Result::Cv::Cvterm;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::Cvterm::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::Cvterm::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::Cvterm

=head1 DESCRIPTION

A term, class, universal or type within an
ontology or controlled vocabulary.  This table is also used for
relations and properties. cvterms constitute nodes in the graph
defined by the collection of cvterms and cvterm_relationships.

=cut

__PACKAGE__->table("cvterm");

=head1 ACCESSORS

=head2 cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cvterm_cvterm_id_seq'

=head2 cv_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The cv or ontology or namespace to which
this cvterm belongs.

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 1024

A concise human-readable name or
label for the cvterm. Uniquely identifies a cvterm within a cv.

=head2 definition

  data_type: 'text'
  is_nullable: 1

A human-readable text
definition.

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

Primary identifier dbxref - The
unique global OBO identifier for this cvterm.  Note that a cvterm may
have multiple secondary dbxrefs - see also table: cvterm_dbxref.

=head2 is_obsolete

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Boolean 0=false,1=true; see
GO documentation for details of obsoletion. Note that two terms with
different primary dbxrefs may exist if one is obsolete.

=head2 is_relationshiptype

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Boolean
0=false,1=true relations or relationship types (also known as Typedefs
in OBO format, or as properties or slots) form a cv/ontology in
themselves. We use this flag to indicate whether this cvterm is an
actual term/class/universal or a relation. Relations may be drawn from
the OBO Relations ontology, but are not exclusively drawn from there.

=cut

__PACKAGE__->add_columns(
  "cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cvterm_cvterm_id_seq",
  },
  "cv_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 1024 },
  "definition",
  { data_type => "text", is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_obsolete",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "is_relationshiptype",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cvterm_id");
__PACKAGE__->add_unique_constraint("cvterm_c2", ["dbxref_id"]);
__PACKAGE__->add_unique_constraint("cvterm_c1", ["name", "cv_id", "is_obsolete"]);

=head1 RELATIONS

=head2 acquisitionprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Acquisitionprop>

=cut

__PACKAGE__->has_many(
  "acquisitionprops",
  "Bio::Chado::Schema::Result::Mage::Acquisitionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 acquisition_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::AcquisitionRelationship>

=cut

__PACKAGE__->has_many(
  "acquisition_relationships",
  "Bio::Chado::Schema::Result::Mage::AcquisitionRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 analysisfeatureprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Companalysis::Analysisfeatureprop>

=cut

__PACKAGE__->has_many(
  "analysisfeatureprops",
  "Bio::Chado::Schema::Result::Companalysis::Analysisfeatureprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 analysisprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Companalysis::Analysisprop>

=cut

__PACKAGE__->has_many(
  "analysisprops",
  "Bio::Chado::Schema::Result::Companalysis::Analysisprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesign_platformtypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesign_platformtypes",
  "Bio::Chado::Schema::Result::Mage::Arraydesign",
  { "foreign.platformtype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesign_substratetypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Arraydesign>

=cut

__PACKAGE__->has_many(
  "arraydesign_substratetypes",
  "Bio::Chado::Schema::Result::Mage::Arraydesign",
  { "foreign.substratetype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 arraydesignprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Arraydesignprop>

=cut

__PACKAGE__->has_many(
  "arraydesignprops",
  "Bio::Chado::Schema::Result::Mage::Arraydesignprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assayprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Assayprop>

=cut

__PACKAGE__->has_many(
  "assayprops",
  "Bio::Chado::Schema::Result::Mage::Assayprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterialprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Biomaterialprop>

=cut

__PACKAGE__->has_many(
  "biomaterialprops",
  "Bio::Chado::Schema::Result::Mage::Biomaterialprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialRelationship>

=cut

__PACKAGE__->has_many(
  "biomaterial_relationships",
  "Bio::Chado::Schema::Result::Mage::BiomaterialRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 biomaterial_treatments

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::BiomaterialTreatment>

=cut

__PACKAGE__->has_many(
  "biomaterial_treatments",
  "Bio::Chado::Schema::Result::Mage::BiomaterialTreatment",
  { "foreign.unittype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineCvterm>

=cut

__PACKAGE__->has_many(
  "cell_line_cvterms",
  "Bio::Chado::Schema::Result::CellLine::CellLineCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop>

=cut

__PACKAGE__->has_many(
  "cell_line_cvtermprops",
  "Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lineprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineprop>

=cut

__PACKAGE__->has_many(
  "cell_lineprops",
  "Bio::Chado::Schema::Result::CellLine::CellLineprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineRelationship>

=cut

__PACKAGE__->has_many(
  "cell_line_relationships",
  "Bio::Chado::Schema::Result::CellLine::CellLineRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 chadoprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Chadoprop>

=cut

__PACKAGE__->has_many(
  "chadoprops",
  "Bio::Chado::Schema::Result::Cv::Chadoprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contacts

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Contact::Contact>

=cut

__PACKAGE__->has_many(
  "contacts",
  "Bio::Chado::Schema::Result::Contact::Contact",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 contact_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Contact::ContactRelationship>

=cut

__PACKAGE__->has_many(
  "contact_relationships",
  "Bio::Chado::Schema::Result::Contact::ContactRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 controls

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Control>

=cut

__PACKAGE__->has_many(
  "controls",
  "Bio::Chado::Schema::Result::Mage::Control",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvprop>

=cut

__PACKAGE__->has_many(
  "cvprops",
  "Bio::Chado::Schema::Result::Cv::Cvprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cv

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cv>

=cut

__PACKAGE__->belongs_to(
  "cv",
  "Bio::Chado::Schema::Result::Cv::Cv",
  { cv_id => "cv_id" },
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

=head2 cvterm_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::CvtermDbxref>

=cut

__PACKAGE__->has_many(
  "cvterm_dbxrefs",
  "Bio::Chado::Schema::Result::Cv::CvtermDbxref",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermpath_types

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermpath>

=cut

__PACKAGE__->has_many(
  "cvtermpath_types",
  "Bio::Chado::Schema::Result::Cv::Cvtermpath",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermpath_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermpath>

=cut

__PACKAGE__->has_many(
  "cvtermpath_objects",
  "Bio::Chado::Schema::Result::Cv::Cvtermpath",
  { "foreign.object_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermpath_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermpath>

=cut

__PACKAGE__->has_many(
  "cvtermpath_subjects",
  "Bio::Chado::Schema::Result::Cv::Cvtermpath",
  { "foreign.subject_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermprop_types

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermprop>

=cut

__PACKAGE__->has_many(
  "cvtermprop_types",
  "Bio::Chado::Schema::Result::Cv::Cvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermprop>

=cut

__PACKAGE__->has_many(
  "cvtermprops",
  "Bio::Chado::Schema::Result::Cv::Cvtermprop",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_relationship_types

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::CvtermRelationship>

=cut

__PACKAGE__->has_many(
  "cvterm_relationship_types",
  "Bio::Chado::Schema::Result::Cv::CvtermRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::CvtermRelationship>

=cut

__PACKAGE__->has_many(
  "cvterm_relationship_objects",
  "Bio::Chado::Schema::Result::Cv::CvtermRelationship",
  { "foreign.object_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvterm_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::CvtermRelationship>

=cut

__PACKAGE__->has_many(
  "cvterm_relationship_subjects",
  "Bio::Chado::Schema::Result::Cv::CvtermRelationship",
  { "foreign.subject_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermsynonym_types

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermsynonym>

=cut

__PACKAGE__->has_many(
  "cvtermsynonym_types",
  "Bio::Chado::Schema::Result::Cv::Cvtermsynonym",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermsynonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermsynonym>

=cut

__PACKAGE__->has_many(
  "cvtermsynonyms",
  "Bio::Chado::Schema::Result::Cv::Cvtermsynonym",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 dbxrefprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Dbxrefprop>

=cut

__PACKAGE__->has_many(
  "dbxrefprops",
  "Bio::Chado::Schema::Result::Cv::Dbxrefprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 elements

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Element>

=cut

__PACKAGE__->has_many(
  "elements",
  "Bio::Chado::Schema::Result::Mage::Element",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 element_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::ElementRelationship>

=cut

__PACKAGE__->has_many(
  "element_relationships",
  "Bio::Chado::Schema::Result::Mage::ElementRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 elementresult_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::ElementresultRelationship>

=cut

__PACKAGE__->has_many(
  "elementresult_relationships",
  "Bio::Chado::Schema::Result::Mage::ElementresultRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 environment_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm>

=cut

__PACKAGE__->has_many(
  "environment_cvterms",
  "Bio::Chado::Schema::Result::Genetic::EnvironmentCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_cvterm_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::ExpressionCvterm>

=cut

__PACKAGE__->has_many(
  "expression_cvterm_cvterms",
  "Bio::Chado::Schema::Result::Expression::ExpressionCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_cvterm_cvterm_types

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::ExpressionCvterm>

=cut

__PACKAGE__->has_many(
  "expression_cvterm_cvterm_types",
  "Bio::Chado::Schema::Result::Expression::ExpressionCvterm",
  { "foreign.cvterm_type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expression_cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::ExpressionCvtermprop>

=cut

__PACKAGE__->has_many(
  "expression_cvtermprops",
  "Bio::Chado::Schema::Result::Expression::ExpressionCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 expressionprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::Expressionprop>

=cut

__PACKAGE__->has_many(
  "expressionprops",
  "Bio::Chado::Schema::Result::Expression::Expressionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 features

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureCvterm>

=cut

__PACKAGE__->has_many(
  "feature_cvterms",
  "Bio::Chado::Schema::Result::Sequence::FeatureCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureCvtermprop>

=cut

__PACKAGE__->has_many(
  "feature_cvtermprops",
  "Bio::Chado::Schema::Result::Sequence::FeatureCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_expressionprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::FeatureExpressionprop>

=cut

__PACKAGE__->has_many(
  "feature_expressionprops",
  "Bio::Chado::Schema::Result::Expression::FeatureExpressionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_genotypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::FeatureGenotype>

=cut

__PACKAGE__->has_many(
  "feature_genotypes",
  "Bio::Chado::Schema::Result::Genetic::FeatureGenotype",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featuremaps

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Map::Featuremap>

=cut

__PACKAGE__->has_many(
  "featuremaps",
  "Bio::Chado::Schema::Result::Map::Featuremap",
  { "foreign.unittype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 featureprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::Featureprop>

=cut

__PACKAGE__->has_many(
  "featureprops",
  "Bio::Chado::Schema::Result::Sequence::Featureprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_pubprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeaturePubprop>

=cut

__PACKAGE__->has_many(
  "feature_pubprops",
  "Bio::Chado::Schema::Result::Sequence::FeaturePubprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureRelationship>

=cut

__PACKAGE__->has_many(
  "feature_relationships",
  "Bio::Chado::Schema::Result::Sequence::FeatureRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_relationshipprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureRelationshipprop>

=cut

__PACKAGE__->has_many(
  "feature_relationshipprops",
  "Bio::Chado::Schema::Result::Sequence::FeatureRelationshipprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genotypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Genotype>

=cut

__PACKAGE__->has_many(
  "genotypes",
  "Bio::Chado::Schema::Result::Genetic::Genotype",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genotypeprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Genotypeprop>

=cut

__PACKAGE__->has_many(
  "genotypeprops",
  "Bio::Chado::Schema::Result::Genetic::Genotypeprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraries

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::Library>

=cut

__PACKAGE__->has_many(
  "libraries",
  "Bio::Chado::Schema::Result::Library::Library",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryCvterm>

=cut

__PACKAGE__->has_many(
  "library_cvterms",
  "Bio::Chado::Schema::Result::Library::LibraryCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraryprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::Libraryprop>

=cut

__PACKAGE__->has_many(
  "libraryprops",
  "Bio::Chado::Schema::Result::Library::Libraryprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiments

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment>

=cut

__PACKAGE__->has_many(
  "nd_experiments",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experimentprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentprop>

=cut

__PACKAGE__->has_many(
  "nd_experimentprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stocks

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stocks",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_stockprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockprop>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stockprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStockprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_geolocationprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop>

=cut

__PACKAGE__->has_many(
  "nd_geolocationprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_protocols

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdProtocol>

=cut

__PACKAGE__->has_many(
  "nd_protocols",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdProtocol",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_protocolprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdProtocolprop>

=cut

__PACKAGE__->has_many(
  "nd_protocolprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdProtocolprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_protocol_reagents

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdProtocolReagent>

=cut

__PACKAGE__->has_many(
  "nd_protocol_reagents",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdProtocolReagent",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagents

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagent>

=cut

__PACKAGE__->has_many(
  "nd_reagents",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagent",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagentprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop>

=cut

__PACKAGE__->has_many(
  "nd_reagentprops",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagentprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_reagent_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship>

=cut

__PACKAGE__->has_many(
  "nd_reagent_relationships",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 organismprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Organism::Organismprop>

=cut

__PACKAGE__->has_many(
  "organismprops",
  "Bio::Chado::Schema::Result::Organism::Organismprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phendescs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Phendesc>

=cut

__PACKAGE__->has_many(
  "phendescs",
  "Bio::Chado::Schema::Result::Genetic::Phendesc",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_assays

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_assays",
  "Bio::Chado::Schema::Result::Phenotype::Phenotype",
  { "foreign.assay_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attrs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_attrs",
  "Bio::Chado::Schema::Result::Phenotype::Phenotype",
  { "foreign.attr_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_observables

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_observables",
  "Bio::Chado::Schema::Result::Phenotype::Phenotype",
  { "foreign.observable_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_cvalues

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotype>

=cut

__PACKAGE__->has_many(
  "phenotype_cvalues",
  "Bio::Chado::Schema::Result::Phenotype::Phenotype",
  { "foreign.cvalue_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparisonCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_cvterms",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparisonCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::PhenotypeCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_cvterms",
  "Bio::Chado::Schema::Result::Phenotype::PhenotypeCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotypeprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotypeprop>

=cut

__PACKAGE__->has_many(
  "phenotypeprops",
  "Bio::Chado::Schema::Result::Phenotype::Phenotypeprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Bio::Chado::Schema::Result::Genetic::Phenstatement",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonodes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::Phylonode>

=cut

__PACKAGE__->has_many(
  "phylonodes",
  "Bio::Chado::Schema::Result::Phylogeny::Phylonode",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonodeprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::Phylonodeprop>

=cut

__PACKAGE__->has_many(
  "phylonodeprops",
  "Bio::Chado::Schema::Result::Phylogeny::Phylonodeprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylonode_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::PhylonodeRelationship>

=cut

__PACKAGE__->has_many(
  "phylonode_relationships",
  "Bio::Chado::Schema::Result::Phylogeny::PhylonodeRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phylotrees

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phylogeny::Phylotree>

=cut

__PACKAGE__->has_many(
  "phylotrees",
  "Bio::Chado::Schema::Result::Phylogeny::Phylotree",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projectprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::Projectprop>

=cut

__PACKAGE__->has_many(
  "projectprops",
  "Bio::Chado::Schema::Result::Project::Projectprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::ProjectRelationship>

=cut

__PACKAGE__->has_many(
  "project_relationships",
  "Bio::Chado::Schema::Result::Project::ProjectRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocols

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Protocol>

=cut

__PACKAGE__->has_many(
  "protocols",
  "Bio::Chado::Schema::Result::Mage::Protocol",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocolparam_unittypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Protocolparam>

=cut

__PACKAGE__->has_many(
  "protocolparam_unittypes",
  "Bio::Chado::Schema::Result::Mage::Protocolparam",
  { "foreign.unittype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 protocolparam_datatypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Protocolparam>

=cut

__PACKAGE__->has_many(
  "protocolparam_datatypes",
  "Bio::Chado::Schema::Result::Mage::Protocolparam",
  { "foreign.datatype_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::Pub>

=cut

__PACKAGE__->has_many(
  "pubs",
  "Bio::Chado::Schema::Result::Pub::Pub",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pubprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::Pubprop>

=cut

__PACKAGE__->has_many(
  "pubprops",
  "Bio::Chado::Schema::Result::Pub::Pubprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pub_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Pub::PubRelationship>

=cut

__PACKAGE__->has_many(
  "pub_relationships",
  "Bio::Chado::Schema::Result::Pub::PubRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantificationprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Quantificationprop>

=cut

__PACKAGE__->has_many(
  "quantificationprops",
  "Bio::Chado::Schema::Result::Mage::Quantificationprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 quantification_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::QuantificationRelationship>

=cut

__PACKAGE__->has_many(
  "quantification_relationships",
  "Bio::Chado::Schema::Result::Mage::QuantificationRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stocks

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stock>

=cut

__PACKAGE__->has_many(
  "stocks",
  "Bio::Chado::Schema::Result::Stock::Stock",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollections

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stockcollection>

=cut

__PACKAGE__->has_many(
  "stockcollections",
  "Bio::Chado::Schema::Result::Stock::Stockcollection",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollectionprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stockcollectionprop>

=cut

__PACKAGE__->has_many(
  "stockcollectionprops",
  "Bio::Chado::Schema::Result::Stock::Stockcollectionprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockCvterm>

=cut

__PACKAGE__->has_many(
  "stock_cvterms",
  "Bio::Chado::Schema::Result::Stock::StockCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockCvtermprop>

=cut

__PACKAGE__->has_many(
  "stock_cvtermprops",
  "Bio::Chado::Schema::Result::Stock::StockCvtermprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_dbxrefprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockDbxrefprop>

=cut

__PACKAGE__->has_many(
  "stock_dbxrefprops",
  "Bio::Chado::Schema::Result::Stock::StockDbxrefprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stockprop>

=cut

__PACKAGE__->has_many(
  "stockprops",
  "Bio::Chado::Schema::Result::Stock::Stockprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationships

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationship>

=cut

__PACKAGE__->has_many(
  "stock_relationships",
  "Bio::Chado::Schema::Result::Stock::StockRelationship",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationshipCvterm>

=cut

__PACKAGE__->has_many(
  "stock_relationship_cvterms",
  "Bio::Chado::Schema::Result::Stock::StockRelationshipCvterm",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studydesignprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Studydesignprop>

=cut

__PACKAGE__->has_many(
  "studydesignprops",
  "Bio::Chado::Schema::Result::Mage::Studydesignprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyfactors

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Studyfactor>

=cut

__PACKAGE__->has_many(
  "studyfactors",
  "Bio::Chado::Schema::Result::Mage::Studyfactor",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Studyprop>

=cut

__PACKAGE__->has_many(
  "studyprops",
  "Bio::Chado::Schema::Result::Mage::Studyprop",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyprop_features

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::StudypropFeature>

=cut

__PACKAGE__->has_many(
  "studyprop_features",
  "Bio::Chado::Schema::Result::Mage::StudypropFeature",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::Synonym>

=cut

__PACKAGE__->has_many(
  "synonyms",
  "Bio::Chado::Schema::Result::Sequence::Synonym",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 treatments

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Treatment>

=cut

__PACKAGE__->has_many(
  "treatments",
  "Bio::Chado::Schema::Result::Mage::Treatment",
  { "foreign.type_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-07 13:19:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cPH9EGtsJO7PK5U3UZ9LvA

use Carp;

=head1 ADDITIONAL RELATIONS

=head2 cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermprop>

This C<cvtermprops> relation is a convenient synonym for the
autogenerated L</cvtermprop_cvterms> above, since most often you want
the properties for the cvterm itself.

If you really do want the Cvtermprop rows that have this cvterm as
their B<type>, use C<cvtermprop_types>, listed above.

=cut

__PACKAGE__->has_many(
  "cvtermprops",
  "Bio::Chado::Schema::Result::Cv::Cvtermprop",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cvtermsynonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Cv::Cvtermsynonym>

=cut
__PACKAGE__->has_many(
  "cvtermsynonyms",
  "Bio::Chado::Schema::Result::Cv::Cvtermsynonym",
  { "foreign.cvterm_id" => "self.cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


=head1 ADDITIONAL METHODS

=head2 add_synonym

 Usage:        $self->add_synonym($synonym , { type => 'exact' , autocreate => 1} );
 Desc:         adds the synonym $new_synonym to this cvterm
               If the synonym $new_synonym already exists,
               nothing is added.
 Args:         a synonym name  and
    options hashref as:
          {
            synonym_type => [e.g. exact, narrow, broad, related],
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given synonym name.  Default false.

            cv_name => cv.name to use for the given synonym type.
                       Defaults to 'synonym_type',

            db_name => db.name to use for autocreated dbxrefs,
                       default 'null',

            definitions => optional hashref of:
                { cvterm_name => definition,
                }
             to load into the cvterm table when autocreating cvterms
          }
 Ret:          a Cvtermsynonym object

=cut

sub add_synonym {
    my ($self, $synonym, $opts) = @_;
    my $schema = $self->result_source->schema;
    $opts ||= {};
    $opts->{cv_name} = 'synonym_type'
        unless defined $opts->{cv_name};
    $opts->{db_name} = 'null'
        unless defined $opts->{db_name};
    $opts->{dbxref_accession_prefix} = 'autocreated:'
        unless defined $opts->{dbxref_accession_prefix};
    my $data;
    $data->{synonym} = $synonym;

    if (defined $opts->{synonym_type} ) {
      my $synonym_type= $opts->{synonym_type} ;
      my $synonym_db; #< set as needed below
      my $synonym_cv = do {
          my $cvrs = $schema->resultset('Cv::Cv');
          my $find_or_create = $opts->{autocreate} ? 'find_or_create' : 'find';
          $cvrs->$find_or_create({ name => $opts->{cv_name}},
                           { key => 'cv_c1' })
            or croak "cv '$opts->{cv_name}' not found and autocreate option not passed, cannot continue";
      };

      # find/create cvterm and dbxref for the synonym,

      my $existing_cvterm =
            $synonym_cv->find_related('cvterms',
                              { name => $synonym_type,
                              is_obsolete => 0,
                              },
                              { key => 'cvterm_c1' },
          );

        # if there is no existing cvterm for this synonym type, and we
        # have the autocreate flag set true, then create a cvterm,
        # dbxref, and db for it if necessary
        unless( $existing_cvterm ) {
            $opts->{autocreate}
          or croak "cvterm not found for cvterm synonym type  '$synonym_type', and autocreate option not passed, cannot continue";

            # look up the db object if we don't already have it, now
            # that we know we need it
            $synonym_db ||=
                $self->result_source->schema
            ->resultset('General::Db')
            ->find_or_create( { name => $opts->{db_name} },
                          { key => 'db_c1' }
            );

            # find or create the dbxref for this cvterm we are about
            # to create
            my $dbx_acc = $synonym_type;
            my $dbxref =
                $synonym_db->find_or_create_related('dbxrefs',{ accession => $dbx_acc })
            || $synonym_db->create_related('dbxrefs',{ accession => $dbx_acc,
                                             version => 1,
                                     });

            # look up any definition we might have been given for this
            # propname, so we can insert it if given
            my $def = $opts->{definition};


          my $synonym_type_cvterm= $synonym_cv->create_related('cvterms',
                                                 { name => $synonym_type,
                                                   is_obsolete => 0,
                                                   dbxref_id => $dbxref->dbxref_id,
                                                   $def ? (definition => $def) : (),
                                                 }
            );
          $data->{type_id} = $synonym_type_cvterm->cvterm_id();
        } else {
          $data->{type_id} = $existing_cvterm->cvterm_id();
      }
    }

    my ($cvtermsynonym)= $self->search_related('cvtermsynonyms', {
      type_id => $data->{type_id} })->
          search({ 'lower(synonym)'   => {like => lc($synonym) } } );

#search({ 'lower(synonym)' => { like => 'blah'}})
#my $rs = $c->model("DB::Dbentry")->$search({
#'lower('.$key.')' => $q },

#search({ \'lower(synonym)' => { like => 'blah'}})
    $cvtermsynonym= $self->create_related('cvtermsynonyms' , $data) unless defined $cvtermsynonym;

    return $cvtermsynonym;
}


=head2 delete_synonym

 Usage: $self->delete_synonym($synonym)
 Desc:  delete synonym $synonym from cvterm object
  Ret:  nothing
 Args: $synonym
 Side Effects: Will delete all cvtermsynonyms with synonym=$synonym. Case insensitive

=cut

sub delete_synonym {
    my $self=shift;
    my $synonym=shift;

    my $schema = $self->result_source->schema;

    $self->result_source
         ->schema
         ->resultset("Cv::Cvtermsynonym")
         ->search( { cvterm_id => $self->get_column('cvterm_id'),
            synonym   => { 'like' , lc($synonym) }
        })
        ->delete();
}



=head2 get_secondary_dbxrefs

 Usage: $self->get_secondary_dbxrefs()
 Desc:  find all secondary accessions associated with the cvterm
         These are stored in cvterm_dbxref table as dbxref_ids
 Ret:    a list of accessions (e.g. GO:0000123)
 Args:   none
 Side Effects: none

=cut

sub get_secondary_dbxrefs {
    my $self=shift;
    my $schema = $self->result_source->schema;
    my @list;
    my @s =  $self->search_related('cvterm_dbxrefs' , { is_for_definition => 0} );
    foreach (@s) {
      my $accession = $_->dbxref->accession;
      my $db_name = $_->dbxref->db->name;
      push @list, $db_name . ":" .  $accession;
    }
    return @list;
}


=head2 add_secondary_dbxref

 Usage: $self->add_secondary_dbxref(accession, 1)
 Desc:  add an alternative id to cvterm. Stores in cvterm_dbxref
 Ret:   a CvtermDbxref object
 Args:  an alternative id (i.e. "GO:0001234"). A second arg will store a is_for_definition=1 (default = 0)
 Side Effects: stores a new dbxref if accession is not found in dbxref table

=cut

sub add_secondary_dbxref {
    my ($self, $accession, $def)=@_;
    $def = 0 if !$def;

    my $schema = $self->result_source->schema;
    my ($db_name, $acc) = split (/:/, $accession);
    if (!$db_name || !$acc) { croak "Accession must be of the form <DB>:<ACCESSION>.  You passed '$accession'" ; }
    my $db = $schema->resultset("General::Db")->find_or_create(
      { name => $db_name },
      { key => 'db_c1' }
      );
    my $dbxref =
         $db->search_related('dbxrefs', { accession => $acc })->first
      || $db->create_related('dbxrefs', { accession => $acc });

    my $cvterm_dbxref = $schema->resultset("Cv::CvtermDbxref")->search(
      { dbxref_id => $dbxref->get_column('dbxref_id'),
        cvterm_id => $self->get_column('cvterm_id') }
      )->first();
    if ($cvterm_dbxref) {
      $cvterm_dbxref->update( { is_for_definition => $def } ) if $def;
    }else {
      $cvterm_dbxref = $schema->resultset("Cv::CvtermDbxref")->create(
          { dbxref_id => $dbxref->get_column('dbxref_id'),
            cvterm_id => $self->get_column('cvterm_id'),
            is_for_definition => $def,
          } );
    }
    return $cvterm_dbxref;
}


=head2 delete_secondary_dbxref

 Usage: $self->delete_secondary_dbxref($accession)
 Desc:  delete a cvterm_dbxref from the database
 Ret:   nothing
 Args:  full accession (db_name:dbxref_accession e.g. PO:0001234)
 Side Effects:

=cut

sub delete_secondary_dbxref {
    my $self=shift;
    my $accession=shift;
    my $schema = $self->result_source->schema;
    my ($db_name, $acc) = split (/:/, $accession);
    if (!$db_name || !$accession) { croak "Did not pass a legal accession! ($accession)" ; }

    my ($cvterm_dbxref) = $schema->resultset("General::Db")->search(
      { name => $db_name } )->
      search_related('dbxrefs' , { accession => $acc } )->
      search_related('cvterm_dbxrefs', { cvterm_id => $self->get_column('cvterm_id') } );
    if ($cvterm_dbxref) { $cvterm_dbxref->delete() ; }

}


=head2 create_cvtermprops

  Usage: $set->create_cvtermprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create cvterm properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given cvtermprop name.  Default false.

            cv_name => cv.name to use for the given cvtermprops.
                       Defaults to 'cvterm_property',

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
                and value in the properties of the cvterm.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new cvtermprop object }

=cut

sub create_cvtermprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'cvterm_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'cvtermprops',
        );
}


=head2 root

 Usage: $self->root
 Desc:  find the root cvterm
 Ret:   Cvterm object
 Args:  none

NOTE: This method requires that your C<cvtermpath> table is populated.

=cut

sub root {
    my $self = shift;
    my $root = $self->search_related('cvtermpath_subjects',
                                     {} ,
                                     {
                                       order_by => { -desc => 'pathdistance'},
                                       rows     => 1,
                                     }
                                    )
                    ->single
                    ->find_related('object' , {});

    return $root;
}

=head2 children

 Usage: $self->children
 Desc:  find the direct children of the cvterm

 Ret: L<Bio::Chado::Schema::Result::Cv::CvtermRelationship> resultset of the
      fetched child terms (this can be used in your program to find the
       relationship type id of each child term)
 Args:  none

=cut

sub children {
    shift->search_related('cvterm_relationship_objects');
}

=head2 direct_children

 Usage: $self->direct_children
 Desc:  find only the direct children of your term
 Ret:   L<Bio::Chado::Schema::Result::Cv::Cvterm>
 Args:  none
 Side Effects: none

NOTE: This method requires that your C<cvtermpath> table is populated.

=cut

sub direct_children {
    my $self = shift;
    return
        $self->search_related (
            'cvtermpath_subjects',
            {
                pathdistance => { '<' =>  0 },
            } )->search_related('object');
}

#the same using cvtermpath
# return $self->search_related('cvtermpath_objects' , undef , {
#pathdistance => 1 ,  }
#);

=head2 recursive_children

 Usage: $self->recursive_children
 Desc:   find all the descendants of the cvterm (children, children of children, and so on)
 Ret: a DBIC resultset of L<Bio::Chado::Schema::Result::Cv::Cvterm>
 Args: none
 Side Effects: none

NOTE: This method requires that your C<cvtermpath> table is populated.

=cut

sub recursive_children {
    my $self = shift;
    return
        $self->search_related(
            'cvtermpath_objects',
            {
                pathdistance => { '>' =>  0 },
            }
        )->search_related('subject');
}


=head2 parents

 Usage: my $self->parents
 Desc:  Find the direct parents of the cvterm
 Ret:  L<Bio::Chado::Schema::Result::Cv::CvtermRelationship> resultset of the parent terms
 Args:  none
 Side Effects: none

=cut

sub parents {
    shift->search_related('cvterm_relationship_subjects');
}

=head2 direct_parents

 Usage: $self->direct_parents
 Desc:  get only the direct parents of the cvterm (from the cvtermpath)
 Ret:   L<Bio::Chado::Schema::Result::Cv::Cvterm>
 Args:  none
 Side Effects: none

NOTE: This method requires that your C<cvtermpath> table is populated.

=cut

sub direct_parents {
    my $self = shift;
    return
        $self->search_related(
            'cvtermpath_objects',
            {
                pathdistance => { '<' => 0 } ,
            } )->search_related( 'subject');
}

=head2 recursive_parents

 Usage: $self->recursive_parents
 Desc:   find all the ancestors of the cvterm (parents, parents of parents, and so on)
 Ret: L<Bio::Chado::Schema::Result::Cv::Cvterm> resultset
 Args: none
 Side Effects: none

NOTE: This method requires that your C<cvtermpath> table is populated.

=cut

sub recursive_parents {
    my $self = shift;
    return
        $self->search_related(
            'cvtermpath_subjects',
            {
                pathdistance => { '>' =>  0 } ,
            } )->search_related( 'object');
}

############ CVTERM CUSTOM RESULTSET PACKAGE #############################


__PACKAGE__->resultset_class('Bio::Chado::Schema::Result::Cv::Cvterm::ResultSet');
package Bio::Chado::Schema::Result::Cv::Cvterm::ResultSet;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::Cvterm::ResultSet::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::Cvterm::ResultSet::VERSION = '0.20000';
}
use base qw/ DBIx::Class::ResultSet /;

use Carp;

=head2 create_with

 Usage: $schema->resultset('Cv::Cvterm')->create_with(
                  { name   => 'cvterm name',
                    cv     => $cv  || 'cv name',
                    db     => $db  || 'db name',
                    dbxref => $dbx || 'accession',
                  });

 Desc: convenience method to create a cvterm, linking it to the CV and
       DB that you name or provide.  For any cv, db, or dbxref that
       you call only by name, does a find_or_create() using that name.
 Ret : a new Cvterm row
 Args: hashref of:
         { name   => 'cvterm name',
           cv     => 'cv name' or L<Bio::Chado::Schema::Result::Cv::Cvterm> row,
           db     => 'db name' or L<Bio::Chado::Schema::Result::General::Db> row,
           dbxref => 'accession' or L<Bio::Chado::Schema::Result::General::Dbxref> row,
         }

=cut

sub create_with {
    my ($self, $opts) = @_;
    $opts or croak 'must provide a hashref of values to create_with';
    $opts->{name} or croak 'must provide a name for the new cvterm';

    # cv and db default to 'null'
    $opts->{cv} = 'null' unless defined $opts->{cv};
    $opts->{db} = 'null' unless defined $opts->{db};

    # dbxref defaults to autocreated:<cvterm_name>
    $opts->{dbxref} = 'autocreated:'.$opts->{name}
        unless defined $opts->{dbxref};

    # if cv, dbxref, or db are row objects, make sure that they are
    # actually stored in the db, since we need to make foreign key
    # relationships to them
    $_->insert_or_update
      for grep ref, @{$opts}{qw| cv dbxref db |};

    my $schema = $self->result_source->schema;

    # use, find, or create the given cv
    my $cv = ref $opts->{cv} ? $opts->{cv}
                           : $schema->resultset('Cv::Cv')
                              ->find_or_create({ name => $opts->{cv} });

    # return our cvterm if it exists already
    if( my $cvterm = $cv->find_related( 'cvterms',
                              {
                                  name => $opts->{name},
                                  is_obsolete => '0',
                              }) ) {
      return $cvterm;
    }

    # now figure out which dbxref to use (creating the dbxref and db if necessary)
    my $dbx = _find_dbxref( $schema, $opts->{dbxref}, $opts->{db} );

    # and finally make a cvterm to go with the cv and dbxref we found
    return $cv->create_related( 'cvterms',
                        { name => $opts->{name},
                          dbxref_id => $dbx->dbxref_id,
                          }
      );
}
sub _find_dbxref {
    my ( $schema, $dbx, $db ) = @_;

    # if we have a dbxref object to begin with, use it
    return $dbx if ref $dbx;

    ### otherwise, need to find the db
    unless( ref $db ) {
      # convert db name string into object if necessary
      $db = $schema->resultset('General::Db')
                   ->find_or_create({ name => $db });
    }

    #now find or create the dbxref from the db
    return $db->find_or_create_related('dbxrefs',
                               { accession => $dbx },
                              );
}



1;
