#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use AI::Perceptron::Simple;

my $module_name = "AI::Perceptron::Simple";
my $initial_value = 1.5;
my @attributes = qw( glossy_look has_flowers );

# print AI::Perceptron::Simple::LEARNING_RATE;

# all important parameter test
my $perceptron = AI::Perceptron::Simple->new( {
    initial_value => $initial_value,
    attribs => \@attributes
} );

is( ref $perceptron, $module_name, "Correct object" );

# default learning_rate() threshold()
is( $perceptron->learning_rate, 0.05, "Correct default learning rate -> ".$perceptron->learning_rate );
is( $perceptron->threshold, 0.5, "Correct default passing rate -> ".$perceptron->threshold );

# new learning_rate() threshold()
# direct invocation is seldom used, but might be useful in some ways if there's a loop
$perceptron->learning_rate(0.123);
is( $perceptron->learning_rate, 0.123, "Correct new learning_rate -> ".$perceptron->learning_rate );

$perceptron->threshold(0.4);
is( $perceptron->threshold, 0.4, "Correct new passing rate -> ".$perceptron->threshold );

$perceptron = AI::Perceptron::Simple->new( {
    initial_value => $initial_value,
    learning_rate => 0.3,
    threshold => 0.85,
    attribs => \@attributes
} );
is( $perceptron->learning_rate, 0.3, "Correct custom learning_rate -> ".$perceptron->learning_rate );
is( $perceptron->threshold, 0.85, "Correct custom passing rate -> ".$perceptron->threshold );

# get_attributes()
my %attributes = $perceptron->get_attributes;
for ( @attributes ) {
    ok( $attributes{ $_ }, "Attribute \'$_\' present" );
    is( $attributes{ $_ }, $initial_value, "Correct initial value (".$attributes{$_}.") for  \'$_\'" );
}

# don't try to use Test::Carp, it won't work, it only tests for direct calling of carp and croak etc
subtest "Caught missing mandatory parameters" => sub {
    eval {
        my $no_attribs = AI::Perceptron::Simple->new( { initial_value => $initial_value} );
    };
    like( $@, qr/attribs/, "Caught missing attribs" );
    
    eval {
        my $perceptron = AI::Perceptron::Simple->new( { attribs => \@attributes} );
    };
    like($@, qr/initial_value/, "Caught missing initial_value");
    
    #my $no_both = AI::Perceptron::Simple->new; # this will fail and give output to use hash ref, nice
    eval { my $no_both = AI::Perceptron::Simple->new( {} ); };
    like( $@, qr/Missing keys: initial_value attribs/, "Caught missing initial_value and attribs" );
};


done_testing();

# besiyata d'shmaya







