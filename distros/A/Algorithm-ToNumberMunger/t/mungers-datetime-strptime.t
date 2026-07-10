#!perl
# The datetime munger's strptime path, exercised across the common real-world
# stamp formats. Every format here is deliberately NOT fast-eligible (it uses a
# code outside %Y %m %d %H %M %S, or omits one of the six), so parsing MUST go
# through Time::Piece->strptime -- and we prove that two ways: white-box, by
# asserting _compile_fast_format rejects the format, and black-box, by counting
# actual Time::Piece::strptime calls through a wrapper.
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

# Count real strptime calls. The munger resolves Time::Piece->strptime at call
# time, so wrapping the glob here is seen by code inside Mungers.pm too.
my $STRPTIME_CALLS = 0;
{
	no warnings 'redefine';
	my $orig = \&Time::Piece::strptime;
	*Time::Piece::strptime = sub { $STRPTIME_CALLS++; goto &$orig };
}

# One reference instant expressed in many notations: Sunday 2026-07-05
# 13:37:42 UTC. The expected numbers are literals (not re-derived via
# Time::Piece) so the module is never its own oracle.
my $EPOCH = 1783258662;

# Each row: [ description, format, stamp, { part => expected } ].
my @FORMATS = (
	[
		'Apache CLF access log (%b month name)',
		'%d/%b/%Y:%H:%M:%S',
		'05/Jul/2026:13:37:42',
		{
			epoch => $EPOCH,
			year  => 2026,
			mon   => 7,
			mday  => 5,
			hour  => 13,
			min   => 37,
			sec   => 42,
			wday  => 0
		},
	],
	[
		'RFC 2822 email Date header (%a weekday, %b month)',
		'%a, %d %b %Y %H:%M:%S',
		'Sun, 05 Jul 2026 13:37:42',
		{ epoch => $EPOCH, hour => 13, wday => 0 },
	],
	[
		'RFC 7231 HTTP-date (fixed GMT literal)',
		'%a, %d %b %Y %H:%M:%S GMT',
		'Sun, 05 Jul 2026 13:37:42 GMT',
		{ epoch => $EPOCH, hour => 13 },
	],
	[
		'RFC 850 cookie date (%A full weekday, %y two-digit year)',
		'%A, %d-%b-%y %H:%M:%S', 'Sunday, 05-Jul-26 13:37:42',
		{ epoch => $EPOCH, year => 2026 },    # POSIX rule: 26 => 2026
	],
	[
		'asctime/ctime (%e space-padded day)',
		'%a %b %e %H:%M:%S %Y',
		'Sun Jul  5 13:37:42 2026',
		{ epoch => $EPOCH, mday => 5 },
	],
	[
		'US 12-hour clock (%I with %p AM/PM)',
		'%m/%d/%Y %I:%M:%S %p',
		'07/05/2026 01:37:42 PM',
		{ epoch => $EPOCH, hour => 13 },
	],
	[
		'ISO 8601 with numeric zone (%z, offset applied)', '%Y-%m-%dT%H:%M:%S%z',
		'2026-07-05T15:37:42+0200', { epoch => $EPOCH, wday => 0 },
	],
	[ 'two-digit year ISO-ish (%y)', '%y-%m-%d %H:%M:%S', '26-07-05 13:37:42', { epoch => $EPOCH, year => 2026 }, ],
	[
		'syslog RFC 3164 (%b, no year -- strptime defaults it to 1970)',
		'%b %d %H:%M:%S',
		'Jul 05 13:37:42',
		{ epoch => 16033062, year => 1970, mon => 7, mday => 5, hour => 13 },
	],
	[
		'European dotted, minute precision (no %S)',
		'%d.%m.%Y %H:%M',
		'05.07.2026 13:37',
		{ epoch => $EPOCH - 42, sec => 0, hour => 13 },
	],
	[
		'ISO date-only (no time codes)', '%Y-%m-%d',
		'2026-07-05', { epoch => 1783209600, mday => 5, hour => 0, frac_day => 0 },
	],
	[ 'ISO 8601 basic compact date (%Y%m%d)', '%Y%m%d', '20260705', { epoch => 1783209600, mon => 7 }, ],
	[ 'epoch seconds (%s)', '%s', "$EPOCH", { epoch => $EPOCH, year => 2026, hour => 13 }, ],
);

for my $row (@FORMATS) {
	my ( $desc, $format, $stamp, $expect ) = @$row;

	# White-box guarantee: the fast engine must refuse this format, leaving
	# strptime as the only way the munger can parse it.
	is( Algorithm::ToNumberMunger::_compile_fast_format($format),
		undef, "$desc: format is not fast-eligible" );

	for my $part ( sort keys %$expect ) {
		my $code = $M->build( { munger => 'datetime', format => $format, part => $part } );

		$STRPTIME_CALLS = 0;
		my $got = $code->($stamp);
		ok( $STRPTIME_CALLS > 0,                   "$desc: $part parse called strptime" );
		ok( abs( $got - $expect->{$part} ) < 1e-9, "$desc: $part value" )
			or diag("got $got, expected $expect->{$part}");

		# The one-slot memo must serve a repeat without re-parsing, and a new
		# stamp must go back through strptime rather than being served stale.
		$STRPTIME_CALLS = 0;
		is( $code->($stamp), $got, "$desc: $part memo repeat value" );
		is( $STRPTIME_CALLS, 0,    "$desc: $part memo repeat skips strptime" );
	} ## end for my $part ( sort keys %$expect )
} ## end for my $row (@FORMATS)

# ---- same instant, every full-precision notation => one epoch ---------------
# All the formats above that carry full date+time+zone information describe the
# identical moment, so their epochs must agree exactly across notations.
{
	my @full = grep { exists $_->[3]{epoch} && $_->[3]{epoch} == $EPOCH } @FORMATS;
	cmp_ok( scalar @full, '>=', 7, 'several full-precision notations to compare' );
	for my $row (@full) {
		my ( $desc, $format, $stamp ) = @$row;
		my $code = $M->build( { munger => 'datetime', format => $format, part => 'epoch' } );
		is( $code->($stamp), $EPOCH, "epoch agrees across notations: $desc" );
	}
}

# ---- leap day through strptime ----------------------------------------------
{
	my $ep = $M->build(
		{
			munger => 'datetime',
			format => '%d/%b/%Y:%H:%M:%S',
			part   => 'epoch'
		}
	);
	my $yd = $M->build(
		{
			munger => 'datetime',
			format => '%d/%b/%Y:%H:%M:%S',
			part   => 'yday'
		}
	);
	$STRPTIME_CALLS = 0;
	is( $ep->('29/Feb/2024:23:59:59'), 1709251199, 'leap-day epoch' );
	is( $yd->('29/Feb/2024:23:59:59'), 59,         'leap-day yday' );
	ok( $STRPTIME_CALLS >= 2, 'leap-day stamps went through strptime' );
}

# ---- cyclic multi-output (parts/into) on the strptime path ------------------
# 2026-07-05T13:37:42 is a Sunday, so sin/cos of frac_week are derivable by
# hand: frac_week = (13*3600 + 37*60 + 42) / 604800.
{
	my $plan = $M->compile(
		tags    => [qw(s c)],
		mungers => {
			tw => {
				munger => 'datetime',
				from   => 'ts',
				format => '%d/%b/%Y:%H:%M:%S',
				parts  => [qw(sin_week cos_week)],
				into   => [qw(s c)],
			},
		},
	);
	my $pi   = 2 * atan2( 0, -1 );
	my $frac = ( 13 * 3600 + 37 * 60 + 42 ) / 604800;

	$STRPTIME_CALLS = 0;
	my $row = $plan->apply_named( { ts => '05/Jul/2026:13:37:42' } );
	ok( $STRPTIME_CALLS > 0,                          'multi-output parse called strptime' );
	ok( abs( $row->[0] - sin( $pi * $frac ) ) < 1e-9, 'sin_week via strptime' );
	ok( abs( $row->[1] - cos( $pi * $frac ) ) < 1e-9, 'cos_week via strptime' );

	$STRPTIME_CALLS = 0;
	is_deeply( $plan->apply_named( { ts => '05/Jul/2026:13:37:42' } ),
		$row, 'multi-output memo repeat returns the identical pair' );
	is( $STRPTIME_CALLS, 0, 'multi-output memo repeat skips strptime' );
}

# ---- control: a fast-eligible format must NOT call strptime... --------------
{
	my $code = $M->build(
		{
			munger => 'datetime',
			format => '%Y-%m-%dT%H:%M:%S',
			part   => 'epoch'
		}
	);
	$STRPTIME_CALLS = 0;
	is( $code->('2026-07-05T13:37:42'), $EPOCH, 'fast-path epoch' );
	is( $STRPTIME_CALLS, 0,
			  'fast-eligible format parses without strptime (counter is live proof '
			. 'the assertions above mean something)' );

	# ...except on a regex mismatch, where strptime is the judge of record:
	# an unpadded month/day fails the {2}-digit captures but strptime's %m/%d
	# accept it, so the fast path must fall back rather than reject.
	$STRPTIME_CALLS = 0;
	is( $code->('2026-7-5T13:37:42'), $EPOCH, 'unpadded stamp falls back to strptime and still parses' );
	ok( $STRPTIME_CALLS > 0, 'the fallback really was strptime' );
}

# ---- unparseable input croaks on the strptime path --------------------------
{
	my $code = $M->build(
		{
			munger => 'datetime',
			format => '%d/%b/%Y:%H:%M:%S',
			part   => 'epoch'
		}
	);
	# Time::Piece warns on its own before strptime dies; keep the TAP clean.
	local $SIG{__WARN__} = sub { };
	eval { $code->('05/Zzz/2026:13:37:42') };
	like( $@, qr/cannot parse '05\/Zzz\/2026:13:37:42'/, 'bogus month name croaks' );
	eval { $code->(undef) };
	like( $@, qr/undefined value/, 'undef croaks' );
}

done_testing;
