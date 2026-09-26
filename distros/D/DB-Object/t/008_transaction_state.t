#!perl
##----------------------------------------------------------------------------
## SQL API Abstraction - t/008_transaction_state.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings;
    use vars qw( $DEBUG );
    use lib './lib';
    use Test::More;
    select(($|=1,select(STDERR),$|=1)[1]);
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

eval
{
    require DBD::SQLite;
};

plan( skip_all => 'DBD::SQLite is not installed' ) if( $@ );

use lib 'lib';
use DB::Object;

my $dbh1 = DB::Object->connect(
    driver => 'SQLite',
    database => ':memory:',
    cache_connections => 0,
    id => 'transaction-test-1',
) || die( DB::Object->error );

my $dbh2 = DB::Object->connect(
    driver => 'SQLite',
    database => ':memory:',
    cache_connections => 0,
) || die( DB::Object->error );

is( $dbh1->id, 'transaction-test-1', 'Caller-provided connection id is preserved' );
ok( defined( $dbh2->id ) && length( $dbh2->id ), 'A default connection id is generated' );
isnt( $dbh1->id, $dbh2->id, 'Connection ids differ' );

my $state = DB::Object->transaction_state( $dbh1 );
is( $state->{active}, 0, 'No active transaction initially' );
is( $state->{count}, 0, 'No active transaction count initially' );

ok( $dbh1->begin_work, 'Begin first transaction' );
ok( $dbh1->transaction, 'Wrapper transaction flag is set' );
is( $dbh1->{dbh}->{private_db_object}->{id}, 'transaction-test-1', 'DBI metadata contains connection id' );
ok( $dbh1->{dbh}->{private_db_object}->{transaction}, 'DBI metadata marks transaction active' );

my $transactions = DB::Object->active_transactions;
is( scalar( @$transactions ), 1, 'One active DB::Object transaction found' );
is( $transactions->[0]->{id}, 'transaction-test-1', 'Active transaction exposes connection id' );

$state = DB::Object->transaction_state( $dbh1 );
is( $state->{active}, 1, 'Transaction state is active' );
is( $state->{count}, 1, 'Transaction state count is one' );
is( $state->{id}, 'transaction-test-1', 'Transaction state exposes id' );
is( $state->{same}, 1, 'Candidate using same DBI handle is recognised' );

$state = DB::Object->transaction_state( $dbh2 );
is( $state->{same}, 0, 'Candidate using another DBI handle is recognised' );

ok( $dbh1->rollback, 'Rollback first transaction' );
ok( !$dbh1->transaction, 'Wrapper transaction flag is cleared' );
ok( !$dbh1->{dbh}->{private_db_object}->{transaction}, 'DBI metadata marks transaction finished' );

$state = DB::Object->transaction_state( $dbh1 );
is( $state->{active}, 0, 'No active transaction after rollback' );
is( $state->{count}, 0, 'Transaction count returns to zero' );

done_testing();

__END__
