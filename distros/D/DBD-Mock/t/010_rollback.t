use strict;

use Test::More tests => 38;

BEGIN {
    use_ok('DBI');
}

my $dbh = DBI->connect( 'dbi:Mock:', '', '' );
isa_ok($dbh, 'DBI::db');

$dbh->{PrintError} = 0;

################################################################################

$dbh->{AutoCommit} = 0;
ok( $dbh->{AutoCommit} == 0, "AutoCommit is off" );

ok( $dbh->commit, 'commit() returns true' );
ok( $dbh->rollback, 'rollback() returns true' );

ok( !defined $dbh->begin_work, "begin_work() fails if AutoCommit is off" );
is( $DBI::errstr, 'AutoCommit is off, you are already within a transaction');

my $history = $dbh->{mock_all_history};
ok( @$history == 2, "Correct number of statements" );

is( $history->[0]->statement, 'COMMIT' );
ok( @{$history->[0]->bound_params} == 0, 'No parameters' );

is( $history->[1]->statement, 'ROLLBACK' );
ok( @{$history->[1]->bound_params} == 0, 'No parameters' );

ok( $dbh->{AutoCommit} == 0, "AutoCommit is still off" );

$dbh->{mock_clear_history} = 1;

################################################################################

$dbh->{AutoCommit} = 1;
ok( $dbh->{AutoCommit} == 1, "AutoCommit is on" );

ok( !defined $dbh->commit, "Commit returns false" );
is( $DBI::errstr, "commit ineffective with AutoCommit" );
ok( !defined $dbh->rollback, "Rollback returns false" );
is( $DBI::errstr, "rollback ineffective with AutoCommit" );

ok( $dbh->{AutoCommit} == 1, "AutoCommit is still on" );

$history = $dbh->{mock_all_history};
ok( @$history == 0, "Correct number of statements" );

$dbh->{mock_clear_history} = 1;

################################################################################

$dbh->{AutoCommit} = 1;
ok( $dbh->{AutoCommit} == 1, "AutoCommit is on" );

ok( $dbh->begin_work, 'begin_work() returns true' );
ok( $dbh->{AutoCommit} == 0, "AutoCommit is now off" );

ok( $dbh->rollback, 'rollback() returns true' );
ok( $dbh->{AutoCommit} == 1, "AutoCommit is back on" );

ok( $dbh->begin_work, 'begin_work() returns true' );
ok( $dbh->{AutoCommit} == 0, "AutoCommit is now off" );

ok( $dbh->commit, 'rollback() returns true' );
ok( $dbh->{AutoCommit} == 1, "AutoCommit is back on" );

$history = $dbh->{mock_all_history};
ok( @$history == 4, "Correct number of statements" );

is( $history->[0]->statement, 'BEGIN WORK' );
ok( @{$history->[0]->bound_params} == 0, 'No parameters' );

is( $history->[1]->statement, 'ROLLBACK' );
ok( @{$history->[1]->bound_params} == 0, 'No parameters' );

is( $history->[2]->statement, 'BEGIN WORK' );
ok( @{$history->[2]->bound_params} == 0, 'No parameters' );

is( $history->[3]->statement, 'COMMIT' );
ok( @{$history->[3]->bound_params} == 0, 'No parameters' );

