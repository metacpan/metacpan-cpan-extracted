package Business::Cart::Generic::Schema::Result::WeightClassRule;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::WeightClassRule

=cut

__PACKAGE__->table("weight_class_rules");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'weight_class_rules_id_seq'

=head2 from_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 to_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 rule

  data_type: 'numeric'
  is_nullable: 0
  size: [15,4]

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "weight_class_rules_id_seq",
  },
  "from_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "to_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "rule",
  { data_type => "numeric", is_nullable => 0, size => [15, 4] },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 to

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::WeightClass>

=cut

__PACKAGE__->belongs_to(
  "to",
  "Business::Cart::Generic::Schema::Result::WeightClass",
  { id => "to_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 from

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::WeightClass>

=cut

__PACKAGE__->belongs_to(
  "from",
  "Business::Cart::Generic::Schema::Result::WeightClass",
  { id => "from_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8wRzQuyFuXjbygBbUsOwQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
