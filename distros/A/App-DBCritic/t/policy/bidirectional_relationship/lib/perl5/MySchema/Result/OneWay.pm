package MySchema::Result::OneWay;
use base 'DBIx::Class::Core';
__PACKAGE__->table('one_way');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'numeric',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    reciprocates_id => {
        data_type      => 'numeric',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
    reciprocates => 'MySchema::Result::Reciprocates',
    'reciprocates_id',
);
__PACKAGE__->has_many(
    reciprocals => 'MySchema::Result::Reciprocates',
    'oneway_id',
);
1;
