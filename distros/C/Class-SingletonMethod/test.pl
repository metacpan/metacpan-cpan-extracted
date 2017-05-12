# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use_ok("Class::SingletonMethod");

my $count = 23;
sub new { bless { id => $count++ }, shift }

my $a = main->new;
my $b = main->new;

$a->singleton_method(id => sub { $_[0]->{id} });
$a->isa_ok("main");

ok($a->can("id"), "a has the new method");
ok(!$b->can("id"), "b does not");
is($a->id, 23, "It does what I expect it to");

$a->singleton_method(id => sub { Test::More::ok(1,"Redefining the method works") }); 

$a->id;
