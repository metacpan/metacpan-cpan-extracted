#!perl

use strict;
use warnings;

use Test::Most;

use lib 't/lib';

use Test::Schema;

my $dsn    = "dbi:SQLite::memory:";
my $schema = Test::Schema->deploy_or_connect($dsn);

ok my $rs = $schema->resultset('A'), 'resultset';

cmp_deeply $rs->result_source->column_info('id'),
  {
    data_type         => 'serial',
    is_auto_increment => 1,
    is_numeric        => 1,
    extra             => {
        type => {
            isa    => isa('Type::Tiny'),
            strict => bool(0),
            coerce => bool(0),
        }
    },
  },
  'id';

cmp_deeply $rs->result_source->column_info('name'),
  {
    data_type => 'text',
    extra     => {
        type => {
            isa    => isa('Type::Tiny'),
            strict => 1,
            coerce => bool(0),
        }
    },
    size       => 255,
    is_numeric => 0,
  },
  'name';

cmp_deeply $rs->result_source->column_info('model'),
  {
    data_type   => 'text',
    is_nullable => 1,
    extra       => {
        type => {
            isa    => isa('Type::Tiny'),
            strict => 1,
            coerce => 1,
        }
    },
    is_numeric => 0,
  },
  'model';

cmp_deeply $rs->result_source->column_info('serial_number'), {
    data_type  => 'varchar',
    size       => 32,
    is_numeric => 1,           # overridden
    extra      => {
        type => {
            isa    => isa('Type::Tiny'),
            strict => bool(0),
            coerce => bool(0),
        }
    },
  },
  'serial_number';

ok my $row = $rs->create( { id => 1, name => 'test', serial_number => '1234' } ), 'created row';

lives_ok {
    $row->name('changed');
} 'changed name';

throws_ok {
    $row->name('Changed Again');
} qr/Must not contain u?pper case letters/;

 TODO: {

     local $TODO = "create does not use set_column";

     dies_ok {
         $rs->create( { id => 2, name => 'Another', serial_number => '321' } )
     } 'create row with invalid name';

     throws_ok {
         my $obj = $rs->new( { id => 3, name => 'Another', serial_number => '321' } );
         $obj->insert;
     } qr/Must not contain u?pper case letters/, 'insert a row with an invalid name';

}

throws_ok {
    $row->update( { name => 'Uppercase Name' } );
} qr/Must not contain u?pper case letters/,
    'update a row with an invalid name';

lives_ok {
    $row->model('model');
} 'set model';

is $row->model, 'MODEL', 'model was coerced';

done_testing;
