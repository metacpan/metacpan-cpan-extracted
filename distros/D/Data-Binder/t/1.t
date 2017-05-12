# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;
BEGIN { use_ok('Data::Binder') };
require_ok('Data::Binder');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Data::Binder;
#use Data::Dumper;
my $binder = new Data::Binder();
ok($binder, 'binder created');
ok($binder->bound(), 'empty binder considered bound');
ok($binder->bind(a=>'ay',b=>'bee',c=>undef),
   'binder took three terms');
ok((not $binder->bound('c')), 'a specific term is still unbound');
ok((not $binder->bound()), 'some term is still unbound');
ok($binder->bindable(a=>'ay',c=>'see'),
   'unbound term could take a value');
ok((not $binder->bound()), 'still unbound after read-only bindable check');
ok($binder->bound('a'), 'single term check');
ok($binder->bound('a', 'b'), 'multiple term check');
