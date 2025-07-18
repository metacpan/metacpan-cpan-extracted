package My::SubClass2::DDL;

use Moo;

extends 'CXC::DB::DDL';

sub table_class { 'My::SubClass2::Table' }

1;
