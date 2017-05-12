package TestDB::NativeEnumNoneNullable;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/
    InflateColumn::Object::Enum
    PK::Auto
    Core
/);
__PACKAGE__->table('nenn');
__PACKAGE__->add_columns(
    id => {
        data_type => 'number',
        is_auto_increment => 1,
        is_nullable => 0
    },
    enum => {
        data_type => 'enum',
        is_enum => 1,
        is_nullable => 0,
        extra => {
            list => [qw/red green blue/]
        },
    }
);
__PACKAGE__->set_primary_key('id');

1;
