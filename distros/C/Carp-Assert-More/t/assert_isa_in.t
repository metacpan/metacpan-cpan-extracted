#!perl -Tw

use warnings;
use strict;

use Test::More tests => 13;
use Carp::Assert::More;

use Test::Exception;

my $rc = eval 'assert_isa_in(undef)';
is( $rc, undef, 'Fails the eval' );
like( $@, qr/Not enough arguments for Carp::Assert::More::assert_isa_in/, 'Prototype requires two arguments' );

dies_ok { assert_isa_in(undef, undef) } 'Dies with one undef argument';
dies_ok { assert_isa_in(bless({}, 'x'), [] ) } 'No types passed in';
dies_ok { assert_isa_in('z', []) } 'List of empty types does not allow you to pass non-objects';

lives_ok { assert_isa_in( bless({}, 'x'), [ 'x' ] ) } 'One out of one';
dies_ok  { assert_isa_in( bless({}, 'x'), [ 'y' ] ) } 'Zero out of one';
lives_ok { assert_isa_in( bless({}, 'x'), [ 'y', 'x' ] ) } 'One out of two';

@y::ISA = ( 'x' );
my $x = bless {}, 'y';
isa_ok( $x, 'y', 'Verifying our assumptions' );
lives_ok { assert_isa_in( bless({}, 'y'), [ 'y' ] ) } 'Matches child class';
lives_ok { assert_isa_in( bless({}, 'y'), [ 'x' ] ) } 'Matches base class';
dies_ok  { assert_isa_in( bless({}, 'x'), [ 'y' ] ) } 'Parent does not match child';


subtest assert_isa_in => sub {
    plan tests => 8;

    package a;
    sub foo {}
    package main;
    my $aa = bless {}, 'a';

    package b;
    sub foo {}
    package main;
    my $bb = bless {}, 'b';

    package c;
    sub foo {}
    package main;
    my $cc = bless {}, 'c';

    package d;
    use base 'a';
    use base 'b';
    use base 'c';
    package main;
    my $dd = bless {}, 'd';

    lives_ok( sub { assert_isa_in($aa, ['a']) }, 'Basic a' );
    lives_ok( sub { assert_isa_in($aa, ['a', 'b', 'c']) }, 'Basic a, b, c' );
    foreach my $class ( ref $aa, ref $bb, ref $cc ) {
        lives_ok( sub { assert_isa_in($dd, [$class]) }, "Inheritance for $class" );
    }

    my $failure_regex = qr/ssertion failed/;
    foreach my $class ( ref $aa, ref $bb, ref $cc ) {
        throws_ok( sub { assert_isa_in($class, ['d']) }, $failure_regex, "No backwards-inheritance for $class" );
    }
};

done_testing();
exit 0;
