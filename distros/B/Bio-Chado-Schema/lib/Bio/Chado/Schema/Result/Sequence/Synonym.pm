package Bio::Chado::Schema::Result::Sequence::Synonym;
BEGIN {
  $Bio::Chado::Schema::Result::Sequence::Synonym::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Sequence::Synonym::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Sequence::Synonym

=head1 DESCRIPTION

A synonym for a feature. One feature can have multiple synonyms, and the same synonym can apply to multiple features.

=cut

__PACKAGE__->table("synonym");

=head1 ACCESSORS

=head2 synonym_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'synonym_synonym_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

The synonym itself. Should be human-readable machine-searchable ascii text.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

Types would be symbol and fullname for now.

=head2 synonym_sgml

  data_type: 'varchar'
  is_nullable: 0
  size: 255

The fully specified synonym, with any non-ascii characters encoded in SGML.

=cut

__PACKAGE__->add_columns(
  "synonym_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "synonym_synonym_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "synonym_sgml",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("synonym_id");
__PACKAGE__->add_unique_constraint("synonym_c1", ["name", "type_id"]);

=head1 RELATIONS

=head2 cell_line_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineSynonym>

=cut

__PACKAGE__->has_many(
  "cell_line_synonyms",
  "Bio::Chado::Schema::Result::CellLine::CellLineSynonym",
  { "foreign.synonym_id" => "self.synonym_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureSynonym>

=cut

__PACKAGE__->has_many(
  "feature_synonyms",
  "Bio::Chado::Schema::Result::Sequence::FeatureSynonym",
  { "foreign.synonym_id" => "self.synonym_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library_synonyms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Library::LibrarySynonym>

=cut

__PACKAGE__->has_many(
  "library_synonyms",
  "Bio::Chado::Schema::Result::Library::LibrarySynonym",
  { "foreign.synonym_id" => "self.synonym_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ajt425W/w/2TgCUWIsvTAw

=head1 MANY-TO-MANY RELATIONSHIPS

=head2 features

Type: many_to_many

Related object: Bio::Chado::Schema::Result::Sequence::Feature

=cut

__PACKAGE__->many_to_many
    (
     'features',
     'feature_synonyms' => 'feature',
    );


# You can replace this text with custom content, and it will be preserved on regeneration
1;
