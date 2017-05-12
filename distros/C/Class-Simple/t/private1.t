# $Id: private1.t,v 1.5 2008/02/01 00:39:26 sullivan Exp $

package Foo;
use Test::More tests => 9;
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
is($f->__shh, 2, 'Set double-underscore.');	##
is($f->get__shh, 2, 'Get double-underscore.');	##
ok(!$f->_shh, '__shh did not set _shh.');	##
ok(!$f->get_shh, '_shh did not set shh.');	##

1;
