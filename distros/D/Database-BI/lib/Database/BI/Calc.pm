package Database::BI::Calc;

use strict;
use warnings;

use Carp	qw(croak);
use POSIX	qw(floor ceil);
use Readonly;
use Scalar::Util	qw(looks_like_number);

our $VERSION = '0.018.0';

Readonly my $MAX_EXPR_LEN => 512;
Readonly my $MAX_DEPTH    => 20;

# --- token type constants ---
Readonly my $T_NUM    => 'NUM';
Readonly my $T_STR    => 'STR';
Readonly my $T_IDENT  => 'IDENT';
Readonly my $T_PLUS   => 'PLUS';
Readonly my $T_MINUS  => 'MINUS';
Readonly my $T_STAR   => 'STAR';
Readonly my $T_SLASH  => 'SLASH';
Readonly my $T_LPAREN => 'LPAREN';
Readonly my $T_RPAREN => 'RPAREN';
Readonly my $T_COMMA  => 'COMMA';
Readonly my $T_EOF    => 'EOF';

# Comparison operator tokens (two-char forms checked before single-char forms)
Readonly my $T_EQ  => 'EQ';	# =
Readonly my $T_NEQ => 'NEQ';	# !=
Readonly my $T_LT  => 'LT';	# <
Readonly my $T_LE  => 'LE';	# <=
Readonly my $T_GT  => 'GT';	# >
Readonly my $T_GE  => 'GE';	# >=

our %MESSAGES = (
	error_expr_too_long   => 'Expression too long (max %d characters)',
	error_expr_too_deep   => 'Expression nesting too deep (max %d levels)',
	error_unknown_fn      => "Unknown function '%s'",
	error_unknown_col     => "Unknown column '%s'",
	error_unexpected_tok  => "Unexpected token '%s' at position %d",
	error_expected_tok    => "Expected '%s' at position %d, got '%s'",
	error_unterminated    => 'Unterminated string at position %d',
	error_bad_char        => "Unexpected character '%s' at position %d",
	error_trailing        => "Unexpected token '%s' at position %d",
	error_double_eq       => "Use = not == for equality comparison at position %d",
	error_param_col_clash => "Parameter '%s' conflicts with a column of the same name",
	error_time_format       => "Unsupported time format token %s",
	error_time_format_date  => "Time format '%s' must name a date, with a year, a month and a day token",
	error_const_arg         => "The second argument of %s() must be a quoted literal",
	error_span_interval     => "Unknown time bucket '%s'; use a count and one of s, m, h, d, w, mon, q or y, for example 1h or 15m",
);

sub _fmt {
	my ($key, @args) = @_;
	return sprintf $MESSAGES{$key}, @args;
}

# --- built-in function dispatch table ---
# 'if' is handled as a special form in _parse_call (short-circuit branches),
# and so are epoch() and span(), whose second argument is a constant that is
# checked once, at compile time, rather than on every row.
#
# The date functions accept an ISO-8601 'YYYY-MM-DD' prefix only, and the time
# functions an ISO date, an ISO timestamp, or an epoch in seconds or
# milliseconds; non-matching values return undef and appear in the empty-cell
# bucket rather than being dropped.

Readonly my %_MONTH_NAME_TO_NUM => (
	jan => 1, feb => 2, mar => 3, apr => 4,  may => 5,  jun => 6,
	jul => 7, aug => 8, sep => 9, oct => 10, nov => 11, dec => 12,
);

# The tokens a strptime-style pattern may hold.  Plain characters in a pattern
# are literals; anything else is a compile error, so a pattern is either fully
# understood or refused.
Readonly my %_FMT_RE => (
	Y => '\d{4}',		# four-digit year
	m => '\d{1,2}',		# month number
	d => '\d{1,2}',		# day of month
	H => '\d{1,2}',		# hour, 24-hour clock
	M => '\d{1,2}',		# minute
	S => '\d{1,2}',		# second
	b => '[A-Za-z]{3}',	# month abbreviation, as in %d-%b-%Y
);

# The functions whose second argument is a constant, not an expression.
Readonly my %TIME_CONST_FNS => map { $_ => 1 } qw(epoch span);

my %FUNCTIONS = (
	# --- string functions ---
	upper    => sub { defined $_[0] ? uc($_[0])      : undef },
	lower    => sub { defined $_[0] ? lc($_[0])      : undef },
	trim     => sub {
		return undef unless defined $_[0];
		my $s = $_[0];
		$s =~ s/\A\s+|\s+\z//g;
		$s;
	},
	len      => sub { defined $_[0] ? length($_[0])  : undef },
	concat   => sub { join '', map { defined $_ ? $_ : '' } @_ },
	substr   => sub {
		my ($s, $start, $len) = @_;
		return undef unless defined $s;
		$start //= 0;
		defined $len ? CORE::substr($s, $start, $len)
		             : CORE::substr($s, $start);
	},

	# --- numeric functions ---
	round    => sub {
		my ($n, $d) = @_;
		return undef unless defined $n && looks_like_number($n);
		$d = (defined $d && looks_like_number($d)) ? int($d) : 0;
		sprintf("%.${d}f", $n) + 0;
	},
	floor    => sub {
		defined $_[0] && looks_like_number($_[0]) ? POSIX::floor($_[0]) : undef;
	},
	ceil     => sub {
		defined $_[0] && looks_like_number($_[0]) ? POSIX::ceil($_[0]) : undef;
	},
	'abs'    => sub {
		defined $_[0] && looks_like_number($_[0]) ? CORE::abs($_[0]) : undef;
	},

	# --- conditional / null-handling ---
	isnull   => sub { defined $_[0] ? $_[0] : $_[1] },
	coalesce => sub {
		for my $v (@_) { return $v if defined $v }
		return undef;
	},

	# --- date functions (ISO-8601 YYYY-MM-DD prefix; no external module) ---
	year => sub {
		return undef unless defined $_[0] && $_[0] =~ /\A(\d{4})-\d\d-\d\d/;
		$1 + 0;
	},
	month => sub {
		return undef unless defined $_[0] && $_[0] =~ /\A\d{4}-(\d\d)-\d\d/;
		$1 + 0;
	},
	day => sub {
		return undef unless defined $_[0] && $_[0] =~ /\A\d{4}-\d\d-(\d\d)/;
		$1 + 0;
	},
	quarter => sub {
		return undef unless defined $_[0] && $_[0] =~ /\A\d{4}-(\d\d)-/;
		int(($1 - 1) / 3) + 1;
	},
	week => sub {
		# Returns ISO 8601 week number (1-53); week containing the first
		# Thursday of the year is week 1.
		return undef unless defined $_[0] && $_[0] =~ /\A(\d{4})-(\d\d)-(\d\d)/;
		my ($yr, $mo, $dy) = ($1 + 0, $2 + 0, $3 + 0);
		my $t  = POSIX::mktime(0, 0, 12, $dy, $mo - 1, $yr - 1900);
		my @lt = localtime($t);
		POSIX::strftime('%V', @lt) + 0;
	},
	month_name => sub {
		# Returns full English month name, e.g. 'January'.
		my @M = qw(January February March April May June
		           July August September October November December);
		return undef unless defined $_[0] && $_[0] =~ /\A\d{4}-(\d\d)-/;
		$M[$1 - 1] // undef;
	},
	weekday => sub {
		# Returns ISO 8601 weekday: 1 = Monday, 7 = Sunday.
		return undef unless defined $_[0] && $_[0] =~ /\A(\d{4})-(\d\d)-(\d\d)/;
		my ($yr, $mo, $dy) = ($1 + 0, $2 + 0, $3 + 0);
		my $t  = POSIX::mktime(0, 0, 12, $dy, $mo - 1, $yr - 1900);
		my $wd = (localtime($t))[6];	# 0 = Sunday
		$wd == 0 ? 7 : $wd;
	},
	now => sub {
		# Returns today's date as 'YYYY-MM-DD'.  Takes no arguments.
		my @t = (localtime)[3, 4, 5];	# mday, mon (0-based), year (since 1900)
		sprintf '%04d-%02d-%02d', $t[2] + 1900, $t[1] + 1, $t[0];
	},

	# --- time of day (see "Time values and time buckets" below) --
	hour => sub {
		my $t = _parse_time($_[0]);
		return undef unless $t && $t->{has_time};
		(localtime($t->{epoch}))[2] + 0;
	},
	minute => sub {
		my $t = _parse_time($_[0]);
		return undef unless $t && $t->{has_time};
		(localtime($t->{epoch}))[1] + 0;
	},
	second => sub {
		my $t = _parse_time($_[0]);
		return undef unless $t && $t->{has_time};
		(localtime($t->{epoch}))[0] + 0;
	},

	# --- grouping / binning ---
	bin => sub {
		# bin(value, width) -> '[lo,hi)' label for the interval containing value.
		# Width must be a positive number.  Both endpoints use %d when width is
		# an integer, %g otherwise, to avoid spurious ".0" suffixes.
		my ($v, $w) = @_;
		return undef unless defined $v && defined $w;
		return undef unless looks_like_number($v) && looks_like_number($w) && $w > 0;
		# Normalise the quotient to 10 significant digits before flooring: binary
		# representation error (0.3 / 0.1 == 2.9999999999999996) must not move a
		# value one bin to the left.  %.10g is magnitude-independent.
		my $n   = POSIX::floor(sprintf('%.10g', $v / $w) + 0);
		my $lo  = $n * $w;
		my $hi  = $lo + $w;
		my $fmt = ($w == int($w)) ? '%d' : '%g';
		sprintf("[${fmt},${fmt})", $lo, $hi);
	},
);

# ---------------------------------------------------------------------------
# Time values and time buckets
#
# One parser and one interval vocabulary, with the time-of-day functions and
# span() on top of them.  Every value is read as *local* time, by
# POSIX::mktime, exactly as the date functions and the relative time ranges
# already are: no zone is parsed, none is stored, and nothing here reads the
# clock -- a bucket for a value is the same bucket tomorrow.
# ---------------------------------------------------------------------------

# _fmt_body($fmt) -> ($regex_body, \@tokens)
#
# Purpose: Turn a strptime-style pattern into a regex body with one capture per
#          token, plus the token each capture belongs to.  A token outside
#          %_FMT_RE is a compile error rather than a silent skip: a pattern
#          that quietly ignored half of itself is how a value ends up in the
#          wrong bucket without anybody being told.
sub _fmt_body {
	my ($fmt) = @_;
	my @tokens;
	my $body = '';
	my $i    = 0;

	while ($i < length $fmt) {
		my $ch = substr($fmt, $i, 1);
		if ($ch ne '%') {
			$body .= quotemeta($ch);
			$i++;
			next;
		}
		my $tok = substr($fmt, $i + 1, 1);
		croak _fmt('error_time_format', length($tok // '') ? "%$tok" : $fmt)
			unless length($tok // '') && exists $_FMT_RE{$tok};
		push @tokens, $tok;
		$body .= '(' . $_FMT_RE{$tok} . ')';
		$i += 2;
	}

	return ($body, \@tokens);
}

# _fmt_compile($fmt) -> { re => qr, tokens => \@tokens }
#
# A pattern on its own has to name a date; a time with no day has no place on a
# calendar to be resolved against.
sub _fmt_compile {
	my ($fmt) = @_;
	my ($body, $tokens) = _fmt_body($fmt);
	croak _fmt('error_time_format_date', $fmt)
		unless _fmt_has_date($tokens);
	return { re => qr/\A$body\z/, tokens => $tokens };
}

# _fmt_has_date(\@tokens) -> bool
#
# A pattern has to name a date: a year, a day, and a month -- as a number
# (C<%m>) or as an abbreviation (C<%b>), which is what %d-%b-%Y uses.
sub _fmt_has_date {
	my ($tokens) = @_;
	my %has = map { $_ => 1 } @$tokens;
	return $has{Y} && $has{d} && ($has{m} || $has{b}) ? 1 : 0;
}

# _fmt_compile_pair($date_fmt, $time_fmt) -> { re => qr, tokens => \@tokens }
#
# A stored time pattern is two patterns holding one value between them, so they
# are compiled into one regex: the date, an optional 'T' or space, the time.
sub _fmt_compile_pair {
	my ($date_fmt, $time_fmt) = @_;
	my ($dbody, $dtokens) = _fmt_body($date_fmt);
	my ($tbody, $ttokens) = _fmt_body($time_fmt);
	croak _fmt('error_time_format_date', $date_fmt)
		unless _fmt_has_date($dtokens);
	return {
		re     => qr/\A$dbody[ T]?$tbody\z/,
		tokens => [ @$dtokens, @$ttokens ],
	};
}

# _fmt_parts($value, $compiled) -> \%parts | undef
sub _fmt_parts {
	my ($value, $compiled) = @_;
	my @caps = ($value =~ $compiled->{re});
	return undef unless @caps;

	my %part;
	my @tokens = @{ $compiled->{tokens} };
	for my $i (0 .. $#tokens) {
		$part{ $tokens[$i] } = $caps[$i];
	}
	return \%part;
}

# _epoch_of($y, $mon, $day, $h, $mi, $s) -> epoch | undef
#
# Purpose: Local epoch seconds for a calendar date and clock time.
# Notes:   POSIX::mktime normalises what it is given -- '2026-02-31' becomes
#          3 March, month 13 becomes January -- so the parts are read back and
#          compared before the value is accepted, and a date that does not
#          exist is unparseable rather than quietly a different date.  The
#          clock time is allowed two hours of slack, because the hour a
#          daylight-saving change skips does not exist and mktime moves it.
sub _epoch_of {
	my ($y, $mon, $day, $h, $mi, $s) = @_;
	require POSIX;
	my $epoch = POSIX::mktime($s, $mi, $h, $day, $mon - 1, $y - 1900);
	return undef unless defined $epoch;

	my @lt = localtime($epoch);
	return undef
		unless $lt[5] + 1900 == $y && $lt[4] + 1 == $mon && $lt[3] == $day;

	my $want = $h * 3_600 + $mi * 60 + $s;
	my $got  = $lt[2] * 3_600 + $lt[1] * 60 + $lt[0];
	return undef if abs($got - $want) > 7_200;
	return $epoch;
}

# _parse_time($value) -> { epoch => E, has_time => 0|1 } | undef
#
# Purpose: Read one cell as a point in time.  Three shapes are recognised, in
#          this order: an ISO date, or an ISO timestamp with 'T' or a space
#          between the date and the time; ten digits, an epoch in seconds; and
#          thirteen digits, an epoch in milliseconds.  Only the digit count
#          separates the last two, so it is the rule -- and it is documented,
#          because nothing in the value itself says which one it is.
sub _parse_time {
	my ($value) = @_;
	return undef unless defined $value && !ref $value && length $value;
	(my $s = $value) =~ s/\A\s+|\s+\z//g;
	return undef unless length $s;

	if (my ($y, $mon, $day, $h, $mi, $sec)
		= $s =~ /\A(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?\z/)
	{
		my $epoch = _epoch_of($y + 0, $mon + 0, $day + 0,
			($h // 0) + 0, ($mi // 0) + 0, ($sec // 0) + 0);
		return undef unless defined $epoch;
		return { epoch => $epoch, has_time => defined $h ? 1 : 0 };
	}

	return { epoch => $s + 0, has_time => 1 }       if $s =~ /\A\d{10}\z/;
	return { epoch => int($s / 1_000), has_time => 1 } if $s =~ /\A\d{13}\z/;
	return undef;
}

# _time_from_format($value, $compiled) -> { epoch => E, has_time => 0|1 } | undef
sub _time_from_format {
	my ($value, $compiled) = @_;
	return undef unless defined $value && !ref $value;
	my $part = _fmt_parts($value, $compiled) or return undef;

	my $mon = defined $part->{m} ? $part->{m} + 0
		: defined $part->{b} ? $_MONTH_NAME_TO_NUM{ lc $part->{b} }
		: undef;
	return undef unless defined $mon && $mon >= 1 && $mon <= 12;

	my $epoch = _epoch_of($part->{Y} + 0, $mon, $part->{d} + 0,
		($part->{H} // 0) + 0, ($part->{M} // 0) + 0, ($part->{S} // 0) + 0);
	return undef unless defined $epoch;
	return { epoch => $epoch, has_time => defined $part->{H} ? 1 : 0 };
}

# _iso_second_label($epoch) -> 'YYYY-MM-DDTHH:MM:SS' in local time
sub _iso_second_label {
	my @lt = localtime($_[0]);
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02d',
		$lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2], $lt[1], $lt[0];
}

# _civil_day($y, $mon, $day) -> days since 1970-01-01
#
# Purpose: A day number that does not move with daylight saving, so the n-day
#          and n-week buckets can be counted from a fixed origin.  Integer
#          civil-calendar arithmetic; no part of this reads the clock.
sub _civil_day {
	my ($y, $mon, $day) = @_;
	$y -= ($mon <= 2) ? 1 : 0;
	my $era = int(($y >= 0 ? $y : $y - 399) / 400);
	my $yoe = $y - $era * 400;			# [0, 399]
	my $doy = int((153 * ($mon + ($mon > 2 ? -3 : 9)) + 2) / 5) + $day - 1;
	my $doe = $yoe * 365 + int($yoe / 4) - int($yoe / 100) + $doy;
	return $era * 146_097 + $doe - 719_468;
}

# _shift_days($y, $mon, $day, $delta) -> ($y, $mon, $day)
#
# Purpose: Move a date by whole days without a calendar library.
# Notes:   Noon is the anchor.  A day is then 86,400 seconds away from its
#          neighbours even across a daylight-saving change, so counting days
#          cannot land on the wrong date -- counting from midnight does, once a
#          year, and only in the autumn.
sub _shift_days {
	my ($y, $mon, $day, $delta) = @_;
	return ($y, $mon, $day) unless $delta;
	require POSIX;
	my @lt = localtime(POSIX::mktime(12, 0, 0, $day, $mon - 1, $y - 1900) + $delta * 86_400);
	return ($lt[5] + 1900, $lt[4] + 1, $lt[3]);
}

# span_interval($interval) -> { n => N, unit => U, [secs => S] } | undef
#
# Purpose: The interval vocabulary span() takes, and the only place its rule
#          lives: a count and a unit, 'mon' for months (because 'm' is
#          minutes) and 'q' for quarters.  A count below one and an unknown
#          unit are both undef rather than a bucket that quietly means
#          something else.  Public because the span= sugar validates an
#          interval before it builds the expression, and one rule with two
#          callers beats two rules that drift apart.
sub span_interval {
	my ($interval) = @_;
	return undef unless defined $interval && !ref $interval && length $interval;
	my ($n, $unit) = $interval =~ /\A(\d+)(mon|s|m|h|d|w|q|y)\z/ or return undef;
	$n += 0;
	return undef if $n < 1;

	my $secs = $unit eq 's' ? 1
		: $unit eq 'm' ? 60
		: $unit eq 'h' ? 3_600
		: undef;
	return { n => $n, unit => $unit, (defined $secs ? (secs => $secs) : ()) };
}

# _span_label($value, \%interval) -> bucket label | undef
#
# Purpose: The ISO label of the bucket a value falls in -- the half-open
#          interval from the bucket's start to the next bucket's start.
# Notes:   The label is ISO at the bucket's own resolution, never 'Oct 2026':
#          group keys are sorted as strings, so an ISO label makes
#          lexicographic order chronological order and a bucketed chart comes
#          out in the right order with no second sort path.  A pretty name is a
#          presentation step (month_name() already reads a month number); it is
#          never the key.
#          The intervals below a day are floored out of the epoch, and 'd'
#          downwards are counted in calendar units, because a day is not always
#          86,400 seconds and a month never is.
sub _span_label {
	my ($value, $interval) = @_;
	my $t = _parse_time($value);
	return undef unless $t;

	my $n    = $interval->{n};
	my $unit = $interval->{unit};

	if (defined $interval->{secs}) {
		my $step = $n * $interval->{secs};
		return _iso_second_label(floor($t->{epoch} / $step) * $step);
	}

	my @lt = localtime($t->{epoch});
	my ($y, $mon, $day) = ($lt[5] + 1900, $lt[4] + 1, $lt[3]);

	if ($unit eq 'd') {
		return sprintf('%04d-%02d-%02d', $y, $mon, $day) if $n == 1;
		my $day_no = _civil_day($y, $mon, $day);
		return sprintf('%04d-%02d-%02d', _shift_days($y, $mon, $day, -($day_no % $n)));
	}

	if ($unit eq 'w') {
		# Monday is the first day of the ISO week, and 1970-01-05 is the
		# Monday the week count runs from.
		require POSIX;
		my $dow    = (localtime(POSIX::mktime(12, 0, 0, $day, $mon - 1, $y - 1900)))[6];
		my $day_no = _civil_day($y, $mon, $day);
		my $monday = $day_no - ($dow == 0 ? 6 : $dow - 1);
		my $weeks  = floor(($monday - 4) / 7);
		my $start  = $monday - ($weeks % $n) * 7;
		return sprintf('%04d-%02d-%02d', _shift_days($y, $mon, $day, $start - $day_no));
	}

	# A month count runs from January 1970, and a quarter count from its first
	# quarter, so the buckets line up with the calendar at every width and not
	# only when the count is one.
	if ($unit eq 'mon') {
		my $idx = ($y - 1970) * 12 + ($mon - 1);
		my $lo  = $idx - ($idx % $n);
		return sprintf('%04d-%02d-01', 1970 + floor($lo / 12), $lo % 12 + 1);
	}

	if ($unit eq 'q') {
		my $qi = ($y - 1970) * 4 + int(($mon - 1) / 3);
		my $lo = $qi - ($qi % $n);
		return sprintf('%04d-%02d-01', 1970 + floor($lo / 4), ($lo % 4) * 3 + 1);
	}

	return sprintf('%04d-01-01', $y - ($y % $n));
}

# ---------------------------------------------------------------------------
# Constructor
# ---------------------------------------------------------------------------

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		_error   => undef,
		_code    => undef,
		_columns => {},
		_params  => {},
	}, $class;

	my $expr   = $args{expr} // '';
	my @cols   = @{ $args{columns} // [] };
	my %params = %{ $args{params}  // {} };
	$self->{_columns}{$_} = 1 for @cols;

	# A name that is both a column and a parameter is an error: the ambiguity
	# would be resolved silently in whichever direction, making expressions
	# non-deterministic when the data changes.
	for my $p (keys %params) {
		if ($self->{_columns}{$p}) {
			$self->{_error} = _fmt('error_param_col_clash', $p);
			return $self;
		}
	}
	# Extend the compile-time column whitelist with param names so _parse_colref
	# accepts them as identifiers; at evaluate() time their values come from
	# _params rather than the row hashref.
	$self->{_columns}{$_} = 1 for keys %params;
	$self->{_params} = \%params;

	if (length($expr) > $MAX_EXPR_LEN) {
		$self->{_error} = _fmt('error_expr_too_long', $MAX_EXPR_LEN);
		return $self;
	}

	my $tokens;
	my $ok = eval { $tokens = _tokenize($expr); 1 };
	unless ($ok) {
		my $err = $@; $err =~ s/ at \S+ line \d+\.?\n?$//;
		$self->{_error} = $err;
		return $self;
	}

	my $pos   = 0;
	my $depth = 0;
	my $code;
	$ok = eval { $code = _parse_cmp($tokens, \$pos, \$depth, $self->{_columns}); 1 };
	unless ($ok) {
		my $err = $@; $err =~ s/ at \S+ line \d+\.?\n?$//;
		$self->{_error} = $err;
		return $self;
	}

	if ($tokens->[$pos]{type} ne $T_EOF) {
		$self->{_error} = _fmt('error_trailing',
			$tokens->[$pos]{val}, $tokens->[$pos]{pos});
		return $self;
	}

	$self->{_code} = $code;
	return $self;
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

sub error     { $_[0]->{_error} }
sub has_error { defined $_[0]->{_error} }

sub evaluate {
	my ($self, $row) = @_;
	return undef unless defined $self->{_code};
	# Merge bound parameters into the evaluation context.  Parameters take
	# precedence over same-named columns: the clash check in new() ensures this
	# never happens legitimately, but a column added to the data after compile
	# time should still see the parameter value.
	my $ctx = %{ $self->{_params} }
		? { %$row, %{ $self->{_params} } }
		: $row;
	my $result;
	my $ok = eval { $result = $self->{_code}->($ctx); 1 };
	return undef unless $ok;
	return $result;
}

# ---------------------------------------------------------------------------
# Tokenizer
# ---------------------------------------------------------------------------

sub _tokenize {
	my ($expr) = @_;
	my @tokens;
	my $pos = 0;
	my $len = length($expr);
	my %single_ops = (
		'+' => $T_PLUS, '-' => $T_MINUS,
		'*' => $T_STAR, '/' => $T_SLASH,
		'(' => $T_LPAREN, ')' => $T_RPAREN, ',' => $T_COMMA,
	);

	while ($pos < $len) {
		my $ch = substr($expr, $pos, 1);

		# skip whitespace
		if ($ch =~ /\A\s/) { $pos++; next }

		# number literal (integer, decimal, scientific)
		if (substr($expr, $pos) =~ /\A(\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/) {
			push @tokens, { type => $T_NUM, val => $1, pos => $pos };
			$pos += length($1);
			next;
		}

		# double-quoted string
		if ($ch eq '"') {
			my $end = index($expr, '"', $pos + 1);
			croak _fmt('error_unterminated', $pos) if $end < 0;
			push @tokens, {
				type => $T_STR,
				val  => substr($expr, $pos + 1, $end - $pos - 1),
				pos  => $pos,
			};
			$pos = $end + 1;
			next;
		}

		# single-quoted string
		if ($ch eq "'") {
			my $end = index($expr, "'", $pos + 1);
			croak _fmt('error_unterminated', $pos) if $end < 0;
			push @tokens, {
				type => $T_STR,
				val  => substr($expr, $pos + 1, $end - $pos - 1),
				pos  => $pos,
			};
			$pos = $end + 1;
			next;
		}

		# identifier: letters/digits/underscore, leading letter or _
		if (substr($expr, $pos) =~ /\A([a-zA-Z_][a-zA-Z0-9_]*)/) {
			push @tokens, { type => $T_IDENT, val => $1, pos => $pos };
			$pos += length($1);
			next;
		}

		# two-character comparison operators (must be tested before single-char)
		if ($pos + 1 < $len) {
			my $two = substr($expr, $pos, 2);
			if ($two eq '!=') {
				push @tokens, { type => $T_NEQ, val => '!=', pos => $pos };
				$pos += 2; next;
			}
			if ($two eq '<=') {
				push @tokens, { type => $T_LE, val => '<=', pos => $pos };
				$pos += 2; next;
			}
			if ($two eq '>=') {
				push @tokens, { type => $T_GE, val => '>=', pos => $pos };
				$pos += 2; next;
			}
			if ($two eq '==') {
				croak _fmt('error_double_eq', $pos);
			}
		}

		# single-character comparison operators
		if ($ch eq '=') {
			push @tokens, { type => $T_EQ, val => '=', pos => $pos };
			$pos++; next;
		}
		if ($ch eq '<') {
			push @tokens, { type => $T_LT, val => '<', pos => $pos };
			$pos++; next;
		}
		if ($ch eq '>') {
			push @tokens, { type => $T_GT, val => '>', pos => $pos };
			$pos++; next;
		}

		# single-character arithmetic operators and punctuation
		if (exists $single_ops{$ch}) {
			push @tokens, { type => $single_ops{$ch}, val => $ch, pos => $pos };
			$pos++;
			next;
		}

		croak _fmt('error_bad_char', $ch, $pos);
	}

	push @tokens, { type => $T_EOF, val => '', pos => $pos };
	return \@tokens;
}

# ---------------------------------------------------------------------------
# Parser  (each _parse_* returns a coderef  sub { my ($row) = @_; ... })
# ---------------------------------------------------------------------------

sub _check_depth {
	my ($depth_ref) = @_;
	croak _fmt('error_expr_too_deep', $MAX_DEPTH) if $$depth_ref >= $MAX_DEPTH;
}

sub _expect {
	my ($tokens, $pos_ref, $expected) = @_;
	my $tok = $tokens->[$$pos_ref];
	croak _fmt('error_expected_tok', $expected, $tok->{pos}, $tok->{val})
		unless $tok->{type} eq $expected;
	$$pos_ref++;
}

# cmp_expr ::= add_expr (cmp_op add_expr)?
# Comparison yields 1 (true), 0 (false), or undef (either operand undef).
# When both operands look numeric, numeric comparison is used; otherwise
# case-insensitive string comparison, matching _apply_filter_spec semantics.
sub _parse_cmp {
	my ($tokens, $pos_ref, $depth_ref, $cols) = @_;
	_check_depth($depth_ref);
	$$depth_ref++;

	my $left = _parse_add($tokens, $pos_ref, $depth_ref, $cols);

	my $type = $tokens->[$$pos_ref]{type};
	if ($type eq $T_EQ || $type eq $T_NEQ
	 || $type eq $T_LT || $type eq $T_LE
	 || $type eq $T_GT || $type eq $T_GE) {
		my $op = $type;
		$$pos_ref++;
		my $right = _parse_add($tokens, $pos_ref, $depth_ref, $cols);
		my ($l, $r) = ($left, $right);
		$left = sub {
			my $lv = $l->($_[0]);
			my $rv = $r->($_[0]);
			return undef unless defined $lv && defined $rv;
			if (looks_like_number($lv) && looks_like_number($rv)) {
				return $op eq $T_EQ  ? ($lv == $rv ? 1 : 0)
				     : $op eq $T_NEQ ? ($lv != $rv ? 1 : 0)
				     : $op eq $T_LT  ? ($lv <  $rv ? 1 : 0)
				     : $op eq $T_LE  ? ($lv <= $rv ? 1 : 0)
				     : $op eq $T_GT  ? ($lv >  $rv ? 1 : 0)
				     :                 ($lv >= $rv ? 1 : 0);
			} else {
				my $cmp = lc($lv) cmp lc($rv);
				return $op eq $T_EQ  ? ($cmp == 0 ? 1 : 0)
				     : $op eq $T_NEQ ? ($cmp != 0 ? 1 : 0)
				     : $op eq $T_LT  ? ($cmp <  0 ? 1 : 0)
				     : $op eq $T_LE  ? ($cmp <= 0 ? 1 : 0)
				     : $op eq $T_GT  ? ($cmp >  0 ? 1 : 0)
				     :                 ($cmp >= 0 ? 1 : 0);
			}
		};
	}

	$$depth_ref--;
	return $left;
}

# add_expr ::= term ( ('+' | '-') term )*
sub _parse_add {
	my ($tokens, $pos_ref, $depth_ref, $cols) = @_;
	_check_depth($depth_ref);
	$$depth_ref++;

	my $left = _parse_term($tokens, $pos_ref, $depth_ref, $cols);

	while ($tokens->[$$pos_ref]{type} eq $T_PLUS
	    || $tokens->[$$pos_ref]{type} eq $T_MINUS) {
		my $op = $tokens->[$$pos_ref]{type};
		$$pos_ref++;
		my $right = _parse_term($tokens, $pos_ref, $depth_ref, $cols);
		my ($l, $r) = ($left, $right);
		if ($op eq $T_PLUS) {
			$left = sub {
				my $lv = $l->($_[0]); my $rv = $r->($_[0]);
				return undef unless defined $lv && defined $rv;
				return undef unless looks_like_number($lv) && looks_like_number($rv);
				$lv + $rv;
			};
		} else {
			$left = sub {
				my $lv = $l->($_[0]); my $rv = $r->($_[0]);
				return undef unless defined $lv && defined $rv;
				return undef unless looks_like_number($lv) && looks_like_number($rv);
				$lv - $rv;
			};
		}
	}

	$$depth_ref--;
	return $left;
}

# term ::= factor ( ('*' | '/') factor )*
sub _parse_term {
	my ($tokens, $pos_ref, $depth_ref, $cols) = @_;

	my $left = _parse_factor($tokens, $pos_ref, $depth_ref, $cols);

	while ($tokens->[$$pos_ref]{type} eq $T_STAR
	    || $tokens->[$$pos_ref]{type} eq $T_SLASH) {
		my $op = $tokens->[$$pos_ref]{type};
		$$pos_ref++;
		my $right = _parse_factor($tokens, $pos_ref, $depth_ref, $cols);
		my ($l, $r) = ($left, $right);
		if ($op eq $T_STAR) {
			$left = sub {
				my $lv = $l->($_[0]); my $rv = $r->($_[0]);
				return undef unless defined $lv && defined $rv;
				return undef unless looks_like_number($lv) && looks_like_number($rv);
				$lv * $rv;
			};
		} else {
			$left = sub {
				my $lv = $l->($_[0]); my $rv = $r->($_[0]);
				return undef unless defined $lv && defined $rv;
				return undef unless looks_like_number($lv) && looks_like_number($rv);
				return undef if $rv == 0;
				$lv / $rv;
			};
		}
	}

	return $left;
}

# factor ::= unary | '(' cmp_expr ')' | number | string | column | call
sub _parse_factor {
	my ($tokens, $pos_ref, $depth_ref, $cols) = @_;
	my $tok = $tokens->[$$pos_ref];

	# unary minus
	if ($tok->{type} eq $T_MINUS) {
		$$pos_ref++;
		my $inner = _parse_factor($tokens, $pos_ref, $depth_ref, $cols);
		return sub {
			my $v = $inner->($_[0]);
			return undef unless defined $v && looks_like_number($v);
			-$v;
		};
	}

	# unary plus (no-op)
	if ($tok->{type} eq $T_PLUS) {
		$$pos_ref++;
		return _parse_factor($tokens, $pos_ref, $depth_ref, $cols);
	}

	# parenthesized sub-expression: allow full cmp_expr so (qty > 0) works
	if ($tok->{type} eq $T_LPAREN) {
		$$pos_ref++;
		my $inner = _parse_cmp($tokens, $pos_ref, $depth_ref, $cols);
		_expect($tokens, $pos_ref, $T_RPAREN);
		return $inner;
	}

	# number literal
	if ($tok->{type} eq $T_NUM) {
		my $val = $tok->{val} + 0;
		$$pos_ref++;
		return sub { $val };
	}

	# string literal
	if ($tok->{type} eq $T_STR) {
		my $val = $tok->{val};
		$$pos_ref++;
		return sub { $val };
	}

	# identifier -- function call or column reference
	if ($tok->{type} eq $T_IDENT) {
		my $name = $tok->{val};
		$$pos_ref++;
		return $tokens->[$$pos_ref]{type} eq $T_LPAREN
			? _parse_call($tokens, $pos_ref, $depth_ref, $cols, $name, $tok->{pos})
			: _parse_colref($cols, $name, $tok->{pos});
	}

	croak _fmt('error_unexpected_tok', $tok->{val}, $tok->{pos});
}

# Parse a function call.  'if' is a special form (short-circuit branches).
# Arguments may be full cmp_expr (e.g. IF(qty > 0, amount/qty, 0)).
sub _parse_call {
	my ($tokens, $pos_ref, $depth_ref, $cols, $name, $name_pos) = @_;
	my $lc = lc($name);

	croak _fmt('error_unknown_fn', $name)
		unless exists $FUNCTIONS{$lc} || $lc eq 'if' || $TIME_CONST_FNS{$lc};

	# epoch(v [, fmt]) and span(v, interval) take a constant second argument:
	# a format or an interval.  It is checked here, once per column rather than
	# once per row, so a bad one is a compile error that names it -- and the
	# pattern is compiled once instead of on every value.
	if ($TIME_CONST_FNS{$lc}) {
		$$pos_ref++;	# consume '('
		my $value_fn = _parse_cmp($tokens, $pos_ref, $depth_ref, $cols);
		my $const;
		if ($tokens->[$$pos_ref]{type} eq $T_COMMA) {
			$$pos_ref++;
			my $tok = $tokens->[$$pos_ref];
			croak _fmt('error_const_arg', $name)
				unless $tok->{type} eq $T_STR;
			$const = $tok->{val};
			$$pos_ref++;
		}
		_expect($tokens, $pos_ref, $T_RPAREN);

		if ($lc eq 'epoch') {
			my $compiled = defined $const ? _fmt_compile($const) : undef;
			return sub {
				my $value = $value_fn->($_[0]);
				my $t = defined $compiled
					? _time_from_format($value, $compiled)
					: _parse_time($value);
				return defined $t ? $t->{epoch} : undef;
			};
		}

		my $interval = defined $const ? span_interval($const) : undef;
		croak _fmt('error_span_interval', defined $const ? $const : '')
			unless $interval;
		return sub { _span_label($value_fn->($_[0]), $interval) };
	}

	$$pos_ref++;	# consume '('
	my @arg_fns;
	if ($tokens->[$$pos_ref]{type} ne $T_RPAREN) {
		push @arg_fns, _parse_cmp($tokens, $pos_ref, $depth_ref, $cols);
		while ($tokens->[$$pos_ref]{type} eq $T_COMMA) {
			$$pos_ref++;
			push @arg_fns, _parse_cmp($tokens, $pos_ref, $depth_ref, $cols);
		}
	}
	_expect($tokens, $pos_ref, $T_RPAREN);

	# 'if' special form: short-circuit true/false branches
	if ($lc eq 'if') {
		my ($cond_fn, $true_fn, $false_fn) = @arg_fns;
		return sub {
			$cond_fn->($_[0]) ? $true_fn->($_[0]) : $false_fn->($_[0]);
		};
	}

	my $fn = $FUNCTIONS{$lc};
	return sub {
		my $row = $_[0];
		$fn->(map { $_->($row) } @arg_fns);
	};
}

# Parse a column reference; validates against the whitelist at compile time.
# Underscores in the expression may match spaces in the actual column name,
# and the comparison is case-insensitive, so  per_unit_price  can address
# a column named "Per Unit Price".
sub _parse_colref {
	my ($cols, $name, $name_pos) = @_;

	# 1. Exact match
	return sub { $_[0]->{$name} } if $cols->{$name};

	# 2. Underscore-to-space alias, case-insensitive
	(my $spaced = $name) =~ s/_/ /g;
	my $lc_spaced = lc($spaced);
	for my $col (keys %{$cols}) {
		if (lc($col) eq $lc_spaced) {
			my $lookup = $col;
			return sub { $_[0]->{$lookup} };
		}
	}

	croak _fmt('error_unknown_col', $name);
}

# ---------------------------------------------------------------------------
# Standalone date-normalisation helper (used by Dashboard::_apply_date_normalization)
# ---------------------------------------------------------------------------

# _iso_day_label($epoch) -> 'YYYY-MM-DD' in local time
sub _iso_day_label {
	my @lt = localtime($_[0]);
	return sprintf '%04d-%02d-%02d', $lt[5] + 1900, $lt[4] + 1, $lt[3];
}

# _normalise_with_format($value, \%pattern) -> ISO string or undef
#
# The hash shape of a stored pattern: { date => '<fmt>', [time => '<fmt'>],
# [as => 'timestamp'] }.  With a time pattern the value is normalised to
# 'YYYY-MM-DDTHH:MM:SS', which is the shape the date comparisons already read
# to the second; with as => 'timestamp' and no time pattern it is that same
# shape at midnight, so a date-only column can be compared against a
# last_24_hours window.
sub _normalise_with_format {
	my ($val, $pattern) = @_;
	return undef unless defined $pattern->{date} && length $pattern->{date};

	my $time_fmt = $pattern->{time};
	if (defined $time_fmt && length $time_fmt) {
		my $t = _time_from_format($val, _fmt_compile_pair($pattern->{date}, $time_fmt));
		return undef unless $t;
		return _iso_second_label($t->{epoch});
	}

	my $t = _time_from_format($val, _fmt_compile($pattern->{date}));
	return undef unless $t;
	return ($pattern->{as} // '') eq 'timestamp'
		? _iso_second_label($t->{epoch})
		: _iso_day_label($t->{epoch});
}

# date_normalise($value, $pattern) -> ISO string or undef
#
# Converts $value from the given strptime-style $pattern to ISO-8601.
# Returns undef when $value does not match the pattern or the pattern is
# unknown.  No external modules required.
#
# $pattern is either one of the three date patterns below, or a hashref
# { date => ..., time => ..., as => ... } for a column that holds a time as
# well as a date; see _normalise_with_format.
#
# Supported date patterns:
#   %m/%d/%Y  -- US slash-date (01/15/2026)
#   %d/%m/%Y  -- EU slash-date (15/01/2026)
#   %d-%b-%Y  -- DD-Mon-YYYY  (15-Jan-2026, case-insensitive month abbrev)
sub date_normalise {
	my ($val, $pattern) = @_;
	return undef unless defined $val && defined $pattern && length $val;
	return _normalise_with_format($val, $pattern) if ref $pattern eq 'HASH';
	if ($pattern eq '%m/%d/%Y') {
		return undef unless $val =~ /\A(\d{1,2})\/(\d{1,2})\/(\d{4})\z/;
		return sprintf('%04d-%02d-%02d', $3, $1, $2);
	} elsif ($pattern eq '%d/%m/%Y') {
		return undef unless $val =~ /\A(\d{1,2})\/(\d{1,2})\/(\d{4})\z/;
		return sprintf('%04d-%02d-%02d', $3, $2, $1);
	} elsif ($pattern eq '%d-%b-%Y') {
		return undef unless $val =~ /\A(\d{1,2})-([A-Za-z]{3})-(\d{4})\z/;
		my $mon = $_MONTH_NAME_TO_NUM{lc($2)};
		return undef unless defined $mon;
		return sprintf('%04d-%02d-%02d', $3, $mon, $1);
	}
	return undef;
}

1;

__END__

=head1 NAME

Database::BI::Calc - Safe recursive-descent expression evaluator for Database::BI

=head1 VERSION

0.012.0

=head1 SYNOPSIS

    use Database::BI::Calc;

    my $calc = Database::BI::Calc->new(
        expr    => 'if(qty > 0, round(amount / qty, 2), 0)',
        columns => [qw(amount qty)],
    );

    die $calc->error if $calc->error;

    for my $row (@rows) {
        my $val = $calc->evaluate($row);   # undef on runtime error
        $row->{unit_price} = $val;
    }

=head1 DESCRIPTION

A compile-once, evaluate-many expression engine. Expressions are parsed into
a pure-Perl closure tree at construction time. No C<eval> of user-supplied
strings is ever performed anywhere in this module.

=head1 CONSTRUCTOR

=head2 new(%args)

    my $calc = Database::BI::Calc->new(
        expr    => 'if(year(date) = 2026, amount * 1.1, amount)',
        columns => [qw(date amount)],
    );

Recognised keys:

=over 4

=item expr

The expression string. Maximum 512 characters.

=item columns

Arrayref of allowed column names. Any identifier in C<expr> that is not a
known function name must appear in this list (or must match when underscores
are replaced with spaces). Unknown identifiers cause a compile-time error
stored in C<error()>.

=back

Always check C<error()> after construction before calling C<evaluate()>.

=head3 API SPECIFICATION

=head4 INPUT

	{
	    expr    => 'string',    # the expression; at most 512 characters
	    columns => 'arrayref',  # optional; column names the expression may read (default [])
	    params  => 'hashref',   # optional; named constants, read like columns
	}

=head4 OUTPUT

Always a C<Database::BI::Calc> object; C<new> does not croak.  A bad
expression, an unknown identifier, an expression over 512 characters, a
parameter named like a column, or a bad C<span()> interval leaves the reason
in C<error()> and the object evaluates nothing.

=head1 METHODS

=head2 error

Returns the compile-time error string, or C<undef> if the expression compiled
successfully.

=head2 has_error

Returns true when C<error()> is defined.

=head3 API SPECIFICATION

Neither takes an argument.  C<error> returns C<'string' | undef>;
C<has_error> returns a boolean.

=head2 evaluate(\%row)

Evaluates the compiled expression against a data row. Returns the computed
scalar value, or C<undef> on any runtime error (division by zero, non-numeric
operand, undef column value, etc.) rather than croaking.

=head3 API SPECIFICATION

=head4 INPUT

	\%row   # hashref of column name => value

=head4 OUTPUT

	'scalar' | undef

C<undef> when the expression did not compile, or when evaluating it fails for
this row.  Bound C<params> are read in place of same-named row keys.

=head1 OPERATORS

    +  addition         -  subtraction
    *  multiplication   /  division (division by zero -> undef)
    -x unary negation   +x unary identity
    (expr)  grouping

    =   equal          !=  not equal
    <   less than      <=  less-or-equal
    >   greater than   >=  greater-or-equal

Operator precedence (highest to lowest): unary, then C<* />, then C<+ ->,
then comparisons. Comparisons yield C<1> (true) or C<0> (false). When both
operands look numeric, numeric comparison is used; otherwise case-insensitive
string comparison, matching C<_apply_filter_spec> semantics.

Use C<=> for equality, not C<==>. Writing C<==> is a compile-time error.

=head1 BUILT-IN FUNCTIONS

=head2 String

    upper(s)                 uc($s)
    lower(s)                 lc($s)
    trim(s)                  strip leading/trailing whitespace
    len(s)                   length($s)
    concat(a, b, ...)        join('', ...), undef treated as ''
    substr(s, start)         0-based start, to end of string
    substr(s, start, len)    0-based start, len characters

=head2 Numeric

    round(n, decimals)       sprintf-based rounding
    floor(n)                 POSIX::floor
    ceil(n)                  POSIX::ceil
    abs(n)                   absolute value

=head2 Conditional

    if(cond, true, false)    short-circuit ternary: only the taken branch is
                             evaluated, so if(qty > 0, amount/qty, 0) is safe
    isnull(val, default)     val if defined, else default
    coalesce(v1, v2, ...)    first defined value

=head2 Date (ISO-8601 C<YYYY-MM-DD> only)

    year(s)        four-digit year (2026)
    month(s)       month number 1-12
    day(s)         day of month 1-31
    quarter(s)     quarter 1-4
    week(s)        ISO 8601 week number 1-53
    month_name(s)  full English month name ('January' .. 'December')
    weekday(s)     ISO 8601 weekday: 1 = Monday, 7 = Sunday
    now()          today's date as 'YYYY-MM-DD' (no arguments)

All date functions return C<undef> when the value does not start with a
valid C<YYYY-MM-DD> prefix, rather than croaking.

=head2 Time of day

    hour(v)          hour of day, 0-23, or undef when v carries no time
    minute(v)        minute, 0-59
    second(v)        second, 0-59
    epoch(v)         epoch seconds
    epoch(v, fmt)    epoch seconds, read with a strptime-style pattern

These read the same values as the date functions and one more shape besides:

    C<2026-10-27>, C<2026-10-27T14:05>, C<2026-10-27 14:05:32>
                     ISO date or timestamp, local time
    C<1761660332>    ten digits: an epoch in seconds
    C<1761660332000> thirteen digits: an epoch in milliseconds
    anything else with C<fmt>, e.g. C<epoch(t,'%d/%m/%Y %H:%M')>
                     read with the pattern

Only the digit count separates the two epoch shapes, which is why it is the
rule and why it is written down here.  A pattern (C<fmt>, and the stored time
pattern below) may use C<%Y> (year), C<%m> (month number), C<%d> (day),
C<%H> (hour), C<%M> (minute), C<%S> (second) and C<%b> (month abbreviation),
with any other character taken literally; a pattern must name a year, a month
and a day, and any other token is a compile error rather than a silent skip.

Nothing here parses or stores a time zone: every value is local time, by
C<POSIX::mktime>, exactly as the date functions and the relative time ranges
already are.  A cell that carries no time -- C<2026-10-27> -- gives C<undef>
for C<hour()>, C<minute()> and C<second()> rather than a made-up zero.

=head2 Time buckets

    span(v, '<n><unit>')     the ISO label of the bucket v falls in

The unit is C<s>, C<m>, C<h>, C<d>, C<w>, C<mon> (months, because C<m> is
minutes), C<q> (quarters) or C<y>, and the count is one or more.  The label is
the start of the half-open interval containing the value:

    span(v, '1s')    2026-10-27T14:05:03
    span(v, '15m')   2026-10-27T14:00:00
    span(v, '1h')    2026-10-27T14:00:00
    span(v, '1d')    2026-10-27        local midnight, so a 23- or 25-hour day
                                       still has one bucket
    span(v, '1w')    2026-10-26        the Monday of that ISO week
    span(v, '1mon')  2026-10-01        the first of that month
    span(v, '1q')    2026-10-01        the first day of that quarter
    span(v, '1y')    2026-01-01

A count above one widens the bucket without moving the calendar: C<3mon>
aligns to January, April, July and October because a month count runs from
January 1970, not from the first value seen.

Labels are ISO at the bucket's own resolution, never C<'Oct 2026'>.  Group keys
are sorted as strings, so an ISO label makes lexicographic order chronological
order -- a bucketed chart is in the right order with no second sort path.  A
pretty name is a presentation step; C<month_name()> already reads a month
number, and it is never the group key.

A value that cannot be read, or an interval that is not one -- C<'1x'>,
C<'0h'>, C<'-1d'> -- gives C<undef>, which C<Dashboard::_apply_calc_fields>
stores as C<'(unparseable)'> so the row stays visible in one explicit bucket
rather than disappearing.  The interval is a constant in the expression, so a
bad one is rejected when the expression is compiled, not when a row is
reached.

The interval rule is also a function:

    Database::BI::Calc::span_interval('1mon')   # { n => 1, unit => 'mon' }
    Database::BI::Calc::span_interval('15m')    # { n => 15, unit => 'm', secs => 60 }
    Database::BI::Calc::span_interval('0h')     # undef

=head3 API SPECIFICATION

=head4 INPUT

	$interval   # '<n><unit>', n >= 1, unit one of s m h d w mon q y

=head4 OUTPUT

	{ n => 'integer', unit => 'string', secs => 'integer' } | undef

C<secs> is present only for C<s>, C<m> and C<h>, whose buckets are floored from
the epoch.  Anything else, including a reference, is C<undef>.

=head2 Date normalisation (standalone helper)

    date_normalise($value, $pattern) -> ISO string or undef

Converts C<$value> from a non-ISO format to ISO-8601.  Returns C<undef> when
the value does not match the pattern.  C<$pattern> is one of:

    %m/%d/%Y   US slash-date  (01/15/2026)
    %d/%m/%Y   EU slash-date  (15/01/2026)
    %d-%b-%Y   DD-Mon-YYYY   (15-Jan-2026; month abbreviation is case-insensitive)

or a hashref for a column that holds a time as well as a date:

    { date => '%d/%m/%Y', time => '%H:%M' }                  -> '2026-10-27T14:05:00'
    { date => '%d/%m/%Y', time => '%H:%M:%S' }               -> '2026-10-27T14:05:32'
    { date => '%d/%m/%Y', as => 'timestamp' }                -> '2026-10-27T00:00:00'

With a C<time> pattern the value is normalised to C<YYYY-MM-DDTHH:MM:SS>, which
is the shape the date comparisons in C<Database::BI::Controller::Dashboard>
already read to the second and which a C<last_24_hours> window can filter on;
with C<as =E<gt> 'timestamp'> and no time pattern it is that shape at midnight,
so a date-only column can be compared the same way.  A date pattern on its own
still means C<YYYY-MM-DD> and still normalises to C<YYYY-MM-DD>, so a stored
pattern that has not changed its meaning has not changed its meaning.

This is called by C<Dashboard::_apply_date_normalization> before calc fields
are evaluated, so C<YEAR(date)>, C<HOUR(date)> and C<span(date, '1h')> see ISO
values regardless of the source format.

=head3 API SPECIFICATION

=head4 INPUT

	$value     # string
	$pattern   # one of the three date patterns, or { date, time, as }

=head4 OUTPUT

	'string' | undef   # YYYY-MM-DD, or YYYY-MM-DDTHH:MM:SS with a time or as => 'timestamp'

An undefined or empty value, an unknown pattern, or a value that does not
match returns C<undef>.  It does not croak.

=head2 Binning

    bin(value, width)   '[lo,hi)' label for the half-open interval containing
                        value.  Width must be a positive number.  Integer widths
                        produce integer labels ('[0,100)'); fractional widths
                        use %g ('[0.5,1)')

=head1 COLUMN NAMES WITH SPACES

Column names containing spaces can be referenced by replacing spaces with
underscores. C<per_unit_price> in an expression addresses a column named
C<"Per Unit Price"> automatically.

=head1 SECURITY

=over 4

=item *

No C<eval> of user-supplied strings is performed anywhere in this module.

=item *

Column references are validated at compile time against the C<columns>
whitelist. Unknown identifiers are rejected at C<new()> time.

=item *

Function names are validated against a hardcoded dispatch table. Unknown
function names are rejected at C<new()> time.

=item *

Expressions longer than 512 characters are rejected.

=item *

Nesting deeper than 20 levels is rejected.

=item *

Division by zero and undef/non-numeric operands return C<undef> rather than
croaking, so a bad row does not abort an export pipeline.

=back

=head1 DEPENDENCIES

L<POSIX>, L<Scalar::Util>, L<Readonly>, L<Carp> -- all present in the
Database::BI dependency set.

=head1 SEE ALSO

L<Database::BI>, L<Database::BI::Controller::Dashboard>

=head1 AUTHOR

Nigel Horne, C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
