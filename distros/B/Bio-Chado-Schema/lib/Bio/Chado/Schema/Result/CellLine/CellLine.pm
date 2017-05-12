package Bio::Chado::Schema::Result::CellLine::CellLine;
BEGIN {
  $Bio::Chado::Schema::Result::CellLine::CellLine::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::CellLine::CellLine::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::CellLine::CellLine

=cut

__PACKAGE__->table("cell_line");

=head1 ACCESSORS

=head2 cell_line_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_cell_line_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 timeaccessioned

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 timelastmodified

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "cell_line_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_cell_line_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "timeaccessioned",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "timelastmodified",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("cell_line_id");
__PACKAGE__->add_unique_constraint("cell_line_c1", ["uniquename", "organism_id"]);

=head1 RELATIONS

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
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 cell_line_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineCvterm>

=cut

__PACKAGE__->has_many(
  "cell_line_cvterms",
  "Bio::Chado::Schema::Result::CellLine::CellLineCvterm",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineDbxref>

=cut

__PACKAGE__->has_many(
  "cell_line_dbxrefs",
  "Bio::Chado::Schema::Result::CellLine::CellLineDbxref",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_features

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineFeature>

=cut

__PACKAGE__->has_many(
  "cell_line_features",
  "Bio::Chado::Schema::Result::CellLine::CellLineFeature",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_libraries

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineLibrary>

=cut

__PACKAGE__->has_many(
  "cell_line_libraries",
  "Bio::Chado::Schema::Result::CellLine::CellLineLibrary",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_lineprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineprop>

=cut

__PACKAGE__->has_many(
  "cell_lineprops",
  "Bio::Chado::Schema::Result::CellLine::CellLineprop",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLinePub>

=cut

__PACKAGE__->has_many(
  "cell_line_pubs",
  "Bio::Chado::Schema::Result::CellLine::CellLinePub",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_relationship_subjects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineRelationship>

=cut

__PACKAGE__->has_many(
  "cell_line_relationship_subjects",
  "Bio::Chado::Schema::Result::CellLine::CellLineRelationship",
  { "foreign.subject_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_relationship_objects

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineRelationship>

=cut

__PACKAGE__->has_many(
  "cell_line_relationship_objects",
  "Bio::Chado::Schema::Result::CellLine::CellLineRelationship",
  { "foreign.object_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 cell_line_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineSynonym>

=cut

__PACKAGE__->has_many(
  "cell_line_synonyms",
  "Bio::Chado::Schema::Result::CellLine::CellLineSynonym",
  { "foreign.cell_line_id" => "self.cell_line_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3hBZ6qxRjDZSFL0gDlrfhA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
