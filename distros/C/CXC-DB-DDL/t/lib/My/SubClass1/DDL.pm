package My::SubClass1::DDL;

use Moo;

extends 'CXC::DB::DDL';

sub table_class { 'My::SubClass1::Table' }

1;
