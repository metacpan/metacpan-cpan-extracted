package Bio::Chado::Schema::Result::Phylogeny::PhylonodeDbxref;
BEGIN {
  $Bio::Chado::Schema::Result::Phylogeny::PhylonodeDbxref::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Phylogeny::PhylonodeDbxref::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Phylogeny::PhylonodeDbxref

=head1 DESCRIPTION

For example, for orthology, paralogy group identifiers; could also be used for NCBI taxonomy; for sequences, refer to phylonode_feature, feature associated dbxrefs.

=cut

__PACKAGE__->table("phylonode_dbxref");

=head1 ACCESSORS

=head2 phylonode_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phylonode_dbxref_phylonode_dbxref_id_seq'

=head2 phylonode_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phylonode_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phylonode_dbxref_phylonode_dbxref_id_seq",
  },
  "phylonode_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("phylonode_dbxref_id");
__PACKAGE__->add_unique_constraint(
  "phylonode_dbxref_phylonode_id_key",
  ["phylonode_id", "dbxref_id"],
);

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

=head2 dbxref

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::General::Dbxref>

=cut

__PACKAGE__->belongs_to(
  "dbxref",
  "Bio::Chado::Schema::Result::General::Dbxref",
  { dbxref_id => "dbxref_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0dvIN4NxK3Ee8559ojEHCg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
