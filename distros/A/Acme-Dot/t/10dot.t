package Foo;
#use Test::More 'no_plan';
use Test::More tests => 6;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    use_ok('Acme::Dot') or die;
}

sub new { bless {}, shift }
sub test1 {
    my $obj = shift;
    isa_ok($obj, "Foo");
    is($obj, $main::testobj, "Object is what we expect");
    is_deeply(\@_, [1,2,3], "Args passed");
}

package main;

Test::More->import();
BEGIN { Foo->import(); };

our $testobj = new Foo;
$testobj.test1(1,2,3);

my $y = "not an object";
is($y.test2(1), "not an object1", "Non-objects still work");

sub test2 {
    is(@_, 1, "Args passed");
    return 1
}
