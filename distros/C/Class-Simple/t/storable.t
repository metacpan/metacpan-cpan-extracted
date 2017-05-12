# $Id: storable.t,v 1.3 2008/01/30 18:02:19 sullivan Exp $
#
#	Testing the Storable hooks.

use Test::More tests => 8;
BEGIN { use_ok('Class::Simple') };				##

SKIP:
{
	eval { require Storable };
	skip('Storable not installed.', 1) if $@;

	my $f = Foo->new();
	$f->set_foo(12345);
	$f->set_three(sub { 3 });
	my $serialized = Storable::freeze($f);
	is($f->foo, 12345, 'Can still get stuff after a freeze.');	##
	my $new_f = Storable::thaw($serialized);
	is($new_f->foo, 12345, 'Storable freezing and thawing seem to work'); ##
	is($new_f->three->(), 3, 'Freezing and thawing a sub is working'); ##

	{
		local $Class::Simple::No_serialized_code = 1;
		eval { Storable::freeze($f); };
		like($@, qr/Can't store CODE/, 'Preventing freeze.');	##
		eval { Storable::thaw($serialized); };
		like($@, qr/Can't eval/, 'Preventing thaw.');		##
	}

	my $g = Storable::dclone($f);
	is($g->foo, 12345, 'Storable cloning seems to work');	##
	$f->set_bar(345);
	isnt($g->foo, 345, 'Storable cloning did not just link'); ##
}

package Foo;
use base qw(Class::Simple);

1;
