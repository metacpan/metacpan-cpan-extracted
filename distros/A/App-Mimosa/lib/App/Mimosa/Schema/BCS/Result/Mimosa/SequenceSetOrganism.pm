package App::Mimosa::Schema::BCS::Result::Mimosa::SequenceSetOrganism;
use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 NAME

Bio::Chado::Schema::Result::Mimosa::SequenceSetOrganism - linking table
between Mimosa::SequenceSet and Organism::Organism.

=head1 COLUMNS

=cut

__PACKAGE__->table("mimosa_sequence_set_organism");

=head2 mimosa_sequence_set_organism_id

Auto-incrementing surrogate primary key.

=head2 mimosa_sequence_set_id

The Mimosa sequence set for this link.

=head2 organism_id

The organism for this link.

=cut

__PACKAGE__->add_columns(

  "mimosa_sequence_set_organism_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mimosa_sequence_set_organism_mimosa_sequence_set_organism_id_seq",
  },

  "mimosa_sequence_set_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },

  "organism_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },

);
__PACKAGE__->set_primary_key( "mimosa_sequence_set_organism_id" );
__PACKAGE__->add_unique_constraint(
  "mimosa_sequence_set_organism_c1",
  ["mimosa_sequence_set_id", "organism_id"],
);

=head1 RELATIONS

=head2 organism

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Organism::Organism>

=cut

__PACKAGE__->belongs_to(
  "organism",
  "Bio::Chado::Schema::Result::Organism::Organism",
  { organism_id => "organism_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 sequence_set

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mimosa::SequenceSet>

=cut

__PACKAGE__->belongs_to(
  "sequence_set",
  "App::Mimosa::Schema::BCS::Result::Mimosa::SequenceSet",
  { mimosa_sequence_set_id => "mimosa_sequence_set_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head1 PLUGIN RELATIONS

Also adds the following relations to classes in core Bio::Chado::Schema.

=head2 Bio::Chado::Schema::Result::Organism::Organism  mimosa_sequence_set_organisms

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Organism::Organism>

=cut

Bio::Chado::Schema::Result::Organism::Organism->has_many(
    "mimosa_sequence_sets",
    "App::Mimosa::Schema::BCS::Result::Mimosa::SequenceSetOrganism",
    { "foreign.organism_id" => "self.organism_id" },
    { cascade_copy => 0, cascade_delete => 0 },
  );

####### also add relations into the BCS modules in question

1;

