package TestFor::DbicVisualizer::Schema::Result::ResultSourceWithMissingRelation;

use base 'DBIx::Class::Core';

__PACKAGE__->table('Author');
__PACKAGE__->add_columns(
    an_id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    author_id => {
        data_type => 'int',
    },
);

__PACKAGE__->set_primary_key(qw/an_id/);

__PACKAGE__->belongs_to(author => 'TestFor::DbicVisualizer::Schema::Result::Author', 'author_id');

1;
