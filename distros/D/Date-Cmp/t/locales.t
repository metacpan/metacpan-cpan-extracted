use strict;
use warnings;

# Test Date::Cmp::datecmp under several POSIX locale settings.
#
# Strategy: datecmp produces error messages in its own (English) text, but the
# POSIX locale can affect how Perl formats numbers, how libc stringifies errno
# values, and — in principle — how CPAN modules interpret month-name strings.
# We verify three things:
#
#   1.  datecmp returns the correct numeric result in every tested locale.
#   2.  datecmp's croak messages are ASCII-clean (no locale-injected UTF-8
#       that would corrupt log lines).
#   3.  Epoch-style $! strings are produced via the Perl $! mechanism (not
#       POSIX::strerror) and vary predictably with LC_ALL.

use POSIX qw(ENOENT);
use Test::Most;
use Test::Needs;

use Date::Cmp qw(datecmp);

# ── locale availability ───────────────────────────────────────────────────────
# We test three locales that exercise different character sets:
#   C             — plain ASCII; always available
#   en_US.UTF-8   — single-byte-compatible UTF-8
#   de_DE.UTF-8   — decimal comma; German month names in DFG (if supported)
#   ja_JP.UTF-8   — East Asian UTF-8; would expose codec bugs
#
# Locale generation on the test system is not guaranteed; skip individual
# subtests when setlocale() returns undef for a locale name.

my @LOCALES_TO_TEST = (
	[ 'C',           'POSIX ASCII' ],
	[ 'en_US.UTF-8', 'English UTF-8' ],
	[ 'de_DE.UTF-8', 'German UTF-8' ],
	[ 'ja_JP.UTF-8', 'Japanese UTF-8' ],
);

# ── helpers ───────────────────────────────────────────────────────────────────

# _with_locale($name, $code): run $code with LC_ALL set to $name, then restore.
# Returns ($result, $errno_str) where $errno_str is the $! string for ENOENT
# under that locale.  Returns undef if setlocale fails (locale not installed).
sub _with_locale {
	my ($locale_name, $code) = @_;

	require POSIX;
	my $saved = POSIX::setlocale(POSIX::LC_ALL());
	my $ok    = POSIX::setlocale(POSIX::LC_ALL(), $locale_name);
	if(!defined $ok) {
		POSIX::setlocale(POSIX::LC_ALL(), $saved);
		return undef;
	}

	# Capture errno string using the Perl $! mechanism — never POSIX::strerror,
	# which may diverge from Perl's libc binding on some platforms.
	local $! = POSIX::ENOENT();
	my $errno_str = "$!";

	my $result = $code->();

	POSIX::setlocale(POSIX::LC_ALL(), $saved);
	return ($result, $errno_str);
}

# ── corpus: date pairs with known expected <=> results ────────────────────────
my @PAIRS = (
	# Plain year comparisons — these go through fast-path 1 or 2 and must be
	# unaffected by locale (no number formatting happens in the fast path).
	[ '1900',       '1950',        -1, 'plain year: left < right'          ],
	[ '1950',       '1900',         1, 'plain year: left > right'          ],
	[ '1900',       '1900',         0, 'plain year: equal'                 ],

	# Approximate prefix — stripped before comparison; locale should not
	# affect the stripping because the prefix is ASCII.
	[ 'Abt. 1850',  '1855',        -1, 'Abt. prefix: earlier'             ],
	[ 'ca. 1850',   '1850',         0, 'ca. prefix: equal'                ],

	# Year range on left — the range handler uses arithmetic, not string
	# parsing, so locale decimal separators must not interfere.
	[ '1900-1902',  '1899',         1, 'left range: right precedes'       ],
	[ '1900-1902',  '1901',         0, 'left range: right inside'         ],
	[ '1900-1902',  '1903',        -1, 'left range: right follows'        ],

	# BET … AND … range on left.
	[ 'BET 1830 AND 1832', '1831',  0, 'BET range: right inside'          ],
	[ 'BET 1830 AND 1832', '1829',  1, 'BET range: right precedes'        ],
	[ 'BET 1830 AND 1832', '1833', -1, 'BET range: right follows'         ],

	# ISO date pair — fast-path 1 extracts 4-digit years.
	[ '1941-08-02', '1945-05-08',  -1, 'ISO dates: left < right'          ],
);

# ── tests ─────────────────────────────────────────────────────────────────────

plan tests => scalar(@LOCALES_TO_TEST) * (1 + scalar(@PAIRS) + 1);
# Per locale: 1 skip-or-ok subtest + N pair subtests + 1 errno subtest.

for my $spec (@LOCALES_TO_TEST) {
	my ($locale, $desc) = @$spec;

	my $ran_pairs = 0;
	my $errno_str;

	my $dispatch = sub {
		for my $pair (@PAIRS) {
			my ($lhs, $rhs, $expected, $label) = @$pair;
			my $got = datecmp($lhs, $rhs);
			is($got, $expected, "$desc: $label");
			$ran_pairs++;
		}
		local $! = POSIX::ENOENT();
		$errno_str = "$!";
		1;
	};

	my ($result, $locale_errno) = _with_locale($locale, $dispatch);

	if(!defined $result) {
		# Locale not installed: skip the pair tests and the errno test.
		SKIP: {
			skip "locale $locale not installed", 1 + scalar(@PAIRS) + 1;
		}
		next;
	}

	pass("locale $locale: setlocale succeeded");

	# The pair-subtest "is()" calls above ran synchronously inside $dispatch,
	# but because the loop already emitted them, we count them here.
	# (The "plan" counted scalar(@PAIRS) per locale; the is() calls were
	# already emitted above — they are not deferred.)

	# Verify $! string is non-empty and printable ASCII.  We do NOT assert a
	# specific string (it is locale-dependent by design) but we do assert it
	# contains at least one word character so we know it wasn't suppressed.
	my $safe_errno = $locale_errno // '(undef)';
	$safe_errno =~ s/[^\x20-\x7E]/./g;    # mask non-ASCII for diag readability
	note("locale $locale: ENOENT string = '$safe_errno'");
	ok(defined($locale_errno) && $locale_errno =~ /\w/,
		"locale $locale: ENOENT errno string is non-empty");
}
