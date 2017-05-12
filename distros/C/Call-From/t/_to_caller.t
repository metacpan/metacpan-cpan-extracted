use strict;
use warnings;

use Test::More 0.95_02;    # subtest w/ no plan

# ABSTRACT: Check _to_caller() using implied "fake this many levels up" behaviour

use Call::From;

use constant _file => sub { [caller]->[1] }
  ->();

subtest "_to_caller(NUM)" => sub {
    is_deeply(
        [ KENTNL::Top::top_function( 0, 0 ) ],
        [ 'KENTNL::DeepChild', _file, 1000 ],
        "_to_caller(0,0)"
    );
    is_deeply(
        [ KENTNL::Top::top_function( 1, 0 ) ],
        [ 'KENTNL::Child', _file, 2000 ],
        "_to_caller(1,0)"
    );
    is_deeply(
        [ KENTNL::Top::top_function( 2, 0 ) ],
        [ 'KENTNL::Top', _file, 3000 ],
        "_to_caller(2,0)"
    );
    is_deeply(
        [ KENTNL::Top::top_function( -1, 1 ) ],
        [ 'KENTNL::DeepChild', _file, 1000 ],
        "_to_caller(-1,1)"
    );
    is_deeply(
        [ KENTNL::Top::top_function( 0, 1 ) ],
        [ 'KENTNL::Child', _file, 2000 ],
        "_to_caller(0,1)"
    );
    is_deeply(
        [ KENTNL::Top::top_function( 1, 1 ) ],
        [ 'KENTNL::Top', _file, 3000 ],
        "_to_caller(1,1)"
    );
};

my $pkg = 'KENTNL::Fake::Package';

subtest "_to_caller(PKGNAME)" => sub {
    is_deeply(
        [ KENTNL::Top::top_function( $pkg, 0 ) ],
        [ $pkg, _file, 1000 ],
        "_to_caller(<name>,0)",
    );

    is_deeply(
        [ KENTNL::Top::top_function( $pkg, 1 ) ],
        [ $pkg, _file, 2000 ],
        "_to_caller(<name>,1)",
    );
};

subtest "_to_caller([])" => sub {
    is_deeply(
        [ KENTNL::Top::top_function( [], 0 ) ],
        [ 'KENTNL::DeepChild', _file, 1000 ],
        "_to_caller([], 0)",
    );

    is_deeply(
        [ KENTNL::Top::top_function( [], 1 ) ],
        [ 'KENTNL::Child', _file, 2000 ],
        "_to_caller([], 1)",
    );
};

subtest "_to_caller([PKG])" => sub {
    is_deeply(
        [ KENTNL::Top::top_function( [$pkg], 0 ) ],
        [ $pkg, _file, 1000 ],
        "_to_caller([PKG], 0)",
    );

    is_deeply(
        [ KENTNL::Top::top_function( [$pkg], 1 ) ],
        [ $pkg, _file, 2000 ],
        "_to_caller([PKG], 1)",
    );
};
subtest "_to_caller([PKG, FILE])" => sub {
    my $file = 'bogus/file';
    is_deeply(
        [ KENTNL::Top::top_function( [ $pkg, $file ], 0 ) ],
        [ $pkg, $file, 1000 ],
        "_to_caller([PKG,FILE], 0)",
    );

    is_deeply(
        [ KENTNL::Top::top_function( [ $pkg, $file ], 1 ) ],
        [ $pkg, $file, 2000 ],
        "_to_caller([PKG,FILE], 1)",
    );
};

subtest "_to_caller([PKG, FILE, LINE])" => sub {
    my $file = 'bogus/file';
    my $line = 1234;
    is_deeply(
        [ KENTNL::Top::top_function( [ $pkg, $file, $line ], 0 ) ],
        [ $pkg, $file, $line ],
        "_to_caller([PKG,FILE,LINE], 0)",
    );

    is_deeply(
        [ KENTNL::Top::top_function( [ $pkg, $file, $line ], 1 ) ],
        [ $pkg, $file, $line ],
        "_to_caller([PKG,FILE,LINE], 1)",
    );
};

subtest "_to_caller(undef)" => sub {
    is_deeply(
        [ KENTNL::Top::top_function( undef, 0 ) ],
        [ 'KENTNL::DeepChild', _file, 1000 ],
        "_to_caller(undef, 0)",
    );

    is_deeply(
        [ KENTNL::Top::top_function( undef, 1 ) ],
        [ 'KENTNL::Child', _file, 2000 ],
        "_to_caller(undef, 1)",
    );
};

done_testing;

{

    package KENTNL::DeepChild;

    sub child_function {
# line 1000
        my (@result) = Call::From::_to_caller(@_);
    }
}
{

    package KENTNL::Child;

    sub child_function {
# line 2000
        KENTNL::DeepChild::child_function(@_);
    }
}
{

    package KENTNL::Top;

    sub top_function {
# line 3000
        KENTNL::Child::child_function(@_);
    }
}

