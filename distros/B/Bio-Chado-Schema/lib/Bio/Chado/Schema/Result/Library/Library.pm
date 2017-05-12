package Bio::Chado::Schema::Result::Library::Library;
BEGIN {
  $Bio::Chado::Schema::Result::Library::Library::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Library::Library::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Library::Library

=cut

__PACKAGE__->table("library");

=head1 ACCESSORS

=head2 library_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'library_library_id_seq'

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

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

The type_id foreign key links
to a controlled vocabulary of library types. Examples of this would be: "cDNA_library" or "genomic_library"

=head2 is_obsolete

  data_type: 'integer'
  default_value: 0
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
  "library_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "library_library_id_seq",
  },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_obsolete",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
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
__PACKAGE__->set_primary_key("library_id");
__PACKAGE__->add_unique_constraint("library_c1", ["organism_id", "uniquename", "type_id"]);

=head1 RELATIONS

=head2 cell_line_libraries

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineLibrary>

=cut

__PACKAGE__->has_many(
  "cell_line_libraries",
  "Bio::Chado::Schema::Result::CellLine::CellLineLibrary",
  { "foreign.library_id" => "self.library_id" },
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

=head2 library_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryCvterm>

=cut

__PACKAGE__->has_many(
  "library_cvterms",
  "Bio::Chado::Schema::Result::Library::LibraryCvterm",
  { "foreign.library_id" => "self.library_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_dbxrefs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryDbxref>

=cut

__PACKAGE__->has_many(
  "library_dbxrefs",
  "Bio::Chado::Schema::Result::Library::LibraryDbxref",
  { "foreign.library_id" => "self.library_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_features

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryFeature>

=cut

__PACKAGE__->has_many(
  "library_features",
  "Bio::Chado::Schema::Result::Library::LibraryFeature",
  { "foreign.library_id" => "self.library_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraryprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::Libraryprop>

=cut

__PACKAGE__->has_many(
  "libraryprops",
  "Bio::Chado::Schema::Result::Library::Libraryprop",
  { "foreign.library_id" => "self.library_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibraryPub>

=cut

__PACKAGE__->has_many(
  "library_pubs",
  "Bio::Chado::Schema::Result::Library::LibraryPub",
  { "foreign.library_id" => "self.library_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibrarySynonym>

=cut

__PACKAGE__->has_many(
  "library_synonyms",
  "Bio::Chado::Schema::Result::Library::LibrarySynonym",
  { "foreign.library_id" => "self.library_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fLTH97E8H695k2TFazyY8A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
