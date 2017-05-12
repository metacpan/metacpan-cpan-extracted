package DemoAppOtherFeaturesSchema::Result::RefB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::B

=cut

__PACKAGE__->table("ref_b");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 a

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reference

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ref_a",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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

=head2 a

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::A>

=cut

__PACKAGE__->belongs_to(
  "ref_a",
  "DemoAppOtherFeaturesSchema::Result::RefA",
  { id => "ref_a" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-15 14:58:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MR5vRo2hETq1evS/7tVQtQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
