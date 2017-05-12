package Bio::Chado::Schema::Result::Sequence::FeatureCvtermDbxref;
BEGIN {
  $Bio::Chado::Schema::Result::Sequence::FeatureCvtermDbxref::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Sequence::FeatureCvtermDbxref::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Sequence::FeatureCvtermDbxref

=head1 DESCRIPTION

Additional dbxrefs for an association. Rows in the feature_cvterm table may be backed up by dbxrefs. For example, a feature_cvterm association that was inferred via a protein-protein interaction may be backed by by refering to the dbxref for the alternate protein. Corresponds to the WITH column in a GO gene association file (but can also be used for other analagous associations). See http://www.geneontology.org/doc/GO.annotation.shtml#file for more details.

=cut

__PACKAGE__->table("feature_cvterm_dbxref");

=head1 ACCESSORS

=head2 feature_cvterm_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feature_cvterm_dbxref_feature_cvterm_dbxref_id_seq'

=head2 feature_cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_cvterm_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feature_cvterm_dbxref_feature_cvterm_dbxref_id_seq",
  },
  "feature_cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("feature_cvterm_dbxref_id");
__PACKAGE__->add_unique_constraint(
  "feature_cvterm_dbxref_c1",
  ["feature_cvterm_id", "dbxref_id"],
);

=head1 RELATIONS

=head2 feature_cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureCvterm>

=cut

__PACKAGE__->belongs_to(
  "feature_cvterm",
  "Bio::Chado::Schema::Result::Sequence::FeatureCvterm",
  { feature_cvterm_id => "feature_cvterm_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:k85jubfMDMgH6FQeLQAPPw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
