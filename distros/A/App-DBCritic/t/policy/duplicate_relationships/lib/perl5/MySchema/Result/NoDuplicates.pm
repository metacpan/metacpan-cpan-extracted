package MySchema::Result::NoDuplicates;
use base 'DBIx::Class::Core';
__PACKAGE__->table('no_duplicates');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'numeric',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    duplicates_id => {
        data_type      => 'numeric',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
    duplicates => 'MySchema::Result::Duplicates',
    'duplicates_id',
);
__PACKAGE__->has_many(
    no_duplicates => 'MySchema::Result::Duplicates',
    'no_duplicates_id',
);
1;
