package TestDB::Foo;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::Path::Class Core/);
__PACKAGE__->table('foo');
__PACKAGE__->add_columns
  (
   id => {
          data_type => 'INT',
          is_nullable => 0,
          extras => {unsigned => 1 },
          is_auto_increment => 1,
    },
   file_path => {
                 data_type => 'VARCHAR',
                 size => 255,
                 is_nullable => 0,
                 is_file => 1,
    },
   dir_path => {
                data_type => 'VARCHAR',
                size => 255,
                is_nullable => 0,
                is_dir => 1,
               },
);

__PACKAGE__->set_primary_key('id');

1;

__END__;
