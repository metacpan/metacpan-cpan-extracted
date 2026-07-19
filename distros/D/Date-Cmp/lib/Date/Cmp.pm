package Date::Cmp;

# Compare two genealogy-style date strings with approximate-date support.
# TODO: handle when only months are known (no year).

use strict;
use warnings;

use autodie 2.06 qw(:all);
use Carp       qw(croak);
use DateTime::Format::Genealogy 0.11;
use Readonly;
use Scalar::Util qw(blessed);
use Term::ANSIColor;

use Exporter qw(import);
our @EXPORT_OK = qw(datecmp);

=encoding utf-8

=head1 NAME

Date::Cmp - Compare two dates with approximate parsing support

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

# Singleton DFG parser reused across calls for speed.  Tests may swap it
# with a mock under "local $Date::Cmp::dfg = MockDFG->new()".
our $dfg = DateTime::Format::Genealogy->new();

=head1 SYNOPSIS

  use Date::Cmp qw(datecmp);

  my $cmp = datecmp('1914', '1918');            # -1 (1914 is earlier)
  my $cmp = datecmp('Abt. 1850', '1855');       # -1
  my $cmp = datecmp('BET 1830 AND 1832', '1831'); # 0 (within range)

  # Optional complaint callback for ambiguous range edge-cases:
  $cmp = datecmp('1996-2000', '1996',
      sub { warn "ambiguous: @_" });

=head1 DESCRIPTION

C<Date::Cmp> provides a single exported function, C<datecmp>, which compares
two date strings or date-like objects, returning a numeric result like Perl's
C<< <=> >> operator.

The comparison handles approximate dates (C<Abt. 1902>, C<BET 1830 AND 1832>,
C<Oct/Nov/Dec 1950>), partial dates (year-only), and the common genealogy
qualifiers C<BEF> and C<AFT>.  Exact parsing delegates to
L<DateTime::Format::Genealogy>; a cascade of fast-path heuristics handles
the most common year-only comparisons without invoking the heavier parser.

=head1 FUNCTIONS

=head2 datecmp

=head3 Purpose

Compare two genealogy-style date strings (or date-like objects) and return
a value equivalent to Perl's spaceship operator (C<< <=> >>): C<-1> if the
left operand is earlier, C<0> if equivalent, or C<1> if later.

=head3 Arguments

=over 4

=item C<$left> (required)

The left-hand date.  Accepted types:

=over 8

=item * A string in any format listed under L</SUPPORTED FORMATS>.

=item * A blessed object with a C<date()> method returning a date string.

=item * A hash reference with a C<date> key whose value is a date string.

=back

=item C<$right> (required)

The right-hand date.  Accepts the same types as C<$left>.

=item C<$complain> (optional)

A CODE reference invoked with a diagnostic string for ambiguous conditions:
equal range endpoints or an inverted range.  C<undef> and other falsy values
are silently ignored (the guard is never triggered).  A truthy non-CODE
value causes an immediate C<croak>.

=back

=head3 Returns

=over 4

=item * C<-1> — C<$left> is earlier than C<$right>

=item * C<0>  — the two dates are considered equivalent

=item * C<1>  — C<$left> is later than C<$right>

=back

When either argument is C<undef> (or resolves to C<undef> after unwrapping),
the function prints a diagnostic to STDERR and returns C<0> rather than dying.
On a fatal parse failure it dies; the exception string begins with
C<"Date parse failure: ">.

=head3 Side Effects

May print coloured diagnostics to STDERR when dates cannot be parsed, when a
range is inverted, or when an argument is undefined.  The C<$complain>
callback is invoked (instead of STDERR output) for selected ambiguous
conditions.

=head3 EXAMPLE

  use Date::Cmp qw(datecmp);

  # Plain years
  datecmp('1900', '1950');              # -1

  # Approximate prefixes are stripped
  datecmp('Abt. 1850', '1850');        # 0
  datecmp('ca. 1799',  '1800');        # -1

  # Year ranges — any year within the range is "equal"
  datecmp('1 Jan 1831', '1830-1832');  # 0
  datecmp('BET 1830 AND 1832', '1829'); # 1  (range is later)

  # Blessed object with date() method
  package MyDate;
  sub new  { bless { d => $_[1] }, $_[0] }
  sub date { $_[0]->{d} }
  package main;
  datecmp(MyDate->new('1900'), '1950'); # -1

  # Hash ref with 'date' key
  datecmp({ date => '1900' }, '1950'); # -1

  # Sort a list of dates
  my @sorted = sort { datecmp($a, $b) } qw(1832 Abt. 1800 1756 BET 1815 AND 1820);

=head3 API SPECIFICATION

=head4 Input

  $left    : Str | Object(date) | HashRef(date => Str)   # required
  $right   : Str | Object(date) | HashRef(date => Str)   # required
  $complain: CodeRef | undef | false                      # optional

Valid string formats (see L</SUPPORTED FORMATS>):

  exact    => qr/^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2})?$/
  slash    => qr{^\d+/\d+/\d{4}$}
  year     => qr/^\d{3,4}$/
  approx   => qr/^(?:Abt\.?|ca?\.?)\s+.+/i  |  qr/.+\s?\?$/
  range    => qr/^\d{3,4}-\d{3,4}$/  |  qr/^BET \d+ AND \d+$/i
  month_rng=> qr/^[a-z\/]+\s+\d{3,4}$/i
  before   => qr/^bef\b/i
  after    => qr/^aft\b/i

=head4 Output

  Int: -1 | 0 | 1

  Or croaks("Date parse failure: ...") when a date cannot be parsed.
  Returns 0 (after STDERR output) when either argument is undef.

=head3 MESSAGES

The following diagnostics may be emitted.  B<[STDERR]> entries print a
message and stack trace then return 0.  B<[croak]> entries die (catchable
with C<eval {}>).

=over 4

=item B<[STDERR]> "left not defined" / "right not defined"

C<$left> or C<$right> was C<undef> on entry.

=item B<[STDERR]> "left date is undefined after input normalisation" / "right ..."

A hashref was passed with no C<date> key, or C<date =E<gt> undef>.

=item B<[croak]> "Third argument to datecmp() must be a CODE reference"

C<$complain> was truthy but not a C<CODE> reference (e.g. a string or
array-ref).

=item B<[croak]> "Date parse failure: left is an unsupported reference type (...)"

C<$left> was a reference that could not be unwrapped (not a blessed
C<date()>-capable object and not a hash).

=item B<[croak]> "Date parse failure: right is an unsupported reference type (...)"

Same for C<$right>.

=item B<[croak]> "Date parse failure: left contains characters not permitted in a date string"

C<$left> contained a character outside the allowed set
C<[A-Za-z0-9 .,/-?:]>.  The string is rejected before any parsing.

=item B<[croak]> "Date parse failure: right contains characters not permitted in a date string"

Same for C<$right>.

=item B<[croak]> "Date parse failure: left = ... (year must be 3-4 digits)"

C<$left> was a bare integer with 5 or more digits.

=item B<[croak]> "Date parse failure: right = ... (year must be 3-4 digits)"

Same for C<$right>.

=item B<[croak]> "Date parse failure: left = ..."

C<$left> failed the first-character semantic check or could not be parsed
by DFG.

=item B<[croak]> "Date parse failure: right = ..."

C<$right> could not be parsed by DFG (and no year suffix was extractable).

=item B<[STDERR]> "... <=> ...: not handled yet"

A C<BEF>/C<AFT> qualifier on the left with a right-hand value that does not
fit any handled pattern.  Returns 0.

=item B<[STDERR]> "... <=> ...: Before not handled"

A C<BEF> qualifier on the right with a left-hand value that is not a plain
integer.  Returns 0.

=item B<[STDERR]> "datecmp(): N > M in daterange ..."

The right-hand year range was inverted (C<from E<gt> to>).  Returns 0.

=back

=head3 PSEUDOCODE

  1.  Validate $complain: croak if truthy but not a CODE reference.
  2.  Guard undef: if either input is undef → STDERR + stack trace + return 0.
  3.  Normalise: blessed date()-objects → call date(); hash refs → 'date' key.
  4.  Guard post-normalise undef → STDERR + stack trace + return 0.
  5.  Reject surviving reference types (croak).
  6.  Identity short-circuit: return 0 if left eq right (no parsing needed).
  7.  Taint-scrub: validate all characters against $DATE_CHARS;
      also produces untainted copies safe for use under perl -T.
  8.  First-char semantic check: first char must be [A-S0-9] (croak if not).
  9.  Reject 5+ digit bare integers (croak).
  10. Fast path 1: 4-digit year in both non-range strings → return if differ.
  11. Fast path 2: trailing 3-4 digit year in both → return if differ.
  12. Normalise LEFT (if string):
      a.  Strip trailing ISO T-timestamp.
      b.  Fast path 3: trailing 4-digit years in both → return if differ.
      c.  BEF/AFT on left: numeric-right or BEF-with-4-digit-right handled;
          otherwise STDERR + stack trace + return 0.
      d.  Strip approximate prefix (Abt./ca.) or suffix (?) or month-range.
      e.  Fast path 4: digit-starting years on both sides → return if differ.
      f.  Fast path 5: left year vs right starting with lowercase "bet".
      g.  "YEAR or YEAR" form: use first year; fire $complain if both equal.
      h.  Dash / BET range on left: compare $right against [from, to].
      i.  Complex date string: parse via DFG (croak if DFG returns nothing).
  13. Normalise RIGHT (if string):
      a.  BEF on right: numeric left → compare; otherwise STDERR + return 0.
      b.  Strip approximate prefix/suffix/month-range.
      c.  Bare 3-4 digit year: compare directly with left (unwrap if ref).
      d.  Dash / BET range on right: compare $left against [from, to].
      e.  Fast path 6: matching year in both → return if differ.
      f.  Parse right via DFG (croak if DFG returns nothing).
  14. Final comparison: unwrap any remaining DateTime objects via ->year(); <=>.

=head1 SUPPORTED FORMATS

=over 4

=item * Exact dates: C<1941-08-02>, C<5/27/1872>

=item * Years only: C<1828>, C<822>

=item * Approximate dates: C<Abt. 1802>, C<ca. 1802>, C<1802 ?>

=item * Date ranges: C<1802-1803>, C<BET 1830 AND 1832>

=item * Month ranges: C<Oct/Nov/Dec 1950>

=item * Qualifiers: C<BEF 1940>, C<AFT 1855>

=back

=head1 ERROR HANDLING

When a date cannot be parsed, diagnostic messages are printed to STDERR and
the function either returns 0 (for recoverable conditions such as undef
input) or C<croak>s with a string beginning C<"Date parse failure: ">.
All C<croak> exceptions are catchable via C<eval {}>.

=head1 LIMITATIONS

=over 4

=item * B<Month-only dates>

Dates where only the month is known (no year) are not supported.

=item * B<Incomplete BEF/AFT handling>

Many C<BEF>/C<AFT> combinations—especially C<AFT> on the left or C<BEF>
against a non-integer right—are not implemented and fall back to returning
0 with a STDERR diagnostic.

=item * B<Dead fast-path code>

Certain fast-path branches and a redundant C<ref($right)> guard inside the
left-side range handler are unreachable at runtime (documented in
C<t/extended_tests.t> subtest 10).

=item * B<Public singleton>

C<$Date::Cmp::dfg> is a package variable.  Concurrent threads replacing it
with different mocks are not safe.

=item * B<No Sub::Private enforcement>

The C<_sanitize_for_diag> and C<_emit_stack_trace> private helpers rely on
naming convention only.  Runtime enforcement via C<Sub::Private> is not yet
declared as a dependency.

=back

=cut

# ─────────────────────────────────────────────────────────────────────────────
# Constant: characters permitted in any date string.
#
# Covers every character that appears in a supported genealogy date:
#   A-Za-z  — month abbreviations; BEF/BET/AFT/AND/Abt/ca prefixes
#   0-9     — year and day digits
#   (space) — component separator
#   .       — Abt. prefix dot
#   ,       — occasional list separator
#   /       — slash-dates (M/D/YYYY) and month ranges (Oct/Nov/Dec)
#   -       — ISO dates (YYYY-MM-DD) and year ranges (1830-1832)
#   ?       — uncertainty suffix ("1828 ?")
#   :       — ISO T-timestamp ("1941-08-02T00:00:00")
# ─────────────────────────────────────────────────────────────────────────────
Readonly my $DATE_CHARS => qr/[A-Za-z0-9 .,\/\-?:]/;

# ─────────────────────────────────────────────────────────────────────────────
# _sanitize_for_diag($val)
#
# Purpose:      Produce a safe printable-ASCII rendering of a user-supplied
#               string for inclusion in log/error output.  Prevents log
#               injection (CWE-117) via embedded newlines, NUL bytes, or ANSI
#               escape sequences.
# Entry:        $val — any scalar; may be undef.
# Exit:         Defined printable string ≤200 chars.  '(undef)' if input is
#               undef.  Non-printable bytes (outside \x20–\x7E) replaced with
#               literal periods.
# ─────────────────────────────────────────────────────────────────────────────
sub _sanitize_for_diag {
	my ($val) = @_;
	return '(undef)' if !defined $val;
	(my $safe = substr($val, 0, 200)) =~ s/[^\x20-\x7E]/./g;
	return $safe;
}

# ─────────────────────────────────────────────────────────────────────────────
# _emit_stack_trace()
#
# Purpose:      Write a coloured call-stack listing to STDERR so that the
#               caller can locate which line of their code triggered a
#               datecmp warning or failure.
# Entry:        Called at any depth inside datecmp.
# Exit:         Nothing returned (void).
# Side Effects: Writes tab-indented, red-coloured lines to STDERR.
# ─────────────────────────────────────────────────────────────────────────────
sub _emit_stack_trace {
	my $i = 0;
	while(my @c = caller($i++)) {
		print STDERR "\t", colored($c[2] . ' of ' . $c[1], 'red'), "\n";
	}
	return;
}

sub datecmp
{
	my ($left, $right, $complain) = @_;

	# Reject truthy non-CODE $complain early.  A falsy value (undef, 0, "")
	# is never invoked because every call site guards with "if($complain)",
	# so skipping validation for falsy values is safe.  A truthy string would
	# call an arbitrary named sub under no strict refs, which is a security
	# risk — reject it now.
	if($complain && ref($complain) ne 'CODE') {
		croak 'Third argument to datecmp() must be a CODE reference';
	}

	# Undef on entry: recoverable — print diagnostic and return 0.
	if((!defined $left) || !defined $right) {
		print STDERR "\n";
		print STDERR "left not defined\n"  if !defined $left;
		print STDERR "right not defined\n" if !defined $right;
		_emit_stack_trace();
		return 0;
	}

	# Unwrap: blessed object with date() → string; hashref → 'date' key.
	if(blessed($left)  && $left->can('date'))  { $left  = $left->date(); }
	if(blessed($right) && $right->can('date')) { $right = $right->date(); }
	if(ref($left)  eq 'HASH') { $left  = $left->{'date'}; }
	if(ref($right) eq 'HASH') { $right = $right->{'date'}; }

	# A hashref without a 'date' key, or with date => undef, arrives here as
	# undef.  Any other surviving reference would stringify silently — reject.
	if(!defined $left || !defined $right) {
		print STDERR "\n";
		print STDERR "left date is undefined after input normalisation\n"  if !defined $left;
		print STDERR "right date is undefined after input normalisation\n" if !defined $right;
		_emit_stack_trace();
		return 0;
	}
	if(ref($left)) {
		croak 'Date parse failure: left is an unsupported reference type (' . ref($left) . ')';
	}
	if(ref($right)) {
		croak 'Date parse failure: right is an unsupported reference type (' . ref($right) . ')';
	}

	# Identical strings — no parsing needed at all.
	return 0 if $left eq $right;

	# Taint-scrub: validate every character in both inputs.  A full-string
	# anchored capture against the allowed class (a) rejects shell
	# metacharacters, newlines, NUL bytes, and HTML characters, and (b)
	# produces an untainted copy, making datecmp safe under perl -T.
	my ($safe_left)  = ($left  =~ /^($DATE_CHARS+)$/);
	my ($safe_right) = ($right =~ /^($DATE_CHARS+)$/);

	if(!defined $safe_left) {
		croak 'Date parse failure: left contains characters not permitted in a date string';
	}
	if(!defined $safe_right) {
		croak 'Date parse failure: right contains characters not permitted in a date string';
	}

	$left  = $safe_left;
	$right = $safe_right;

	# Semantic first-character check: all supported formats begin with a
	# letter A-S (month abbreviations Jan-Sep, Oct=O, Nov=N, Dec=D; prefixes
	# BEF/BET/AFT/Abt/ca) or a digit (year-first formats).  Letters T-Z as
	# the leading character do not appear in any supported format.
	if($left !~ /^[A-S0-9]/i) {
		_emit_stack_trace();
		croak 'Date parse failure: left = ' . _sanitize_for_diag($left);
	}
	if($right !~ /^[A-S0-9]/i) {
		_emit_stack_trace();
		croak 'Date parse failure: right = ' . _sanitize_for_diag($right);
	}

	# Reject bare integers with 5+ digits — they are not valid year strings
	# and the fast-path regexes would silently extract the wrong substring.
	if($left =~ /^\d{5,}$/) {
		croak 'Date parse failure: left = ' . $left . ' (year must be 3-4 digits)';
	}
	if($right =~ /^\d{5,}$/) {
		croak 'Date parse failure: right = ' . $right . ' (year must be 3-4 digits)';
	}

	# ── Fast path 1 ─────────────────────────────────────────────────────────
	# Both strings contain a 4-digit year, neither is a BET/dash-range.
	# If the years differ we can return immediately without further parsing.
	if((!ref($left)) && (!ref($right))
		&& ($left  =~ /\d{3,4}/) && ($right =~ /\d{3,4}/)
		&& ($left  !~ /^bet/i)   && ($left  !~ /\-/)
		&& ($right !~ /^bet/i)   && ($right !~ /^\d{3,4}\-\d{3,4}$/))
	{
		if($left =~ /(\d{4})/) {
			my $lyear = $1;
			if($right =~ /(\d{4})/) {
				my $ryear = $1;
				return $lyear <=> $ryear if $lyear != $ryear;
			}
		}
	}

	# ── Fast path 2 ─────────────────────────────────────────────────────────
	# Both strings END with a 3-4 digit year, neither is a BET/dash-range.
	if((!ref($left)) && (!ref($right))
		&& ($left  =~ /(\d{3,4})$/) && ($left  !~ /^bet/i) && ($left  !~ /\-/)
		&& ($right !~ /^bet/i)       && ($right !~ /\-/))
	{
		my $yol = $1;
		if($right =~ /(\d{3,4})$/) {
			my $yor = $1;
			return $yol <=> $yor if $yol != $yor;
		}
	}

	if(!ref($left)) {
		# Strip trailing ISO T-timestamp before further checks.
		$left =~ s/T\d\d:\d\d:\d\d$//;

		# ── Fast path 3 ─────────────────────────────────────────────────
		# Both strings end with a 4-digit year (after space or slash).
		# Note: fast-paths 1 and 2 handle all cases where the extracted
		# years differ, so the return inside this block is unreachable in
		# practice — but the outer if still serves to tie-break below.
		if((!ref($right))
			&& ($left  =~ /(^|[\s\/])\d{4}$/)
			&& ($left  !~ /^bet/i) && ($left  !~ /\-/)
			&& ($right !~ /^bet/i) && ($right !~ /\-/)
			&& ($right =~ /(^|[\s\/,])(\d{4})$/))
		{
			my $ryear = $2;
			$left =~ /(^|[\s\/])(\d{4})$/;
			my $lyear = $2;
			return $lyear <=> $ryear if $lyear != $ryear;
		}

		# ── BEF / AFT on left side ───────────────────────────────────────
		if($left =~ /^(bef|aft)/i) {
			if($right =~ /^\d+$/) {
				# e.g. "bef 1 Jun 1965" vs "1969"
				if($left =~ /\s(\d+)$/) {
					return -1 if $1 < $right;
				}
			}
			if($right =~ /(\d{4})/) {
				# e.g. "BEF. 1932" vs "2005-06-16"
				my $ryear = $1;
				if($left =~ /^bef/i && $left =~ /(\d{4})/) {
					return -1 if $1 < $ryear;
				}
			}
			print STDERR _sanitize_for_diag($left) . ' <=> ' . _sanitize_for_diag($right) . ": not handled yet\n";
			_emit_stack_trace();
			return 0;
		}

		# ── Approximate prefix / suffix stripping ────────────────────────
		if($left =~ /^(Abt|ca?)\.?\s+(.+)/i) {
			$left = $2;
		} elsif($left =~ /(.+?)\s?\?$/) {
			$left = $1;
		} elsif(($left =~ /\//) && ($left =~ /^[a-z\/]+\s+(.+)/i)) {
			# e.g. "Oct/Nov/Dec 1950" → "1950"
			$left = $1;
		}

		# ── Fast path 4 ─────────────────────────────────────────────────
		# After stripping, both sides start with a 3-4 digit year.
		if(($left =~ /^\d{3,4}/) && ($left !~ /\-/)
			&& ($right =~ /^\d{3,4}/) && ($right !~ /\-/))
		{
			$left  =~ /^(\d{3,4})/; my $start = $1;
			$right =~ /^(\d{3,4})/; my $end   = $1;
			return $start <=> $end if $start != $end;
		}

		# ── Fast path 5 ─────────────────────────────────────────────────
		# Left contains a year; right starts with lowercase "bet" (the
		# BET range handler below uses case-insensitive /^Bet .../i so
		# this catches the bare lowercase form first).
		if($left =~ /(\d{3,4})/) {
			my $start = $1;
			if(($left !~ /^bet/i) && ($right =~ /^bet/)) {
				if($right =~ /(\d{3,4})/) {
					my $end = $1;
					return $start <=> $end if $start != $end;
				}
			}
		}

		# ── "YEAR or YEAR" format ────────────────────────────────────────
		if($left =~ /^(\d{3,4})\sor\s(\d{3,4})$/) {
			my ($start, $end) = ($1, $2);
			$complain->("the years are the same '$left'") if $complain && $start == $end;
			$left = $start;
		}
		# ── Left-side dash / BET range ───────────────────────────────────
		elsif(($left =~ /^(\d{3,4})\-(\d{3,4})$/)
			|| ($left =~ /^Bet (\d{3,4})\sand\s(\d{3,4})$/i))
		{
			my ($from, $to) = ($1, $2);

			if($from == $to) {
				# Degenerate range: collapse to single year.
				$complain->("from == to, $from") if $complain;
				$left = $from;

			} elsif($from > $to) {
				# Inverted range: fire complain and give up.
				$complain->("datecmp(): $from > $to in daterange '$left'") if $complain;
				return 0;

			} else {
				# Parse $right to a plain year integer if it isn't already.
				if($right !~ /^\d{4}$/) {
					my @r = $dfg->parse_datetime({ date => $right, quiet => 1 });
					if(!defined $r[0]) {
						if($right =~ /[\s\/](\d{4})$/) {
							# e.g. 'BET 1830 AND 1832' vs 'Oct/Nov/Dec 1821'
							# $left is the range string here; use $from/$to.
							my $year = $1;
							return $year < $from ?  1
							     : $year > $to   ? -1
							     :                  0;
						}
						# croak is catchable via eval{}, resolving the prior TODO.
						_emit_stack_trace();
						croak 'Date parse failure: right = ' . _sanitize_for_diag($right);
					}
					$right = $r[0]->year();
				}

				# Compare the single right year against [from, to].
				# Any year within the interval (inclusive) is "equal".
				return  1 if $right < $from;   # right predates range: range is later
				return -1 if $right > $to;      # right postdates range: range is earlier
				return  0;                       # right within [from, to]
			}
		}
		# ── Complex left-side date string → DFG ─────────────────────────
		elsif($left !~ /^\d{3,4}$/) {
			if($left !~ /^\d{4}\-\d{2}\-\d{2}$/) {
				# Not an ISO date — validate it has letters in valid positions.
				if(($left !~ /[a-z]/i) || ($left =~ /[a-z]$/)) {
					_emit_stack_trace();
					croak 'Date parse failure: left = ' . _sanitize_for_diag($left);
				}
			}

			# $l[1] is preferred over $l[0]: for genealogy date ranges DFG
			# may return (start_DateTime, end_DateTime); using the end date
			# gives a consistent upper-bound for range inputs.
			my @l = $dfg->parse_datetime({ date => $left, quiet => 1 });
			my $rc = $l[1] || $l[0];
			if(!defined $rc) {
				_emit_stack_trace();
				croak 'Date parse failure: left = ' . _sanitize_for_diag($left);
			}
			$left = $rc;
		}
	}

	# ── Right side ──────────────────────────────────────────────────────────
	if(!ref($right)) {
		# ── BEF on right ────────────────────────────────────────────────
		if($right =~ /^bef/i) {
			if($left =~ /^\d+$/) {
				# e.g. "1939" vs "bef 1 Jun 1965"
				if($right =~ /\s(\d+)$/) {
					return $left <=> $1;
				}
			}
			print STDERR _sanitize_for_diag($left) . ' <=> ' . _sanitize_for_diag($right) . ": Before not handled\n";
			_emit_stack_trace();
			return 0;
		}

		# ── Approximate prefix / suffix stripping ────────────────────────
		if($right =~ /^(Abt|ca?)\.?\s+(.+)/i) {
			$right = $2;
		} elsif($right =~ /(.+?)\s?\?$/) {
			$right = $1;
		} elsif(($right =~ /\//) && ($right =~ /^[a-z\/]+\s+(.+)/i)) {
			$right = $1;
		}

		# ── Bare year on right ───────────────────────────────────────────
		if($right =~ /^\d{3,4}$/) {
			return ref($left) ? $left->year() <=> $right : $left <=> $right;
		}

		# ── Right-side dash / BET range ──────────────────────────────────
		if(($right =~ /^(\d{3,4})\-(\d{3,4})$/)
			|| ($right =~ /^Bet (\d{3,4})\sand\s(\d{3,4})$/i))
		{
			my ($from, $to) = ($1, $2);

			if($from == $to) {
				# Degenerate range: fire complain then compare directly.
				$complain->("from == to, $from") if $complain;
				# Return immediately rather than falling through to DFG,
				# which cannot parse a bare integer.
				return ref($left) ? $left->year() <=> $from : $left <=> $from;

			} elsif($from > $to) {
				print STDERR 'datecmp(): ' . $from . ' > ' . $to . ' in daterange ' . _sanitize_for_diag($right) . "\n";
				_emit_stack_trace();
				return 0;

			} else {
				# Unwrap any DateTime before numeric comparison.
				if(ref($left)) { $left = $left->year(); }

				# Compare left year against [from, to].
				return -1 if $left < $from;   # left predates range: left is earlier
				return  1 if $left > $to;      # left postdates range: left is later
				return  0;                      # left within [from, to]
			}
		}

		# ── Fast path 6 ──────────────────────────────────────────────────
		# Both sides still contain a 3-4 digit year; return if they differ.
		if($left =~ /(\d{3,4})/) {
			my $start = $1;
			if($right =~ /(\d{3,4})/) {
				my $end = $1;
				return $start <=> $end if $start != $end;
			}
		}

		# ── Right-side DFG parse ─────────────────────────────────────────
		my @r = $dfg->parse_datetime({ date => $right, quiet => 1 });
		if(!defined $r[0]) {
			if($right =~ /[\s\/](\d{4})$/) {
				# e.g. "1891" vs "Oct/Nov/Dec 1892" or "5/27/1872"
				my $year = $1;
				if(ref($left)) {
					return $left->year() <=> $year if $left->year() != $year;
				} else {
					return $left <=> $year if $left != $year;
				}
			}
			# croak is catchable via eval{}, resolving the prior TODO.
			_emit_stack_trace();
			croak 'Date parse failure: right = ' . _sanitize_for_diag($right);
		}
		$right = $r[0];
	}

	# ── Final comparison ─────────────────────────────────────────────────────
	# Unwrap any remaining DateTime objects and compare numerically.
	return $left  <=> $right->year() if !ref($left)  && ref($right);
	return $left->year() <=> $right  if  ref($left)  && !ref($right);
	return $left <=> $right;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Date-Cmp/coverage/>

=item * L<Sort::Key::DateTime>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report bugs to C<bug-date-cmp at rt.cpan.org> or via
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Cmp>.

    perldoc Date::Cmp

=head1 FORMAL SPECIFICATION

=head2 datecmp

    [DATESTR, DIAGMSG]

    DATE ::= exact⟨year: ℕ⟩
           | approx⟨year: ℕ⟩
           | before⟨year: ℕ⟩
           | after⟨year: ℕ⟩
           | range⟨from: ℕ; to: ℕ⟩
           | invalid

    COMPARISON ::= lt | eq | gt | error

    DateCmp
    left?, right?: DATESTR
    diagnostic!: ℙ DIAGMSG
    result!: COMPARISON

    ∀d: DATESTR @ validDate(d)

    ≙
    ∃ l, r: DATE •
        l = parse(left?) ∧ r = parse(right?) ∧
        (
          (l = invalid ∨ r = invalid ⇒ result! = error) ∧
          (l = r ⇒ result! = eq) ∧
          (compare(l, r, diagnostic!) = -1 ⇒ result! = lt) ∧
          (compare(l, r, diagnostic!) = 0  ⇒ result! = eq) ∧
          (compare(l, r, diagnostic!) = 1  ⇒ result! = gt)
        )

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
