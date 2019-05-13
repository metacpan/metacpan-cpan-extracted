#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

use Test2::Require::Module qw( Algorithm::Loops );
use Test2::Require::Module qw( List::MoreUtils );

use Algorithm::Loops qw( NestedLoops );
use List::MoreUtils qw( zip );

use Curio::Factory;

my %possibles = (
    resource_method_name   => [undef, 'chi'],
    registers_resources    => [undef, 1],
    does_caching           => [undef, 1],
    cache_per_process      => [undef, 1],
    allow_undeclared_keys  => [undef, 1],
    default_key            => [undef, 'random'],
    key_argument           => [undef, 'connection_key'],
    add_key                => [0, 1],
    alias_key              => [0, 1],
);

my @keys = (sort keys %possibles);

my @permutations;
NestedLoops(
    [
        map { $possibles{$_} }
        @keys
    ],
    sub { push @permutations, [@_] },
);

my @tests = (
    map { { zip @keys, @$_ } }
    @permutations
);

my $class_iter = 0;

foreach my $test (@tests) {
    $class_iter++;
    my $class = "CC$class_iter";
    $test->{class} = $class;

    my $add_key = delete $test->{add_key};
    my $alias_key = delete $test->{alias_key};

    $test = {
        map { $_ => $test->{$_} }
        grep { defined( $test->{$_} ) ? $_ : () }
        keys %$test
    };

    my $factory = Curio::Factory->new( $test );

    $factory->add_key(
        geo_ip => (
            driver => 'Memory',
            global => 0,
        ),
    ) if $add_key;

    $factory->alias_key(
        foo => 'geo_ip',
    ) if $alias_key and $add_key;

    ok( 1, 'made factory object' );
}

done_testing;
