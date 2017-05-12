package Bio::Chado::Schema::Result::CellLine::CellLineCvterm;
BEGIN {
  $Bio::Chado::Schema::Result::CellLine::CellLineCvterm::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::CellLine::CellLineCvterm::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::CellLine::CellLineCvterm

=cut

__PACKAGE__->table("cell_line_cvterm");

=head1 ACCESSORS

=head2 cell_line_cvterm_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_cvterm_cell_line_cvterm_id_seq'

=head2 cell_line_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cell_line_cvterm_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_cvterm_cell_line_cvterm_id_seq",
  },
  "cell_line_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cell_line_cvterm_id");
__PACKAGE__->add_unique_constraint(
  "cell_line_cvterm_c1",
  ["cell_line_id", "cvterm_id", "pub_id", "rank"],
);

=head1 RELATIONS

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

=head2 cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "cvterm",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "cvterm_id" },
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

=head2 cell_line_cvtermprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop>

=cut

__PACKAGE__->has_many(
  "cell_line_cvtermprops",
  "Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop",
  { "foreign.cell_line_cvterm_id" => "self.cell_line_cvterm_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kZg/ltnvnaPkOeWCuGCX8g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
