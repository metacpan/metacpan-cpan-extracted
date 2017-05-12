use strict;

use lib 't/lib';

use Test::More tests => 12;

BEGIN {
    use_ok('Class::LazyLoad', 'Test2', 'Test8', 'Test9');
    use_ok('Test4');
}

# test overloaded object, with un-overloaded operator

my $test4 = Test4->new();
isa_ok($test4, 'Test4');

eval {
    my $x = 2 - $test4;
};
is($@, "LazyLoaded object 'Test4' does not overloaded '-'\n", '... got the error we expected');

# test un-overloaded object

my $test2 = Test2->new();
isa_ok($test2, 'Test2');

eval {
    my $x = 2 + $test2;
};
is($@, "LazyLoaded object 'Test2' is not overloaded, cannot perform '+'\n", '... got the error we expected');

# test incorrect method

eval {
    $test2->Fail()
};
is($@, "Cannot call 'Fail' on an instance of 'Test2'\n", '... got the error we expected');

# test lazyload() not being able to load a package

eval {
    Class::LazyLoad::lazyload('Fail');
};
like($@, qr/^Could not load \'Fail\' because \: Can\'t locate Fail\.pm in \@INC/, '... got the error we expected');

# test build failures

my $test8 = Test8->new();
isa_ok($test8, 'Test8');

eval {
    $test8->hello();
};
is($@, "INTERNAL ERROR: Cannot build instance of 'Test8'\n", '... got the error we expected');

my $test9 = Test9->new();
isa_ok($test9, 'Test9');

eval {
    $test9->hello();
};
is($@, "INTERNAL ERROR: _build() failed to build a new object\n", '... got the error we expected');
