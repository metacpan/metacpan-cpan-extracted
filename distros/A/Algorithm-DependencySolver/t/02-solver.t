use strict;
use warnings;

use Test::More tests => 5;
use Test::TempDir::Tiny;
use File::Type;
use File::Spec::Functions;
use File::Which;

use Algorithm::DependencySolver::Operation;
use Algorithm::DependencySolver::Solver;

# This tests checks that a Solver object can be created 
# and that the methods on the solver work as expected.

# The testable methods on the Solver object are to_png and to_dot. The other
# more graph-y methods will be tested by the Traversal test.

my @operations = (
    Algorithm::DependencySolver::Operation->new(
        id            => 'First',
        depends       => [ ],
        affects       => [ 'a' ],
        prerequisites => [ ],
    ),
    Algorithm::DependencySolver::Operation->new(
        id            => 'Second',
        depends       => [ 'a' ],
        affects       => [ 'b' ],
        prerequisites => [ ],
    ),
    Algorithm::DependencySolver::Operation->new(
        id            => 'Third',
        depends       => [ 'b' ],
        affects       => [ ],
        prerequisites => [ ],
    ),
);

my $solver = Algorithm::DependencySolver::Solver->new(
    nodes => \@operations
);
ok $solver, 'created Solver object with 3 Operations';

my $ft = File::Type->new();
my $test_tempdir = tempdir();

SKIP: {
    ## Testing that to_png() works correctly

    # requires the "dot" binary from graphviz to exist
    skip("'dot' binary not found", 2) unless (which('dot'));

    my $temp_png = catfile($test_tempdir, 'temp.png');
    $solver->to_png($temp_png);

    ok -f $temp_png, "created temporary png file ($temp_png)";
    is $ft->checktype_filename($temp_png), 'image/x-png', "File::Type thinks it is a PNG file ($temp_png)";
}

SKIP: {
    ## Testing that to_dot() works correctly

    # requires the "dot" binary from graphviz to exist
    skip("'dot' binary not found", 2) unless (which('dot'));

    my $temp_dot = catfile($test_tempdir, 'temp.dot');
    $solver->to_dot($temp_dot);

    ok -f $temp_dot, "created temporary dot file ($temp_dot)";
    is $ft->checktype_filename($temp_dot), 'application/octet-stream', "File::Type thinks it is a dot file ($temp_dot)";
}
