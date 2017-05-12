# $Id: override.t,v 1.1 2007/10/08 19:19:18 sullivan Exp $

use Test::More tests => 6;
BEGIN { use_ok('Class::Simple') };				##

my $moo = Foo->new();
$moo->set_moo(1);
is($moo->moo, 1, "Base class set.");				##

my $woof = Bar->new();
$woof->set_moo(1);
is($woof->get_moo, 4, "Derived class override.");		##
is($woof->moo, 4, "Derived class override.");			##

$woof->moo(5);
is($woof->get_moo, 8, "Derived class override.");		##
is($woof->moo, 8, "Derived class override.");			##

package Foo;
use base qw(Class::Simple);

1;


package Bar;
use base qw(Foo);

sub set_moo
{
my $self = shift;
my $val = shift;

	$self->set__moo($val + 1);
}


sub get_moo
{
my $self = shift;
my $val = shift;

	return ($self->get__moo + 2);
}

1;
