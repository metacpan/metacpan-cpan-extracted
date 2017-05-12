# $Id: separate_vars.t,v 1.2 2008/01/30 18:02:37 sullivan Exp $

use Test::More skip_all => 'Problem with multiple inheritance.';
#use Test::More tests => 6;
BEGIN { use_ok('Class::Simple') };				##

my $moo = Moo->new();
$moo->set_foo(2);
is($moo->foo, 2, "Just in case.");				##
$moo->set_Foo_foo();
is($moo->foo, 2, "Inherited class didn't change me.");		##
$moo->set_Bar_foo();
is($moo->foo, 2, "Inherited class didn't change me.");		##
is($moo->get_Foo_foo, 3, "Foo_foo set properly.");			##
is($moo->get_Bar_foo, 4, "Bar_foo set properly.");			##

package Foo;
use base qw(Class::Simple);

sub BUILD
{
my $self = shift;

	$self->set_foo(1);
}

sub set_Foo_foo
{
my $self = shift;

	$self->set_foo(3);
}

sub get_Foo_foo
{
my $self = shift;

	return $self->get_foo();
}

1;

package Bar;
use base qw(Class::Simple);

sub BUILD
{
my $self = shift;

	$self->set_foo(2);
}

sub set_Bar_foo
{
my $self = shift;

	$self->set_foo(4);
}

sub get_Bar_foo
{
my $self = shift;

	return $self->get_foo();
}

1;

package Moo;
use base qw(Foo Bar);

1;
