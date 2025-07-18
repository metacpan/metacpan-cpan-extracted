package My::SubClass2::Table;

use Moo;

extends 'CXC::DB::DDL::Table';

sub field_class { 'My::SubClass2::Field' }

1;
