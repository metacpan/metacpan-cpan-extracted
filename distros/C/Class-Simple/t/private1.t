# $Id: private1.t,v 1.4 2007/10/02 23:04:47 sullivan Exp $

package Foo;
use Test::More tests => 7;
BEGIN { use_ok('Class::Simple') };		##

use base qw(Class::Simple);

my $buildit;
sub BUILD
{
my $self = shift;
$buildit = shift;

}

Foo->privatize(qw(bar));
my $f = Foo->new(3);
is($buildit, 3, 'BUILD got extra args');	##
eval { $f->bar(1) };
diag($@) if $@;
ok(!$@, 'bar is private in Foo');		##

is($f->_bar, 1, 'underscore get');		##
$f->set_bar(2);
is($f->_bar, 2, 'second underscore get');	##

$f->set__shh(2);
ok($f->_shh, 'Set double-underscore.');		##
is($f->get__shh, 2, 'Get double-underscore.');	##

1;
