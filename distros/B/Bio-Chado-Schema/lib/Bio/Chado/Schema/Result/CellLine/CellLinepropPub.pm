package Bio::Chado::Schema::Result::CellLine::CellLinepropPub;
BEGIN {
  $Bio::Chado::Schema::Result::CellLine::CellLinepropPub::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::CellLine::CellLinepropPub::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::CellLine::CellLinepropPub

=cut

__PACKAGE__->table("cell_lineprop_pub");

=head1 ACCESSORS

=head2 cell_lineprop_pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cell_lineprop_pub_cell_lineprop_pub_id_seq'

=head2 cell_lineprop_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cell_lineprop_pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cell_lineprop_pub_cell_lineprop_pub_id_seq",
  },
  "cell_lineprop_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cell_lineprop_pub_id");
__PACKAGE__->add_unique_constraint("cell_lineprop_pub_c1", ["cell_lineprop_id", "pub_id"]);

=head1 RELATIONS

=head2 cell_lineprop

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::CellLine::CellLineprop>

=cut

__PACKAGE__->belongs_to(
  "cell_lineprop",
  "Bio::Chado::Schema::Result::CellLine::CellLineprop",
  { cell_lineprop_id => "cell_lineprop_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w1sepj/CYEKGjTKbcNTy2w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
