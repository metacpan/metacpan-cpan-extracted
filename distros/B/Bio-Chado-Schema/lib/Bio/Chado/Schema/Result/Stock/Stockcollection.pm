package Bio::Chado::Schema::Result::Stock::Stockcollection;
BEGIN {
  $Bio::Chado::Schema::Result::Stock::Stockcollection::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Stock::Stockcollection::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Stock::Stockcollection

=head1 DESCRIPTION

The lab or stock center distributing the stocks in their collection.

=cut

__PACKAGE__->table("stockcollection");

=head1 ACCESSORS

=head2 stockcollection_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stockcollection_stockcollection_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

type_id is the collection type cv.

=head2 contact_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

contact_id links to the contact information for the collection.

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

name is the collection.

=head2 uniquename

  data_type: 'text'
  is_nullable: 0

uniqename is the value of the collection cv.

=cut

__PACKAGE__->add_columns(
  "stockcollection_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stockcollection_stockcollection_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "contact_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "uniquename",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("stockcollection_id");
__PACKAGE__->add_unique_constraint("stockcollection_c1", ["uniquename", "type_id"]);

=head1 RELATIONS

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

=head2 contact

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Contact::Contact>

=cut

__PACKAGE__->belongs_to(
  "contact",
  "Bio::Chado::Schema::Result::Contact::Contact",
  { contact_id => "contact_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 stockcollectionprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::Stockcollectionprop>

=cut

__PACKAGE__->has_many(
  "stockcollectionprops",
  "Bio::Chado::Schema::Result::Stock::Stockcollectionprop",
  { "foreign.stockcollection_id" => "self.stockcollection_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stockcollection_stocks

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Stock::StockcollectionStock>

=cut

__PACKAGE__->has_many(
  "stockcollection_stocks",
  "Bio::Chado::Schema::Result::Stock::StockcollectionStock",
  { "foreign.stockcollection_id" => "self.stockcollection_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+3eqKa0SQPhsJx2sglJqNw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
