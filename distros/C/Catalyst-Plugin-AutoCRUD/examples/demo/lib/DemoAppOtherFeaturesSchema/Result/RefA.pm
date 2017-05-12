package DemoAppOtherFeaturesSchema::Result::RefA;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::A

=cut

__PACKAGE__->table("ref_a");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 reference

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "reference",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 reference

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::Reference>

=cut

__PACKAGE__->belongs_to(
  "reference",
  "DemoAppOtherFeaturesSchema::Result::Reference",
  { id => "reference" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 bs

Type: has_many

Related object: L<DemoAppOtherFeaturesSchema::Result::B>

=cut

__PACKAGE__->has_many(
  "ref_bs",
  "DemoAppOtherFeaturesSchema::Result::RefB",
  { "foreign.ref_a" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-15 14:58:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XLBJfiY2TVbu0hULuLKzTw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
