package MySchema::Result::Duplicates;
use base 'DBIx::Class::Core';
__PACKAGE__->table('duplicates');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'numeric',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    no_duplicates_id => {
        data_type      => 'numeric',
        is_nullable    => 0,
        is_foreign_key => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
    no_duplicates => 'MySchema::Result::NoDuplicates',
    'no_duplicates_id',
);
__PACKAGE__->has_many(
    duplicates => 'MySchema::Result::NoDuplicates',
    'duplicates_id',
);

__PACKAGE__->belongs_to(
    no_duplicates2 => 'MySchema::Result::NoDuplicates',
    'no_duplicates_id',
);
1;
