use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::More;
use DBI;
use Coro;
use AnyEvent;
use Coro::AnyEvent;
use Time::HiRes 'time';
use DBIx::Connector::Pool;
use DBIx::Connector;
use PgSet;

SKIP: {
	eval {PgSet::initdb};
	skip "no PostgreSQL found" if $@;
	ok(PgSet::startdb, 'local postgres db started');

	my $tc = DBIx::Connector->new("dbi:Pg:dbname=postgres", $PgSet::testuser, '', {RootClass => 'DBIx::PgCoroAnyEvent'})
		or die DBI::errstr;
	async {
		$tc->run(
			sub {
				my $sel = -int(rand(10));
				my $sth = $_->prepare(q{select abs(?)});
				$sth->execute($sel);
				my ($res) = $sth->fetchrow_array;
				is($res, abs($sel), 'true connector fetchrow_array');
				($res) = $_->selectrow_array(q{select abs(?)}, undef, $sel);
				is($res, abs($sel), 'true connector selectrow_array');
			}
		);
	}
	->join;
	my @pool_wait_queue;
	$DBIx::Connector::Pool::Item::not_in_use_event = sub {
		if (my $wc = shift @pool_wait_queue) {
			$wc->ready;
		}
		$_[0]->used_now;
	};

	ok(
		my $pool = DBIx::Connector::Pool->new(
			dsn        => "dbi:Pg:dbname=postgres",
			user       => $PgSet::testuser,
			password   => '',
			initial    => 1,
			keep_alive => 1,
			max_size   => 5,
			tid_func   => sub {"$Coro::current" =~ /(0x[0-9a-f]+)/i; hex $1},
			wait_func  => sub {push @pool_wait_queue, $Coro::current; Coro::schedule;},
			attrs => {RootClass => 'DBIx::PgCoroAnyEvent'}
		),
		'created pool'
	);

	my @async;
	for my $th (1 .. 10) {
		push @async, async {
			my $connector = $pool->get_connector;
			$connector->run(
				sub {
					my $sel = -int(rand(10));
					my $sth = $_->prepare(q{select abs(?)});
					$sth->execute($sel);
					my ($res) = $sth->fetchrow_array;
					is($res, abs($sel), $th . ': pool connector fetchrow_array');
					#				print Dumper [sort {$a <=> $b} map {$_->{tid}} @{$pool->{pool}}],
					#					[sort {$a <=> $b} map {"$_->{connector}" =~ /(0x[0-9a-f]+)/i; hex $1} @{$pool->{pool}}];
					($res) = $_->selectrow_array(q{select abs(?)}, undef, $sel);
					is($res, abs($sel), $th . ': pool connector selectrow_array');
				}
			);
		};
	}

	for (@async) {
		$_->join;
	}

	@async = ();
	Coro::AnyEvent::sleep 2;
	$pool->collect_unused;
	is($pool->connected_size, 1, 'pool shrunken');
	for my $th (1 .. 3) {
		push @async, async {
			my $connector = $pool->get_connector;
			$connector->run(
				sub {
					my $sel = -int(rand(10));
					my $sth = $_->prepare(q{select abs(?)});
					$sth->execute($sel);
					my ($res) = $sth->fetchrow_array;
					is($res, abs($sel), $th . ': pool connector fetchrow_array');
					#				print Dumper [sort {$a <=> $b} map {$_->{tid}} @{$pool->{pool}}],
					#					[sort {$a <=> $b} map {"$_->{connector}" =~ /(0x[0-9a-f]+)/i; hex $1} @{$pool->{pool}}];
					($res) = $_->selectrow_array(q{select abs(?)}, undef, $sel);
					is($res, abs($sel), $th . ': pool connector selectrow_array');
				}
			);
		};
	}

	for (@async) {
		$_->join;
	}
	@async = ();
	is($pool->connected_size, 3, 'pool grown');

	for my $th (1 .. 10) {
		push @async, async {
			my $connector = $pool->get_connector;
			$connector->run(
				sub {
					my $internal_connector = $pool->get_connector;
					ok($connector == $internal_connector, $th . ': internal connector is the same');
					Coro::AnyEvent::sleep 0.05;
				}
			);
		};
	}

	for (@async) {
		$_->join;
	}
	@async = ();
	is($pool->connected_size, 5, 'pool grown max');

	my $cv               = AE::cv;
	my $start_async_time = time;
	for my $th (1 .. 10) {
		$cv->begin;
		push @async, async {
			my $start_connector_time  = time;
			my $connector             = $pool->get_connector;
			my $to_get_connector_time = time - $start_connector_time;
			print "$th: duration to get connector: $to_get_connector_time\n";
			$connector->run(
				sub {
					ok(my $sth = $_->prepare('select pg_sleep(' . $th . ')'), "prepared $th");
					my $start_time = time;
					ok($sth->execute(), "executed $th");
					my $duration = time - $start_time;
					ok(($duration > $th - 1 && $duration < $th + 1), "slept $th");
					print "duration: $th: $duration\n";
					$cv->end;
				}
			);
		};
	}

	$cv->recv;
	my $test_duration = (time - $start_async_time);
	ok($test_duration > 14 && $test_duration < 16, "test duration");
}
done_testing();
