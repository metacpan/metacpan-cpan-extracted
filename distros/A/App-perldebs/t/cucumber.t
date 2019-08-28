use strict;
use warnings;

=pod

This is basically taken from the documentation of Test::BDD::Cucumber.
I added the skipping of the tests unless the environment variable
RUN_ACCEPTANCE_TESTS is set to a true value.

Rationale: Running the acceptance tests does only make sense after
the unit tests are run.

=cut

#use FindBin::libs;

use Test::More;

# This will find step definitions and feature files in the directory you point
# it at below
use Test::BDD::Cucumber::Loader;

# This harness prints out nice TAP
use Test::BDD::Cucumber::Harness::TestBuilder;

SKIP: {
    skip 'Acceptance test are skipped' if !$ENV{RUN_ACCEPTANCE_TESTS};

    # Load a directory with Cucumber files in it. It will recursively execute any
    # file matching .*_steps.pl as a Step file, and .*\.feature as a feature file.
    # The features are returned in @features, and the executor is created with the
    # step definitions loaded.
    my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load('t/features/');

    # Create a Harness to execute against. TestBuilder harness prints TAP
    my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new( {} );

    # For each feature found, execute it, using the Harness to print results
    $executor->execute( $_, $harness ) for @features;
}

done_testing;
