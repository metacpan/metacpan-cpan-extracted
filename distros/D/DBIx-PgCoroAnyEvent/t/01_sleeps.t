use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::More;
use DBI;
use Coro;
use AnyEvent;
use Coro::AnyEvent;
use Time::HiRes 'time';
use PgSet;

SKIP: {
	eval {PgSet::initdb};
	skip "no PostgreSQL found" if $@;
	ok(PgSet::startdb, 'local postgres db started');

	sub db_connect {
		DBI->connect(
			"dbi:Pg:dbname=postgres",
			$PgSet::testuser,
			"",
			{   AutoCommit => 1,
				RootClass  => 'DBIx::PgCoroAnyEvent'
			}
		);
	}

	my $cv = AE::cv;

	ok(my $dbh = db_connect(), 'connected');
	ok(my $sth = $dbh->prepare('select pg_sleep(2)'), 'prepared');
	my $start_time = time;
	ok($sth->execute(), 'executed');
	my $duration = time - $start_time;
	ok(($duration > 1 && $duration < 3), 'slept');
	is(ref($dbh), 'DBIx::PgCoroAnyEvent::db', 'dbh class');
	is(ref($sth), 'DBIx::PgCoroAnyEvent::st', 'sth class');

	for my $t (1 .. 10) {
		my $timer;
		$cv->begin;
		$timer = AE::timer 0.01 + $t / 100, 0, unblock_sub {
			ok(my $dbh = db_connect(), "connected $t");
			ok(my $sth = $dbh->prepare('select pg_sleep(' . $t . ')'), "prepared $t");
			my $start_time = time;
			ok($sth->execute(), "executed $t");
			my $duration = time - $start_time;
			ok(($duration > $t - 1 && $duration < $t + 1), "slept $t");
			print "duration: $t: $duration\n";
			$cv->end;
			undef $timer;
		};
	}

	$cv->recv;

	print "total run time: " . (time - $start_time) . " sec\n";
}
done_testing();
