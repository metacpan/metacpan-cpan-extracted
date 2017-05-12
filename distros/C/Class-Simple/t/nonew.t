# $Id: nonew.t,v 1.1 2007/10/03 23:32:37 sullivan Exp $

use Test::More tests => 3;
BEGIN { use_ok('Class::Simple') };			##

eval { my $foo = Foo->new(); };
ok($@, "Can't new Foo.");				##
eval { my $bar = Bar->new(); };
ok(!$@, "Can new Bar.");				##

package Foo;
use base qw(Class::Simple);

sub NONEW {}

1;

package Bar;
use base qw(Foo);

1;
