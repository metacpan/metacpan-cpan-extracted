package Bio::Chado::Schema::Result::Stock::StockRelationship;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::StockRelationship::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::StockRelationship::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Stock::StockRelationship

=cut

__PACKAGE__->table("stock_relationship");

=head1 ACCESSORS

=head2 stock_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_relationship_stock_relationship_id_seq'

=head2 subject_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

stock_relationship.subject_id is the subject of the subj-predicate-obj sentence. This is typically the substock.

=head2 object_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

stock_relationship.object_id is the object of the subj-predicate-obj sentence. This is typically the container stock.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

stock_relationship.type_id is relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.

=head2 value

  data_type: 'text'
  is_nullable: 1

stock_relationship.value is for additional notes or comments.

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

stock_relationship.rank is the ordering of subject stocks with respect to the object stock may be important where rank is used to order these; starts from zero.

=cut

__PACKAGE__->add_columns(
  "stock_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_relationship_stock_relationship_id_seq",
  },
  "subject_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("stock_relationship_id");
__PACKAGE__->add_unique_constraint(
  "stock_relationship_c1",
  ["subject_id", "object_id", "type_id", "rank"],
);

=head1 RELATIONS

=head2 subject

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Stock::Stock>

=cut

__PACKAGE__->belongs_to(
  "subject",
  "Bio::Chado::Schema::Result::Stock::Stock",
  { stock_id => "subject_id" },
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

=head2 object

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Stock::Stock>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Bio::Chado::Schema::Result::Stock::Stock",
  { stock_id => "object_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 stock_relationship_cvterms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationshipCvterm>

=cut

__PACKAGE__->has_many(
  "stock_relationship_cvterms",
  "Bio::Chado::Schema::Result::Stock::StockRelationshipCvterm",
  { "foreign.stock_relationship_id" => "self.stock_relationship_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stock_relationship_pubs

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockRelationshipPub>

=cut

__PACKAGE__->has_many(
  "stock_relationship_pubs",
  "Bio::Chado::Schema::Result::Stock::StockRelationshipPub",
  { "foreign.stock_relationship_id" => "self.stock_relationship_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-22 08:45:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ClokyNSMEKjwcU78vbfKPg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
