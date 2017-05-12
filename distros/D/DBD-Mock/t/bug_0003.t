#!/usr/bin/perl
use Test::More tests => 3; 
use strict;
use warnings;
use Test::Exception;
use DBI;
use DBD::Mock;

# This tests that spurious extra ->execute invocations fail with a
# useful message. This is because there was a bug in which
# DBD::Mock->verify_bound_params didn't check that the session had run
# out, and on return out-of-bounds element of the state array is
# accessed, causing an unhelpful error "Can't use an undefined value
# as an ARRAY reference at ../lib/DBD/Mock.pm line 635."

my @session = (
    {
        'statement' => 'INSERT INTO foo (bar) values (?);',
        'results' => [],
        'bound_params' => [1]
    },
);

my $dbh = DBI->connect('dbi:Mock:', '',  '', { PrintError => 0, RaiseError => 1});

# Add just part of the expected session, such that the next step would be a 'BEGIN WORK'
$dbh->{mock_session} = DBD::Mock::Session->new(@session);

# now execute the steps in the session
my $step = $session[0];

my $sth = $dbh->prepare($step->{statement});
ok $sth, 
    "prepare statement";

my $params = $step->{bound_params} || [];
ok $sth->execute(@$params),
    "execute statement";

# Session expects that to be all.  So let's surprise it with another
# ->execute.  It should fail appropriately.
throws_ok {
    ok $sth->execute(@$params),
} qr/\QSession states exhausted, only '1' in DBD::Mock::Session\E/,
    "fails on executing one too many times";
