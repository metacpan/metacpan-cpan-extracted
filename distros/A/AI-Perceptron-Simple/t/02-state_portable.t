#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use AI::Perceptron::Simple qw( :portable_data );
# for :local_data test, see 04-train.t   02-state_synonyms.t utilizes the full invocation

use FindBin;
use constant MODULE_NAME => "AI::Perceptron::Simple";

my @attributes = qw ( has_trees trees_coverage_more_than_half has_other_living_things );

my $total_headers = scalar @attributes;

my $perceptron = AI::Perceptron::Simple->new( {
    initial_value => 0.01,
    attribs => \@attributes
} );

subtest "All data related subroutines found" => sub {
    # this only checks if the subroutines are contained in the package
    ok( AI::Perceptron::Simple->can("preserve_as_yaml"), "&preserve_as_yaml is present" );
    ok( AI::Perceptron::Simple->can("save_perceptron_yaml"), "&save_perceptron_yaml is persent" );

    ok( AI::Perceptron::Simple->can("revive_from_yaml"), "&revive_from_yaml is present" );
    ok( AI::Perceptron::Simple->can("load_perceptron_yaml"), "&load_perceptron_yaml is present" );

};

my $yaml_nerve_file = $FindBin::Bin . "/portable_nerve.yaml";

# save file
save_perceptron_yaml( $perceptron, $yaml_nerve_file );
ok( -e $yaml_nerve_file, "Found the YAML perceptron." );
# load and check
ok( my $transfered_nerve = load_perceptron_yaml( $yaml_nerve_file ), "&loaded_perceptron_from_YAML" );

is_deeply( $transfered_nerve, $perceptron, "&load_perceptron_yaml - correct data after loading" );
is ( ref ($transfered_nerve), "AI::Perceptron::Simple", "Loaded back as a blessed object" );

# test synonyms
AI::Perceptron::Simple::preserve_as_yaml( $perceptron, $yaml_nerve_file );
ok( -e $yaml_nerve_file, "Synonym - Found the YAML perceptron." );

ok( $transfered_nerve = AI::Perceptron::Simple::revive_from_yaml( $yaml_nerve_file ), "&revive_from_yaml is working correctly" );

is_deeply( $transfered_nerve, $perceptron, "&revive_from_yaml - correct data after loading" );
is ( ref ($transfered_nerve), "AI::Perceptron::Simple", "Loaded back as a blessed object" );

done_testing();

# besiyata d'shmaya


