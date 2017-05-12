package MySchema::Result::Reciprocates;
use base 'DBIx::Class::Core';
__PACKAGE__->table('reciprocates');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'numeric',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    oneway_id => {
        data_type      => 'numeric',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
);
__PACKAGE__->set_primary_key('id');
1;
