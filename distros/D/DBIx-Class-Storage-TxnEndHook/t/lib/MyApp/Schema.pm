package MyApp::Schema::Table;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('table');
__PACKAGE__->add_columns(
    id   => {
        data_type         => 'INTEGER',
        is_nullable       => 0,
        is_auto_increment => 1,
    },
    name => {
        data_type   => 'VARCHAR',
        size        => 255,
        is_nullable => 0,
    },
);
__PACKAGE__->set_primary_key('id');

package MyApp::Schema;
use strict;
use warnings;

use parent 'DBIx::Class::Schema';
__PACKAGE__->register_class('Table', 'MyApp::Schema::Table');
__PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::TxnEndHook');
__PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::DBI');
__PACKAGE__->inject_base('DBIx::Class::Storage::DBI', 'DBIx::Class::Storage::TxnEndHook');
__PACKAGE__->load_components('Schema::TxnEndHook');
1;
