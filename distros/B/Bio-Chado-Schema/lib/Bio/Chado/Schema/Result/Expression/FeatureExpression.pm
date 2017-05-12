package Bio::Chado::Schema::Result::Expression::FeatureExpression;
BEGIN {
  $Bio::Chado::Schema::Result::Expression::FeatureExpression::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Expression::FeatureExpression::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Expression::FeatureExpression

=cut

__PACKAGE__->table("feature_expression");

=head1 ACCESSORS

=head2 feature_expression_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'feature_expression_feature_expression_id_seq'

=head2 expression_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 feature_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pub_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "feature_expression_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "feature_expression_feature_expression_id_seq",
  },
  "expression_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "feature_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pub_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("feature_expression_id");
__PACKAGE__->add_unique_constraint(
  "feature_expression_c1",
  ["expression_id", "feature_id", "pub_id"],
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

=head2 feature

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Sequence::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "Bio::Chado::Schema::Result::Sequence::Feature",
  { feature_id => "feature_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 expression

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Expression::Expression>

=cut

__PACKAGE__->belongs_to(
  "expression",
  "Bio::Chado::Schema::Result::Expression::Expression",
  { expression_id => "expression_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 feature_expressionprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::FeatureExpressionprop>

=cut

__PACKAGE__->has_many(
  "feature_expressionprops",
  "Bio::Chado::Schema::Result::Expression::FeatureExpressionprop",
  { "foreign.feature_expression_id" => "self.feature_expression_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DO8chWXnKUx1O/2AipXfIQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
