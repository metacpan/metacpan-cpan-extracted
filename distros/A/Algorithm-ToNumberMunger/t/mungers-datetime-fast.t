#!perl
# The datetime fast path (compiled regex + integer date math) must be
# value-identical to the strptime path for every part, and the one-slot memo
# must never serve a stale result.
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require Time::Piece; 1 }
		or plan skip_all => 'Time::Piece not available';
}

use Algorithm::ToNumberMunger;
my $M = 'Algorithm::ToNumberMunger';

my $FMT = '%Y-%m-%dT%H:%M:%S';    # fast-eligible: all six numeric codes

my @PARTS = qw(epoch year mon mday hour min sec wday yday
	frac_day frac_week sin_day cos_day sin_week cos_week);

# Stamps chosen to poke the arithmetic: epoch origin, leap day, year edges,
# pre-1970 (negative epoch days), and an ordinary modern stamp.
my @STAMPS = qw(
	1970-01-01T00:00:00
	1969-12-31T23:59:59
	2000-02-29T23:59:59
	1999-12-31T00:00:00
	2024-03-01T00:00:01
	2026-07-05T13:37:42
);

# ---- fast == strptime for every part on every stamp ------------------------
for my $part (@PARTS) {
	my $fast = $M->build( { munger => 'datetime', format => $FMT, part => $part } );
	for my $stamp (@STAMPS) {
		# expected value straight off Time::Piece, computed here in the test so
		# the module's slow path is not the oracle for itself.
		my $t   = Time::Piece->strptime( $stamp, $FMT );
		my %exp = (
			epoch     => $t->epoch,
			year      => $t->year,
			mon       => $t->mon,
			mday      => $t->mday,
			hour      => $t->hour,
			min       => $t->min,
			sec       => $t->sec,
			wday      => $t->day_of_week,
			yday      => $t->yday,
			frac_day  => ( $t->hour * 3600 + $t->min * 60 + $t->sec ) / 86400,
			frac_week => ( $t->day_of_week * 86400 + $t->hour * 3600 + $t->min * 60 + $t->sec ) / 604800,
		);
		my $pi = 2 * atan2( 0, -1 );
		$exp{sin_day}  = sin( $pi * $exp{frac_day} );
		$exp{cos_day}  = cos( $pi * $exp{frac_day} );
		$exp{sin_week} = sin( $pi * $exp{frac_week} );
		$exp{cos_week} = cos( $pi * $exp{frac_week} );

		my $got = $fast->($stamp);
		ok( abs( $got - $exp{$part} ) < 1e-9, "$part($stamp) fast == strptime" )
			or diag("got $got, expected $exp{$part}");
	} ## end for my $stamp (@STAMPS)
} ## end for my $part (@PARTS)

# ---- memo: repeat hits and non-stale updates --------------------------------
{
	my $c = $M->build( { munger => 'datetime', format => $FMT, part => 'hour' } );
	is( $c->('2026-07-05T13:00:00'), 13, 'first call' );
	is( $c->('2026-07-05T13:00:00'), 13, 'memo repeat hit' );
	is( $c->('2026-07-05T14:00:00'), 14, 'different stamp is not served stale' );
	is( $c->('2026-07-05T13:00:00'), 13, 'switching back re-parses correctly' );

	# a parse failure must not poison the memo
	eval { $c->('garbage') };
	like( $@, qr/cannot parse 'garbage'/, 'bad input croaks on the fast path' );
	is( $c->('2026-07-05T14:00:00'), 14, 'memo survives a failed parse' );

	# multi-output memo: same pair, then a different stamp
	my ( $code, $arity ) = do {
		# via compile, the public route to a multi munger
		my $plan = $M->compile(
			tags    => [qw(s c)],
			mungers => {
				tw => {
					munger => 'datetime',
					from   => 'ts',
					format => $FMT,
					parts  => [qw(sin_week cos_week)],
					into   => [qw(s c)]
				}
			},
		);
		( $plan, 2 );
	};
	my $r1 = $code->apply_named( { ts => '2026-07-05T00:00:00' } );
	my $r2 = $code->apply_named( { ts => '2026-07-05T00:00:00' } );
	is_deeply( $r2, $r1, 'multi memo repeat returns the identical pair' );
	my $r3 = $code->apply_named( { ts => '2026-07-06T12:00:00' } );
	ok( abs( $r3->[1] - $r1->[1] ) > 0.1, 'multi memo does not serve stale pairs' );
}

# ---- non-fast formats still work via strptime -------------------------------
{
	# %b (alphabetic month) is not fast-eligible; apache-style log stamp.
	my $c = $M->build(
		{
			munger => 'datetime',
			format => '%d/%b/%Y:%H:%M:%S',
			part   => 'hour'
		}
	);
	is( $c->('05/Jul/2026:13:37:42'), 13, 'strptime path for %b formats' );

	# a fast format missing some codes (date-only) also stays on strptime
	my $d = $M->build( { munger => 'datetime', format => '%Y-%m-%d', part => 'mday' } );
	is( $d->('2026-07-05'), 5, 'date-only format works via strptime' );
}

# ---- out-of-range fields must behave exactly as strptime would ---------------
# A stamp can match the fast regex's shape without being a real time: month 13,
# hour 24, Feb 30 are all six digit-groups of the right width. The fast path
# must hand such stamps to strptime rather than run blind integer date math on
# them, so both paths stay value-identical even off the happy path: they croak
# together (month 13, hour 24) or normalize together (Time::Piece rolls Feb 30
# over into March 2). The expectations here are oracle-driven -- computed from
# Time::Piece in the test -- because *matching strptime* is the contract, and
# a leap-day control confirms valid-but-rare stamps still parse.
{
	my @stamps = (
		'2026-13-01T00:00:00',    # month 13        -> strptime rejects
		'2026-00-10T00:00:00',    # month 0         -> strptime rejects
		'2026-07-05T24:00:00',    # hour 24         -> strptime rejects
		'2026-07-05T23:60:00',    # minute 60       -> strptime rejects
		'2026-07-00T12:00:00',    # day 0           -> normalizes to Jun 30
		'2026-02-30T12:00:00',    # Feb 30          -> normalizes to Mar 2
		'2023-02-29T12:00:00',    # non-leap Feb 29 -> normalizes to Mar 1
		'1900-02-29T12:00:00',    # century non-leap-> normalizes to Mar 1
		'2024-02-29T12:00:00',    # real leap day   -> valid, stays fast
	);
	my %get_exp = (
		epoch => sub { $_[0]->epoch },
		mon   => sub { $_[0]->mon },
		mday  => sub { $_[0]->mday },
		hour  => sub { $_[0]->hour },
		wday  => sub { $_[0]->day_of_week },
	);
	for my $part ( sort keys %get_exp ) {
		my $c = $M->build( { munger => 'datetime', format => $FMT, part => $part } );
		for my $stamp (@stamps) {
			my $t   = eval { Time::Piece->strptime( $stamp, $FMT ) };
			my $got = eval { $c->($stamp) };
			if ($t) {
				my $exp = $get_exp{$part}->($t);
				ok( defined $got && abs( $got - $exp ) < 1e-9, "$part($stamp) normalizes like strptime" )
					or diag( 'got ' . ( defined $got ? $got : "croak: $@" ) . ", expected $exp" );
			} else {
				ok( !defined $got, "$part($stamp) is rejected like strptime" )
					or diag("got $got where strptime rejects");
				like( $@, qr/cannot parse/, "$part($stamp) croaks with the parse message" );
			}
		} ## end for my $stamp (@stamps)
	} ## end for my $part ( sort keys %get_exp )

	# a rejection must not poison the memo for the next good stamp
	my $c = $M->build( { munger => 'datetime', format => $FMT, part => 'mon' } );
	is( $c->('2026-07-05T13:00:00'), 7, 'good stamp parses' );
	eval { $c->('2026-13-01T00:00:00') };
	like( $@, qr/cannot parse/, 'month 13 croaks' );
	is( $c->('2026-07-05T13:00:00'), 7, 'memo survives the rejected stamp' );
}

done_testing;
