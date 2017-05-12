package DemoAppOtherFeaturesSchema::Result::SelfRefAlias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::SelfRefAlias

=cut

__PACKAGE__->table("self_ref_alias");

=head1 ACCESSORS

=head2 self_ref

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 alias

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "self_ref",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "alias",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("self_ref", "alias");

=head1 RELATIONS

=head2 alias

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::SelfRef>

=cut

__PACKAGE__->belongs_to(
  "alias",
  "DemoAppOtherFeaturesSchema::Result::SelfRef",
  { id => "alias" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 self_ref

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::SelfRef>

=cut

__PACKAGE__->belongs_to(
  "self_ref",
  "DemoAppOtherFeaturesSchema::Result::SelfRef",
  { id => "self_ref" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wXLBc0wzt9MAYSr+q/Cu3g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
