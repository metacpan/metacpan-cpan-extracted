# this is bug RT #71438
use 5.008;

use strict;
use warnings;

use Test::More;
use DBI;

my $dbh = DBI->connect('dbi:Mock:', '',  '', { PrintError => 0, RaiseError => 1});

my $query = 'SELECT foo, bar FROM baz WHERE id=?';
my @session = (
    {
        statement => $query,
        results   => [
            ['foo', 'bar'],
            [1, 'test1'],
            [2, 'test2']
        ],
        bound_params => [ 1 ],
    },
    {
        statement => $query,
        results   => [
            ['abc', 'xyz'],
            [7, 'test7'],
            [8, 'test8']
        ],
        bound_params => [ 2 ],
    },
);
$dbh->{mock_session} = DBD::Mock::Session->new(@session);

# First query
my $sth = $dbh->prepare($query);
$sth->execute(1);

is_deeply(
    $sth->fetchrow_hashref(),
    {foo => 1, bar => 'test1'}
);

is_deeply(
    $sth->fetchrow_hashref(),
    {foo => 2, bar => 'test2'}
);

is_deeply(
    $sth->fetchrow_hashref(),
    undef
);

# Second query
$sth = $dbh->prepare($query);
$sth->execute(2);

is_deeply(
    $sth->fetchrow_hashref(),
    {abc => 7, xyz => 'test7'}
);

is_deeply(
    $sth->fetchrow_hashref(),
    {abc => 8, xyz => 'test8'}
);

is_deeply(
    $sth->fetchrow_hashref(),
    undef
);

done_testing();
