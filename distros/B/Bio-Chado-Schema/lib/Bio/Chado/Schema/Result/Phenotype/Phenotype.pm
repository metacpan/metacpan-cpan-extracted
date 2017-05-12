package Bio::Chado::Schema::Result::Phenotype::Phenotype;
BEGIN {
  $Bio::Chado::Schema::Result::Phenotype::Phenotype::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Phenotype::Phenotype::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Phenotype::Phenotype

=head1 DESCRIPTION

A phenotypic statement, or a single
atomic phenotypic observation, is a controlled sentence describing
observable effects of non-wild type function. E.g. Obs=eye, attribute=color, cvalue=red.

=cut

__PACKAGE__->table("phenotype");

=head1 ACCESSORS

=head2 phenotype_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_phenotype_id_seq'

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 observable_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

The entity: e.g. anatomy_part, biological_process.

=head2 attr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

Phenotypic attribute (quality, property, attribute, character) - drawn from PATO.

=head2 value

  data_type: 'text'
  is_nullable: 1

Value of attribute - unconstrained free text. Used only if cvalue_id is not appropriate.

=head2 cvalue_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

Phenotype attribute value (state).

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

Evidence type.

=cut

__PACKAGE__->add_columns(
  "phenotype_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotype_phenotype_id_seq",
  },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "observable_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "attr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "cvalue_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("phenotype_id");
__PACKAGE__->add_unique_constraint("phenotype_c1", ["uniquename"]);

=head1 RELATIONS

=head2 feature_phenotypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::FeaturePhenotype>

=cut

__PACKAGE__->has_many(
  "feature_phenotypes",
  "Bio::Chado::Schema::Result::Phenotype::FeaturePhenotype",
  { "foreign.phenotype_id" => "self.phenotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_phenotypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPhenotype>

=cut

__PACKAGE__->has_many(
  "nd_experiment_phenotypes",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentPhenotype",
  { "foreign.phenotype_id" => "self.phenotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assay

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "assay",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "assay_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 attr

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "attr",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "attr_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 observable

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "observable",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "observable_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 cvalue

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvalue",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "cvalue_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 phenotype_comparison_phenotype1s

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_phenotype1s",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparison",
  { "foreign.phenotype1_id" => "self.phenotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_comparison_phenotype2s

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::PhenotypeComparison>

=cut

__PACKAGE__->has_many(
  "phenotype_comparison_phenotype2s",
  "Bio::Chado::Schema::Result::Genetic::PhenotypeComparison",
  { "foreign.phenotype2_id" => "self.phenotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::PhenotypeCvterm>

=cut

__PACKAGE__->has_many(
  "phenotype_cvterms",
  "Bio::Chado::Schema::Result::Phenotype::PhenotypeCvterm",
  { "foreign.phenotype_id" => "self.phenotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotypeprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Phenotype::Phenotypeprop>

=cut

__PACKAGE__->has_many(
  "phenotypeprops",
  "Bio::Chado::Schema::Result::Phenotype::Phenotypeprop",
  { "foreign.phenotype_id" => "self.phenotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenstatements

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Genetic::Phenstatement>

=cut

__PACKAGE__->has_many(
  "phenstatements",
  "Bio::Chado::Schema::Result::Genetic::Phenstatement",
  { "foreign.phenotype_id" => "self.phenotype_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-07 13:19:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Doe95PQkanrP5pONEXNZ0w


=head2 create_phenotypeprops

  Usage: $set->create_phenotypeprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create phenotype properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given phenotypeprop name.  Default false.

            cv_name => cv.name to use for the given phenotypeprops.
                       Defaults to 'phenotype_property',

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
                If true, allow duplicate instances of the same phenotype
                and value in the properties of the phenotype.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new phenotypeprop object }

=cut

sub create_phenotypeprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'phenotype_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'phenotypeprops',
        );
}

1;
