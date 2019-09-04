#!/usr/bin/perl
use Test::More tests => 15; 
use strict;
use warnings;
use Test::Exception;
use DBI;
use DBD::Mock;

# This test is designed to expose the bug found in the DBD::Mock
# methods begin_work, commit and rollback (RT #66815), where a failing
# ->prepare invocation (returning nothing) is not detected and the
# undefined value resulting is used anyway. In this test, as in the
# example found in the wild, the failure is triggered by exhaustion of
# the session states.
#
# This is a list of sessions designed to engineer the right condition
# to trigger the bug.  They all start with a dummy statement (so that
# there are at least two states) then the final statement is removed
# before it is passed to DBD::Mock::Session->new (which requires at
# least one state).  The final statements are 'BEGIN WORK', 'COMMIT'
# and 'ROLLBACK', respectively.
#
# Hence, when the test tries to invoke the final state, the session
# will have run out and DBD::Mock->verify_statement will cause the
# prepare method to fail.

my @cases = (
    'begin_work' => [
        {
            statement => 'SELECT something FROM somewhere',
            results => [],
        },
        {
            statement => 'BEGIN WORK',
            results => [],
        },
    ],

    'commit' => [
        {
            statement => 'SELECT something FROM somewhere',
            results => [],
        },
        {
            statement => 'BEGIN WORK',
            results => [],
        },
        {
            statement => 'INSERT INTO foo (bar) VALUES (?);',
            results => [],
            bound_params => [1],
        },
        {
            statement => 'COMMIT',
            results => [],
        },
    ],

    'rollback' => [
        {
            statement => 'SELECT something FROM somewhere',
            results => [],
        },
        {
            statement => 'BEGIN WORK',
            results => [],
        },
        {
            statement => 'INSERT INTO foo (bar) VALUES (?);',
            results => [],
            bound_params => [1],
        },
        {
            statement => 'ROLLBACK',
            results => [],
        },
    ],
);

while(@cases) {
    my ($name, $states) = splice @cases, 0, 2;
    my $case_name = "case $name";

    my $dbh = DBI->connect('dbi:Mock:', '',  '', 
                           { PrintError => 0, 
                             RaiseError => 1 });

    # Add all but the last state of the expected session
    my $missing_state = pop @$states;
    my $num_states = @$states;
    $dbh->{mock_session} = DBD::Mock::Session->new($name => @$states);

    # Execute the initial dummy statement.
    my $state = $states->[0];
    my $sth = $dbh->prepare($state->{statement});
    ok $sth, 
        "$case_name: prepare statement";
        
    ok $sth->execute(),
        "$case_name: execute statement";
    
    # Now try and do the next steps in @session, but using the
    # appropriate transaction methods directly.  This should fail when
    # the session is exhausted with a useful message. (The original
    # bug meant that the message got clobbered by "Can't call method
    # 'execute' on an undefined value".)
    throws_ok {
        # This stlibatement is always the same.
        ok $dbh->begin_work,
            "$case_name: start transaction";

        my $state = $states->[2];
        my $sth = $dbh->prepare($state->{statement});
        ok $sth, 
            "$case_name: prepare statement";
        
        ok $sth->execute(@{$state->{bound_params}}),
            "$case_name: execute statement";

        # get the final operation from the session
        my $operation = lc $missing_state->{statement};

        ok $dbh->$operation,
            "$case_name: $operation transaction";        
    } qr/\QSession states exhausted, only '$num_states' in DBD::Mock::Session\E/;

}
