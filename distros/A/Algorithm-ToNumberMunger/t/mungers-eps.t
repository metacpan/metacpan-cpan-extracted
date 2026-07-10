#!perl
# The eps munger against a real iqbi-damiq daemon (Algorithm::EventsPerSecond::
# Sukkal) forked for the duration of the test. Skips when that dist is not
# installed -- the munger itself only speaks the wire protocol and never loads
# it, so this is purely a test-time dependency.
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
	eval { require Algorithm::EventsPerSecond::Sukkal; 1 }
		or plan skip_all => 'Algorithm::EventsPerSecond::Sukkal not available';
	eval { require IO::Socket::UNIX; require Socket; 1 }
		or plan skip_all => 'IO::Socket::UNIX not available';
}

use Algorithm::ToNumberMunger;
my $M = 'Algorithm::ToNumberMunger';

# ---- fork daemons -----------------------------------------------------------
my $dir    = tempdir( CLEANUP => 1 );
my $parent = $$;
my @PIDS;

END {
	if ( $$ == $parent ) {
		for my $p (@PIDS) { kill 'TERM', $p; waitpid $p, 0 }
	}
}

# Fractional sleep via 4-arg select, deliberately: Time::HiRes would be this
# test's only use of it and the dist nominally supports pre-5.8 perls.
sub nap {
	select( undef, undef, undef, $_[0] );    ## no critic (ProhibitSleepViaSelect)
	return;
}

# Fork an iqbi-damiq on $sock_path, wait until it answers PING; returns true
# on ready, false when fork/startup failed. The window is much longer than the
# test will ever run: count/rate assertions read marks made earlier, and a
# short window let them age out under scheduling delay (flaky failures).
sub start_daemon {
	my ( $sock_path, %opts ) = @_;
	my $pid = fork;
	return 0 unless defined $pid;
	if ( !$pid ) {
		my $daemon = Algorithm::EventsPerSecond::Sukkal->new(
			socket => $sock_path,
			window => 300,
			%opts
		);
		local $SIG{TERM} = sub { $daemon->stop };
		$daemon->run;
		exit 0;
	} ## end if ( !$pid )
	push @PIDS, $pid;
	for ( 1 .. 100 ) {
		my $c = IO::Socket::UNIX->new(
			Type => Socket::SOCK_STREAM(),
			Peer => $sock_path
		);
		if ($c) {
			print {$c} "PING\n";
			my $reply = <$c>;
			return 1 if defined $reply && $reply =~ /\AOK PONG/;
		}
		nap(0.1);
	} ## end for ( 1 .. 100 )
	return 0;
} ## end sub start_daemon

my $sock = "$dir/eps.sock";
start_daemon($sock) or plan skip_all => 'iqbi-damiq did not come up';

# ---- mark + read ------------------------------------------------------------
{
	my $rate = $M->build( { munger => 'eps', socket => $sock, prefix => 't1:' } );
	my $r;
	$r = $rate->('k') for 1 .. 5;    # five marks against t1:k
	ok( defined $r && $r >= 0, 'marked rate read back a number' );

	# a meter's rate is count/elapsed-seconds, so a brand-new key reads 0
	# until the second boundary passes; age it, then a read-only rate is > 0.
	nap(1.1);
	my $rate_ro = $M->build(
		{
			munger => 'eps',
			socket => $sock,
			prefix => 't1:',
			mark   => 0
		}
	);
	ok( $rate_ro->('k') > 0, 'rate is positive once the meter has aged' );

	my $total = $M->build(
		{
			munger => 'eps',
			socket => $sock,
			prefix => 't1:',
			read   => 'total',
			mark   => 0
		}
	);
	is( $total->('k'), 5, 'five marks landed (read-only total)' );

	my $count = $M->build(
		{
			munger => 'eps',
			socket => $sock,
			prefix => 't1:',
			read   => 'count',
			mark   => 0
		}
	);
	is( $count->('k'), 5, 'count inside the window' );

	# read-only calls must not have marked
	is( $total->('k'), 5, 'read-only reads do not mark' );
}

# ---- prefix isolation -------------------------------------------------------
{
	my $t2 = $M->build(
		{
			munger => 'eps',
			socket => $sock,
			prefix => 't2:',
			read   => 'total',
			mark   => 0
		}
	);
	is( $t2->('k'), 0, 'same source value under another prefix is a fresh key' );
}

# ---- key sanitization -------------------------------------------------------
{
	my $mark = $M->build(
		{
			munger => 'eps',
			socket => $sock,
			prefix => 't3:',
			read   => 'total'
		}
	);
	my $out = $mark->('has spaces');
	is( $out, 1, 'whitespace in the value is sanitized, mark lands' );

	my $ro = $M->build(
		{
			munger => 'eps',
			socket => $sock,
			prefix => 't3:',
			read   => 'total',
			mark   => 0
		}
	);
	is( $ro->('has_spaces'), 1, 'sanitized key is deterministic (spaces -> _)' );
}

# ---- multi-output: rate + count in one round trip ----------------------------
{
	my $plan = $M->compile(
		tags    => [qw(req_rate req_count)],
		mungers => {
			req => {
				munger => 'eps',
				socket => $sock,
				prefix => 'm1:',
				from   => 'ip',
				parts  => [qw(rate count)],
				into   => [qw(req_rate req_count)]
			},
		},
	);
	my $row;
	$row = $plan->apply_named( { ip => '10.0.0.1' } ) for 1 .. 3;
	is( $row->[1], 3, 'multi-output count reflects all three marks' );

	# age the meter past a second boundary, then the fourth call sees rate > 0
	nap(1.1);
	$row = $plan->apply_named( { ip => '10.0.0.1' } );
	ok( $row->[0] > 0, 'multi-output rate is positive once aged' );
	is( $row->[1], 4, 'fourth mark counted' );
}

# ---- on_error ----------------------------------------------------------------
{
	my $quiet = $M->build(
		{
			munger   => 'eps',
			socket   => "$dir/nope.sock",
			prefix   => 'x:',
			on_error => 0
		}
	);
	is( $quiet->('k'), 0, 'unreachable daemon with numeric on_error falls back' );

	my $loud = $M->build(
		{
			munger => 'eps',
			socket => "$dir/nope.sock",
			prefix => 'x:'
		}
	);
	eval { $loud->('k') };
	like( $@, qr/cannot connect to iqbi-damiq/, 'default on_error croaks' );

	# multi-output fallback fills every column
	my $plan = $M->compile(
		tags    => [qw(a b)],
		mungers => {
			m => {
				munger   => 'eps',
				socket   => "$dir/nope.sock",
				from     => 'ip',
				on_error => -1,
				parts    => [qw(rate count)],
				into     => [qw(a b)]
			}
		},
	);
	is_deeply( $plan->apply_named( { ip => 'k' } ), [ -1, -1 ], 'multi-output on_error fills all columns' );
}

# ---- MARKRATE's error reply (key limit) is caught, and the munger recovers ---
SKIP: {
	my $sock2 = "$dir/eps-limited.sock";
	start_daemon( $sock2, max_keys => 1 )
		or skip 'limited iqbi-damiq did not come up', 4;

	my $rate = $M->build( { munger => 'eps', socket => $sock2, prefix => 'L:' } );
	ok( defined $rate->('first'), 'first key fits under max_keys=1' );

	# a second key trips the limit; MARKRATE replies ERR in-band, one reply
	eval { $rate->('second') };
	like( $@, qr/iqbi-damiq replied: ERR key limit/, 'MARKRATE key-limit error croaks with the daemon message' );

	# after the error the connection was dropped; the next call reconnects
	ok( defined $rate->('first'), 'munger recovers on the next call' );

	my $quiet = $M->build(
		{
			munger   => 'eps',
			socket   => $sock2,
			prefix   => 'L:',
			on_error => -1
		}
	);
	is( $quiet->('second'), -1, 'numeric on_error absorbs the ERR reply' );
} ## end SKIP:

# ---- build-time validation (no daemon needed) --------------------------------
{
	ok( $M->build( { munger => 'eps', socket => "$dir/nothere.sock" } ), 'building an eps munger never connects' );

	eval { $M->build( { munger => 'eps', read => 'bogus' } ) };
	like( $@, qr/unknown read 'bogus'/, 'bad read mode croaks at build' );

	eval { $M->build( { munger => 'eps', parts => ['rate'] } ) };
	like( $@, qr/'parts' is for the multi-output form/, 'scalar eps rejects parts without into' );

	eval { $M->build( { munger => 'eps', prefix => 'has space:' } ) };
	like( $@, qr/'prefix' may not contain/, 'bad prefix croaks at build' );

	eval { $M->build( { munger => 'eps', on_error => 'maybe' } ) };
	like( $@, qr/'on_error' must be/, 'bad on_error croaks at build' );

	eval {
		$M->compile(
			tags    => [qw(a)],
			mungers => {
				m => {
					munger => 'eps',
					from   => 'ip',
					parts  => ['bogus'],
					into   => ['a']
				}
			}
		);
	};
	like( $@, qr/unknown part 'bogus'/, 'bad multi part croaks at compile' );
}

done_testing;
