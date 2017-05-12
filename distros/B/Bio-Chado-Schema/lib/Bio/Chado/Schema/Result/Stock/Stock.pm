package Bio::Chado::Schema::Result::Stock::Stock;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::Stock::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::Stock::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Stock::Stock

=head1 DESCRIPTION

Any stock can be globally identified by the
combination of organism, uniquename and stock type. A stock is the physical entities, either living or preserved, held by collections. Stocks belong to a collection; they have IDs, type, organism, description and may have a genotype.

=cut

__PACKAGE__->table("stock");

=head1 ACCESSORS

=head2 stock_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_stock_id_seq'

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

The dbxref_id is an optional primary stable identifier for this stock. Secondary indentifiers and external dbxrefs go in table: stock_dbxref.

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

The organism_id is the organism to which the stock belongs. This column should only be left blank if the organism cannot be determined.

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

The name is a human-readable local name for a stock.

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

The description is the genetic description provided in the stock list.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type_id foreign key links to a controlled vocabulary of stock types. The would include living stock, genomic DNA, preserved specimen. Secondary cvterms for stocks would go in stock_cvterm.

=head2 is_obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "stock_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_stock_id_seq",
  },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("stock_id");
__PACKAGE__->add_unique_constraint("stock_c1", ["organism_id", "uniquename", "type_id"]);

=head1 RELATIONS

=head2 nd_experiment_stocks

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock>

=cut

__PACKAGE__->has_many(
  "nd_experiment_stocks",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentStock",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
    join_type      => "LEFT",
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

=head2 organism

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Organism::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "Bio::Chado::Schema::Result::Organism::Organism",
  { organism_id => "organism_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 stockcollection_stocks

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockcollectionStock>

=cut

__PACKAGE__->has_many(
  "stockcollection_stocks",
  "Bio::Chado::Schema::Result::Stock::StockcollectionStock",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockCvterm>

=cut

__PACKAGE__->has_many(
  "stock_cvterms",
  "Bio::Chado::Schema::Result::Stock::StockCvterm",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockDbxref>

=cut

__PACKAGE__->has_many(
  "stock_dbxrefs",
  "Bio::Chado::Schema::Result::Stock::StockDbxref",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_genotypes

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockGenotype>

=cut

__PACKAGE__->has_many(
  "stock_genotypes",
  "Bio::Chado::Schema::Result::Stock::StockGenotype",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stockprop>

=cut

__PACKAGE__->has_many(
  "stockprops",
  "Bio::Chado::Schema::Result::Stock::Stockprop",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockPub>

=cut

__PACKAGE__->has_many(
  "stock_pubs",
  "Bio::Chado::Schema::Result::Stock::StockPub",
  { "foreign.stock_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationship>

=cut

__PACKAGE__->has_many(
  "stock_relationship_subjects",
  "Bio::Chado::Schema::Result::Stock::StockRelationship",
  { "foreign.subject_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationship>

=cut

__PACKAGE__->has_many(
  "stock_relationship_objects",
  "Bio::Chado::Schema::Result::Stock::StockRelationship",
  { "foreign.object_id" => "self.stock_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v+GluxMkFEC508znwinNsA


=head2 create_stockprops

  Usage: $set->create_stockprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create stock properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given stockprop name.  Default false.

            cv_name => cv.name to use for the given stockprops.
                       Defaults to 'stock_property',

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
                If true, allow duplicate instances of the same stock
                and value in the properties of the stock.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new stockprop object }

=cut

sub create_stockprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'stock_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'stockprops',
        );
}


############ STOCK CUSTOM RESULTSET PACKAGE #############################


__PACKAGE__->resultset_class('Bio::Chado::Schema::Result::Stock::Stock::ResultSet');
package Bio::Chado::Schema::Result::Stock::Stock::ResultSet;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::Stock::ResultSet::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::Stock::ResultSet::VERSION = '0.20000';
}
use base qw/ DBIx::Class::ResultSet /;

use Carp;


=head1 ADDITIONAL METHODS

=head2 stock_phenotypes_rs

   Usage: $schema->resultset("Stock::Stock")->stock_phenotypes_rs($stock_rs);
   Desc:  retrieve a resultset for stock(s) with phenotyping experiments with the following values mapped to [column name]
          stock_id [stock_id]
          phenotype.value [value]
          observable.name [observable] (the cvterm name for the phenotype.observable field)
          observable_cvterm_id [observable_id]
          observable.definition [definition]
          unit_name (from phenotype_cvterm)
          cv_name (the cv_name for the phenotype_cvterm)
          type_name (the cvterm name for the phenotype_cvterm)
          method_name (a phenotypeprop value)
          dbxref.accession [accession] of the observable cvterm
          db.name of the observable cvterm [db_name] (useful for constructing the ontology ID of the observable)
          project.description [project_description] (useful for grouping phenotype values by projects)
   Args:  a L<Bio::Chado::Schema::Result::Stock::Stock>  resultset
   Ret:   a resultset with the above columns. Access the data with e.g. $rs->get_column('stock_id')

=cut

sub stock_phenotypes_rs {
    my $self = shift;
    my $stock = shift;
    my $rs = $stock->result_source->schema->resultset("Stock::Stock")->search_rs(
        {
            'observable.name' => { '!=', undef } ,
            'me.stock_id'     => {  '-in' => $stock->get_column('stock_id')->as_query },
        } , {
            join => [
                { nd_experiment_stocks => {
                    nd_experiment => {
                        nd_experiment_phenotypes => {
                            phenotype  => {
                                observable        => { dbxref   => 'db' },
                                phenotypeprops    => 'type',
                                phenotype_cvterms => { cvterm =>  'cv' }
                            },
                        },
                        nd_experiment_projects => 'project',
                    },
                  }
                } ,
                ],
            select    => [ qw/  me.stock_id phenotype.value observable.name observable.cvterm_id observable.definition phenotypeprops.value type.name dbxref.accession db.name  project.description  cv.name cvterm.name   / ],
            as        => [ qw/ stock_id value observable observable_id definition method_name type_name  accession db_name project_description cv_name unit_name / ],
            distinct  => 1,
            order_by  => [ 'project.description' , 'observable.name' ],
        }  );
    return $rs;
}

=head2 recursive_phenotypes_rs

    Usage: $schema->resultset("Stock::Stock")->recursive_phenotypes_rs($stock_rs, \@results)
    Desc: Retrieve recursively phenotypes of stock objects and their subjects
    Args: Stock resultSet and an arrayref with the results
    Ret: listref of stock_phenotypes_rs (see function stock_phenotypes_rs for columns fetched)

=cut

sub recursive_phenotypes_rs {
    my $self = shift ;
    my $stock_rs = shift;
    my $results = shift;

    my $rs = $self->stock_phenotypes_rs($stock_rs);
    push @$results, $rs ;
    my $subjects = $stock_rs->result_source->schema->resultset("Stock::Stock")->search(
        {
            'me.stock_id' => { '-in' => [ map { $_->subject_id }  $stock_rs->search_related('stock_relationship_objects')->all ] }
        } );

    if ($subjects->count ) {
        $self->recursive_phenotypes_rs($subjects, $results);
    }
    return $results;
}

=head2 stock_genotypes_rs

   Usage: $schema->resultset("Stock::Stock")->stock_genotypes_rs($stock_rs);
   Desc:  retrieve a resultset for stock(s) with genotyping experiments
          with the following values mapped to [column name]
          stock_id [stock_id]
          genotype.name [name]
          genotype.uniquname [uniquename]
          genotype.description [description]
          genotype.type.name [type_name] (the cvterm name for the genotype type)
          propvalue [propvalue] (a genotypeprop value)

   Args:  a L<Bio::Chado::Schema::Result::Stock::Stock> resultset
   Ret:   a resultset with the above columns. Access the data with e.g. $rs->get_column('stock_id')

=cut

sub stock_genotypes_rs {
    my $self = shift;
    my $stock = shift;

    my $rs = $stock->result_source->schema->resultset("Stock::Stock")->search_rs(
        {
            'genotype.uniquename' => { '!=', undef } ,
            'me.stock_id'     => { '-in' => $stock->get_column('stock_id')->as_query },
        } , {
            join => [
                { nd_experiment_stocks => {
                    nd_experiment => {
                        nd_experiment_genotypes => {
                            genotype  => {
                                genotypeprops    => 'type',
                            },
                            'type',
                        },
                    },
                  }
                } ,
                ],
            select    => [ qw/  stock_id genotype.name genotype.uniquename genotype.description type.name genotypeprops.value   / ],
            as        => [ qw/ stock_id name uniquename description type_name propvalue / ],
            distinct  => 1,
            order_by  => [],
        }  );
    return $rs;
}


=head2 stock_project_phenotypes

   Usage: $schema->resultset("Stock::Stock")->stock_project_phenotypes($stock_rs);
   Desc:  retrieve a list of phenotype resultsets by project name
   Args:  a L<Bio::Chado::Schema::Result::Stock::Stock> object or a stock resultset
   Ret:   hashref key = project descriptions, values = hash ref of
          {phenotypes} = phenotype resultset
          {project}   =  L<Bio::Chado::Schema::Result::Project::Project> object

=cut

sub stock_project_phenotypes {
    my $self = shift;
    my $stock = shift;

    my %phenotypes;
    my $project_rs = $stock->search_related('nd_experiment_stocks')
        ->search_related('nd_experiment')
        ->search_related('nd_experiment_projects')
        ->search_related('project' , {} , { distinct =>1 } );

    while (my $project = $project_rs->next) {
        my $experiment_rs = $stock->search_related('nd_experiment_stocks')
            ->search_related('nd_experiment' ,
                             { 'project.project_id' => $project->project_id },
                             { prefetch => { 'nd_experiment_projects' => 'project' } },
            );
        $phenotypes{ $project->description }->{project} = $project;
        my $nd_exp_phen_rs =  $experiment_rs->search_related('nd_experiment_phenotypes');
        my $phenotype_rs = $nd_exp_phen_rs->search_related('phenotype') if $nd_exp_phen_rs;
        $phenotypes{ $project->description }->{phenotypes} = $phenotype_rs;
    }
    return \%phenotypes;
}

1;

