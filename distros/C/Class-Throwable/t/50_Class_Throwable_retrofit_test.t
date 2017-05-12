#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;

BEGIN {
    use_ok('Class::Throwable' => (
                'InsufficientArguments'
                ));
    use_ok('Class::Throwable' => (
                retrofit => 'My::Test::Package'
                ));
    use_ok('Class::Throwable' => (
                retrofit => 'My::Other::Test::Package' => sub {
                    if ($_[0] =~ /Insufficient Arguments/) {
                        InsufficientArguments->throw(@_);                    
                    }
                    else {
                        Class::Throwable->throw(@_);
                    }
                }
                ));                
}

{
    package My::Test::Package;
    sub test { die 'This will be a Class::Throwable exeception' }

    package My::Other::Test::Package;
    sub test { die 'Insufficient Arguments : This will be a InsufficientArguments exeception' }
    sub other_test { die 'This will be a Class::Throwable exeception' }    
}

eval { My::Test::Package::test() };
isa_ok($@, 'Class::Throwable');
is($@->getMessage(), 'This will be a Class::Throwable exeception', '... got the right message too');

eval { My::Other::Test::Package::test() };
isa_ok($@, 'InsufficientArguments');
isa_ok($@, 'Class::Throwable');

is($@->getMessage(), 'Insufficient Arguments : This will be a InsufficientArguments exeception', '... got the right message too');

eval { My::Other::Test::Package::other_test() };
isa_ok($@, 'Class::Throwable');
is($@->getMessage(), 'This will be a Class::Throwable exeception', '... got the right message too');

eval "use Class::Throwable 'retrofit';";
like($@, 
    qr/You must specify a module for Class\:\:Throwable to retrofit/, 
    '... got the exception we expected');
    