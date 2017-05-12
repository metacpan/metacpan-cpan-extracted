use Data::SingletonManager;
use Test::More tests => 14;

my $make = sub { return Data::SingletonManager->instance(@_, creator => \&create); };

my $one = $make->(key => "one");
my $two = $make->(key => "two");

is($one->[0], 1, "is one");
is($two->[0], 2, "is two");

my $still_one = $make->(key => "one");
is($one, $still_one, "one is still one");

my $three = $make->(key => "three");
is($three->[0], 3, "is three");

Data::SingletonManager->clear("main");
is($make->(key => "one")->[0], 4, "post clear main");

Data::SingletonManager->clear("non-exist");
is($make->(key => "one")->[0], 4, "post clear non-exist, still 4");

Data::SingletonManager->clear;
is($make->(key => "one")->[0], 5, "post clear default, now 5");

Data::SingletonManager->clear_all;
is($make->(key => "one")->[0], 6, "post clear_clear, now 6");

is($make->(key => "one", namespace => "foo")->[0], 7, "in foo, one is 7");
is($make->(key => "one")->[0],                     6, "back in main, one is 6");
Data::SingletonManager->clear("foo");
is($make->(key => "one", namespace => "foo")->[0], 8, "in foo, one is 8 now");

my @foos = Data::SingletonManager->instances("foo");
is(scalar @foos, 1, "foo namespace is 1 deep");
is($foos[0][0],  8, "foo namespace has only 8");

my $create_n = 0;
sub create {
    $create_n++;
    return [ $create_n ];
}


ok(1);
