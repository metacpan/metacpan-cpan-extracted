package DemoAppOtherFeaturesSchema::Result::Reference;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::Reference

=cut

__PACKAGE__->table("reference");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 a

Type: has_many

Related object: L<DemoAppOtherFeaturesSchema::Result::A>

=cut

__PACKAGE__->has_many(
  "ref_a",
  "DemoAppOtherFeaturesSchema::Result::RefA",
  { "foreign.reference" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bs

Type: has_many

Related object: L<DemoAppOtherFeaturesSchema::Result::B>

=cut

__PACKAGE__->has_many(
  "ref_bs",
  "DemoAppOtherFeaturesSchema::Result::RefB",
  { "foreign.reference" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-15 14:58:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XhHAxU8Fcum4DoJrn3+okQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
