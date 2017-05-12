use strict;
use warnings;
use Test::More qw(no_plan);
package Foo;
use base qw(Class::Entity);
package Foo::Bar;
use base qw(Class::Entity);
package Foo::Bar::Baz;
use base qw(Class::Entity);
package Class::Entity::Test;
use base qw(Class::Entity);
package Class::Entity::MyTest;
use base qw(Class::Entity);
sub _table { "mytable" }

package main;
cmp_ok(Foo->_table, "eq", "Foo", "auto table name generation");
cmp_ok(Foo::Bar->_table, "eq", "Bar", "auto table name generation");
cmp_ok(Foo::Bar::Baz->_table, "eq", "Baz", "auto table name generation");
cmp_ok(Class::Entity::Test->_table, "eq", "Test",
  "static method call to _table");
my $test = Class::Entity::Test->new;
cmp_ok($test->_table, "eq", "Test",
  "object method call to _table");
cmp_ok(Class::Entity::MyTest->_table, "eq", "mytable",
  "overloaded static method call to _table");
my $mytest = Class::Entity::MyTest->new;
cmp_ok($mytest->_table, "eq", "mytable",
  "overloaded object method call to _table");

