# $Id: isa.t,v 1.1 2007/04/03 19:47:16 sullivan Exp $
#
#	BUILD is supposed to happen at the oldest ancestor first, then
#	go down the family tree.  This tests that.

use Test::More tests => 1;

my $foo = Foo3->new();						##
ok($foo, 'BUILD starts at the furthest ancestor.');

package Foo1;
use base(Class::Simple);

sub BUILD
{
my $self = shift;

	$self->set_chumba(1);
}

1;

package Foo2;
use base(Foo1);

sub BUILD
{
my $self = shift;

	die("chumba not set!") unless $self->chumba;
	$self->set_wumba(1);
}

1;

package Foo3;
use base(Foo2);

sub BUILD
{
my $self = shift;

	die("wumba not set!") unless $self->wumba;
}

1;
