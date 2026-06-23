package DBIOVersion::Table;

use base 'DBIO::Core';
use strict;
use warnings;

__PACKAGE__->table('TestVersion');

__PACKAGE__->add_columns
    ( 'Version' => {
        'data_type' => 'INTEGER',
        'is_auto_increment' => 1,
        'default_value' => undef,
        'is_foreign_key' => 0,
        'is_nullable' => 0,
        'size' => ''
        },
      'VersionName' => {
        'data_type' => 'VARCHAR',
        'is_auto_increment' => 0,
        'default_value' => undef,
        'is_foreign_key' => 0,
        'is_nullable' => 0,
        'size' => '10'
        },
      'NewVersionName' => {
        'data_type' => 'VARCHAR',
        'is_auto_increment' => 0,
        'default_value' => undef,
        'is_foreign_key' => 0,
        'is_nullable' => 1,
        'size' => '20'
        },
      'ExtraColumn' => {
        'data_type' => 'VARCHAR',
        'is_auto_increment' => 0,
        'default_value' => undef,
        'is_foreign_key' => 0,
        'is_nullable' => 1,
        'size' => '20'
        }
      );

__PACKAGE__->set_primary_key('Version');

package DBIOVersion::Schema;
use base 'DBIOTest::BaseSchema';
use strict;
use warnings;
use File::Temp qw(tempdir);

our $VERSION = '3.0';

__PACKAGE__->register_class('Table', 'DBIOVersion::Table');
__PACKAGE__->load_components('+DBIO::Schema::Versioned');
__PACKAGE__->upgrade_directory(tempdir( CLEANUP => 1 ));
__PACKAGE__->backup_directory(tempdir( CLEANUP => 1 ));

1;
