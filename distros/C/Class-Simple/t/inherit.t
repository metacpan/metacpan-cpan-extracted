# $Id: inherit.t,v 1.1 2007/10/08 18:23:19 sullivan Exp $

use Test::More tests => 2;
BEGIN { use_ok('Class::Simple') };				##

my $moo = Bar->new();
is($moo->foo, 2, "Inheritance called BUILD in right order.");	##

package Foo;
use base qw(Class::Simple);

sub BUILD
{
my $self = shift;

	$self->set_foo(1);
}

1;

package Bar;
use base qw(Foo);

sub BUILD
{
my $self = shift;

	$self->set_foo(2);
}

1;
