# Regression test for %AUTODB=0

package PctAUTODB_0;
use Test::More;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=0;			# illegal
eval {Class::AutoClass::declare;};
ok($@,'%AUTODB=0 illegal as expected');

package main;
use Test::More;
done_testing();
