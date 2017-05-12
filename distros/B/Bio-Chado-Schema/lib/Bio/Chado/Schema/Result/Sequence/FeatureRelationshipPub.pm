package Bio::Chado::Schema::Result::Sequence::FeatureRelationshipPub;
BEGIN {
  $Bio::Chado::Schema::Result::Sequence::FeatureRelationshipPub::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Sequence::FeatureRelationshipPub::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Sequence::FeatureRelationshipPub

=head1 DESCRIPTION

Provenance. Attach optional evidence to a feature_relationship in the form of a publication.

=cut

__PACKAGE__->table("feature_relationship_pub");

=head1 ACCESSORS

=head2 feature_relationship_pub_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feature_relationship_pub_feature_relationship_pub_id_seq'

=head2 feature_relationship_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_relationship_pub_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feature_relationship_pub_feature_relationship_pub_id_seq",
  },
  "feature_relationship_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("feature_relationship_pub_id");
__PACKAGE__->add_unique_constraint(
  "feature_relationship_pub_c1",
  ["feature_relationship_id", "pub_id"],
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

=head2 feature_relationship

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::FeatureRelationship>

=cut

__PACKAGE__->belongs_to(
  "feature_relationship",
  "Bio::Chado::Schema::Result::Sequence::FeatureRelationship",
  { feature_relationship_id => "feature_relationship_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xvcH0v4k9TD5wECYXQaqgw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
