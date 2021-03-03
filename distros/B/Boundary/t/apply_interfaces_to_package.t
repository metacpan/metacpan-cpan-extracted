use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Boundary ();

subtest 'no interfaces' => sub {
    eval {
        Boundary->apply_interfaces_to_package('Foo');
    };
    like $@, qr/No interfaces supplied!/;
};

subtest 'not found interface' => sub {
    eval {
        Boundary->apply_interfaces_to_package('Foo', 'NoFoo');
    };
    like $@, qr/cannot load interface package:/;
};

subtest 'basic' => sub {

    my @ASSERT_REQUIRES;
    no warnings 'redefine';
    *Boundary::assert_requires = sub { push @ASSERT_REQUIRES => [$_[1], $_[2]]; };

    eval {
        Boundary->apply_interfaces_to_package('Foo', 'IFoo', 'IBar');
    };
    is_deeply \@ASSERT_REQUIRES, [
        ['Foo', 'IFoo'],
        ['Foo', 'IBar'],
    ];
    is_deeply $Boundary::INFO{Foo}{interface_map}, { IFoo => 1, IBar => 1 };
};

done_testing;
