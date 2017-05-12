package Bio::Chado::Schema::Result::CellLine::CellLineSynonym;
BEGIN {
  $Bio::Chado::Schema::Result::CellLine::CellLineSynonym::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::CellLine::CellLineSynonym::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::CellLine::CellLineSynonym

=cut

__PACKAGE__->table("cell_line_synonym");

=head1 ACCESSORS

=head2 cell_line_synonym_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_synonym_cell_line_synonym_id_seq'

=head2 cell_line_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 synonym_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_current

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_internal

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cell_line_synonym_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_synonym_cell_line_synonym_id_seq",
  },
  "cell_line_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "synonym_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_current",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_internal",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cell_line_synonym_id");
__PACKAGE__->add_unique_constraint(
  "cell_line_synonym_c1",
  ["synonym_id", "cell_line_id", "pub_id"],
);

=head1 RELATIONS

=head2 synonym

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Synonym>

=cut

__PACKAGE__->belongs_to(
  "synonym",
  "Bio::Chado::Schema::Result::Sequence::Synonym",
  { synonym_id => "synonym_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 pub

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Pub::Pub>

=cut

__PACKAGE__->belongs_to(
  "pub",
  "Bio::Chado::Schema::Result::Pub::Pub",
  { pub_id => "pub_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 cell_line

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLine>

=cut

__PACKAGE__->belongs_to(
  "cell_line",
  "Bio::Chado::Schema::Result::CellLine::CellLine",
  { cell_line_id => "cell_line_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2ZA98OhhDkZM4pVj6oXMkw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
