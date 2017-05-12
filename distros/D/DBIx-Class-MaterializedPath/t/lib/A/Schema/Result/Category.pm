package A::Schema::Result::Category;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('category');

__PACKAGE__->load_components('MaterializedPath');

__PACKAGE__->add_columns(
   id => {
      data_type => 'int',
      is_auto_increment => 1,
   },

   parent_id => {
      data_type => 'int',
      is_nullable => 1, # root
   },
   # XXX: does it make sense to generate this column for the user?
   parent_path => {
      data_type => 'varchar',
      size      => 256,
      # XXX: this seems required because we won't know our own id till *after* insertion
      is_nullable => 1,
   },
   name => {
      data_type => 'varchar',
      size      => 256,
   },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(parent_category => 'A::Schema::Result::Category', 'parent_id');
__PACKAGE__->has_many(child_categories => 'A::Schema::Result::Category', 'parent_id');

sub materialized_path_columns {
   return {
      parent => {
         parent_column            => 'parent_id',
         parent_fk_column         => 'id',
         materialized_path_column => 'parent_path',
         include_self_in_path => 1,
         include_self_in_reverse_path => 1,
         separator            => '~',
         # XXX: should we create these rels or infer from them?
         parent_relationship  => 'parent_category',
         children_relationship  => 'child_categories',
         full_path            => 'ancestry',
         reverse_full_path    => 'descendants',
      },
   }
}

1;
