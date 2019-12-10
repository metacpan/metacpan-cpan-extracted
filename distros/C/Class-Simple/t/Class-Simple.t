# $Id: Class-Simple.t,v 1.8 2008/01/01 16:38:37 sullivan Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 45;
BEGIN { use_ok('Class::Simple') };

#########################

my $destroyed;
INIT
{
	$destroyed = 0;
}

#
#	Count these twice.
#
sub run_tests
{
my $f = shift;
my $package = shift;

	#diag("Package is $package.");
	isa_ok($f, $package);					##
	can_ok($f, 'new');					##
	can_ok($f, 'privatize');				##
	can_ok($f, 'DESTROY');					##
	can_ok($f, 'AUTOLOAD');					##
	can_ok($f, 'STORABLE_freeze');				##
	can_ok($f, 'STORABLE_thaw');				##
	
	is($f->zomba, 333, 'BUILD initialized');		##
	$f->foo(1);
	can_ok($f, 'foo');					##
	is($f->foo, 1, 'set with bare word');			##
	is($f->set_foo(2), 2, 'set returns right thing');	##
	is($f->foo, 2, 'returns with bare word');		##
	is($f->get_foo, 2, 'returns with get');			##
	$f->clear_foo();
	ok(!$f->get_foo, 'unset');				##
	$f->raise_foo();
	ok($f->get_foo, 'raise');				##
	
	eval { $f->bar(1) };
	ok($@, 'bar is private in main');			##
	my $h2;
	$main::destroyed = 0;
	{
		my $h = $package->new();
	}
	is($main::destroyed, 1, 'destroyed');			##

	is($f->readonly_chumba(2), 2, 'readonly set');
	is($f->chumba, 2, 'readonly set set the val');		##
	eval { $f->set_chumba(4) };
	like($@, qr/readonly/, 'setting a readonly fails');	##
	is($f->chumba, 2, 'readonly still set');		##

## Bug in Perl that keeps this from working.
#	$f->set_lemmy(1);
#	is($f->lemmy, 1, 'Getting ready for lvalue test');	##
#	$f->lv_lemmy += 2;
#	is($f->lemmy, 3, 'lvalue worked with +=');		##
#	++$f->lv_lemmy;
#	is($f->lemmy, 4, 'lvalue worked with ++');		##
#	$f->lv_lemmy -= 3;
#	is($f->lemmy, 1, 'lvalue worked with -=');		##

	$f->set_monkey_boy(1);
	ok($f->monkey_boy, 'Methods with underscores.');	##
}


package Foo;
use base qw(Class::Simple);

Foo->privatize(qw(bar));
my $f = Foo->new();
main::run_tests($f, __PACKAGE__);

sub DEMOLISH
{
	$main::destroyed = 1;
}

sub BUILD
{
my $self = shift;

	$self->zomba(333);
}

1;


#
#	Inheritance
#

package Foobie;
use base qw(Foo);

my $fb = Foobie->new();
main::run_tests($fb, __PACKAGE__);

1;
