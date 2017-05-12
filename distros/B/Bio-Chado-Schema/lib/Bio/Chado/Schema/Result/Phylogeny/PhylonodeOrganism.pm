package Bio::Chado::Schema::Result::Phylogeny::PhylonodeOrganism;
BEGIN {
  $Bio::Chado::Schema::Result::Phylogeny::PhylonodeOrganism::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Phylogeny::PhylonodeOrganism::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Phylogeny::PhylonodeOrganism

=head1 DESCRIPTION

This linking table should only be used for nodes in taxonomy trees; it provides a mapping between the node and an organism. One node can have zero or one organisms, one organism can have zero or more nodes (although typically it should only have one in the standard NCBI taxonomy tree).

=cut

__PACKAGE__->table("phylonode_organism");

=head1 ACCESSORS

=head2 phylonode_organism_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phylonode_organism_phylonode_organism_id_seq'

=head2 phylonode_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

One phylonode cannot refer to >1 organism.

=head2 organism_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phylonode_organism_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phylonode_organism_phylonode_organism_id_seq",
  },
  "phylonode_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("phylonode_organism_id");
__PACKAGE__->add_unique_constraint("phylonode_organism_phylonode_id_key", ["phylonode_id"]);

=head1 RELATIONS

=head2 phylonode

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Phylogeny::Phylonode>

=cut

__PACKAGE__->belongs_to(
  "phylonode",
  "Bio::Chado::Schema::Result::Phylogeny::Phylonode",
  { phylonode_id => "phylonode_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9+K+tdAa3FZn8QK19S5zrQ

# You can replace this text with custom content, and it will be preserved on regeneration
1;
