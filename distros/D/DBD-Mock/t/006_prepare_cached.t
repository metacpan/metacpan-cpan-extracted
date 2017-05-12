use strict;

use Test::More tests => 11;

BEGIN {
    use_ok('DBD::Mock');  
    use_ok('DBI');  
}

my $dbh = DBI->connect('dbi:Mock:', '', '');
isa_ok($dbh, 'DBI::db');

foreach my $i ( 1 .. 2 ) {
    my $sth = $dbh->prepare('SELECT foo FROM bar WHERE x = ?');
    $sth->execute($i);
    my $history = $dbh->{mock_all_history};
    is(scalar(@{$history}), $i, "... have $i statement executions");
}

$dbh->{mock_clear_history} = 1;
my $history = $dbh->{mock_all_history};
is(scalar(@{$history}), 0, '... the history has been is cleared');

foreach my $i ( 1 .. 2 ) {
    my $sth = $dbh->prepare_cached('SELECT foo FROM bar WHERE x = ?');
    $sth->execute($i);
    my $history = $dbh->{mock_all_history};
    is(scalar(@{$history}), $i, "... have $i statement executions");
}

my $st_track = $dbh->{mock_all_history}->[0];
isa_ok($st_track, 'DBD::Mock::StatementTrack');

is($st_track->statement, 'SELECT foo FROM bar WHERE x = ?', '... our statements match');

my $params = $st_track->bound_params;
is(scalar(@{$params}), 1, '... got the expected amount of params');
