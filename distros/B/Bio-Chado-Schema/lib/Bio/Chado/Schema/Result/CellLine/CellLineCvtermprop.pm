package Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop;
BEGIN {
  $Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::CellLine::CellLineCvtermprop

=cut

__PACKAGE__->table("cell_line_cvtermprop");

=head1 ACCESSORS

=head2 cell_line_cvtermprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_line_cvtermprop_cell_line_cvtermprop_id_seq'

=head2 cell_line_cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cell_line_cvtermprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_line_cvtermprop_cell_line_cvtermprop_id_seq",
  },
  "cell_line_cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cell_line_cvtermprop_id");
__PACKAGE__->add_unique_constraint(
  "cell_line_cvtermprop_c1",
  ["cell_line_cvterm_id", "type_id", "rank"],
);

=head1 RELATIONS

=head2 cell_line_cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineCvterm>

=cut

__PACKAGE__->belongs_to(
  "cell_line_cvterm",
  "Bio::Chado::Schema::Result::CellLine::CellLineCvterm",
  { cell_line_cvterm_id => "cell_line_cvterm_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:crPOjTxliBbzZzhehbKAOA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
