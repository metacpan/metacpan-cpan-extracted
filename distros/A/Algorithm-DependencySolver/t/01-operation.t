use strict;
use warnings;

use Test::More tests => 8;

use Algorithm::DependencySolver::Operation;

# This test checks that Operation objects can be created
# with various different options which should make sense.

{
    ## operation with...
    ##  no resources it depends on
    ##  no resources it affects
    ##  no prerequesites
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ ],
        affects       => [ ],
        prerequisites => [ ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... no depends, no affects, no prerequesites';
}

{
    ## operation with...
    ##  one resource it depends on
    ##  no resources it affects
    ##  no prerequesites
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ 'a' ],
        affects       => [ ],
        prerequisites => [ ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... 1 depend, no affects, no prerequesites';
}

{
    ## operation with...
    ##  two resources it depends on
    ##  no resources it affects
    ##  no prerequesites
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ 'a', 'b' ],
        affects       => [ ],
        prerequisites => [ ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... 2 depends, no affects, no prerequesites';
}

{
    ## operation with...
    ##  no resources it depends on
    ##  one resource it affects
    ##  no prerequesites
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ ],
        affects       => [ 'a' ],
        prerequisites => [ ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... no depends, 1 affects, no prerequesites';
}

{
    ## operation with...
    ##  no resources it depends on
    ##  two resources it affects
    ##  no prerequesites
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ ],
        affects       => [ 'a', 'b' ],
        prerequisites => [ ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... no depends, 2 affects, no prerequesites';
}

{
    ## operation with...
    ##  no resources it depends on
    ##  no resources it affects
    ##  one prerequesite
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ ],
        affects       => [ ],
        prerequisites => [ 'a' ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... no depends, no affects, 1 prerequesite';
}

{
    ## operation with...
    ##  no resources it depends on
    ##  no resources it affects
    ##  two prerequesites
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ ],
        affects       => [ ],
        prerequisites => [ 'a', 'b' ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... no depends, no affects, 2 prerequesites';
}

{
    ## operation with...
    ##  one resource it depends on
    ##  two resources it affects
    ##  three prerequesites
    my $operation = Algorithm::DependencySolver::Operation->new(
        id            => 1,
        depends       => [ 'a' ],
        affects       => [ 'b', 'c' ],
        prerequisites => [ 'd', 'e', 'f' ],
        obj           => bless({}, "Object"),
    );

    ok $operation, 'operation with... 1 depend, 2 affects, 3 prerequesites';
}
