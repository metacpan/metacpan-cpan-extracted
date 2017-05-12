package Bio::Chado::Schema::Result::Expression::ExpressionCvtermprop;
BEGIN {
  $Bio::Chado::Schema::Result::Expression::ExpressionCvtermprop::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Expression::ExpressionCvtermprop::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Expression::ExpressionCvtermprop

=head1 DESCRIPTION

Extensible properties for
expression to cvterm associations. Examples: qualifiers.

=cut

__PACKAGE__->table("expression_cvtermprop");

=head1 ACCESSORS

=head2 expression_cvtermprop_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'expression_cvtermprop_expression_cvtermprop_id_seq'

=head2 expression_cvterm_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The name of the
property/slot is a cvterm. The meaning of the property is defined in
that cvterm. For example, cvterms may come from the FlyBase miscellaneous cv.

=head2 value

  data_type: 'text'
  is_nullable: 1

The value of the
property, represented as text. Numeric values are converted to their
text representation. This is less efficient than using native database
types, but is easier to query.

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

Property-Value
ordering. Any expression_cvterm can have multiple values for any particular
property type - these are ordered in a list using rank, counting from
zero. For properties that are single-valued rather than multi-valued,
the default 0 value should be used.

=cut

__PACKAGE__->add_columns(
  "expression_cvtermprop_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "expression_cvtermprop_expression_cvtermprop_id_seq",
  },
  "expression_cvterm_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("expression_cvtermprop_id");
__PACKAGE__->add_unique_constraint(
  "expression_cvtermprop_c1",
  ["expression_cvterm_id", "type_id", "rank"],
);

=head1 RELATIONS

=head2 expression_cvterm

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Expression::ExpressionCvterm>

=cut

__PACKAGE__->belongs_to(
  "expression_cvterm",
  "Bio::Chado::Schema::Result::Expression::ExpressionCvterm",
  { expression_cvterm_id => "expression_cvterm_id" },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lUGuhQAy+DWrt2blIh35zw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
