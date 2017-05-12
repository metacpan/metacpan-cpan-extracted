package Bio::Chado::Schema::Result::Project::Project;
BEGIN {
  $Bio::Chado::Schema::Result::Project::Project::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Project::Project::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Project::Project - Standard Chado flexible property table for projects.

=cut

__PACKAGE__->table("project");

=head1 ACCESSORS

=head2 project_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_project_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "project_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_project_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("project_id");
__PACKAGE__->add_unique_constraint("project_c1", ["name"]);

=head1 RELATIONS

=head2 assay_projects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::AssayProject>

=cut

__PACKAGE__->has_many(
  "assay_projects",
  "Bio::Chado::Schema::Result::Mage::AssayProject",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nd_experiment_projects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentProject>

=cut

__PACKAGE__->has_many(
  "nd_experiment_projects",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdExperimentProject",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_contacts

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::ProjectContact>

=cut

__PACKAGE__->has_many(
  "project_contacts",
  "Bio::Chado::Schema::Result::Project::ProjectContact",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projectprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::Projectprop>

=cut

__PACKAGE__->has_many(
  "projectprops",
  "Bio::Chado::Schema::Result::Project::Projectprop",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::ProjectPub>

=cut

__PACKAGE__->has_many(
  "project_pubs",
  "Bio::Chado::Schema::Result::Project::ProjectPub",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_relationship_subject_projects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::ProjectRelationship>

=cut

__PACKAGE__->has_many(
  "project_relationship_subject_projects",
  "Bio::Chado::Schema::Result::Project::ProjectRelationship",
  { "foreign.subject_project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 project_relationship_object_projects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Project::ProjectRelationship>

=cut

__PACKAGE__->has_many(
  "project_relationship_object_projects",
  "Bio::Chado::Schema::Result::Project::ProjectRelationship",
  { "foreign.object_project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-06 11:44:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Xm+QPuYjkvnrESy2qIgGaA


=head2 create_projectprops

  Usage: $set->create_projectprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create project properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given projectprop name.  Default false.

            cv_name => cv.name to use for the given projectprops.
                       Defaults to 'project_property',

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
                and value in the properties of the project.  Duplicate
                values will have different ranks.
          }
  Ret  : hashref of { propname => new projectprop object }

=cut

sub create_projectprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'project_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'projectprops',
        );
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
