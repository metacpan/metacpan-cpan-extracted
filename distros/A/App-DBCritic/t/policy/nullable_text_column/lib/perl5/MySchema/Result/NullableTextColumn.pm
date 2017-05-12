package MySchema::Result::NullableTextColumn;
use base 'DBIx::Class::Core';
__PACKAGE__->table('nullable_text_column');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'numeric',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    text => { data_type => 'text', is_nullable => 1 },
);
__PACKAGE__->set_primary_key('id');
1;
