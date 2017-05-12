package Bio::Chado::Schema::Result::Phylogeny::PhylotreePub;
BEGIN {
  $Bio::Chado::Schema::Result::Phylogeny::PhylotreePub::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Phylogeny::PhylotreePub::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Phylogeny::PhylotreePub

=head1 DESCRIPTION

Tracks citations global to the tree e.g. multiple sequence alignment supporting tree construction.

=cut

__PACKAGE__->table("phylotree_pub");

=head1 ACCESSORS

=head2 phylotree_pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phylotree_pub_phylotree_pub_id_seq'

=head2 phylotree_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phylotree_pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phylotree_pub_phylotree_pub_id_seq",
  },
  "phylotree_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("phylotree_pub_id");
__PACKAGE__->add_unique_constraint("phylotree_pub_phylotree_id_key", ["phylotree_id", "pub_id"]);

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

=head2 phylotree

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Phylogeny::Phylotree>

=cut

__PACKAGE__->belongs_to(
  "phylotree",
  "Bio::Chado::Schema::Result::Phylogeny::Phylotree",
  { phylotree_id => "phylotree_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rxacq3W1aTezUJ2L0Navgg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
