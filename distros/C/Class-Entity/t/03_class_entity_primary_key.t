use strict;
use warnings;
use Test::More qw(no_plan);

package Class::Entity::Test;
use base qw(Class::Entity);

package Class::Entity::MyTest;
use base qw(Class::Entity);
sub _primary_key { "mykey" }

package main;
cmp_ok(Class::Entity::Test->_primary_key, "eq", "id",
  "static method call to _primary_key");
my $test = Class::Entity::Test->new;
cmp_ok($test->_primary_key, "eq", "id",
  "object method call to _primary_key");
cmp_ok(Class::Entity::MyTest->_primary_key, "eq", "mykey",
  "overloaded static method call to _primary_key");
my $mytest = Class::Entity::MyTest->new;
cmp_ok($mytest->_primary_key, "eq", "mykey",
  "overloaded object method call to _primary_key");

