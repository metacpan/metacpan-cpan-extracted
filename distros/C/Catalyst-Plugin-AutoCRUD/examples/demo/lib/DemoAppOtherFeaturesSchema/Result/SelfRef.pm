package DemoAppOtherFeaturesSchema::Result::SelfRef;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DemoAppOtherFeaturesSchema::Result::SelfRef

=cut

__PACKAGE__->table("self_ref");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 self_ref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "self_ref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 self_ref

Type: belongs_to

Related object: L<DemoAppOtherFeaturesSchema::Result::SelfRef>

=cut

__PACKAGE__->belongs_to(
  "self_ref",
  "DemoAppOtherFeaturesSchema::Result::SelfRef",
  { id => "self_ref_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 aliases

Type: has_many

Related object: L<DemoAppOtherFeaturesSchema::Result::SelfRefAlias>

=cut

__PACKAGE__->has_many(
  "aliases",
  "DemoAppOtherFeaturesSchema::Result::SelfRefAlias",
  { "foreign.self_ref" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 22:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4xcB0hpKEVkyg5e8W4eVLA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
