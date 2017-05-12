package Bio::Chado::Schema::Result::Sequence::ProteinCodingGene;
BEGIN {
  $Bio::Chado::Schema::Result::Sequence::ProteinCodingGene::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Sequence::ProteinCodingGene::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Sequence::ProteinCodingGene

=cut

__PACKAGE__->table("protein_coding_gene");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'integer'
  is_nullable: 1

=head2 dbxref_id

  data_type: 'integer'
  is_nullable: 1

=head2 organism_id

  data_type: 'integer'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 uniquename

  data_type: 'text'
  is_nullable: 1

=head2 residues

  data_type: 'text'
  is_nullable: 1

=head2 seqlen

  data_type: 'integer'
  is_nullable: 1

=head2 md5checksum

  data_type: 'char'
  is_nullable: 1
  size: 32

=head2 type_id

  data_type: 'integer'
  is_nullable: 1

=head2 is_analysis

  data_type: 'boolean'
  is_nullable: 1

=head2 is_obsolete

  data_type: 'boolean'
  is_nullable: 1

=head2 timeaccessioned

  data_type: 'timestamp'
  is_nullable: 1

=head2 timelastmodified

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_id",
  { data_type => "integer", is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_nullable => 1 },
  "organism_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 1 },
  "residues",
  { data_type => "text", is_nullable => 1 },
  "seqlen",
  { data_type => "integer", is_nullable => 1 },
  "md5checksum",
  { data_type => "char", is_nullable => 1, size => 32 },
  "type_id",
  { data_type => "integer", is_nullable => 1 },
  "is_analysis",
  { data_type => "boolean", is_nullable => 1 },
  "is_obsolete",
  { data_type => "boolean", is_nullable => 1 },
  "timeaccessioned",
  { data_type => "timestamp", is_nullable => 1 },
  "timelastmodified",
  { data_type => "timestamp", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2LC9ZsSCSp/U2xNTkXWN2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
