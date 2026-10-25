package Database::BI::Calc;

use strict;
use warnings;

use Carp	qw(croak);
use POSIX	qw(floor ceil);
use Readonly;
use Scalar::Util	qw(looks_like_number);

our $VERSION = '0.017.0';

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
);

sub _fmt {
	my ($key, @args) = @_;
	return sprintf $MESSAGES{$key}, @args;
}

# --- built-in function dispatch table ---
# 'if' is handled as a special form in _parse_call (short-circuit branches).
# All date functions accept ISO-8601 'YYYY-MM-DD' prefix only; non-matching
# values return undef and appear in the empty-cell bucket rather than being
# dropped.

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
		unless exists $FUNCTIONS{$lc} || $lc eq 'if';

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

Readonly my %_MONTH_NAME_TO_NUM => (
	jan => 1, feb => 2, mar => 3, apr => 4,  may => 5,  jun => 6,
	jul => 7, aug => 8, sep => 9, oct => 10, nov => 11, dec => 12,
);

# date_normalise($value, $pattern) -> 'YYYY-MM-DD' or undef
#
# Converts $value from the given strptime-style $pattern to ISO-8601.
# Returns undef when $value does not match the pattern or the pattern is
# unknown.  No external modules required.
#
# Supported patterns:
#   %m/%d/%Y  -- US slash-date (01/15/2026)
#   %d/%m/%Y  -- EU slash-date (15/01/2026)
#   %d-%b-%Y  -- DD-Mon-YYYY  (15-Jan-2026, case-insensitive month abbrev)
sub date_normalise {
	my ($val, $pattern) = @_;
	return undef unless defined $val && defined $pattern && length $val;
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

=head1 METHODS

=head2 error

Returns the compile-time error string, or C<undef> if the expression compiled
successfully.

=head2 has_error

Returns true when C<error()> is defined.

=head2 evaluate(\%row)

Evaluates the compiled expression against a data row. Returns the computed
scalar value, or C<undef> on any runtime error (division by zero, non-numeric
operand, undef column value, etc.) rather than croaking.

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

=head2 Date normalisation (standalone helper)

    date_normalise($value, $pattern) -> 'YYYY-MM-DD' or undef

Converts C<$value> from a non-ISO format to ISO-8601 C<YYYY-MM-DD>.
Returns C<undef> when the value does not match the pattern.
Supported patterns:

    %m/%d/%Y   US slash-date  (01/15/2026)
    %d/%m/%Y   EU slash-date  (15/01/2026)
    %d-%b-%Y   DD-Mon-YYYY   (15-Jan-2026; month abbreviation is case-insensitive)

This is called by C<Dashboard::_apply_date_normalization> before calc fields
are evaluated, so C<YEAR(date)> sees ISO values regardless of the source format.

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

=head1 LICENSE

Same terms as Database::BI.

=cut
