package A::Schema::Result::Human;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('human');

__PACKAGE__->load_components('MaterializedPath');

__PACKAGE__->add_columns(
   id => {
      data_type => 'int',
      is_auto_increment => 1,
   },

   mom_id => {
      data_type => 'int',
      is_nullable => 1, # eve
   },
   dad_id => {
      data_type => 'int',
      is_nullable => 1, # adam
   },
   mom_path => {
      data_type => 'varchar',
      size      => 256,
      # XXX: this seems required because we won't know our own id till *after* insertion
      is_nullable => 1,
   },
   dad_path => {
      data_type => 'varchar',
      size      => 256,
      is_nullable => 1,
   },
   name => {
      data_type => 'varchar',
      size      => 256,
   },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(sons => 'A::Schema::Result::Human', 'dad_id');
__PACKAGE__->has_many(daughters => 'A::Schema::Result::Human', 'mom_id');
__PACKAGE__->belongs_to(dad => 'A::Schema::Result::Human', 'dad_id');
__PACKAGE__->belongs_to(mom => 'A::Schema::Result::Human', 'mom_id');

sub materialized_path_columns {
   return {
      mom => {
         # XXX: we should infer these from the direct rels
         parent_column            => 'mom_id',
         parent_fk_column         => 'id',
         materialized_path_column => 'mom_path',
         # XXX: should we create these rels or infer from them?
         parent_relationship  => 'mom',
         # XXX: pretty sure we can infer this one too
         children_relationship  => 'daughters',
         full_path            => 'maternal_lineage',
         reverse_full_path    => 'daughters',
      },
      dad => {
         parent_column            => 'dad_id',
         parent_fk_column         => 'id',
         materialized_path_column => 'dad_path',
         separator           => '.',
         parent_relationship => 'dad',
         children_relationship  => 'sons',
         full_path           => 'paternal_lineage',
         reverse_full_path   => 'sons',
      },
   }
}

1;
