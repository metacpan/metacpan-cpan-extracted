package My::Field;

use Test::Lib;

package    #
  My::Field::Type {
    use base 'CXC::DB::DDL::FieldType';
}

use CXC::DB::DDL::Util {
    add_dbd => {
        dbd         => 'MyTestDBD',
        tag         => ':sql_types',
        field_class => 'My::Field',
        type_class  => 'My::Field::Type',
    },
  },
  'SQL_TYPE_VALUES';

use Types::Standard 'ArrayRef', 'Enum', 'Int', 'InstanceOf';

use constant DataType => Enum->of( SQL_TYPE_VALUES ) | InstanceOf ['My::Field::Type'];

use Moo;


extends 'CXC::DB::DDL::Field';

has '+data_type' => (
    is     => 'ro',
    isa    => ArrayRef->of( DataType )->plus_coercions( DataType, sub { [$_] } ),
    coerce => 1,
);

1;


