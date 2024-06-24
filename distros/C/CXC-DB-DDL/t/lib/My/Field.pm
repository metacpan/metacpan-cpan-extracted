package My::Field;

use Test::Lib;

use CXC::DB::DDL::Util {
    add_dbd => {
        dbd         => 'MyTestDBD',
        tag         => ':sql_types',
        field_class => 'My::Field',
    },
  },
  'SQL_TYPE_VALUES';

use Moo;

use Types::Standard 'ArrayRef', 'Enum', 'Int';
extends 'CXC::DB::DDL::Field';

has '+data_type' => (
    is     => 'ro',
    isa    => ArrayRef->of( Enum [SQL_TYPE_VALUES] )->plus_coercions( Int, sub { [$_] } ),
    coerce => 1,
);

1;


