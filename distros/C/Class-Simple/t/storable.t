# $Id: storable.t,v 1.1 2007/10/29 21:08:54 sullivan Exp $
#
#	Testing the Storable hooks.

use Test::More tests => 2;
BEGIN { use_ok('Class::Simple') };				##

SKIP:
{
	eval { require Storable };
	skip('Storable not installed.', 1) if $@;

	my $f = Foo->new();
	$f->set_foo(12345);
	my $serialized = Storable::freeze($f);
	my $new_f = Storable::thaw($serialized);
	is($new_f->foo, 12345, 'Storable freezing and thawing seem to work'); ##
}

package Foo;
use base qw(Class::Simple);

1;
