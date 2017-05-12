package Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship;
BEGIN {
  $Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::NaturalDiversity::NdReagentRelationship

=head1 DESCRIPTION

Relationships between reagents. Some reagents form a group. i.e., they are used all together or not at all. Examples are adapter/linker/enzyme experiment reagents.

=cut

__PACKAGE__->table("nd_reagent_relationship");

=head1 ACCESSORS

=head2 nd_reagent_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'nd_reagent_relationship_nd_reagent_relationship_id_seq'

=head2 subject_reagent_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The subject reagent in the relationship. In parent/child terminology, the subject is the child. For example, in "linkerA 3prime-overhang-linker enzymeA" linkerA is the subject, 3prime-overhand-linker is the type, and enzymeA is the object.

=head2 object_reagent_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The object reagent in the relationship. In parent/child terminology, the object is the parent. For example, in "linkerA 3prime-overhang-linker enzymeA" linkerA is the subject, 3prime-overhand-linker is the type, and enzymeA is the object.

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The type (or predicate) of the relationship. For example, in "linkerA 3prime-overhang-linker enzymeA" linkerA is the subject, 3prime-overhand-linker is the type, and enzymeA is the object.

=cut

__PACKAGE__->add_columns(
  "nd_reagent_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "nd_reagent_relationship_nd_reagent_relationship_id_seq",
  },
  "subject_reagent_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_reagent_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("nd_reagent_relationship_id");

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

=head2 subject_reagent

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagent>

=cut

__PACKAGE__->belongs_to(
  "subject_reagent",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagent",
  { nd_reagent_id => "subject_reagent_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 object_reagent

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::NaturalDiversity::NdReagent>

=cut

__PACKAGE__->belongs_to(
  "object_reagent",
  "Bio::Chado::Schema::Result::NaturalDiversity::NdReagent",
  { nd_reagent_id => "object_reagent_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I+jy84SjM8ko34ZISwtW2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
