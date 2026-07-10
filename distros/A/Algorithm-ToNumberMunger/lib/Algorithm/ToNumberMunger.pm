package Algorithm::ToNumberMunger;

use 5.006;
use strict;
use warnings;

use Carp         qw(carp croak);
use Scalar::Util qw(looks_like_number);

=head1 NAME

Algorithm::ToNumberMunger - Compile declarative specs into closures that munge raw values into numbers.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Feature hashing (the 'hash' munger) is a tight per-byte FNV-1a loop with a
# 32-bit modular multiply. That is exactly the kind of work XS is good at and
# pure Perl is bad at (both for speed and, on a 32-bit perl, for correctness of
# the wrap-around), so we compile it in C when we can. Everything else here is a
# hash lookup or a couple of flops -- crossing the XS boundary per row would
# only make those slower, so they stay pure Perl. If the XS did not build (no
# compiler at install time) we fall back to a pure-Perl FNV-1a, which is exact
# on a 64-bit perl.
our $HAVE_XS = 0;
eval {
	require XSLoader;
	XSLoader::load( __PACKAGE__, $VERSION );
	$HAVE_XS = 1;
	1;
};

=head1 SYNOPSIS

    use Algorithm::ToNumberMunger;

    # one munger from a spec hash
    my $code = Algorithm::ToNumberMunger->build(
        { munger => 'enum', map => { GET => 0, POST => 1, PUT => 2 } },
    );
    my $n = $code->('POST');          # 1

    # a whole table of them at once, from a 'field => spec' hash
    my $by_tag = Algorithm::ToNumberMunger->build_all(
        \%mungers,
    );
    my $row_value = $by_tag->{method}->($raw{method});

=head1 DESCRIPTION

Many numeric pipelines -- anomaly detectors, feature stores, CSV loaders --
want every column to be a number, but the values they are handed are not always
numbers to begin with: an HTTP method is a string, a timestamp is a formatted
date, a high-cardinality label wants bucketing. An B<input munger> turns such a
raw value into a single number. Munging happens on the input side, before a row
is stored.

Mungers are declared as a plain data spec -- a hash naming a built-in munger and
carrying that munger's parameters -- so a table of them can be read straight out
of JSON or a config file:

    {
        "method": { "munger": "enum",  "map": { "GET": 0, "POST": 1 } },
        "bytes":  { "munger": "log",   "offset": 1 },
        "label":  { "munger": "hash",  "buckets": 1024 }
    }

B<Any field without an entry is raw> and is passed through unchanged; this module
is only concerned with fields that name a munger.

This class does not read or write files. It B<compiles> a spec into a closure
that maps one raw value to one number, so a caller can build its mungers once
from configuration and then apply them per row with no re-parsing. All
configuration errors are caught at build time; the returned closure only croaks
on genuinely un-mungeable I<input>.

=head1 CLASS METHODS

=head2 build

    my $code = ...->build( \%spec );
    my $code = ...->build( \%spec, $tag_name );   # $tag_name only sharpens errors

Compile a single munger spec into a coderef. C<%spec> must contain a C<munger>
key naming one of the L</BUILT-IN MUNGERS>; the remaining keys are that munger's
parameters. Croaks on an unknown munger name or an invalid parameter set. The
optional second argument is only used to make error messages point at a tag.

=cut

# name => builder. Each builder validates its slice of the spec up front and
# returns the per-value closure. Keeping them in a table (rather than a big
# if/elsif) is what makes known_mungers() and has_munger() cheap and honest.
my %BUILDERS = (
	enum            => \&_build_enum,
	frozen_freq_map => \&_build_frozen_freq_map,
	bool            => \&_build_bool,
	length          => \&_build_length,
	entropy         => \&_build_entropy,
	ngram           => \&_build_ngram,
	char            => \&_build_char,
	run             => \&_build_run,
	count           => \&_build_count,
	match           => \&_build_match,
	bucket          => \&_build_bucket,
	quantile        => \&_build_quantile,
	scale           => \&_build_scale,
	zscore          => \&_build_zscore,
	log             => \&_build_log,
	clamp           => \&_build_clamp,
	num             => \&_build_num,
	bit             => \&_build_bit,
	ip_class        => \&_build_ip_class,
	cidr            => \&_build_cidr,
	datetime        => \&_build_datetime,
	hash            => \&_build_hash,
	chain           => \&_build_chain,
	eps             => \&_build_eps,
	mgcp_enum       => \&_build_mgcp_enum,
);

# Status-class mungers (http_enum, smtp_enum, sip_enum, ...) are one transform
# -- collapse a numeric reply code to its leading digit, int(code/div), with a
# divisor of 100 (10 for gemini's two-digit codes) -- differing only in which
# range 'strict' accepts. Register them all from this table so a new protocol
# is a single line and they can never drift apart. mgcp_enum is deliberately
# NOT a row here: its strict range has a hole (8xx exists, 6xx/7xx do not),
# which a single [lo, hi] cannot express, so it has its own builder below.
my %STATUS_PROTO = (
	http   => [ 100, 599 ],       # 1xx-5xx
	smtp   => [ 200, 599 ],       # 2xx-5xx; SMTP never issues 1yz in practice
	sip    => [ 100, 699 ],       # 1xx-6xx; SIP adds a 6xx global-failure class
	ftp    => [ 100, 599 ],       # 1xx-5xx FTP reply codes
	rtsp   => [ 100, 599 ],       # RTSP (RFC 2326) reuses HTTP's status scheme
	nntp   => [ 100, 599 ],       # 1xx-5xx NNTP (RFC 3977), SMTP-convention codes
	dict   => [ 100, 599 ],       # DICT (RFC 2229) uses SMTP-style codes
	gemini => [ 10,  69, 10 ],    # two-digit codes, 1x-6x; class = int(code/10)
);
for my $proto ( keys %STATUS_PROTO ) {
	my ( $lo, $hi, $div ) = @{ $STATUS_PROTO{$proto} };
	$div = 100 unless defined $div;
	$BUILDERS{"${proto}_enum"}
		= sub { _status_class_munger( $proto, $lo, $hi, $div, @_ ) };
}

# ratio and combine consume several source fields at once, so they are only
# buildable through compile()'s multi-input form ('from' as an arrayref) -- a
# scalar build can never hand them more than one value. Registering a stub
# keeps known_mungers() honest and turns "used it as a scalar munger" into a
# pointed error instead of an unknown-munger one.
for my $name (qw(ratio combine)) {
	$BUILDERS{$name} = sub {
		my ( $spec, $where ) = @_;
		croak "$name munger$where combines several inputs; it is only usable "
			. "via compile() with 'from' as an arrayref of source fields";
	};
}

sub build {
	my ( $class, $spec, $tag ) = @_;
	my $where = defined $tag ? " for tag '$tag'" : '';

	croak "munger spec$where must be a hashref"
		unless ref $spec eq 'HASH';

	my $name = $spec->{munger};
	croak "munger spec$where has no 'munger' name"
		unless defined $name && length $name;

	my $builder = $BUILDERS{$name}
		or croak "unknown munger '$name'$where (known: " . join( ', ', $class->known_mungers ) . ')';

	return $builder->( $spec, $where );
} ## end sub build

=head2 build_all

    my $by_tag = ...->build_all( $info->{mungers} );

Compile a whole C<mungers> hash (tag name => spec) into a hash of tag name =>
coderef. A false/absent argument yields an empty hashref (every tag is raw).
Croaks if any spec is invalid, naming the offending tag.

=cut

sub build_all {
	my ( $class, $mungers ) = @_;
	return {} unless $mungers;

	croak "'mungers' must be a hashref"
		unless ref $mungers eq 'HASH';

	my %by_tag;
	for my $tag ( keys %$mungers ) {
		$by_tag{$tag} = $class->build( $mungers->{$tag}, $tag );
	}
	return \%by_tag;
} ## end sub build_all

=head2 compile

    my $plan = ...->compile( tags => \@tags, mungers => $info->{mungers} );
    my $row  = $plan->apply_named( \%named_input );   # numbers, in tags order

Compile a set's C<tags> and (optional) C<mungers> into a B<plan> object that maps
one input record to a fully-numeric row in tag order. Unlike L</build_all> (which
just compiles each spec in isolation), C<compile> understands the whole set:

=over 4

=item * a scalar munger, keyed by its output tag, fills that one column; its
input is read from the tag's own name, or from C<< from => 'other' >> to alias a
source field;

=item * an B<expanding> munger, keyed by any label and carrying C<< into =>
[tag, ...] >>, reads one source (C<from>, defaulting to the label) and fills
several columns at once -- this is how a single timestamp becomes both a
C<sin>/C<cos> pair without the two ever drifting apart (see L</datetime>);

=item * a B<combining> munger, keyed by its output tag and carrying a C<from>
B<list> (C<< from => ['bytes_out', 'bytes_in'] >>), reads several source
fields and fills that one column -- this is how a ratio becomes a single
feature without precomputing it upstream (see L</ratio> and L</combine>). The
sources are raw input fields, not other (possibly munged) columns;

=item * every remaining tag is B<raw> and passed through unchanged.

=back

Coverage is validated up front: C<compile> croaks if two mungers write the same
column, if an C<into> names a column not in C<tags>, if a munger key is neither a
tag nor an expander, if an expander's output count does not match its C<into>,
or if a C<from> list is given to a munger that cannot combine inputs. The
returned plan has two methods, both returning an arrayref of numbers in C<tags>
order: C<apply_named(\%hash)> (keyed by field name, the only form that supports
expanders and combiners) and C<apply_positional(\@row)> (positional; croaks if
the set has any expanding or combining munger, since a shared or combined
source cannot be expressed by position).

=cut

# name => builder returning ($list_returning_code, $arity), for the mungers that
# can fan one input out into several columns via 'into'.
my %MULTI_BUILDERS = (
	datetime => \&_build_datetime_multi,
	eps      => \&_build_eps_multi,
	chain    => \&_build_chain_multi,
);

sub _build_multi {
	my ( $class, $spec, $where ) = @_;
	my $name = $spec->{munger};
	croak "munger spec$where has no 'munger' name"
		unless defined $name && length $name;
	my $builder = $MULTI_BUILDERS{$name}
		or croak "munger '$name'$where does not support multiple outputs "
		. "('into'); only these do: "
		. join( ', ', sort keys %MULTI_BUILDERS );
	return $builder->( $spec, $where );
} ## end sub _build_multi

# name => builder returning the N-input closure, for the mungers that combine
# several source fields ('from' as an arrayref) into one column. The builder is
# handed the source count so arity errors surface at compile time.
my %COMBINE_BUILDERS = (
	ratio   => \&_build_ratio,
	combine => \&_build_combine_op,
);

sub _build_combine {
	my ( $class, $spec, $where, $nsrc ) = @_;
	my $name = $spec->{munger};
	croak "munger spec$where has no 'munger' name"
		unless defined $name && length $name;
	my $builder = $COMBINE_BUILDERS{$name}
		or croak "munger '$name'$where does not support multiple inputs "
		. "(a 'from' list); only these do: "
		. join( ', ', sort keys %COMBINE_BUILDERS );
	return $builder->( $spec, $where, $nsrc );
} ## end sub _build_combine

sub compile {
	my ( $class, %args ) = @_;

	my $tags = $args{tags};
	croak "compile requires a non-empty 'tags' arrayref"
		unless ref $tags eq 'ARRAY' && @$tags;
	my $mungers = $args{mungers} || {};
	croak "compile: 'mungers' must be a hashref"
		unless ref $mungers eq 'HASH';

	my %pos;
	for my $i ( 0 .. $#$tags ) {
		croak "compile: duplicate tag '$tags->[$i]'"
			if exists $pos{ $tags->[$i] };
		$pos{ $tags->[$i] } = $i;
	}

	my ( @scalar, @expand, @combine, %claimed );
	my $claim = sub {
		my ( $tag, $by ) = @_;
		croak "munger '$by' targets unknown column '$tag'"
			unless exists $pos{$tag};
		croak "two mungers write column '$tag'"
			if $claimed{$tag}++;
	};

	for my $key ( sort keys %$mungers ) {
		my $spec = $mungers->{$key};
		croak "munger '$key' spec must be a hashref"
			unless ref $spec eq 'HASH';
		my $from = defined $spec->{from} ? $spec->{from} : $key;

		if ( ref $from eq 'ARRAY' ) {
			croak "munger '$key': a 'from' list needs at least 2 source fields"
				unless @$from >= 2;
			croak "munger '$key': 'into' cannot be combined with a 'from' list"
				if defined $spec->{into};
			croak "munger '$key' is not a declared tag and has no 'into'"
				unless exists $pos{$key};
			my $code = $class->_build_combine( $spec, " for '$key'", scalar @$from );
			$claim->( $key, $key );
			push @combine, { tag => $key, from => [@$from], code => $code };
		} elsif ( defined $spec->{into} ) {
			my $into = $spec->{into};
			croak "munger '$key': 'into' must be a non-empty arrayref"
				unless ref $into eq 'ARRAY' && @$into;
			my ( $code, $arity ) = $class->_build_multi( $spec, " for '$key'" );
			croak "munger '$key' produces $arity value(s) but 'into' lists " . scalar(@$into)
				unless $arity == @$into;
			$claim->( $_, $key ) for @$into;
			push @expand, { from => $from, into => [@$into], code => $code };
		} else {
			croak "munger '$key' is not a declared tag and has no 'into'"
				unless exists $pos{$key};
			$claim->( $key, $key );
			push @scalar, { tag => $key, from => $from, code => $class->build( $spec, $key ) };
		}
	} ## end for my $key ( sort keys %$mungers )

	for my $tag (@$tags) {
		push @scalar, { tag => $tag, from => $tag, code => undef }
			unless $claimed{$tag};
	}

	return bless {
		tags    => [@$tags],
		pos     => \%pos,
		scalar  => \@scalar,
		expand  => \@expand,
		combine => \@combine,
		},
		"${class}::Plan";
} ## end sub compile

=head2 known_mungers

    my @names = ...->known_mungers;

The sorted list of built-in munger names this version understands.

=head2 has_munger

    if ( ...->has_munger('enum') ) { ... }

True if the named munger is built in.

=cut

sub known_mungers { my @names = sort keys %BUILDERS; return @names }
sub has_munger    { return exists $BUILDERS{ $_[1] } }

=head1 BUILT-IN MUNGERS

Every munger returns a plain number and, where the input cannot be interpreted,
croaks -- the Writer would reject a non-numeric field anyway, so failing at the
munger gives a better message. Parameters are validated when the munger is
built, not per row.

=head2 enum

    { munger => 'enum', map => { GET => 0, POST => 1 }, default => -1 }

Categorical string to number via an explicit C<map>. All map values must be
numeric. Without a C<default>, an unmapped input croaks; with one, unmapped
inputs (including C<undef>) yield the default.

=cut

sub _build_enum {
	my ( $spec, $where ) = @_;

	my $map = $spec->{map};
	croak "enum munger$where requires a 'map' hashref"
		unless ref $map eq 'HASH';

	for my $k ( keys %$map ) {
		croak "enum munger$where: map value for '$k' ('"
			. ( defined $map->{$k} ? $map->{$k} : 'undef' )
			. "') is not numeric"
			unless looks_like_number( $map->{$k} );
	}

	my $has_default = exists $spec->{default};
	my $default     = $spec->{default};
	croak "enum munger$where: 'default' must be numeric"
		if $has_default && !looks_like_number($default);

	# Copy so a later edit of the caller's spec cannot mutate a live munger.
	my %m = %$map;
	return sub {
		my ($v) = @_;
		return $m{$v}   if defined $v && exists $m{$v};
		return $default if $has_default;
		croak "enum munger$where: no mapping for '" . ( defined $v ? $v : 'undef' ) . "'";
	};
} ## end sub _build_enum

=head2 frozen_freq_map

    { munger => 'frozen_freq_map', counts => { jpg => 40213, exe => 12, scr => 3 },
      total => 67560 }
    # defaults: mode => 'neg_log_prob', smoothing => 1, unseen => 'rare'

Frequency-encoding from a B<precomputed, frozen> count table: the rarer a value
was when the table was built, the more anomalous it scores. This is C<enum>'s
cousin -- a value-to-number map -- except the numbers are derived from observed
C<counts> rather than hand-authored, with the smoothing and unseen-value policy
that "rare = interesting" needs. It stays a stateless munger: the table is
computed offline and shipped in C<info.json>; this class only I<applies> it.

C<counts> maps each value to how many times it was seen. C<total> is the overall
observation count; it defaults to the sum of C<counts>, but may be given
explicitly and larger so you can B<prune the long tail> out of C<counts> while
still computing correct probabilities. The emitted number depends on C<mode>:

=over 4

=item * C<neg_log_prob> (default) - self-information C<-ln(prob)>: rare values
score high, common ones low. This is the axis "rare = interesting" describes and
what an Isolation Forest splits on most naturally.

=item * C<freq> - the probability itself, C<(count + smoothing) / denom>.

=item * C<log_count> - C<ln(1 + count)>, the count with its heavy tail tamed.

=item * C<count> - the raw count.

=back

Probabilities use add-one style C<smoothing> (default C<1>), treating "unseen" as
one aggregate bucket: C<prob(v) = (count + smoothing) / (total + smoothing*(V+1))>
where C<V> is the number of listed values. C<unseen> controls what a value absent
from the table maps to -- C<'rare'> (default) emits that value under the current
mode as if it had been seen zero times (for C<neg_log_prob>/C<freq> this is the
smoothed unseen bucket, for C<count>/C<log_count> it is C<0>), or a number to
force a fixed default. Because an unseen value is usually the very thing you are
hunting, mapping it to "maximally rare" rather than erroring is the point.

C<frozen_freq_map> only suits B<bounded, moderate-cardinality> columns (extensions,
vendor classes, named pipes, keyboard layouts, link addresses): the table lives
in C<info.json>, so a huge one bloats every read -- building one past
C<$Algorithm::ToNumberMunger::FROZEN_FREQ_MAP_WARN_KEYS>
values (default 10000) warns. For unbounded cardinality (JA3, full user-agents)
use L</hash> instead, which needs no table but keeps only decorrelation, not
commonness.

=cut

# name => 1 for the recognized frozen_freq_map output modes.
my %FREQ_MODE = map { $_ => 1 } qw(neg_log_prob freq log_count count);

# Building a table larger than this warns: info.json ships the whole map, so a
# high-cardinality column belongs in the 'hash' munger instead.
our $FROZEN_FREQ_MAP_WARN_KEYS = 10_000;

sub _build_frozen_freq_map {
	my ( $spec, $where ) = @_;

	my $counts = $spec->{counts};
	croak "frozen_freq_map munger$where requires a non-empty 'counts' hashref"
		unless ref $counts eq 'HASH' && %$counts;

	my $sum = 0;
	for my $k ( keys %$counts ) {
		my $c = $counts->{$k};
		croak "frozen_freq_map munger$where: count for '$k' ('"
			. ( defined $c ? $c : 'undef' )
			. "') is not a non-negative number"
			unless looks_like_number($c) && $c >= 0;
		$sum += $c;
	}

	my $V = keys %$counts;
	carp "frozen_freq_map munger$where: 'counts' has $V keys; a table this large bloats "
		. "info.json -- consider the 'hash' munger for unbounded cardinality"
		if $V > $FROZEN_FREQ_MAP_WARN_KEYS;

	my $total = defined $spec->{total} ? $spec->{total} : $sum;
	croak "frozen_freq_map munger$where: 'total' must be numeric"
		unless looks_like_number($total);
	croak "frozen_freq_map munger$where: 'total' ($total) must be >= sum of counts ($sum)"
		if $total < $sum;

	my $mode = defined $spec->{mode} ? $spec->{mode} : 'neg_log_prob';
	croak "frozen_freq_map munger$where: unknown mode '$mode' (known: " . join( ', ', sort keys %FREQ_MODE ) . ')'
		unless $FREQ_MODE{$mode};

	my $s = defined $spec->{smoothing} ? $spec->{smoothing} : 1;
	croak "frozen_freq_map munger$where: 'smoothing' must be a non-negative number"
		unless looks_like_number($s) && $s >= 0;

	my $unseen = defined $spec->{unseen} ? $spec->{unseen} : 'rare';
	croak "frozen_freq_map munger$where: 'unseen' must be 'rare' or a number"
		unless $unseen eq 'rare' || looks_like_number($unseen);

	# An unseen value under neg_log_prob has probability s/denom; with no
	# smoothing that is 0 and -ln(0) is infinite, which would poison the column.
	# Refuse to build rather than emit inf.
	croak "frozen_freq_map munger$where: mode 'neg_log_prob' with unseen => 'rare' needs "
		. "smoothing > 0 (an unseen value would otherwise be infinitely surprising)"
		if $mode eq 'neg_log_prob' && $unseen eq 'rare' && $s == 0;

	# Smoothed-probability denominator, treating "unseen" as one extra bucket.
	my $denom = $total + $s * ( $V + 1 );

	# raw count -> emitted number under the chosen mode.
	my $emit_for = sub {
		my ($c) = @_;
		return $c            if $mode eq 'count';
		return log( 1 + $c ) if $mode eq 'log_count';
		my $p = ( $c + $s ) / $denom;
		return $p if $mode eq 'freq';
		return -log($p);    # neg_log_prob
	};

	my %emit         = map { $_ => $emit_for->( $counts->{$_} ) } keys %$counts;
	my $unseen_value = $unseen eq 'rare' ? $emit_for->(0) : $unseen;

	return sub {
		my ($v) = @_;
		return defined $v && exists $emit{$v} ? $emit{$v} : $unseen_value;
	};
} ## end sub _build_frozen_freq_map

=head2 http_enum

    { munger => 'http_enum' }
    { munger => 'http_enum', strict => 1 }

Collapse an HTTP status code to its class: C<1xx> to C<1>, C<2xx> to C<2>, C<3xx>
to C<3>, and so on (i.e. C<int(code / 100)>). This is the usual bucketing for an
HTTP status column -- the forest cares far more about "was this a 4xx vs a 2xx"
than about C<403> vs C<404>, and it keeps the feature low-cardinality without
having to spell out every code in an C<enum> C<map>. The input must be numeric.

By default any numeric input is bucketed, so a bogus C<700> would quietly become
C<7>. With a true C<strict>, inputs outside the valid HTTP status range
(C<100>-C<599>) croak instead, so a malformed code is caught at write time rather
than smuggled into the model as a spurious class.

=head2 smtp_enum

    { munger => 'smtp_enum' }
    { munger => 'smtp_enum', strict => 1 }

The SMTP counterpart of L</http_enum>: collapse an SMTP reply code to its leading
digit (C<int(code / 100)>), since that digit I<is> the reply's meaning -- C<2yz>
completion, C<3yz> intermediate, C<4yz> transient failure, C<5yz> permanent
failure. As with C<http_enum> this keeps the column low-cardinality and lets the
forest weigh "a 5xx where a 2xx was expected" without enumerating every code.

With a true C<strict>, inputs outside the valid SMTP reply range (C<200>-C<599>)
croak. SMTP never issues C<1yz> replies in practice (no command permits a
positive-preliminary reply), so the strict floor is C<200> rather than
C<http_enum>'s C<100>.

=head2 sip_enum

    { munger => 'sip_enum' }
    { munger => 'sip_enum', strict => 1 }

The SIP counterpart of L</http_enum>: collapse a SIP status code to its leading
digit (C<int(code / 100)>). SIP reuses HTTP's class scheme but adds a sixth
class -- C<1xx> provisional, C<2xx> success, C<3xx> redirection, C<4xx> client
error, C<5xx> server error, C<6xx> global failure.

With a true C<strict>, inputs outside the valid SIP status range (C<100>-C<699>)
croak. The ceiling is C<699> rather than C<http_enum>'s C<599> precisely because
of that C<6xx> global-failure class.

=head2 ftp_enum

    { munger => 'ftp_enum' }
    { munger => 'ftp_enum', strict => 1 }

The FTP counterpart of L</http_enum>, for FTP reply codes: C<int(code / 100)>,
bucketing into C<1yz>-C<5yz>. With a true C<strict>, inputs outside C<100>-C<599>
croak.

=head2 rtsp_enum

    { munger => 'rtsp_enum' }
    { munger => 'rtsp_enum', strict => 1 }

The RTSP counterpart of L</http_enum>. RTSP (RFC 2326) deliberately reuses
HTTP's status scheme, so codes collapse to their leading digit the same way.
With a true C<strict>, inputs outside C<100>-C<599> croak.

=head2 nntp_enum

    { munger => 'nntp_enum' }
    { munger => 'nntp_enum', strict => 1 }

The NNTP counterpart of L</http_enum>, for NNTP (RFC 3977) reply codes, which
follow the SMTP convention -- C<1xx> informational, C<2xx> success, C<3xx>
send-more-input, C<4xx> transient failure, C<5xx> permanent failure. Unlike
SMTP, NNTP does issue C<1xx> replies (help text, capability lists), so the
strict floor is C<100> rather than C<smtp_enum>'s C<200>. With a true
C<strict>, inputs outside C<100>-C<599> croak.

=head2 dict_enum

    { munger => 'dict_enum' }
    { munger => 'dict_enum', strict => 1 }

The DICT counterpart of L</http_enum>, for DICT protocol (RFC 2229) status
codes, which use the SMTP-style code classes. With a true C<strict>, inputs
outside C<100>-C<599> croak.

=head2 gemini_enum

    { munger => 'gemini_enum' }
    { munger => 'gemini_enum', strict => 1 }

Like L</http_enum> but for the Gemini protocol, whose status codes are B<two>
digits -- C<1x> input expected, C<2x> success, C<3x> redirect, C<4x> temporary
failure, C<5x> permanent failure, C<6x> client certificate required -- so the
class is C<int(code / 10)>. With a true C<strict>, inputs outside C<10>-C<69>
croak.

=cut

# Shared closure for the status-class mungers registered from %STATUS_PROTO.
sub _status_class_munger {
	my ( $proto, $lo, $hi, $div, $spec, $where ) = @_;
	my $strict = $spec->{strict} ? 1 : 0;
	return sub {
		my ($v) = @_;
		croak "${proto}_enum munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not a numeric status code"
			unless looks_like_number($v);
		croak "${proto}_enum munger$where: status code '$v' is out of range " . "($lo-$hi)"
			if $strict && ( $v < $lo || $v > $hi );
		return int( $v / $div );
	};
} ## end sub _status_class_munger

=head2 mgcp_enum

    { munger => 'mgcp_enum' }
    { munger => 'mgcp_enum', strict => 1 }

The MGCP counterpart of L</http_enum>, for MGCP (RFC 3435) response codes:
C<int(code / 100)>. MGCP's classes are C<1xx> provisional, C<2xx> success,
C<4xx> transient error, C<5xx> permanent error, and C<8xx> package-specific --
there are no C<6xx> or C<7xx> codes, so the valid set has a B<hole> in it.
With a true C<strict>, inputs outside C<100>-C<599> B<and> outside
C<800>-C<899> croak. (That hole is why this is a hand-written builder rather
than another row of the shared status-class table, which can only express one
contiguous range.)

=cut

# MGCP's strict range is [100,599] union [800,899] -- 8xx package-specific
# codes are real, 6xx/7xx are not -- which %STATUS_PROTO's single [lo, hi]
# cannot express, hence this dedicated builder.
sub _build_mgcp_enum {
	my ( $spec, $where ) = @_;
	my $strict = $spec->{strict} ? 1 : 0;
	return sub {
		my ($v) = @_;
		croak "mgcp_enum munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not a numeric status code"
			unless looks_like_number($v);
		croak "mgcp_enum munger$where: status code '$v' is out of range " . "(100-599 or 800-899)"
			if $strict && !( ( $v >= 100 && $v <= 599 ) || ( $v >= 800 && $v <= 899 ) );
		return int( $v / 100 );
	};
} ## end sub _build_mgcp_enum

=head2 dns_rcode_enum

    { munger => 'dns_rcode_enum' }
    { munger => 'dns_rcode_enum', default => -1 }

The first of the B<named-map enums>: like L</enum>, except the C<map> is baked
in from a well-known registry instead of hand-authored (and inevitably
typo'd). All named-map enums share the same lookup rules: names are matched
B<case-insensitively>; where the emitted numbers are the protocol's own wire
encoding (as here -- rcode C<3> I<is> C<NXDOMAIN>), a numeric input is passed
through unchanged, so mixed feeds (one tool logs C<NXDOMAIN>, another logs
C<3>) land in one consistent column; and an unmapped value croaks unless the
spec supplies a numeric C<default>. As with C<enum>, an unrecognized value is
often exactly the anomaly worth keeping, so C<< default => -1 >> is the usual
escape hatch.

This one maps DNS RCODE names to their IANA values: C<NOERROR> 0, C<FORMERR>
1, C<SERVFAIL> 2, C<NXDOMAIN> 3, C<NOTIMP> 4 (alias C<NOTIMPL>), C<REFUSED> 5,
C<YXDOMAIN> 6, C<YXRRSET> 7, C<NXRRSET> 8, C<NOTAUTH> 9, C<NOTZONE> 10,
C<DSOTYPENI> 11, and the extended rcodes C<BADVERS>/C<BADSIG> 16, C<BADKEY>
17, C<BADTIME> 18, C<BADMODE> 19, C<BADNAME> 20, C<BADALG> 21, C<BADTRUNC> 22,
C<BADCOOKIE> 23.

=head2 dns_qtype_enum

    { munger => 'dns_qtype_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>; numeric inputs pass
through) mapping DNS RR type names to their IANA numbers: C<A> 1, C<NS> 2,
C<CNAME> 5, C<SOA> 6, C<NULL> 10, C<PTR> 12, C<MX> 15, C<TXT> 16, C<AAAA> 28,
C<SRV> 33, C<NAPTR> 35, C<DS> 43, C<RRSIG> 46, C<DNSKEY> 48, C<TLSA> 52,
C<SVCB> 64, C<HTTPS> 65, C<AXFR> 252, C<ANY> (or C<*>) 255, C<URI> 256,
C<CAA> 257, and the rest of the commonly-observed registry. The query-type mix
is a classic DNS-tunneling feature -- C<TXT>/C<NULL>-heavy traffic where
C<A>/C<AAAA> is normal.

=head2 syslog_severity_enum

    { munger => 'syslog_severity_enum' }

Named-map enum (lookup rules as L</dns_rcode_enum>; numeric inputs pass
through) mapping syslog severity names to their RFC 5424 codes: C<emerg> 0
(alias C<panic>), C<alert> 1, C<crit> 2, C<err> 3 (alias C<error>),
C<warning> 4 (alias C<warn>), C<notice> 5, C<info> 6 (alias
C<informational>), C<debug> 7. Genuinely ordinal -- lower is more severe --
so a threshold split on it is meaningful.

=head2 syslog_facility_enum

    { munger => 'syslog_facility_enum' }

Named-map enum (lookup rules as L</dns_rcode_enum>; numeric inputs pass
through) mapping syslog facility names to their RFC 5424 codes: C<kern> 0,
C<user> 1, C<mail> 2, C<daemon> 3, C<auth> 4 (alias C<security>), C<syslog> 5,
C<lpr> 6, C<news> 7, C<uucp> 8, C<cron> 9, C<authpriv> 10, C<ftp> 11, C<ntp>
12, C<audit> 13, C<alert> 14, C<clock> 15, and C<local0>-C<local7> 16-23.

=head2 ip_proto_enum

    { munger => 'ip_proto_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>; numeric inputs pass
through) mapping IP protocol names to their IANA protocol numbers: C<icmp> 1,
C<igmp> 2, C<ipip> 4 (alias C<ipencap>), C<tcp> 6, C<egp> 8, C<udp> 17,
C<dccp> 33, C<ipv6> 41, C<rsvp> 46, C<gre> 47, C<esp> 50, C<ah> 51,
C<icmpv6> 58 (alias C<ipv6-icmp>), C<ospf> 89, C<pim> 103, C<sctp> 132,
C<udplite> 136. The map is frozen here rather than delegated to
C<getprotobyname> so a value munges to the same number on every host.

=head2 tls_version_enum

    { munger => 'tls_version_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) mapping a TLS/SSL protocol
version name to an B<ordinal>: C<SSLv2> 0, C<SSLv3> 1, C<TLSv1> 2, C<TLSv1.1>
3, C<TLSv1.2> 4, C<TLSv1.3> 5, with the common spelling variants (C<ssl3>,
C<tls1.2>, ...) accepted. Ordinal so "older than expected" is a monotone
feature a threshold split can express. Because these ordinals are this
module's invention rather than a wire encoding, numeric inputs are B<not>
passed through -- a C<1.2> would land on the wrong scale -- and croak like
any other unmapped value (or take the C<default>).

=head2 http_method_enum

    { munger => 'http_method_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the registered HTTP
request methods: C<GET> 0, C<HEAD> 1, C<POST> 2, C<PUT> 3, C<DELETE> 4,
C<CONNECT> 5, C<OPTIONS> 6, C<TRACE> 7, C<PATCH> 8. HTTP has no numeric
method encoding, so these are unordered ordinals of this module's invention
(a canonical map beats every set inventing its own numbering) and numeric
inputs are not passed through. An unlisted -- possibly probing -- method
croaks unless a C<default> is given, and that unlisted-method signal is often
the interesting one.

=head2 sip_method_enum

    { munger => 'sip_method_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the SIP request
methods: C<INVITE> 0, C<ACK> 1, C<BYE> 2, C<CANCEL> 3, C<REGISTER> 4,
C<OPTIONS> 5, C<PRACK> 6, C<SUBSCRIBE> 7, C<NOTIFY> 8, C<PUBLISH> 9,
C<INFO> 10, C<REFER> 11, C<MESSAGE> 12, C<UPDATE> 13. Like
L</http_method_enum> these are ordinals of this module's invention, so
numeric inputs are not passed through.

=head2 dhcp_msgtype_enum

    { munger => 'dhcp_msgtype_enum' }

Named-map enum (lookup rules as L</dns_rcode_enum>; numeric inputs pass
through) mapping DHCP message-type names to their option-53 values:
C<DISCOVER> 1, C<OFFER> 2, C<REQUEST> 3, C<DECLINE> 4, C<ACK> 5, C<NAK> 6,
C<RELEASE> 7, C<INFORM> 8 -- each also accepted with the C<DHCP> prefix
(C<DHCPDISCOVER>, ...) that most tooling logs.

=head2 app_proto_enum

    { munger => 'app_proto_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for Suricata's
C<app_proto> field -- the detected application-layer protocol on a flow or
alert (C<http>, C<dns>, C<tls>, C<ssh>, C<smtp>, C<dcerpc>, C<quic>, ...),
including C<failed> and C<unknown>, which are usually the very rows worth
keeping. These are unordered ordinals of this module's invention (Suricata
logs a string, not a number), so numeric inputs are B<not> passed through.
C<ssl> is accepted as an alias for C<tls> and C<ikev2> for C<ike>. This is
distinct from L</ip_proto_enum>, which numbers the L4 protocol
(C<tcp>/C<udp>/...) rather than the app layer riding on it.

=head2 tcp_state_enum

    { munger => 'tcp_state_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) mapping the TCP state
machine, as Suricata logs it under C<flow.tcp.state>, to an B<ordinal> along
the connection lifecycle: C<none> 0, C<syn_sent> 1, C<syn_recv> 2,
C<established> 3, C<fin_wait1> 4, C<fin_wait2> 5, C<closing> 6, C<time_wait>
7, C<close_wait> 8, C<last_ack> 9, C<closed> 10. Ordinal so "further along
teardown than expected" is a monotone feature a threshold split can express.
Being ordinals of our own invention, numeric inputs are not passed through.

=head2 flow_state_enum

    { munger => 'flow_state_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for Suricata's
C<flow.state>: C<new> 0, C<established> 1, C<closed> 2, C<bypassed> 3,
C<local_bypass> 4 -- roughly ordinal along the flow lifecycle. Numeric inputs
are not passed through.

=head2 flow_reason_enum

    { munger => 'flow_reason_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for Suricata's
C<flow.reason>, why a flow was logged out: C<timeout> 0, C<forced> 1,
C<shutdown> 2, C<unknown> 3. Numeric inputs are not passed through.

=head2 suricata_action_enum

    { munger => 'suricata_action_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for Suricata's
C<alert.action> and the related rule/drop actions: C<allowed> 0, C<blocked>
1, C<pass> 2, C<drop> 3, C<reject> 4, C<alert> 5. In IDS mode the field is
C<allowed>/C<blocked>; the rule-action names are accepted too for IPS feeds
and C<drop> events. Numeric inputs are not passed through.

=head2 postfix_status_enum

    { munger => 'postfix_status_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for Postfix's delivery
C<status=> disposition, numbered in a rough sent-to-failed severity order so
a threshold split is meaningful: C<sent> 0, C<deferred> 1, C<bounced> 2,
C<expired> 3, C<deliverable> 4, C<undeliverable> 5, C<hold> 6, C<discard> 7,
C<filtered> 8, C<reject> 9, C<softbounce> 10. Stock delivery agents emit only
C<sent>/C<deferred>/C<bounced>/C<expired>; C<deliverable>/C<undeliverable> come
from address verification (C<verify>), and the remainder cover HOLD/DISCARD
actions and values common log normalizers emit. Being labels of this module's
numbering, numeric inputs are not passed through.

=head2 spf_result_enum

    { munger => 'spf_result_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for an SPF check result
(RFC 7208), as logged by policyd-spf or carried in an C<Authentication-Results>
header, numbered pass-to-fail: C<pass> 0, C<neutral> 1, C<none> 2, C<softfail>
3, C<fail> 4, C<temperror> 5, C<permerror> 6. The older spellings C<error>
(for C<temperror>) and C<unknown> (for C<permerror>) are accepted as aliases.
Numeric inputs are not passed through.

=head2 dkim_result_enum

    { munger => 'dkim_result_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for a DKIM verification
result (RFC 8601), as logged by opendkim or carried in an
C<Authentication-Results> header, numbered pass-to-fail: C<pass> 0, C<neutral>
1, C<none> 2, C<policy> 3, C<fail> 4, C<temperror> 5, C<permerror> 6. The older
spellings C<error> (for C<temperror>) and C<unknown> (for C<permerror>) are
accepted as aliases. Numeric inputs are not passed through.

=head2 dmarc_result_enum

    { munger => 'dmarc_result_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for a DMARC evaluation
result (RFC 7489 / RFC 8601), as logged by opendmarc or carried in an
C<Authentication-Results> header: C<pass> 0, C<none> 1, C<fail> 2, C<temperror>
3, C<permerror> 4, and opendmarc's C<bestguesspass> 5. This is the DMARC
I<result> (did the message pass alignment), not the policy I<disposition>
(C<none>/C<quarantine>/C<reject>) -- for that, use a plain L</enum>. Numeric
inputs are not passed through.

=head2 sasl_mech_enum

    { munger => 'sasl_mech_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the SASL
authentication mechanism -- as Dovecot logs C<mech=>, Postfix logs
C<sasl_method=>, and submission/IMAP/POP3 auth report -- numbered in a rough
B<weakest-to-strongest> order so the ordinal carries a little signal on its
own: the cleartext and C<anonymous> mechanisms sort low, the legacy
challenge-response ones (C<cram-md5>, C<digest-md5>, C<ntlm>, ...) in the
middle, then C<srp>/C<scram-*>, the OAuth/federated tokens, and finally the
Kerberos/GSS and certificate (C<external>) mechanisms. About two dozen
mechanisms are baked in, covering the IANA registry plus the ubiquitous
non-registered C<login>, C<xoauth2>, and C<apop>. Being ordinals of this
module's numbering, numeric inputs are not passed through; an unlisted
mechanism croaks unless a numeric C<default> is given.

If you would rather the number carry B<no> implied gradient, see
L</sasl_mech_iana_enum>, which numbers the same set alphabetically.

=head2 sasl_mech_iana_enum

    { munger => 'sasl_mech_iana_enum', default => -1 }

The nominal counterpart of L</sasl_mech_enum>: the B<same> set of SASL
mechanisms (the two share one list, so they can never cover different
mechanisms), but numbered B<alphabetically> rather than by strength -- a
purely categorical encoding for when a strength gradient would be a
misleading feature. Lookup rules and the no-numeric-passthrough behaviour are
as L</sasl_mech_enum>.

=head2 http_version_enum

    { munger => 'http_version_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) mapping the HTTP protocol
version to an B<ordinal>: C<HTTP/0.9> 0, C<HTTP/1.0> 1, C<HTTP/1.1> 2,
C<HTTP/2.0> 3, C<HTTP/3.0> 4. The access-log spelling (C<HTTP/1.1>), the bare
number (C<1.1>), and the ALPN/shorthand forms (C<h2>, C<h2c>, C<h3>) are all
accepted, so an Apache/nginx C<%H> field and a Suricata C<http.protocol> land
in one column. Ordinal so "older than expected" (a C<0.9>/C<1.0> request from
a scanner) is a monotone feature a threshold split can express. Because these
are ordinals of our own numbering -- and a logged C<2> denotes version C<2.0>,
not the integer two -- numeric inputs are B<not> passed through.

=head2 spamassassin_autolearn_enum

    { munger => 'spamassassin_autolearn_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for SpamAssassin's
C<autolearn=> field: C<no> 0, C<ham> 1, C<spam> 2, C<disabled> 3, C<failed> 4,
C<unavailable> 5, C<unknown> 6. The numbering is essentially nominal (the
Bayes auto-learn outcome is a category, not a scale), arranged only so the
"nothing was learned" states cluster away from the ham/spam ones. The spam
I<score> is already a number for L</num>, and the spam/ham verdict a L</bool>;
this covers the one autolearn field neither derives. Numeric inputs are not
passed through.

=head2 rspamd_action_enum

    { munger => 'rspamd_action_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for rspamd's action,
numbered by B<increasing severity> so the ordinal is a usable feature on its
own: C<no action> 0, C<greylist> 1, C<add header> 2, C<rewrite subject> 3,
C<soft reject> 4, C<reject> 5. Both the space and underscore spellings rspamd
emits (C<no action>/C<no_action>, C<add header>/C<add_header>, ...) are
accepted. Numeric inputs are not passed through.

=head2 ssh_auth_method_enum

    { munger => 'ssh_auth_method_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the OpenSSH
authentication method logged by C<sshd> (the word after C<Accepted>/C<Failed>,
or the C<method=> field): C<none> 0, C<password> 1, C<keyboard-interactive> 2,
C<hostbased> 3, C<publickey> 4, C<gssapi-with-mic> 5, C<gssapi-keyex> 6, with
bare C<gssapi> aliased to C<gssapi-with-mic>. Numbered roughly
B<weakest-to-strongest> so "weaker credential than expected" is a monotone
feature; the ordering is a judgement call, not a registry. Numeric inputs are
not passed through.

=head2 amavis_category_enum

    { munger => 'amavis_category_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the amavisd-new
content category, ordered clean-to-worst: C<clean> 0, C<oversized> 1,
C<unchecked> 2, C<spammy> 3, C<spam> 4, C<badheader> 5, C<banned> 6,
C<infected> 7, C<mtablocked> 8. The hyphenated spellings (C<bad-header>,
C<mta-blocked>) and the legacy C<virus> (for C<infected>) are accepted as
aliases. The Passed/Blocked I<action> itself is a L</bool>; this is the
finer-grained reason. Numeric inputs are not passed through.

=head2 systemd_result_enum

    { munger => 'systemd_result_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for a systemd unit
C<result> (as in C<Failed with result 'timeout'>): C<success> 0, C<protocol>
1, C<timeout> 2, C<exit-code> 3, C<signal> 4, C<core-dump> 5, C<watchdog> 6,
C<start-limit-hit> 7, C<oom-kill> 8, C<resources> 9. The underscore spellings
(C<exit_code>, C<core_dump>, C<start_limit_hit>, C<oom_kill>) are accepted as
aliases. Numeric inputs are not passed through.

=head2 clamav_result_enum

    { munger => 'clamav_result_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for a ClamAV per-target
verdict as logged by C<clamd> / clamav-milter: C<OK> 0, C<FOUND> 1, C<ERROR>
2. Small but exactly the signal worth flagging (a C<FOUND> line). Numeric
inputs are not passed through.

=head2 kerberos_etype_enum

    { munger => 'kerberos_etype_enum', default => -1 }

Named-map enum for the Kerberos ticket encryption type -- Windows events
4768/4769 (logged as hex, C<0x17>) and any other AD/Kerberos source. The
values are the RFC 3961 etype numbers, which B<are> the wire encoding, so
(unlike most of the enums here) a decimal input passes through unchanged: the
map exists only to resolve the hex spellings (C<0x17> => 23, C<0x12> => 18,
...) and the RFC/MIT names (C<rc4-hmac>/C<rc4>/C<arcfour-hmac> => 23,
C<aes256-cts-hmac-sha1-96>/C<aes256> => 18, C<aes128> => 17, C<des3> => 16,
C<des-cbc-md5> => 3, C<des-cbc-crc> => 1) onto that same number. The classic
use is flagging C<rc4-hmac> (0x17) as a downgrade/roasting signal against an
C<aes256> baseline. Lookup is case-insensitive; an unlisted etype croaks
unless a numeric C<default> is given.

=head2 windows_integrity_level_enum

    { munger => 'windows_integrity_level_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the Windows / Sysmon
process integrity level, as an B<ordinal>: C<untrusted> 0, C<low> 1, C<medium>
2, C<high> 3, C<system> 4 (with C<mediumplus> folded into C<medium>). The
C<S-1-16-*> mandatory-label SIDs Windows sometimes logs in place of the word
(C<S-1-16-12288> => 3, ...) are accepted as aliases. Ordinal so "higher
privilege than expected" is a monotone feature. Numeric inputs are not passed
through.

=head2 windows_logon_status_enum

    { munger => 'windows_logon_status_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the NTSTATUS
sub-status on a failed Windows logon (events 4625/4776), collapsed to a
compact B<reason category> rather than the raw 32-bit code: C<0xC0000064>
(no such user) 0, C<0xC000006A> (bad password) 1, C<0xC000006D> (generic bad
user/pass) 2, C<0xC000006F> (outside hours) 3, C<0xC0000070> (workstation
restriction) 4, C<0xC0000071> (password expired) 5, C<0xC0000072> (disabled)
6, C<0xC0000193> (account expired) 7, C<0xC0000133> (clock skew) 8,
C<0xC0000224> (must change password) 9, C<0xC0000234> (locked out) 10,
C<0xC000015B> (logon type not granted) 11. Keys are the hex codes exactly as
logged (matched case-insensitively); only the common logon subset is baked in,
so an unlisted code croaks unless a numeric C<default> is given. Numeric
inputs are not passed through.

=head2 windows_impersonation_level_enum

    { munger => 'windows_impersonation_level_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the event 4624
impersonation level, ordered by reach: C<anonymous> 0, C<identification> 1,
C<impersonation> 2, C<delegation> 3. The C<%%1832> / C<%%1833> message tokens
Windows often emits in place of the words (Identification / Impersonation) are
accepted as aliases. Numeric inputs are not passed through.

=head2 aad_signin_error_enum

    { munger => 'aad_signin_error_enum', default => -1 }

Named-map enum for the Azure AD / Entra sign-in C<ResultType> error code,
collapsed to a compact B<reason category> rather than the raw code: C<0>
(success) 0, invalid-password (C<50126>, C<50056>) 1, no-such-user (C<50034>)
2, disabled (C<50057>) 3, locked / smart-lockout (C<50053>) 4, password-expired
(C<50055>, C<50144>) 5, MFA-required (C<50074>, C<50076>, C<50079>) 6,
MFA-failed (C<500121>, C<50158>) 7, blocked-by-conditional-access (C<53003>,
C<53000>, C<53001>, C<530032>) 8, session-expired (C<50173>) 9. Although
C<ResultType> is already numeric, the code space is huge and sparse and its
magnitude carries no signal -- this maps the common codes onto a handful of
meaningful buckets (and, unlike L</hash>, keeps related codes together). Keys
are the codes as logged; only the common subset is baked in, so an unlisted
code croaks unless a numeric C<default> is given. Because the output is a
category of our own numbering, numeric inputs are B<not> passed through.

=head2 risk_level_enum

    { munger => 'risk_level_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the Entra Identity
Protection C<riskLevel> as an B<ordinal>: C<none> 0, C<low> 1, C<medium> 2,
C<high> 3. C<hidden> and C<unknownFutureValue> are left to the C<default>
(they are not points on the scale). Numeric inputs are not passed through.

=head2 aws_principal_type_enum

    { munger => 'aws_principal_type_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the CloudTrail
C<userIdentity.type>: C<Root> 0, C<IAMUser> 1, C<AssumedRole> 2,
C<FederatedUser> 3, C<SAMLUser> 4, C<WebIdentityUser> 5, C<Directory> 6,
C<IdentityCenterUser> 7, C<AWSAccount> 8, C<AWSService> 9, C<Unknown> 10. The
numbering is nominal (distinct stable numbers, not a scale); C<Root> is the
value you actually alert on. Numeric inputs are not passed through.

=head2 aad_client_app_enum

    { munger => 'aad_client_app_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the Azure AD
C<ClientAppUsed>, numbered so the modern clients sort low (C<Browser> 0,
C<Mobile Apps and Desktop clients> 1) and the B<legacy-auth> protocols -- which
cannot satisfy MFA -- sort high (C<Exchange ActiveSync>, C<IMAP4>, C<POP3>,
C<Authenticated SMTP>, C<MAPI Over HTTP>, C<Exchange Web Services>, C<Exchange
Online PowerShell>, C<AutoDiscover>, C<Offline Address Book>, C<Other
clients>, from 2 up). A "C<< >= 2 >> means legacy auth" threshold is the
intended feature. C<imap>/C<pop>/C<mapi> short forms are accepted as aliases.
Numeric inputs are not passed through.

=head2 risk_state_enum

    { munger => 'risk_state_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the Entra Identity
Protection C<riskState>: C<none> 0, C<confirmedSafe> 1, C<remediated> 2,
C<dismissed> 3, C<atRisk> 4, C<confirmedCompromised> 5. Numeric inputs are not
passed through.

=head2 vpc_flow_log_status_enum

    { munger => 'vpc_flow_log_status_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the AWS VPC Flow Logs
C<log-status>: C<OK> 0, C<NODATA> 1, C<SKIPDATA> 2. (The per-flow
C<ACCEPT>/C<REJECT> action is a plain L</bool>; this is the capture-health
field.) Numeric inputs are not passed through.

=head2 aws_event_type_enum

    { munger => 'aws_event_type_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the CloudTrail
C<eventType>: C<AwsApiCall> 0, C<AwsServiceEvent> 1, C<AwsConsoleAction> 2,
C<AwsConsoleSignIn> 3, C<AwsCloudTrailInsight> 4. C<AwsConsoleSignIn> is the
one worth flagging. Numeric inputs are not passed through.

=head2 conditional_access_result_enum

    { munger => 'conditional_access_result_enum', default => -1 }

Named-map enum (lookup rules as L</dns_rcode_enum>) for the Azure AD sign-in
C<conditionalAccessStatus>: C<success> 0, C<notApplied> 1, C<notEnabled> 2,
C<reportOnly> 3, C<failure> 4. Numeric inputs are not passed through.

=cut

# Named-map enums: baked-in value->number maps for well-known registries,
# registered as "<name>_enum". Keys are stored lowercase; lookup lowercases
# the input, giving the case-insensitive matching the POD promises. 'numeric'
# says whether a numeric input is passed through as-is -- set only where the
# numbers are the protocol's own encoding (a qtype 28 IS AAAA on the wire);
# where they are ordinals of our own invention (tls_version, the method
# enums), passthrough would mix scales, so a number croaks like any other
# unmapped value.

# SASL mechanism names, ordered weakest-to-strongest, for sasl_mech_enum. The
# same set is numbered alphabetically for sasl_mech_iana_enum, so the two
# mungers can never end up covering different mechanisms. Includes the IANA
# registry plus the ubiquitous non-registered login/xoauth2/apop.
my @SASL_MECHS_BY_STRENGTH = qw(
	anonymous plain login
	apop cram-md5 digest-md5 ntlm skey otp securid rpa kerberos_v4
	srp scram-sha-1 scram-sha-1-plus scram-sha-256 scram-sha-256-plus
	xoauth2 oauthbearer openid20 saml20
	gssapi gs2-krb5 gss-spnego external
);

my %NAMED_ENUM = (
	dns_rcode => {
		numeric => 1,
		map     => {
			noerror   => 0,
			formerr   => 1,
			servfail  => 2,
			nxdomain  => 3,
			notimp    => 4,
			notimpl   => 4,
			refused   => 5,
			yxdomain  => 6,
			yxrrset   => 7,
			nxrrset   => 8,
			notauth   => 9,
			notzone   => 10,
			dsotypeni => 11,
			badvers   => 16,
			badsig    => 16,
			badkey    => 17,
			badtime   => 18,
			badmode   => 19,
			badname   => 20,
			badalg    => 21,
			badtrunc  => 22,
			badcookie => 23,
		},
	},
	dns_qtype => {
		numeric => 1,
		map     => {
			a          => 1,
			ns         => 2,
			cname      => 5,
			soa        => 6,
			mb         => 7,
			mg         => 8,
			mr         => 9,
			'null'     => 10,
			wks        => 11,
			ptr        => 12,
			hinfo      => 13,
			minfo      => 14,
			mx         => 15,
			txt        => 16,
			rp         => 17,
			afsdb      => 18,
			sig        => 24,
			key        => 25,
			aaaa       => 28,
			loc        => 29,
			srv        => 33,
			naptr      => 35,
			kx         => 36,
			cert       => 37,
			dname      => 39,
			opt        => 41,
			ds         => 43,
			sshfp      => 44,
			ipseckey   => 45,
			rrsig      => 46,
			nsec       => 47,
			dnskey     => 48,
			dhcid      => 49,
			nsec3      => 50,
			nsec3param => 51,
			tlsa       => 52,
			smimea     => 53,
			hip        => 55,
			cds        => 59,
			cdnskey    => 60,
			openpgpkey => 61,
			csync      => 62,
			zonemd     => 63,
			svcb       => 64,
			https      => 65,
			eui48      => 108,
			eui64      => 109,
			tkey       => 249,
			tsig       => 250,
			ixfr       => 251,
			axfr       => 252,
			any        => 255,
			'*'        => 255,
			uri        => 256,
			caa        => 257,
		},
	},
	syslog_severity => {
		numeric => 1,
		map     => {
			emerg         => 0,
			panic         => 0,
			alert         => 1,
			crit          => 2,
			err           => 3,
			error         => 3,
			warning       => 4,
			warn          => 4,
			notice        => 5,
			info          => 6,
			informational => 6,
			debug         => 7,
		},
	},
	syslog_facility => {
		numeric => 1,
		map     => {
			kern     => 0,
			user     => 1,
			mail     => 2,
			daemon   => 3,
			auth     => 4,
			security => 4,
			syslog   => 5,
			lpr      => 6,
			news     => 7,
			uucp     => 8,
			cron     => 9,
			authpriv => 10,
			ftp      => 11,
			ntp      => 12,
			audit    => 13,
			alert    => 14,
			clock    => 15,
			( map { ( "local$_" => 16 + $_ ) } 0 .. 7 ),
		},
	},
	ip_proto => {
		numeric => 1,
		map     => {
			icmp        => 1,
			igmp        => 2,
			ipip        => 4,
			ipencap     => 4,
			tcp         => 6,
			egp         => 8,
			udp         => 17,
			dccp        => 33,
			ipv6        => 41,
			rsvp        => 46,
			gre         => 47,
			esp         => 50,
			ah          => 51,
			icmpv6      => 58,
			'ipv6-icmp' => 58,
			ospf        => 89,
			pim         => 103,
			sctp        => 132,
			udplite     => 136,
		},
	},
	tls_version => {
		numeric => 0,
		map     => {
			sslv2     => 0,
			ssl2      => 0,
			sslv3     => 1,
			ssl3      => 1,
			tlsv1     => 2,
			'tlsv1.0' => 2,
			tls1      => 2,
			'tls1.0'  => 2,
			'tlsv1.1' => 3,
			'tls1.1'  => 3,
			'tlsv1.2' => 4,
			'tls1.2'  => 4,
			'tlsv1.3' => 5,
			'tls1.3'  => 5,
		},
	},
	http_method => {
		numeric => 0,
		map     => {
			get     => 0,
			head    => 1,
			post    => 2,
			put     => 3,
			delete  => 4,
			connect => 5,
			options => 6,
			trace   => 7,
			patch   => 8,
		},
	},
	sip_method => {
		numeric => 0,
		map     => {
			invite    => 0,
			ack       => 1,
			bye       => 2,
			cancel    => 3,
			register  => 4,
			options   => 5,
			prack     => 6,
			subscribe => 7,
			notify    => 8,
			publish   => 9,
			info      => 10,
			refer     => 11,
			message   => 12,
			update    => 13,
		},
	},
	dhcp_msgtype => {
		numeric => 1,
		map     => {
			(
				map { ( $_->[0] => $_->[1], "dhcp$_->[0]" => $_->[1] ) } [ discover => 1 ],
				[ offer   => 2 ],
				[ request => 3 ],
				[ decline => 4 ],
				[ ack     => 5 ],
				[ nak     => 6 ],
				[ release => 7 ],
				[ inform  => 8 ]
			),
		},
	},
	app_proto => {
		numeric => 0,
		map     => {
			# Ordinals of our own invention (Suricata's app_proto is a string
			# label with no wire number), assigned from a fixed order so a value
			# munges to the same number on every host. 'failed'/'unknown' are
			# kept as their own classes -- an un-parsed app layer is often the
			# interesting row.
			do {
				my @order = qw(
					unknown failed http http2 ftp ftp-data smtp imap
					tls ssh smb dcerpc dns modbus enip dnp3 nfs ntp
					tftp ike krb5 quic dhcp snmp sip rfb mqtt rdp
					telnet pgsql ldap websocket bittorrent-dht
				);
				my %m = map { $order[$_] => $_ } 0 .. $#order;
				$m{ssl}   = $m{tls};    # Suricata's older spelling
				$m{ikev2} = $m{ike};
				%m;
			},
		},
	},
	tcp_state => {
		numeric => 0,
		map     => {
			# The TCP state machine (flow.tcp.state), numbered along the
			# connection lifecycle so the ordinal is meaningful.
			do {
				my @order = qw(
					none syn_sent syn_recv established
					fin_wait1 fin_wait2 closing time_wait
					close_wait last_ack closed
				);
				map { $order[$_] => $_ } 0 .. $#order;
			},
		},
	},
	flow_state => {
		numeric => 0,
		map     => {
			new          => 0,
			established  => 1,
			closed       => 2,
			bypassed     => 3,
			local_bypass => 4,
		},
	},
	flow_reason => {
		numeric => 0,
		map     => {
			timeout  => 0,
			forced   => 1,
			shutdown => 2,
			unknown  => 3,
		},
	},
	suricata_action => {
		numeric => 0,
		map     => {
			allowed => 0,
			blocked => 1,
			pass    => 2,
			drop    => 3,
			reject  => 4,
			alert   => 5,
		},
	},
	postfix_status => {
		numeric => 0,
		map     => {
			sent          => 0,
			deferred      => 1,
			bounced       => 2,
			expired       => 3,
			deliverable   => 4,
			undeliverable => 5,
			hold          => 6,
			discard       => 7,
			filtered      => 8,
			reject        => 9,
			softbounce    => 10,
		},
	},
	spf_result => {
		numeric => 0,
		map     => {
			pass      => 0,
			neutral   => 1,
			none      => 2,
			softfail  => 3,
			fail      => 4,
			temperror => 5,
			error     => 5,    # older spelling of temperror
			permerror => 6,
			unknown   => 6,    # older spelling of permerror
		},
	},
	dkim_result => {
		numeric => 0,
		map     => {
			pass      => 0,
			neutral   => 1,
			none      => 2,
			policy    => 3,
			fail      => 4,
			temperror => 5,
			error     => 5,    # older spelling of temperror
			permerror => 6,
			unknown   => 6,    # older spelling of permerror
		},
	},
	dmarc_result => {
		numeric => 0,
		map     => {
			pass          => 0,
			none          => 1,
			fail          => 2,
			temperror     => 3,
			permerror     => 4,
			bestguesspass => 5,
		},
	},
	sasl_mech => {
		numeric => 0,
		map     => {
			do {
				my @o = @SASL_MECHS_BY_STRENGTH;
				map { $o[$_] => $_ } 0 .. $#o;
			},
		},
	},
	sasl_mech_iana => {
		numeric => 0,
		map     => {
			do {
				my @o = sort @SASL_MECHS_BY_STRENGTH;
				map { $o[$_] => $_ } 0 .. $#o;
			},
		},
	},
	http_version => {
		numeric => 0,    # a logged "2" is version 2.0, not the integer two
		map     => {
			# Ordinal so "older than expected" is a monotone feature. Accepts
			# the access-log spelling (HTTP/1.1), the bare number (1.1), and
			# the ALPN/h2 shorthands.
			do {
				my %v = (
					'http/0.9' => 0,
					'http/1.0' => 1,
					'http/1.1' => 2,
					'http/2.0' => 3,
					'http/3.0' => 4,
				);
				$v{'0.9'} = 0;
				$v{'1.0'} = 1;
				$v{'1.1'} = 2;
				$v{'2.0'} = $v{'2'} = $v{'http/2'} = $v{'h2'} = $v{'h2c'} = 3;
				$v{'3.0'} = $v{'3'} = $v{'http/3'} = $v{'h3'} = 4;
				%v;
			},
		},
	},
	spamassassin_autolearn => {
		numeric => 0,
		map     => {
			# SpamAssassin's autolearn= field. Nominal, but ordered so
			# "no learning happened" sorts below the ham/spam outcomes.
			no          => 0,
			ham         => 1,
			spam        => 2,
			disabled    => 3,
			failed      => 4,
			unavailable => 5,
			unknown     => 6,
		},
	},
	rspamd_action => {
		numeric => 0,
		map     => {
			# rspamd's action, ordered by severity. Accept both the space
			# and underscore spellings rspamd emits across its outputs.
			do {
				my %a = (
					'no action'       => 0,
					'greylist'        => 1,
					'add header'      => 2,
					'rewrite subject' => 3,
					'soft reject'     => 4,
					'reject'          => 5,
				);
				$a{'no_action'}       = $a{'noaction'} = 0;
				$a{'add_header'}      = 2;
				$a{'rewrite_subject'} = 3;
				$a{'soft_reject'}     = $a{'soft-reject'} = 4;
				%a;
			},
		},
	},
	ssh_auth_method => {
		numeric => 0,
		map     => {
			# OpenSSH authentication method, ordered by credential strength
			# (weakest first) so "weaker than expected" is monotone. The
			# ordering is a judgement call, not an IANA registry.
			do {
				my @o = qw(
					none password keyboard-interactive
					hostbased publickey
					gssapi-with-mic gssapi-keyex
				);
				my %m = map { $o[$_] => $_ } 0 .. $#o;
				$m{'gssapi'} = $m{'gssapi-with-mic'};
				%m;
			},
		},
	},
	amavis_category => {
		numeric => 0,
		map     => {
			# amavisd-new content category, ordered clean -> worst.
			do {
				my @o = qw(
					clean oversized unchecked spammy spam
					badheader banned infected mtablocked
				);
				my %m = map { $o[$_] => $_ } 0 .. $#o;
				$m{'bad-header'}  = $m{'badheader'};
				$m{'virus'}       = $m{'infected'};
				$m{'mta-blocked'} = $m{'mtablocked'};
				%m;
			},
		},
	},
	systemd_result => {
		numeric => 0,
		map     => {
			# systemd unit "result" (e.g. "Failed with result 'timeout'").
			do {
				my @o = qw(
					success protocol timeout exit-code signal
					core-dump watchdog start-limit-hit oom-kill resources
				);
				my %m = map { $o[$_] => $_ } 0 .. $#o;
				$m{'exit_code'}       = $m{'exit-code'};
				$m{'core_dump'}       = $m{'core-dump'};
				$m{'start_limit_hit'} = $m{'start-limit-hit'};
				$m{'oom_kill'}        = $m{'oom-kill'};
				%m;
			},
		},
	},
	clamav_result => {
		numeric => 0,
		map     => {
			# clamd / clamav-milter per-target verdict.
			ok    => 0,
			found => 1,
			error => 2,
		},
	},
	kerberos_etype => {
		numeric => 1,    # RFC 3961 etype numbers are the wire value; a logged 23 IS rc4
		map     => {
			# Windows logs the ticket encryption type as hex ("0x17"); the
			# RFC/MIT names appear in other Kerberos logs. Everything resolves
			# to the decimal etype number, so a decimal input passes through.
			do {
				my %e = (
					'des-cbc-crc'             => 1,
					'des-cbc-md5'             => 3,
					'des3-cbc-sha1'           => 16,
					'aes128-cts-hmac-sha1-96' => 17,
					'aes256-cts-hmac-sha1-96' => 18,
					'rc4-hmac'                => 23,
					'rc4-hmac-exp'            => 24,
				);
				$e{'des3'}         = 16;
				$e{'aes128'}       = 17;
				$e{'aes256'}       = 18;
				$e{'arcfour-hmac'} = $e{'rc4'} = 23;
				$e{'0x1'}          = 1;
				$e{'0x3'}          = 3;
				$e{'0x10'}         = 16;
				$e{'0x11'}         = 17;
				$e{'0x12'}         = 18;
				$e{'0x17'}         = 23;
				$e{'0x18'}         = 24;
				%e;
			},
		},
	},
	windows_integrity_level => {
		numeric => 0,
		map     => {
			# Sysmon IntegrityLevel; ordinal so "higher privilege than
			# expected" is monotone. Text labels plus the S-1-16-* mandatory
			# label SIDs Windows sometimes logs in their place.
			do {
				my %m = (
					untrusted => 0,
					low       => 1,
					medium    => 2,
					high      => 3,
					system    => 4,
				);
				$m{'mediumplus'}   = 2;
				$m{'s-1-16-0'}     = 0;
				$m{'s-1-16-4096'}  = 1;
				$m{'s-1-16-8192'}  = 2;
				$m{'s-1-16-12288'} = 3;
				$m{'s-1-16-16384'} = 4;
				%m;
			},
		},
	},
	windows_logon_status => {
		numeric => 0,
		map     => {
			# Common NTSTATUS sub-status codes on failed logons (4625/4776),
			# mapped to a compact reason category -- the raw 32-bit value is
			# not itself a useful feature. Keys are the hex codes as logged.
			'0xc0000064' => 0,     # user name does not exist
			'0xc000006a' => 1,     # bad password
			'0xc000006d' => 2,     # bad user name or password (generic)
			'0xc000006f' => 3,     # outside authorized hours
			'0xc0000070' => 4,     # workstation restriction
			'0xc0000071' => 5,     # password expired
			'0xc0000072' => 6,     # account disabled
			'0xc0000193' => 7,     # account expired
			'0xc0000133' => 8,     # clock skew between client and server
			'0xc0000224' => 9,     # must change password at next logon
			'0xc0000234' => 10,    # account locked out
			'0xc000015b' => 11,    # logon type not granted
		},
	},
	windows_impersonation_level => {
		numeric => 0,
		map     => {
			# 4624 ImpersonationLevel; ordinal by reach. Text labels plus the
			# two "%%18xx" message tokens Windows most often emits in place.
			anonymous      => 0,
			identification => 1,
			impersonation  => 2,
			delegation     => 3,
			'%%1832'       => 1,
			'%%1833'       => 2,
		},
	},
	aad_signin_error => {
		numeric => 0,
		map     => {
			# Azure AD / Entra sign-in ResultType codes collapsed to a compact
			# reason category -- the raw code is a huge sparse space whose
			# magnitude carries no signal. Keys are the numeric codes as
			# logged; only the common subset is baked in, the rest take the
			# default.
			'0'      => 0,    # success
			'50126'  => 1,    # invalid username or password
			'50056'  => 1,    # invalid or null password
			'50034'  => 2,    # user does not exist in directory
			'50057'  => 3,    # account disabled
			'50053'  => 4,    # account locked / smart lockout
			'50055'  => 5,    # password expired
			'50144'  => 5,    # AD password expired
			'50074'  => 6,    # strong auth (MFA) required
			'50076'  => 6,    # MFA required by conditional access
			'50079'  => 6,    # user must enroll for MFA
			'500121' => 7,    # MFA denied / authentication failed
			'50158'  => 7,    # external security challenge not satisfied
			'53003'  => 8,    # blocked by conditional access
			'53000'  => 8,    # device not compliant (CA)
			'53001'  => 8,    # device not domain joined (CA)
			'530032' => 8,    # blocked by security policy (CA)
			'50173'  => 9,    # fresh auth token required (session expired)
		},
	},
	risk_level => {
		numeric => 0,
		map     => {
			# Entra Identity Protection riskLevel, ordinal. hidden /
			# unknownFutureValue are left to the default.
			none   => 0,
			low    => 1,
			medium => 2,
			high   => 3,
		},
	},
	aws_principal_type => {
		numeric => 0,
		map     => {
			# CloudTrail userIdentity.type. Nominal (distinct stable numbers);
			# 'root' is the value you actually alert on.
			do {
				my @o = qw(
					root iamuser assumedrole federateduser samluser
					webidentityuser directory identitycenteruser
					awsaccount awsservice unknown
				);
				map { $o[$_] => $_ } 0 .. $#o;
			},
		},
	},
	aad_client_app => {
		numeric => 0,
		map     => {
			# Azure AD ClientAppUsed. Numbered so the modern clients sort low
			# and the legacy-auth protocols (which cannot do MFA) sort high --
			# a ">= 2 means legacy auth" threshold is the feature you want.
			do {
				my %m = (
					'browser'                         => 0,
					'mobile apps and desktop clients' => 1,
				);
				my @legacy = (
					'exchange activesync',
					'imap4',
					'pop3',
					'authenticated smtp',
					'smtp',
					'mapi over http',
					'exchange web services',
					'exchange online powershell',
					'autodiscover',
					'offline address book',
					'other clients',
				);
				my $i = 2;
				$m{$_}     = $i++ for @legacy;
				$m{'imap'} = $m{'imap4'};
				$m{'pop'}  = $m{'pop3'};
				$m{'mapi'} = $m{'mapi over http'};
				%m;
			},
		},
	},
	risk_state => {
		numeric => 0,
		map     => {
			# Entra Identity Protection riskState.
			none                 => 0,
			confirmedsafe        => 1,
			remediated           => 2,
			dismissed            => 3,
			atrisk               => 4,
			confirmedcompromised => 5,
		},
	},
	vpc_flow_log_status => {
		numeric => 0,
		map     => {
			# VPC Flow Logs log-status.
			ok       => 0,
			nodata   => 1,
			skipdata => 2,
		},
	},
	aws_event_type => {
		numeric => 0,
		map     => {
			# CloudTrail eventType. AwsConsoleSignIn is the one you flag.
			awsapicall           => 0,
			awsserviceevent      => 1,
			awsconsoleaction     => 2,
			awsconsolesignin     => 3,
			awscloudtrailinsight => 4,
		},
	},
	conditional_access_result => {
		numeric => 0,
		map     => {
			# Azure AD sign-in conditionalAccessStatus.
			success    => 0,
			notapplied => 1,
			notenabled => 2,
			reportonly => 3,
			failure    => 4,
		},
	},
);
for my $name ( keys %NAMED_ENUM ) {
	my $e = $NAMED_ENUM{$name};
	$BUILDERS{"${name}_enum"} = sub { _named_enum_munger( $name, $e, @_ ) };
}

# Shared closure for the named-map enums registered from %NAMED_ENUM.
sub _named_enum_munger {
	my ( $name, $e, $spec, $where ) = @_;

	my $has_default = exists $spec->{default};
	my $default     = $spec->{default};
	croak "${name}_enum munger$where: 'default' must be numeric"
		if $has_default && !looks_like_number($default);

	my ( $map, $numeric ) = @{$e}{qw(map numeric)};
	return sub {
		my ($v) = @_;
		if ( defined $v ) {
			return $v + 0 if $numeric && looks_like_number($v);
			my $k = lc $v;
			return $map->{$k} if exists $map->{$k};
		}
		return $default if $has_default;
		croak "${name}_enum munger$where: no mapping for '" . ( defined $v ? $v : 'undef' ) . "'";
	}; ## end sub
} ## end sub _named_enum_munger

=head2 bool

    { munger => 'bool' }                       # Perl truthiness -> 1/0
    { munger => 'bool', true => [ 'yes', 'Y', '1', 'true' ] }

Coerce to C<1> or C<0>. With a C<true> list, only those (string-compared) values
are C<1>; otherwise ordinary Perl truthiness is used.

=cut

sub _build_bool {
	my ( $spec, $where ) = @_;

	if ( exists $spec->{true} ) {
		croak "bool munger$where: 'true' must be an arrayref"
			unless ref $spec->{true} eq 'ARRAY';
		my %true = map { $_ => 1 } @{ $spec->{true} };
		return sub {
			my ($v) = @_;
			return exists $true{ defined $v ? $v : '' } ? 1 : 0;
		};
	}

	return sub { $_[0] ? 1 : 0 };
} ## end sub _build_bool

=head2 length

    { munger => 'length' }

The character length of the stringified input, C<undef> counting as C<0> (an
absent value is a zero-length one -- e.g. an SNI-absent TLS record). This is the
cheap shape feature behind every C<*_length> column (domain, URL, filename, SNI,
hostname, ...): tunneling and generated names run long, so raw length is a
surprisingly strong corroborator next to L</entropy>. Length is counted in
B<characters>, not bytes, so a multi-byte name is measured as a human would read
it; use L</entropy> (which is byte-oriented) when you want per-symbol randomness.

=cut

sub _build_length {
	my ( $spec, $where ) = @_;
	return sub {
		my ($v) = @_;
		return length( defined $v ? "$v" : '' );
	};
}

=head2 entropy

    { munger => 'entropy' }

Shannon entropy of the input string, in B<bits per symbol> -- i.e.
C<-sum(p*log2(p))> over the frequencies of its bytes. This is the single most
common feature in the pipeline (DGA domains, randomized filenames, forged
User-Agents, generated SNIs / hostnames / principal names), because
machine-generated strings spread their characters far more evenly than
human-chosen ones and so score high, while a real word scores low. An empty
string is C<0>; the maximum is C<8> (every byte value equally likely).

Entropy is computed over the string's B<UTF-8 bytes> (matching L</hash>), so the
value is well-defined regardless of the scalar's internal encoding flag. Like
C<hash>, this munger is XS-accelerated -- a per-byte histogram plus a C<log> per
distinct byte -- with a pure-Perl fallback that produces identical values;
C<$Algorithm::ToNumberMunger::HAVE_XS> says which
is in use.

=cut

sub _build_entropy {
	my ( $spec, $where ) = @_;
	my $fn = $HAVE_XS ? \&_entropy_xs : \&_entropy_pp;
	return sub {
		my ($v) = @_;
		return $fn->( defined $v ? "$v" : '' );
	};
}

# Pure-Perl Shannon entropy (bits), used only when the XS did not build. Byte
# view via an explicit encode so it matches the XS's SvPVutf8, and so the same
# string scores the same regardless of its internal flag.
sub _entropy_pp {
	my ($str) = @_;
	utf8::encode($str);
	my $n = length $str;
	return 0 unless $n;
	my %count;
	$count{$_}++ for unpack 'C*', $str;
	my $ln2 = log(2);
	my $h   = 0;

	for my $c ( values %count ) {
		my $p = $c / $n;
		$h -= $p * ( log($p) / $ln2 );
	}
	return $h;
} ## end sub _entropy_pp

=head2 ngram

    { munger => 'ngram', counts => { th => 152, he => 128, in => 94, ... } }
    # defaults: smoothing => 1, fold_case => 1; n is inferred from the keys

Mean per-gram surprisal of the input string against a B<precomputed, frozen>
n-gram count table: C<sum(-ln p(gram)) / gram_count>, each gram's probability
smoothed exactly as in L</frozen_freq_map>. This is C<frozen_freq_map>'s sequential cousin
and the strongest single gibberish detector: L</entropy> misses
I<pronounceable> generated names and is unreliable on short strings, while an
n-gram score against (say) hostname bigram statistics catches both -- real
words ride the common bigrams and score low, generated names keep hitting rare
ones and score high. Dividing by the gram count keeps scores comparable across
lengths.

C<counts> maps each n-gram to how often it was observed when the table was
built; all keys must be the same length, and that length B<is> C<n> (bigrams
are the usual choice -- a 26x26 table stays tiny in C<info.json>; past
C<$FROZEN_FREQ_MAP_WARN_KEYS> entries it warns like C<frozen_freq_map>). C<total> defaults
to the sum of counts and may be given larger to prune the tail, exactly as in
C<frozen_freq_map>. A gram absent from the table gets the smoothed unseen-bucket
probability -- an unseen gram is the interesting case -- so C<smoothing> must
be > 0 (default C<1>). With C<fold_case> (default on) the input is lowercased
before scoring, matching the usual lowercased table. A string with no grams
(shorter than C<n>) scores C<0>. Grams are taken over B<characters>, matching
L</length> rather than the byte-oriented C<entropy>.

=cut

sub _build_ngram {
	my ( $spec, $where ) = @_;

	my $counts = $spec->{counts};
	croak "ngram munger$where requires a non-empty 'counts' hashref"
		unless ref $counts eq 'HASH' && %$counts;

	my $n;
	my $sum = 0;
	for my $g ( keys %$counts ) {
		$n = length $g unless defined $n;
		croak "ngram munger$where: all 'counts' keys must be the same length "
			. "(that length is n); got '$g' alongside a $n-gram"
			unless length($g) == $n;
		my $c = $counts->{$g};
		croak "ngram munger$where: count for '$g' ('"
			. ( defined $c ? $c : 'undef' )
			. "') is not a non-negative number"
			unless looks_like_number($c) && $c >= 0;
		$sum += $c;
	} ## end for my $g ( keys %$counts )
	croak "ngram munger$where: 'counts' keys must be at least 1 character"
		unless $n >= 1;

	my $V = keys %$counts;
	carp "ngram munger$where: 'counts' has $V keys; a table this large bloats info.json"
		if $V > $FROZEN_FREQ_MAP_WARN_KEYS;

	my $total = defined $spec->{total} ? $spec->{total} : $sum;
	croak "ngram munger$where: 'total' must be numeric"
		unless looks_like_number($total);
	croak "ngram munger$where: 'total' ($total) must be >= sum of counts ($sum)"
		if $total < $sum;

	my $s = defined $spec->{smoothing} ? $spec->{smoothing} : 1;
	croak "ngram munger$where: 'smoothing' must be a number > 0 "
		. '(an unseen gram would otherwise be infinitely surprising)'
		unless looks_like_number($s) && $s > 0;

	my $fold = exists $spec->{fold_case} ? ( $spec->{fold_case} ? 1 : 0 ) : 1;

	# Same smoothed-probability scheme as frozen_freq_map, "unseen" as one extra
	# bucket; surprisal precomputed per listed gram.
	my $denom  = $total + $s * ( $V + 1 );
	my %si     = map { $_ => -log( ( $counts->{$_} + $s ) / $denom ) } keys %$counts;
	my $unseen = -log( $s / $denom );

	return sub {
		my ($v) = @_;
		my $str = defined $v ? "$v" : '';
		$str = lc $str if $fold;
		my $grams = length($str) - $n + 1;
		return 0 if $grams < 1;
		my $tot = 0;
		for my $i ( 0 .. $grams - 1 ) {
			my $g = substr( $str, $i, $n );
			$tot += exists $si{$g} ? $si{$g} : $unseen;
		}
		return $tot / $grams;
	}; ## end sub
} ## end sub _build_ngram

=head2 char

    { munger => 'char', class => 'non_alnum', mode => 'ratio' }
    { munger => 'char', class => 'non_ascii' }               # mode defaults to count

Count the characters of the input that fall in a named C<class>, either as a raw
C<count> (default) or, with C<< mode => 'ratio' >>, as a fraction of the string's
length (C<0> for an empty string). This is the injection / obfuscation detector
behind columns like C<url_non_alnum> (a I<ratio>, so it stays independent of
length) and C<filename_non_ascii> (a I<count>): payloads and homoglyph tricks
are dense with punctuation, percent-encoding, or non-ASCII where normal input is
not. Counting is over B<characters>, so C<non_ascii> means codepoints above 127.

Recognised classes: C<alnum> / C<non_alnum>, C<ascii> / C<non_ascii>, C<digit>,
C<alpha>, C<upper>, C<lower>, C<vowel>, C<consonant>, C<xdigit>, C<space>,
C<punct>. C<vowel> and C<consonant> are the ASCII letters (C<y> counting as a
consonant) -- a vowel/consonant I<ratio> is a DGA corroborator that catches
consonant-heavy random strings C<entropy> alone underrates; C<xdigit> is
C<0-9a-fA-F>, dense in encoded payloads.

=cut

# class name => a counting sub over an (already copied) string. The literal-
# range classes count with tr///, which runs at C speed -- an order of
# magnitude faster than tallying regex matches. tr/// needs its ranges spelled
# at compile time, hence one sub per class rather than a data table. The 'run'
# munger's %RUN_RE mirrors these class names; keep the two in sync.
my %CHAR_COUNT = (
	alnum     => sub { $_[0] =~ tr/A-Za-z0-9// },
	non_alnum => sub { $_[0] =~ tr/A-Za-z0-9//c },
	ascii     => sub { $_[0] =~ tr/\x00-\x7f// },
	non_ascii => sub { $_[0] =~ tr/\x00-\x7f//c },
	digit     => sub { $_[0] =~ tr/0-9// },
	alpha     => sub { $_[0] =~ tr/A-Za-z// },
	upper     => sub { $_[0] =~ tr/A-Z// },
	lower     => sub { $_[0] =~ tr/a-z// },
	vowel     => sub { $_[0] =~ tr/aeiouAEIOU// },
	consonant => sub { $_[0] =~ tr/b-df-hj-np-tv-zB-DF-HJ-NP-TV-Z// },
	xdigit    => sub { $_[0] =~ tr/0-9A-Fa-f// },
	# space and punct match richer classes (\s, [[:punct:]], including their
	# Unicode behavior) that tr/// ranges cannot reproduce; they stay on the
	# regex so their semantics do not change.
	space => sub { my $n = () = $_[0] =~ /\s/g;          $n },
	punct => sub { my $n = () = $_[0] =~ /[[:punct:]]/g; $n },
);

sub _build_char {
	my ( $spec, $where ) = @_;

	my $class = $spec->{class};
	croak "char munger$where requires a 'class'"
		unless defined $class;
	my $count = $CHAR_COUNT{$class}
		or croak "char munger$where: unknown class '$class' (known: " . join( ', ', sort keys %CHAR_COUNT ) . ')';

	my $mode = defined $spec->{mode} ? $spec->{mode} : 'count';
	croak "char munger$where: 'mode' must be 'count' or 'ratio'"
		unless $mode eq 'count' || $mode eq 'ratio';
	my $ratio = $mode eq 'ratio' ? 1 : 0;

	return sub {
		my ($v) = @_;
		my $s   = defined $v ? "$v" : '';
		my $n   = $count->($s);
		return $n unless $ratio;
		my $len = length $s;
		return $len ? $n / $len : 0;
	};
} ## end sub _build_char

=head2 run

    { munger => 'run', class => 'consonant' }
    { munger => 'run', class => 'digit' }

The length of the longest unbroken run of characters in a named C<class> --
the same class names L</char> recognises. Where C<char> counts how many such
characters occur in total, C<run> measures how tightly they clump: the
longest consonant run and longest digit run are staple generated-name (DGA)
features that neither total counts nor L</entropy> capture, because a real
word breaks its consonants up with vowels while a random string will happily
emit six in a row. An empty or undef input is C<0>.

=cut

# class name => a character-class pattern for the 'run' munger. Mirrors
# %CHAR_COUNT's class names (keep in sync); runs need a regex quantifier, so
# tr///'s speed trick does not apply here.
my %RUN_RE = (
	alnum     => '[A-Za-z0-9]',
	non_alnum => '[^A-Za-z0-9]',
	ascii     => '[\x00-\x7f]',
	non_ascii => '[^\x00-\x7f]',
	digit     => '[0-9]',
	alpha     => '[A-Za-z]',
	upper     => '[A-Z]',
	lower     => '[a-z]',
	vowel     => '[aeiouAEIOU]',
	consonant => '[b-df-hj-np-tv-zB-DF-HJ-NP-TV-Z]',
	xdigit    => '[0-9A-Fa-f]',
	space     => '\s',
	punct     => '[[:punct:]]',
);

sub _build_run {
	my ( $spec, $where ) = @_;

	my $class = $spec->{class};
	croak "run munger$where requires a 'class'"
		unless defined $class;
	my $cc = $RUN_RE{$class}
		or croak "run munger$where: unknown class '$class' (known: " . join( ', ', sort keys %RUN_RE ) . ')';
	my $re = qr/((?:$cc)+)/;

	return sub {
		my ($v) = @_;
		my $s   = defined $v ? "$v" : '';
		my $max = 0;
		while ( $s =~ /$re/g ) {
			$max = length $1 if length $1 > $max;
		}
		return $max;
	};
} ## end sub _build_run

=head2 count

    { munger => 'count', of => '/' }             # url_path_depth, topic_depth
    { munger => 'count', of => '.', plus => 1 }  # label_count (dots + 1)

Count non-overlapping occurrences of a literal substring C<of> in the input,
optionally adding a constant C<plus>. This is the segment/depth feature behind
C<url_path_depth> and C<topic_depth> (count of C<`/`>) and C<label_count> (dots
plus one). C<of> is matched literally, not as a pattern, so C<.> means a literal
dot.

=cut

sub _build_count {
	my ( $spec, $where ) = @_;

	my $of = $spec->{of};
	croak "count munger$where requires a non-empty 'of' string"
		unless defined $of && length $of;

	my $plus = defined $spec->{plus} ? $spec->{plus} : 0;
	croak "count munger$where: 'plus' must be numeric"
		unless looks_like_number($plus);

	# index() beats a global regex match here: no pattern engine, and no
	# per-call list of matches just to count them. Advancing by length($of)
	# keeps the non-overlapping semantics m//g had.
	my $oflen = length $of;
	return sub {
		my ($v) = @_;
		my $s   = defined $v ? "$v" : '';
		my $n   = 0;
		my $p   = 0;
		while ( ( $p = index( $s, $of, $p ) ) >= 0 ) {
			$n++;
			$p += $oflen;
		}
		return $n + $plus;
	}; ## end sub
} ## end sub _build_count

=head2 match

    { munger => 'match', pattern => '^xn--' }                       # punycode label
    { munger => 'match', pattern => '%[0-9A-Fa-f]{2}', mode => 'count' }

Match the input against a Perl regular expression C<pattern>: C<1>/C<0> under
the default C<< mode => 'bool' >>, or the number of non-overlapping matches
with C<< mode => 'count' >>. A true C<ignore_case> makes the match
case-insensitive. This is the catch-all shape test behind flags like "is this
label punycode" or "is the Host an IP literal", and counters like
percent-escapes in a URL -- anything L</char> and L</count> are not expressive
enough for. The pattern is compiled at build time, so a broken one fails at
C<write_info> rather than per row.

B<Trust note:> a pattern cannot execute code (Perl requires C<use re 'eval'>
for that, which this module does not enable), but a pathological pattern can
still backtrack catastrophically and stall a writer. Treat munger specs --
like the rest of C<info.json> -- as configuration from a trusted operator,
not as untrusted input.

=cut

sub _build_match {
	my ( $spec, $where ) = @_;

	my $pat = $spec->{pattern};
	croak "match munger$where requires a non-empty 'pattern'"
		unless defined $pat && length $pat;

	my $mode = defined $spec->{mode} ? $spec->{mode} : 'bool';
	croak "match munger$where: 'mode' must be 'bool' or 'count'"
		unless $mode eq 'bool' || $mode eq 'count';

	# qr// on spec text cannot run code -- (?{...}) needs 'use re "eval"',
	# which is not enabled here -- but it can be syntactically invalid, so
	# compile eagerly and croak at build time.
	my $re = eval { $spec->{ignore_case} ? qr/$pat/i : qr/$pat/ };
	croak "match munger$where: cannot compile pattern '$pat': $@"
		unless defined $re;

	if ( $mode eq 'bool' ) {
		return sub {
			my $s = defined $_[0] ? "$_[0]" : '';
			return $s =~ $re ? 1 : 0;
		};
	}
	return sub {
		my $s = defined $_[0] ? "$_[0]" : '';
		my $n = () = $s =~ /$re/g;
		return $n;
	};
} ## end sub _build_match

=head2 bucket

    { munger => 'bucket', bounds => [ 1024, 49152 ] }   # dest_port classes

Map a number to a bucket index by ascending C<bounds>: the result is how many
bounds the value is greater than or equal to. With C<< bounds => [1024, 49152] >>
a value under C<1024> is C<0> (well-known), C<1024>-C<49151> is C<1> (registered),
and C<49152>+ is C<2> (ephemeral) -- the classic port classing, where the literal
port number is meaningless to a threshold split but the I<class> is a real
signal. C<bounds> must be strictly ascending; N bounds yield indices C<0>..C<N>.

This generalises the C<*_enum> status-class mungers, which are the special case
of bucketing a reply code by its leading digit.

=cut

sub _build_bucket {
	my ( $spec, $where ) = @_;

	my $bounds = $spec->{bounds};
	croak "bucket munger$where requires a non-empty 'bounds' arrayref"
		unless ref $bounds eq 'ARRAY' && @$bounds;

	my @b = @$bounds;
	for my $i ( 0 .. $#b ) {
		croak "bucket munger$where: bound[$i] ('" . ( defined $b[$i] ? $b[$i] : 'undef' ) . "') is not numeric"
			unless looks_like_number( $b[$i] );
		croak "bucket munger$where: 'bounds' must be strictly ascending"
			if $i && $b[$i] <= $b[ $i - 1 ];
	}

	return sub {
		my ($v) = @_;
		croak "bucket munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
			unless looks_like_number($v);
		my $idx = 0;
		for my $bound (@b) {
			last if $v < $bound;
			$idx++;
		}
		return $idx;
	}; ## end sub
} ## end sub _build_bucket

=head2 quantile

    { munger => 'quantile', bounds => [ 40, 180, 460, 2200, 64000 ] }

Piecewise-linear ECDF: map a number onto C<[0, 1]> by where it falls among
ascending C<bounds> taken from the training data's quantiles (e.g. its
min / p25 / p50 / p75 / max). Values at or below the first bound map to C<0>,
at or above the last to C<1>, and anything between two adjacent bounds
interpolates linearly between their positions. This is L</bucket>'s continuous
sibling and the heavy-tail normaliser to reach for when L</log> is not enough
and L</zscore> would let one outlier stretch the whole scale: after the
transform the training distribution is roughly uniform, so a forest threshold
split lands anywhere in it with equal ease. C<bounds> must be strictly
ascending with at least two values; like C<zscore>, the parameters are
supplied rather than learned, so munging stays stateless.

=cut

sub _build_quantile {
	my ( $spec, $where ) = @_;

	my $bounds = $spec->{bounds};
	croak "quantile munger$where requires a 'bounds' arrayref with at least 2 values"
		unless ref $bounds eq 'ARRAY' && @$bounds >= 2;

	my @b = @$bounds;
	for my $i ( 0 .. $#b ) {
		croak "quantile munger$where: bound[$i] ('" . ( defined $b[$i] ? $b[$i] : 'undef' ) . "') is not numeric"
			unless looks_like_number( $b[$i] );
		croak "quantile munger$where: 'bounds' must be strictly ascending"
			if $i && $b[$i] <= $b[ $i - 1 ];
	}
	my $segs = $#b;

	return sub {
		my ($v) = @_;
		croak "quantile munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
			unless looks_like_number($v);
		return 0 if $v <= $b[0];
		return 1 if $v >= $b[-1];
		my $i = 0;
		$i++ while $v >= $b[ $i + 1 ];
		return ( $i + ( $v - $b[$i] ) / ( $b[ $i + 1 ] - $b[$i] ) ) / $segs;
	}; ## end sub
} ## end sub _build_quantile

=head2 scale

    { munger => 'scale', min => 0, max => 1000, clamp => 1 }

Min-max normalisation: C<(v - min) / (max - min)>, mapping C<[min, max]> onto
C<[0, 1]>. C<min> and C<max> must differ. With a true C<clamp>, results are
pinned into C<[0, 1]> so out-of-range inputs cannot escape the unit interval.

=cut

sub _build_scale {
	my ( $spec, $where ) = @_;

	my ( $min, $max ) = @{$spec}{qw(min max)};
	croak "scale munger$where requires numeric 'min' and 'max'"
		unless looks_like_number($min) && looks_like_number($max);

	my $range = $max - $min;
	croak "scale munger$where: 'min' and 'max' must differ"
		if $range == 0;

	my $clamp = $spec->{clamp} ? 1 : 0;
	return sub {
		my ($v) = @_;
		croak "scale munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
			unless looks_like_number($v);
		my $s = ( $v - $min ) / $range;
		if ($clamp) { $s = 0 if $s < 0; $s = 1 if $s > 1; }
		return $s;
	};
} ## end sub _build_scale

=head2 zscore

    { munger => 'zscore', mean => 42.0, std => 7.5 }

Standardise: C<(v - mean) / std>. C<std> must be non-zero. The C<mean>/C<std>
are supplied (this module does not learn them) so munging stays stateless and a
row can be munged in isolation.

=cut

sub _build_zscore {
	my ( $spec, $where ) = @_;

	my ( $mean, $std ) = @{$spec}{qw(mean std)};
	croak "zscore munger$where requires numeric 'mean' and 'std'"
		unless looks_like_number($mean) && looks_like_number($std);
	croak "zscore munger$where: 'std' must be non-zero"
		if $std == 0;

	return sub {
		my ($v) = @_;
		croak "zscore munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
			unless looks_like_number($v);
		return ( $v - $mean ) / $std;
	};
} ## end sub _build_zscore

=head2 log

    { munger => 'log' }                 # natural log
    { munger => 'log', offset => 1 }    # log1p-style, so 0 is allowed
    { munger => 'log', base => 10, offset => 1 }

Logarithm of C<v + offset>. Heavy-tailed counts (bytes, durations) compress well
under a log, which keeps a few huge values from dominating the forest. C<offset>
(default C<0>) shifts the input so zeros/small values are representable; the
shifted value must be strictly positive or the input croaks. C<base> defaults to
natural log.

=cut

sub _build_log {
	my ( $spec, $where ) = @_;

	my $offset = exists $spec->{offset} ? $spec->{offset} : 0;
	croak "log munger$where: 'offset' must be numeric"
		unless looks_like_number($offset);

	my $ln_base;
	if ( defined $spec->{base} ) {
		croak "log munger$where: 'base' must be numeric and > 0 and != 1"
			unless looks_like_number( $spec->{base} )
			&& $spec->{base} > 0
			&& $spec->{base} != 1;
		$ln_base = log( $spec->{base} );
	}

	return sub {
		my ($v) = @_;
		croak "log munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
			unless looks_like_number($v);
		my $x = $v + $offset;
		croak "log munger$where: value+offset must be > 0 (got $x)"
			unless $x > 0;
		my $r = log($x);
		$r /= $ln_base if defined $ln_base;
		return $r;
	}; ## end sub
} ## end sub _build_log

=head2 clamp

    { munger => 'clamp', min => 0 }
    { munger => 'clamp', min => 0, max => 65535 }

Pass the number through, pinned into C<[min, max]>. Either bound may be omitted
to clamp on one side only. Unlike C<scale> this does not rescale; it only caps
outliers before they reach the model.

=cut

sub _build_clamp {
	my ( $spec, $where ) = @_;

	my ( $min, $max ) = @{$spec}{qw(min max)};
	my $have_min = defined $min;
	my $have_max = defined $max;
	croak "clamp munger$where needs at least one of 'min' or 'max'"
		unless $have_min || $have_max;
	croak "clamp munger$where: 'min' must be numeric"
		if $have_min && !looks_like_number($min);
	croak "clamp munger$where: 'max' must be numeric"
		if $have_max && !looks_like_number($max);
	croak "clamp munger$where: 'min' must be <= 'max'"
		if $have_min && $have_max && $min > $max;

	return sub {
		my ($v) = @_;
		croak "clamp munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
			unless looks_like_number($v);
		$v = $min if $have_min && $v < $min;
		$v = $max if $have_max && $v > $max;
		return $v;
	};
} ## end sub _build_clamp

=head2 num

    { munger => 'num', base => 16 }        # '0x1a' or '1a' -> 26
    { munger => 'num' }                    # plain numeric coercion

Parse a string as a number in C<base> (2-36, default 10). Base 10 simply
validates and numifies. Other bases accept the digits C<0-9a-z> below the
base, case-insensitively, an optional leading C<->, and the conventional
prefix for that base (C<0x> for 16, C<0b> for 2, C<0o> for 8). Plenty of
tooling logs flag words and IDs in hex (C<0x2f>), which the Writer would
reject as non-numeric; this munger is the bridge. Croaks on anything that is
not a clean number in the chosen base.

=cut

sub _build_num {
	my ( $spec, $where ) = @_;

	my $base = defined $spec->{base} ? $spec->{base} : 10;
	croak "num munger$where: 'base' must be an integer from 2 to 36"
		unless $base =~ /\A[0-9]+\z/ && $base >= 2 && $base <= 36;

	if ( $base == 10 ) {
		return sub {
			my ($v) = @_;
			croak "num munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
				unless looks_like_number($v);
			return $v + 0;
		};
	}

	my %digit;
	my $i = 0;
	$digit{$_} = $i++ for ( '0' .. '9', 'a' .. 'z' );
	# Strip only the base's own conventional prefix; for other bases a letter
	# like 'b' is just a digit, so there is nothing to disambiguate.
	my $prefix
		= $base == 16 ? qr/\A0x/
		: $base == 8  ? qr/\A0o/
		: $base == 2  ? qr/\A0b/
		:               undef;

	return sub {
		my ($v) = @_;
		my $s   = defined $v ? lc "$v" : '';
		my $err = "num munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not a base-$base number";
		my $neg = $s =~ s/\A-//;
		$s =~ s/$prefix// if defined $prefix;
		croak $err unless length $s;
		my $n = 0;
		for my $c ( split //, $s ) {
			my $d = $digit{$c};
			croak $err unless defined $d && $d < $base;
			$n = $n * $base + $d;
		}
		return $neg ? -$n : $n;
	}; ## end sub
} ## end sub _build_num

=head2 ratio

    # 'io_ratio' is a tag; bytes_out and bytes_in are input fields
    "io_ratio": { "munger": "ratio", "from": ["bytes_out", "bytes_in"] }
    { munger => 'ratio', from => [qw(bytes_out bytes_in)], zero => -1 }

First source divided by the second: with C<< from => [a, b] >> the column gets
C<a / b>. Asymmetry between two counters is a classic feature the counters
alone cannot express -- bytes out over bytes in flags exfiltration, requests
over responses flags scanning -- and the division has to happen at munge time
because a forest split only ever sees one column. A zero denominator yields
C<zero> (default C<0>) instead of dying, since "nothing came back" is a
legitimate row, not bad input; pick a C<zero> outside the ratio's normal range
if you want those rows to stand out. Both inputs must be numeric.

This is a B<multi-input> munger: it only makes sense with several sources, so
it is only usable through L</compile> with C<from> as an arrayref of exactly
two field names (and thus C<apply_named> / C<write_named>). The sources are
raw input fields, not other columns.

=head2 combine

    { munger => 'combine', op => 'sum', from => [qw(bytes_in bytes_out)] }
    { munger => 'combine', op => 'max', from => [qw(req_time resp_time)] }

Fold two or more numeric source fields into one column with C<op>: C<sum>,
C<diff> (first minus second; exactly two sources), C<product>, C<min>, C<max>,
or C<mean>. The general-purpose sibling of L</ratio> for when the interesting
feature is a total, a gap, or an extreme across fields rather than any one
field. Every input must be numeric.

Like C<ratio>, this is a B<multi-input> munger: only usable through
L</compile> with C<from> as an arrayref of source field names.

=cut

sub _build_ratio {
	my ( $spec, $where, $nsrc ) = @_;

	croak "ratio munger$where takes exactly 2 source fields (numerator, denominator), not $nsrc"
		unless $nsrc == 2;

	my $zero = defined $spec->{zero} ? $spec->{zero} : 0;
	croak "ratio munger$where: 'zero' must be numeric"
		unless looks_like_number($zero);

	return sub {
		for my $v (@_) {
			croak "ratio munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
				unless looks_like_number($v);
		}
		return $zero if $_[1] == 0;
		return $_[0] / $_[1];
	};
} ## end sub _build_ratio

# op => fold over the already numeric-checked source values. A table so the
# error message can enumerate them and a new op is one line.
my %COMBINE_OPS = (
	sum     => sub { my $t = 0; $t += $_ for @_; return $t },
	diff    => sub { return $_[0] - $_[1] },
	product => sub { my $t = 1; $t *= $_ for @_; return $t },
	min     => sub {
		my $t = shift;
		for (@_) { $t = $_ if $_ < $t }
		return $t;
	},
	max => sub {
		my $t = shift;
		for (@_) { $t = $_ if $_ > $t }
		return $t;
	},
	mean => sub { my $t = 0; $t += $_ for @_; return $t / @_ },
);

sub _build_combine_op {
	my ( $spec, $where, $nsrc ) = @_;

	my $op = $spec->{op};
	croak "combine munger$where requires an 'op' (one of: " . join( ', ', sort keys %COMBINE_OPS ) . ')'
		unless defined $op && length $op;
	my $fold = $COMBINE_OPS{$op}
		or croak "combine munger$where: unknown op '$op' (known: " . join( ', ', sort keys %COMBINE_OPS ) . ')';
	croak "combine munger$where: op 'diff' takes exactly 2 source fields, not $nsrc"
		if $op eq 'diff' && $nsrc != 2;

	return sub {
		for my $v (@_) {
			croak "combine munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not numeric"
				unless looks_like_number($v);
		}
		return $fold->(@_);
	};
} ## end sub _build_combine_op

=head2 bit

    { munger => 'bit', mask => '0x12' }                  # SYN or ACK set?
    { munger => 'bit', mask => '0x02', mode => 'all' }   # the SYN bit itself
    { munger => 'bit', mode => 'popcount' }              # how many flags at all
    { munger => 'bit', mask => '0x0f', mode => 'value' } # low nibble, 0-15
    { munger => 'bit', mask => '0x02', base => 16 }      # Suricata tcp_flags "1b"

Bit-level features from an integer flags word (TCP flags, DNS header flags,
protocol option words): the raw word is meaningless to a threshold split, but
individual bits and bit I<counts> are real signals. The input must be a
non-negative integer, in decimal or C<0x> hex (so a logged C<0x12> works
as-is); C<mask> may be written either way too.

Set C<< base => 16 >> to read the B<input> as bare hexadecimal with no C<0x>
prefix -- Suricata logs C<tcp.tcp_flags> (and C<tcp_flags_ts>/C<tcp_flags_tc>)
as e.g. C<"1b">, which is otherwise ambiguous with decimal. A C<0x> prefix on
the input is still accepted under C<< base => 16 >>. C<mask> is always written
in decimal or C<0x> hex regardless of C<base>. Modes:

=over 4

=item * C<any> (default) - C<1> if any bit of C<mask> is set in the value.

=item * C<all> - C<1> only if every bit of C<mask> is set.

=item * C<value> - the masked bits, shifted down to the mask's lowest set
bit: C<< mask => '0x0f' >> extracts the low nibble as C<0>-C<15>.

=item * C<popcount> - the number of set bits in C<value & mask>; C<mask> is
optional here and defaults to all bits. An abnormal flag I<count> (a
Christmas-tree packet) is anomalous even when each individual bit is common.

=back

C<mask> is required (and must be non-zero) for every mode except C<popcount>.

=cut

my %BIT_MODE = map { $_ => 1 } qw(any all value popcount);

# Accept an integer in decimal or 0x-hex form; returns the number, or undef
# if it is neither. Shared by bit's mask (spec) and value (input) parsing.
sub _bit_int {
	my ($v) = @_;
	return undef unless defined $v;
	return hex($v) if $v =~ /\A0x[0-9a-f]+\z/i;
	return $v + 0  if $v =~ /\A[0-9]+\z/;
	return undef;
}

# Parse an input value as bare hex (a '0x' prefix is tolerated), for bit's
# 'base => 16' mode. Suricata logs tcp_flags as "1b" with no prefix, which
# _bit_int would read as decimal (or reject), hence a separate parser opted
# into per munger rather than a change to the ambiguous default.
sub _bit_hex {
	my ($v) = @_;
	return undef unless defined $v;
	return hex($1) if $v =~ /\A(?:0x)?([0-9a-f]+)\z/i;
	return undef;
}

sub _build_bit {
	my ( $spec, $where ) = @_;

	my $mode = defined $spec->{mode} ? $spec->{mode} : 'any';
	croak "bit munger$where: unknown mode '$mode' (known: " . join( ', ', sort keys %BIT_MODE ) . ')'
		unless $BIT_MODE{$mode};

	# Input base: 10 (default, decimal or 0x hex) or 16 (bare hex, for feeds
	# like Suricata's tcp_flags). Only the per-row input parser changes; the
	# mask below is always read with _bit_int.
	my $base = defined $spec->{base} ? $spec->{base} : 10;
	croak "bit munger$where: 'base' must be 10 or 16"
		unless $base eq '10' || $base eq '16';
	my $parse_in = $base eq '16' ? \&_bit_hex : \&_bit_int;
	my $in_form  = $base eq '16' ? 'hex'      : 'decimal or 0x hex';

	my $mask;
	if ( defined $spec->{mask} ) {
		$mask = _bit_int( $spec->{mask} );
		croak "bit munger$where: 'mask' must be a non-negative integer " . '(decimal or 0x hex)'
			unless defined $mask;
		croak "bit munger$where: 'mask' must be non-zero"
			if $mask == 0 && $mode ne 'popcount';
	} elsif ( $mode ne 'popcount' ) {
		croak "bit munger$where: mode '$mode' requires a 'mask'";
	}

	# For 'value', bake in the shift down to the mask's lowest set bit.
	my $shift = 0;
	if ( $mode eq 'value' ) {
		my $m = $mask;
		until ( $m & 1 ) { $m >>= 1; $shift++; }
	}

	return sub {
		my ($v) = @_;
		my $n   = $parse_in->( defined $v ? "$v" : undef );
		croak "bit munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not a non-negative integer ($in_form)"
			unless defined $n;
		$n &= $mask                          if defined $mask;
		return sprintf( '%b', $n ) =~ tr/1// if $mode eq 'popcount';
		return $n          ? 1 : 0 if $mode eq 'any';
		return $n == $mask ? 1 : 0 if $mode eq 'all';
		return $n >> $shift;    # value
	}; ## end sub
} ## end sub _build_bit

=head2 ip_class

    { munger => 'ip_class' }
    { munger => 'ip_class', default => -1 }

Collapse an IPv4 or IPv6 address to its address-space class -- to addresses
what the status-class enums are to reply codes: the literal address is
high-cardinality noise, but "an internal host suddenly talking multicast" is
a class-level signal. Classes and their emitted numbers:

    0  global       anything not covered below
    1  private      10/8, 172.16/12, 192.168/16, 100.64/10 (CGNAT), fc00::/7 (ULA)
    2  loopback     127/8, ::1
    3  link_local   169.254/16, fe80::/10
    4  multicast    224/4, ff00::/8
    5  broadcast    255.255.255.255
    6  unspecified  0.0.0.0, ::
    7  reserved     0/8, 192.0.0/24, the documentation nets (192.0.2/24,
                    198.51.100/24, 203.0.113/24, 2001:db8::/32), benchmarking
                    (198.18/15), 240/4, and the 100::/64 discard prefix

An IPv4-mapped IPv6 address (C<::ffff:a.b.c.d>) is classified as its embedded
IPv4 address. An unparseable input croaks, or yields the numeric C<default>
when one is given. IPv6 parsing uses L<Socket>'s C<inet_pton>, loaded lazily
the way L</datetime> loads Time::Piece. For B<site-specific> zones (DMZ,
server VLAN, guest Wi-Fi) use L</cidr>, which knows your networks instead of
the RFCs'.

=head2 cidr

    { munger => 'cidr',
      nets    => [ '10.10.0.0/16', '10.20.0.0/16', '2001:db8:5::/48' ],
      default => -1 }

Membership in a list of CIDR networks: the result is the (0-based) index of
the B<first> net in C<nets> containing the address -- L</bucket> for address
space, and the way a site encodes its own zones (DMZ vs. server VLAN vs.
guest Wi-Fi) that L</ip_class>'s generic RFC classes cannot know about.
C<nets> may mix IPv4 and IPv6; an address is only tested against nets of its
own family. Overlapping nets are fine -- list the most specific first, since
the first match wins. An input that is unparseable or in none of the listed
nets croaks, or yields the numeric C<default> when one is given (a catch-all
C<default> is the usual configuration).

=cut

# Parse an IP address string: (4, $int) for IPv4, (6, $bytes16) for IPv6, or
# an empty list for neither. v4 goes through a regex (also pinning the
# dotted-quad form, so inet_pton's odd shorthands never sneak in); v6 leans
# on Socket's inet_pton, loaded lazily so no munger that skips IPs pays for
# it.
sub _parse_ip {
	my ($s) = @_;
	if ( $s =~ /\A([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\z/ ) {
		return unless $1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255;
		return ( 4, ( $1 << 24 ) | ( $2 << 16 ) | ( $3 << 8 ) | $4 );
	}
	if ( index( $s, ':' ) >= 0 ) {
		require Socket;
		my $b = eval { Socket::inet_pton( Socket::AF_INET6(), $s ) };
		return ( 6, $b ) if defined $b && length $b == 16;
	}
	return;
} ## end sub _parse_ip

# The ip_class class names, pinned to their emitted numbers.
my %IP_CLASS = (
	global      => 0,
	private     => 1,
	loopback    => 2,
	link_local  => 3,
	multicast   => 4,
	broadcast   => 5,
	unspecified => 6,
	reserved    => 7,
);

sub _ip4_class {
	my ($n) = @_;
	return 'unspecified' if $n == 0;
	return 'broadcast'   if $n == 0xffffffff;
	my $a = $n >> 24;
	my $b = ( $n >> 16 ) & 0xff;
	my $c = ( $n >> 8 ) & 0xff;
	return 'reserved'   if $a == 0;                                  # 0/8 "this network"
	return 'private'    if $a == 10;
	return 'private'    if $a == 100 && $b >= 64 && $b <= 127;       # CGNAT 100.64/10
	return 'loopback'   if $a == 127;
	return 'link_local' if $a == 169 && $b == 254;
	return 'private'    if $a == 172 && $b >= 16 && $b <= 31;
	return 'reserved'   if $a == 192 && $b == 0  && ( $c == 0 || $c == 2 );
	return 'private'    if $a == 192 && $b == 168;
	return 'reserved'   if $a == 198 && ( $b == 18 || $b == 19 );    # benchmarking
	return 'reserved'   if $a == 198 && $b == 51 && $c == 100;       # TEST-NET-2
	return 'reserved'   if $a == 203 && $b == 0  && $c == 113;       # TEST-NET-3
	return 'multicast'  if $a >= 224 && $a <= 239;
	return 'reserved'   if $a >= 240;                                # 240/4 future use
	return 'global';
} ## end sub _ip4_class

sub _ip6_class {
	my ($bytes) = @_;
	my @o       = unpack 'C16', $bytes;
	my $lead0   = 1;
	for my $i ( 0 .. 14 ) { $lead0 &&= $o[$i] == 0 }
	if ($lead0) {
		return 'unspecified' if $o[15] == 0;
		return 'loopback'    if $o[15] == 1;
	}
	# v4-mapped ::ffff:a.b.c.d -- classify as the embedded v4 address.
	my $map = 1;
	for my $i ( 0 .. 9 ) { $map &&= $o[$i] == 0 }
	return _ip4_class( ( $o[12] << 24 ) | ( $o[13] << 16 ) | ( $o[14] << 8 ) | $o[15] )
		if $map && $o[10] == 0xff && $o[11] == 0xff;
	return 'multicast'  if $o[0] == 0xff;
	return 'private'    if ( $o[0] & 0xfe ) == 0xfc;                                            # ULA fc00::/7
	return 'link_local' if $o[0] == 0xfe && ( $o[1] & 0xc0 ) == 0x80;                           # fe80::/10
	return 'reserved'   if $o[0] == 0x20 && $o[1] == 0x01 && $o[2] == 0x0d && $o[3] == 0xb8;    # 2001:db8::/32
	my $discard = $o[0] == 0x01;                                                                # 100::/64
	for my $i ( 1 .. 7 ) { $discard &&= $o[$i] == 0 }
	return 'reserved' if $discard;
	return 'global';
} ## end sub _ip6_class

sub _build_ip_class {
	my ( $spec, $where ) = @_;

	my $has_default = exists $spec->{default};
	my $default     = $spec->{default};
	croak "ip_class munger$where: 'default' must be numeric"
		if $has_default && !looks_like_number($default);

	return sub {
		my ($v) = @_;
		my ( $fam, $p ) = _parse_ip( defined $v ? "$v" : '' );
		if ($fam) {
			return $IP_CLASS{ $fam == 4 ? _ip4_class($p) : _ip6_class($p) };
		}
		return $default if $has_default;
		croak "ip_class munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not a parseable IP address";
	};
} ## end sub _build_ip_class

# Build a 16-byte netmask string for an IPv6 prefix length.
sub _v6_mask {
	my ($len) = @_;
	my $mask = "\xff" x int( $len / 8 );
	$mask .= chr( ( 0xff << ( 8 - $len % 8 ) ) & 0xff ) if $len % 8;
	return $mask . ( "\0" x ( 16 - length $mask ) );
}

sub _build_cidr {
	my ( $spec, $where ) = @_;

	my $nets = $spec->{nets};
	croak "cidr munger$where requires a non-empty 'nets' arrayref"
		unless ref $nets eq 'ARRAY' && @$nets;

	# [family, masked network, mask] per net; & on the 16-byte v6 strings is
	# Perl's bitwise string AND, so both families match the same way.
	my @match;
	for my $i ( 0 .. $#$nets ) {
		my $net = $nets->[$i];
		croak "cidr munger$where: nets[$i] ('"
			. ( defined $net ? $net : 'undef' )
			. "') is not in 'address/prefix' form"
			unless defined $net && $net =~ m{\A(.+)/([0-9]{1,3})\z};
		my ( $addr, $len ) = ( $1, $2 );
		my ( $fam,  $p )   = _parse_ip($addr);
		croak "cidr munger$where: nets[$i] ('$net') has an unparseable address"
			unless $fam;
		my $max = $fam == 4 ? 32 : 128;
		croak "cidr munger$where: nets[$i] ('$net') prefix length must be 0-$max"
			if $len > $max;
		my $mask
			= $fam == 4
			? ( $len == 0 ? 0 : ( 0xffffffff << ( 32 - $len ) ) & 0xffffffff )
			: _v6_mask($len);
		push @match, [ $fam, $p & $mask, $mask ];
	} ## end for my $i ( 0 .. $#$nets )

	my $has_default = exists $spec->{default};
	my $default     = $spec->{default};
	croak "cidr munger$where: 'default' must be numeric"
		if $has_default && !looks_like_number($default);

	return sub {
		my ($v) = @_;
		my ( $fam, $p ) = _parse_ip( defined $v ? "$v" : '' );
		if ($fam) {
			for my $i ( 0 .. $#match ) {
				my ( $f, $network, $mask ) = @{ $match[$i] };
				next unless $f == $fam;
				return $i
					if $fam == 4
					? ( ( $p & $mask ) == $network )
					: ( ( $p & $mask ) eq $network );
			}
			return $default if $has_default;
			croak "cidr munger$where: '$v' is in none of the listed networks (and no 'default')";
		} ## end if ($fam)
		return $default if $has_default;
		croak "cidr munger$where: '" . ( defined $v ? $v : 'undef' ) . "' is not a parseable IP address";
	}; ## end sub
} ## end sub _build_cidr

=head2 datetime

    { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'epoch' }
    { munger => 'datetime', format => '%Y-%m-%d %H:%M:%S', part => 'hour' }

Parse a formatted timestamp with L<Time::Piece> (C<strptime>, so C<format> is a
standard strptime pattern) and extract one numeric C<part>:

=over 4

=item * C<epoch> (default) - seconds since the epoch.

=item * C<year>, C<mon> (1-12), C<mday> (1-31), C<hour>, C<min>, C<sec>.

=item * C<wday> - day of week, C<0>=Sunday .. C<6>=Saturday.

=item * C<yday> - day of year, C<0>-based.

=item * C<frac_day> - time of day as a fraction in C<[0, 1)>, i.e.
C<(hour*3600 + min*60 + sec) / 86400>. Handy as a cyclic-ish time-of-day feature.

=item * C<frac_week> - position within the week as a fraction in C<[0, 1)>, the
week starting Sunday to match C<wday>: C<(wday*86400 + hour*3600 + min*60 + sec)
/ 604800>. Like C<frac_day> but cycling over a week, so a weekly rhythm (weekend
vs. weekday, or a Monday-morning batch) shows up as a feature.

=item * C<sin_day> / C<cos_day>, C<sin_week> / C<cos_week> - the C<frac_*> value
mapped onto a circle, C<sin(2*pi*frac)> and C<cos(2*pi*frac)>. Prefer these over
the raw C<frac_*> when feeding the forest: a plain fraction has a false seam at
the wrap (23:59 and 00:00 sit at opposite ends, 1 vs 0, though they are a minute
apart), whereas the sin/cos pair is continuous across midnight/Sunday. Store
I<both> of a pair in two columns so the position is unambiguous.

=back

Time features often carry the anomaly (a job that normally runs at 03:00
suddenly firing at noon, or a weekday task firing on a Sunday), which is why this
is a first-class munger.

B<Multi-output form.> A cyclic pair belongs together -- C<sin> alone collides
(C<sin> is symmetric about its peak, so two different times map to one value) and
the forest then treats distinct times as identical. To emit a pair atomically,
give C<parts> (plural) and route them to two columns with C<into> (see
L</compile>):

    "time_of_week": {
        "munger": "datetime", "from": "timestamp",
        "format": "%Y-%m-%dT%H:%M:%S",
        "parts":  [ "sin_week", "cos_week" ],
        "into":   [ "time_sin", "time_cos" ]
    }

The timestamp is parsed once and both columns are filled together, so they can
never drift apart or be half-configured. C<parts> and C<into> must be the same
length. (Using C<parts> without C<into>, or C<part> with C<into>, is an error.)

B<Performance.> Two transparent accelerations, both value-identical to the plain
path: a one-slot memo returns the previous result when the same stamp string
repeats (the common case in bursty event streams); and when the format is built
from only the six numeric codes C<%Y %m %d %H %M %S> (once each, e.g.
C<%Y-%m-%dT%H:%M:%S>), parsing skips C<strptime> for a compiled regex plus
integer date math, falling back to C<strptime> for any value the regex does not
match B<or whose fields are out of range> (a month C<13>, an hour C<24>, a
C<Feb 30>) -- so an invalid stamp croaks or normalizes exactly as C<strptime>
would, never silently feeding nonsense to the date math. Like C<strptime>
without a zone code, stamps are treated as UTC.

=cut

# Fraction (in [0,1)) of the way through the day / week, shared by the frac_*
# parts and their sin/cos cyclic encodings.
sub _frac_day {
	my $t = shift;
	return ( $t->hour * 3600 + $t->min * 60 + $t->sec ) / 86400;
}

sub _frac_week {
	my $t = shift;
	return ( $t->day_of_week * 86400 + $t->hour * 3600 + $t->min * 60 + $t->sec ) / 604800;
}

my $TWO_PI = 2 * atan2( 0, -1 );    # atan2(0,-1) == pi, core-only, no POSIX

# part name => how to pull it off a Time::Piece object.
my %DATETIME_PART = (
	epoch     => sub { $_[0]->epoch },
	year      => sub { $_[0]->year },
	mon       => sub { $_[0]->mon },
	mday      => sub { $_[0]->mday },
	hour      => sub { $_[0]->hour },
	min       => sub { $_[0]->min },
	sec       => sub { $_[0]->sec },
	wday      => sub { $_[0]->day_of_week },
	yday      => sub { $_[0]->yday },
	frac_day  => \&_frac_day,
	frac_week => \&_frac_week,
	sin_day   => sub { sin( $TWO_PI * _frac_day( $_[0] ) ) },
	cos_day   => sub { cos( $TWO_PI * _frac_day( $_[0] ) ) },
	sin_week  => sub { sin( $TWO_PI * _frac_week( $_[0] ) ) },
	cos_week  => sub { cos( $TWO_PI * _frac_week( $_[0] ) ) },
);

# ---- fast fixed-format engine ----------------------------------------------
#
# Time::Piece->strptime costs microseconds per call. When the format is built
# from only the six all-numeric codes below (once each, e.g. the ubiquitous
# '%Y-%m-%dT%H:%M:%S'), we can compile it to a capture regex and derive every
# part with integer math instead -- several times faster, and bit-identical:
# both paths treat the stamp as UTC (strptime with no zone does the same).
# Anything fancier (%b, %z, %j, ...) stays on strptime.

# strptime code => [ field name, capture pattern ].
my %FAST_CODE = (
	Y => [ 'year', '[0-9]{4}' ],
	m => [ 'mon',  '[0-9]{2}' ],
	d => [ 'mday', '[0-9]{2}' ],
	H => [ 'hour', '[0-9]{2}' ],
	M => [ 'min',  '[0-9]{2}' ],
	S => [ 'sec',  '[0-9]{2}' ],
);

# Compile a strptime format into { re, idx } for the arithmetic fast path --
# idx maps field name (year/mon/...) to its capture position -- or return undef
# when the format is not fast-eligible. All six codes must appear exactly once
# so every part can be derived.
sub _compile_fast_format {
	my ($format) = @_;
	my $re       = '';
	my %idx      = ();
	my $n        = 0;
	my $rest     = $format;
	while ( length $rest ) {
		if ( $rest =~ s/\A%(.)//s ) {
			my $f = $FAST_CODE{$1} or return undef;
			return undef if exists $idx{ $f->[0] };
			$idx{ $f->[0] } = $n++;
			$re .= '(' . $f->[1] . ')';
		} elsif ( $rest =~ s/\A([^%]+)//s ) {
			$re .= quotemeta($1);
		} else {
			return undef;    # lone trailing '%' -- not fast-eligible
		}
	} ## end while ( length $rest )
	return undef unless keys %idx == 6;
	return { re => qr/\A$re\z/, idx => \%idx };
} ## end sub _compile_fast_format

# A regex match only proves each fast-path field is digits of the right width,
# not that the six of them form a real timestamp: '2026-13-01T25:00:00' matches
# the shape. Fields out of range (month 13, hour 24, Feb 30) must not reach the
# blind integer date math -- they are routed to strptime instead, which stays
# the judge of whether such a stamp croaks or normalizes (Time::Piece rolls
# Feb 30 over into March), keeping the two paths value-identical. Seconds stop
# at 59: a :60 leap second is not representable in epoch math, so strptime
# arbitrates it too.
my @DAYS_IN_MONTH = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

sub _fast_fields_in_range {
	my ( $c, $idx ) = @_;
	my ( $y, $m, $d, $H, $M, $S ) = @{$c}[ @{$idx}{qw(year mon mday hour min sec)} ];
	return 0 if $m < 1 || $m > 12;
	my $dim = $DAYS_IN_MONTH[ $m - 1 ];
	$dim = 29 if $m == 2 && ( ( !( $y % 4 ) && $y % 100 ) || !( $y % 400 ) );
	return 0 if $d < 1 || $d > $dim;
	return 0 if $H > 23 || $M > 59 || $S > 59;
	return 1;
} ## end sub _fast_fields_in_range

# Days since 1970-01-01 for a proleptic-Gregorian date (Howard Hinnant's
# days-from-civil). Pure integer math; Perl's % already yields a non-negative
# result for the wday derivation even on pre-1970 dates.
sub _days_from_civil {
	my ( $y, $m, $d ) = @_;
	$y -= $m <= 2;
	my $era = int( ( $y >= 0 ? $y : $y - 399 ) / 400 );
	my $yoe = $y - $era * 400;
	my $doy = int( ( 153 * ( $m + ( $m > 2 ? -3 : 9 ) ) + 2 ) / 5 ) + $d - 1;
	my $doe = $yoe * 365 + int( $yoe / 4 ) - int( $yoe / 100 ) + $doy;
	return $era * 146097 + $doe - 719468;
}

# part name => factory(\%idx) => getter(\@captures). Mirrors %DATETIME_PART;
# t/mungers-datetime-fast.t asserts the two stay value-identical. The factories
# bake the capture positions in at build time so a per-row getter indexes the
# raw capture array directly -- no intermediate hash per row, which is where
# the fast path's time would otherwise go. Slot 6 of the capture array caches
# days-from-civil so a multi-part (sin/cos) extraction computes it once.
my %DATETIME_PART_FAST;
{
	my $days_of = sub {
		my ( $iy, $im, $id ) = @{ $_[0] }{qw(year mon mday)};
		return sub {
			my $c = shift;
			return defined $c->[6]
				? $c->[6]
				: ( $c->[6] = _days_from_civil( $c->[$iy], $c->[$im], $c->[$id] ) );
		};
	};
	my $sod_of = sub {
		my ( $ih, $in, $is ) = @{ $_[0] }{qw(hour min sec)};
		return sub { $_[0][$ih] * 3600 + $_[0][$in] * 60 + $_[0][$is] };
	};
	my $frac_day_of = sub {
		my $sod = $sod_of->( $_[0] );
		return sub { $sod->( $_[0] ) / 86400 };
	};
	my $frac_week_of = sub {
		my ( $days, $sod ) = ( $days_of->( $_[0] ), $sod_of->( $_[0] ) );
		return sub {
			my $c = shift;
			return ( ( ( $days->($c) + 4 ) % 7 ) * 86400 + $sod->($c) ) / 604800;
		};
	};
	my $field_of = sub {
		my ($name) = @_;
		return sub {
			my $i = $_[0]{$name};
			return sub { $_[0][$i] + 0 }
		};
	};

	%DATETIME_PART_FAST = (
		year  => $field_of->('year'),
		mon   => $field_of->('mon'),
		mday  => $field_of->('mday'),
		hour  => $field_of->('hour'),
		min   => $field_of->('min'),
		sec   => $field_of->('sec'),
		epoch => sub {
			my ( $days, $sod ) = ( $days_of->( $_[0] ), $sod_of->( $_[0] ) );
			return sub { $days->( $_[0] ) * 86400 + $sod->( $_[0] ) };
		},
		wday => sub {    # epoch day 0 = Thursday = 4
			my $days = $days_of->( $_[0] );
			return sub { ( $days->( $_[0] ) + 4 ) % 7 };
		},
		yday => sub {
			my ($idx) = @_;
			my $days  = $days_of->($idx);
			my $iy    = $idx->{year};
			return sub {
				my $c = shift;
				return $days->($c) - _days_from_civil( $c->[$iy], 1, 1 );
			};
		},
		frac_day  => $frac_day_of,
		frac_week => $frac_week_of,
		sin_day   => sub {
			my $f = $frac_day_of->( $_[0] );
			return sub { sin( $TWO_PI * $f->( $_[0] ) ) };
		},
		cos_day => sub {
			my $f = $frac_day_of->( $_[0] );
			return sub { cos( $TWO_PI * $f->( $_[0] ) ) };
		},
		sin_week => sub {
			my $f = $frac_week_of->( $_[0] );
			return sub { sin( $TWO_PI * $f->( $_[0] ) ) };
		},
		cos_week => sub {
			my $f = $frac_week_of->( $_[0] );
			return sub { cos( $TWO_PI * $f->( $_[0] ) ) };
		},
	);
}

# Build the parse/getter machinery for a datetime spec: ($parse, $getter_for),
# where $parse->($v) yields whatever the getters consume (a capture array on
# the fast path, a Time::Piece object otherwise) and $getter_for->($part)
# resolves a part name to a getter closure, croaking on an unknown part.
# Shared by the scalar and multi-output builders so the choice is made in
# exactly one place.
sub _datetime_engine {
	my ( $format, $where ) = @_;
	croak "datetime munger$where requires a strptime 'format'"
		unless defined $format && length $format;

	# Time::Piece is not core on the ancient perls Makefile.PL still nominally
	# supports, so only pull it in for the one munger that needs it. The fast
	# path keeps it loaded too: a regex mismatch falls back to strptime so the
	# fast path can never reject a value the slow path would have accepted.
	require Time::Piece;

	my $strptime = sub {
		my ($v) = @_;
		my $t = eval { Time::Piece->strptime( $v, $format ) };
		croak "datetime munger$where: cannot parse '$v' with '$format'"
			unless $t;
		return $t;
	};

	if ( my $fast = _compile_fast_format($format) ) {
		my ( $re, $idx ) = @{$fast}{qw(re idx)};
		my $parse = sub {
			my ($v) = @_;
			croak "datetime munger$where: undefined value" unless defined $v;
			if ( my @c = $v =~ $re ) {
				return \@c if _fast_fields_in_range( \@c, $idx );
			}
			# Regex mismatch or out-of-range fields: let strptime be the judge,
			# rebuilding the capture array (normalized, when strptime chooses
			# to normalize rather than reject) in this format's capture order.
			my $t = $strptime->($v);
			my @c;
			@c[ @{$idx}{qw(year mon mday hour min sec)} ]
				= ( $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec );
			return \@c;
		}; ## end $parse = sub
		my $getter_for = sub {
			my ($part) = @_;
			my $factory = $DATETIME_PART_FAST{$part}
				or croak "datetime munger$where: unknown part '$part' (known: "
				. join( ', ', sort keys %DATETIME_PART ) . ')';
			return $factory->($idx);
		};
		return ( $parse, $getter_for );
	} ## end if ( my $fast = _compile_fast_format($format...))

	my $parse = sub {
		my ($v) = @_;
		croak "datetime munger$where: undefined value" unless defined $v;
		return $strptime->($v);
	};
	my $getter_for = sub {
		my ($part) = @_;
		my $get = $DATETIME_PART{$part}
			or croak "datetime munger$where: unknown part '$part' (known: "
			. join( ', ', sort keys %DATETIME_PART ) . ')';
		return $get;
	};
	return ( $parse, $getter_for );
} ## end sub _datetime_engine

sub _build_datetime {
	my ( $spec, $where ) = @_;

	croak "datetime munger$where: 'parts' is for the multi-output form (needs "
		. "'into'); use 'part' for a single column"
		if defined $spec->{parts};

	my ( $parse, $getter_for ) = _datetime_engine( $spec->{format}, $where );
	my $get = $getter_for->( defined $spec->{part} ? $spec->{part} : 'epoch' );

	# One-slot memo: event streams repeat the same stamp within a second
	# constantly, so the previous input usually answers the next call with a
	# string compare. A parse failure leaves the memo untouched.
	my ( $memo_in, $memo_out );
	return sub {
		my ($v) = @_;
		return $memo_out
			if defined $v && defined $memo_in && $v eq $memo_in;
		my $out = $get->( $parse->($v) );
		( $memo_in, $memo_out ) = ( $v, $out );
		return $out;
	};
} ## end sub _build_datetime

# Multi-output datetime: parse once, emit one number per part, in 'parts' order
# (which lines up with the caller's 'into'). Returns ($list_returning_code,
# $arity) so compile() can check the arity against 'into'. Memoized like the
# scalar form, caching the whole output list per input stamp.
sub _build_datetime_multi {
	my ( $spec, $where ) = @_;

	my $parts = $spec->{parts};
	croak "datetime munger$where: 'parts' must be a non-empty arrayref"
		unless ref $parts eq 'ARRAY' && @$parts;

	my ( $parse, $getter_for ) = _datetime_engine( $spec->{format}, $where );
	my @get = map { $getter_for->($_) } @$parts;

	my ( $memo_in, @memo_out );
	my $code = sub {
		my ($v) = @_;
		return @memo_out
			if defined $v && defined $memo_in && $v eq $memo_in;
		my $t   = $parse->($v);
		my @out = map { $_->($t) } @get;
		( $memo_in, @memo_out ) = ( $v, @out );
		return @out;
	};
	return ( $code, scalar @$parts );
} ## end sub _build_datetime_multi

=head2 hash

    { munger => 'hash', buckets => 1024 }
    { munger => 'hash', buckets => 1024, seed => 7 }
    { munger => 'hash' }                          # raw 32-bit FNV-1a value

Feature hashing for high-cardinality categoricals you do not want to (or cannot)
enumerate with C<enum>. The input is stringified and run through 32-bit FNV-1a;
with C<buckets> the result is reduced modulo that many buckets (C<[0, buckets)>),
otherwise the full 32-bit hash is returned. An optional C<seed> lets you decorrelate
two hashed columns.

This is the one munger that is XS-accelerated: FNV-1a is a per-byte loop with a
32-bit modular multiply, which is slow in pure Perl and (on a 32-bit perl) fussy
to get exactly right. C<$Algorithm::ToNumberMunger::HAVE_XS>
reports whether the compiled path is in use; a pure-Perl fallback (exact on a
64-bit perl) is used otherwise, and both produce identical values.

=cut

sub _build_hash {
	my ( $spec, $where ) = @_;

	my $buckets = $spec->{buckets};
	croak "hash munger$where: 'buckets' must be a positive integer"
		if defined $buckets && $buckets !~ /\A[1-9][0-9]*\z/;

	my $seed = defined $spec->{seed} ? $spec->{seed} : 0;
	croak "hash munger$where: 'seed' must be a non-negative integer"
		if $seed !~ /\A[0-9]+\z/;

	my $fn = $HAVE_XS ? \&_fnv1a_xs : \&_fnv1a_pp;
	return sub {
		my ($v) = @_;
		my $h = $fn->( defined $v ? "$v" : '', $seed );
		return defined $buckets ? $h % $buckets : $h;
	};
} ## end sub _build_hash

# Pure-Perl 32-bit FNV-1a, used only when the XS did not build. On a 64-bit
# perl the intermediate h*16777619 (< 2**57) stays an exact integer, so the
# masked result matches the C version bit for bit. The string is always
# utf8-encoded first so a value hashes as its UTF-8 bytes no matter the internal
# flag -- the same well-defined bytes SvPVutf8 hands the XS.
sub _fnv1a_pp {
	my ( $str, $seed ) = @_;
	utf8::encode($str);
	my $h = ( 2166136261 ^ ( $seed & 0xFFFFFFFF ) ) & 0xFFFFFFFF;
	for my $c ( unpack 'C*', $str ) {
		$h ^= $c;
		$h = ( $h * 16777619 ) & 0xFFFFFFFF;
	}
	return $h;
} ## end sub _fnv1a_pp

=head2 chain

    # Shannon entropy of just the TLD: lowercase, keep the last dot-label
    { munger => 'chain',
      steps  => [ { op => 'lc' }, { op => 'split', on => '.', index => -1 } ],
      then   => { munger => 'entropy' } }

    # a hex request id buried in a token like 'req-0x2F'
    { munger => 'chain',
      steps  => [ { op => 'capture', pattern => 'req-(0x[0-9a-fA-F]+)' } ],
      then   => { munger => 'num', base => 16 } }

Run the input through a list of string pre-transforms (C<steps>, applied in
order), then hand the result to a terminal munger (C<then>) for the actual
number. Every string munger above scores the I<whole> value; C<chain> is how a
feature targets a I<piece> of it -- the entropy of the TLD alone, the length
of the first path segment, an enum over a normalized token -- without asking
the writer's caller to pre-slice its input. Each step is a hashref with an
C<op>:

=over 4

=item * C<lc> / C<uc> - case-fold the value.

=item * C<trim> - strip leading and trailing whitespace.

=item * C<split> - split on the literal separator C<on> and keep piece
C<index> (0-based; negative counts from the end, so C<-1> is a hostname's last
label). An index past either end yields the empty string.

=item * C<capture> - match the regex C<pattern> and keep capture group
C<group> (default C<1>). No match, or a group that did not participate, yields
the empty string. A true C<ignore_case> matches case-insensitively; the
L</match> trust note applies here too.

=item * C<replace> - replace every match of the regex C<pattern> with the
literal string C<with> (default: delete the matches). C<ignore_case> as above.

=back

C<then> is a full munger spec and may be any built-in that takes one value --
including another C<chain>. All step parameters and the terminal spec are
validated at build time. An undef input enters the chain as the empty string;
whether an empty result is acceptable is the terminal's call (C<entropy> and
C<length> score it C<0>, C<num> croaks).

The multi-output form works too: put C<into> on the B<chain> and the C<parts>
on the terminal, e.g. C<trim> a sloppy timestamp before a L</datetime>
C<sin>/C<cos> expansion.

=cut

# op => step builder; each validates its slice of the step spec at build time
# and returns a string-to-string closure. Steps only ever see a defined string
# (the chain entry point turns undef into '').
my %CHAIN_OPS = (
	lc => sub {
		return sub { return lc $_[0] }
	},
	uc => sub {
		return sub { return uc $_[0] }
	},
	trim => sub {
		return sub { my ($s) = @_; $s =~ s/\A\s+//; $s =~ s/\s+\z//; return $s };
	},
	split => sub {
		my ( $step, $where ) = @_;
		my $on = $step->{on};
		croak "chain munger$where: split step requires a non-empty 'on' string"
			unless defined $on && length $on;
		my $idx = defined $step->{index} ? $step->{index} : 0;
		croak "chain munger$where: split 'index' must be an integer"
			unless $idx =~ /\A-?[0-9]+\z/;
		# limit -1 keeps trailing empty pieces, so 'a.' really has two labels
		# and index -1 is the empty last one, not 'a'.
		return sub {
			my @p = split /\Q$on\E/, $_[0], -1;
			return ( $idx > $#p || $idx < -@p ) ? '' : $p[$idx];
		};
	},
	capture => sub {
		my ( $step, $where ) = @_;
		my $pat = $step->{pattern};
		croak "chain munger$where: capture step requires a non-empty 'pattern'"
			unless defined $pat && length $pat;
		my $re = eval { $step->{ignore_case} ? qr/$pat/i : qr/$pat/ };
		croak "chain munger$where: cannot compile pattern '$pat': $@"
			unless defined $re;
		my $group = defined $step->{group} ? $step->{group} : 1;
		croak "chain munger$where: capture 'group' must be a positive integer"
			unless $group =~ /\A[1-9][0-9]*\z/;
		# @-/@+ rather than a list-context match: a pattern with no capture
		# groups returns (1) in list context, which would masquerade as a
		# captured '1'; $#+ says how many groups the pattern really has.
		return sub {
			my ($s) = @_;
			return '' unless $s =~ $re;
			return '' unless $group <= $#+ && defined $-[$group];
			return substr( $s, $-[$group], $+[$group] - $-[$group] );
		};
	},
	replace => sub {
		my ( $step, $where ) = @_;
		my $pat = $step->{pattern};
		croak "chain munger$where: replace step requires a non-empty 'pattern'"
			unless defined $pat && length $pat;
		my $re = eval { $step->{ignore_case} ? qr/$pat/i : qr/$pat/ };
		croak "chain munger$where: cannot compile pattern '$pat': $@"
			unless defined $re;
		my $with = defined $step->{with} ? $step->{with} : '';
		return sub { my ($s) = @_; $s =~ s/$re/$with/g; return $s };
	},
);

# Compile the 'steps' list into string-to-string closures; shared by the
# scalar and multi-output chain builders.
sub _chain_steps {
	my ( $spec, $where ) = @_;

	my $steps = $spec->{steps};
	croak "chain munger$where requires a non-empty 'steps' arrayref"
		unless ref $steps eq 'ARRAY' && @$steps;

	my @ops;
	for my $i ( 0 .. $#$steps ) {
		my $step = $steps->[$i];
		croak "chain munger$where: step[$i] must be a hashref"
			unless ref $step eq 'HASH';
		my $op = $step->{op};
		croak "chain munger$where: step[$i] has no 'op'"
			unless defined $op && length $op;
		my $mk = $CHAIN_OPS{$op}
			or croak "chain munger$where: step[$i] has unknown op '$op' (known: "
			. join( ', ', sort keys %CHAIN_OPS ) . ')';
		push @ops, $mk->( $step, $where );
	} ## end for my $i ( 0 .. $#$steps )
	return \@ops;
} ## end sub _chain_steps

# Validate and unpack the terminal spec; shared like _chain_steps.
sub _chain_terminal_spec {
	my ( $spec, $where ) = @_;
	my $then = $spec->{then};
	croak "chain munger$where requires a 'then' hashref -- the terminal munger that produces the number"
		unless ref $then eq 'HASH';
	my $name = $then->{munger};
	croak "chain munger$where: 'then' has no 'munger' name"
		unless defined $name && length $name;
	return ( $then, $name );
} ## end sub _chain_terminal_spec

sub _build_chain {
	my ( $spec, $where ) = @_;

	my $ops = _chain_steps( $spec, $where );
	my ( $then, $name ) = _chain_terminal_spec( $spec, $where );
	my $builder = $BUILDERS{$name}
		or croak "chain munger$where: unknown terminal munger '$name' (known: "
		. join( ', ', sort keys %BUILDERS ) . ')';
	my $term = $builder->( $then, "$where (chain terminal)" );

	return sub {
		my $s = defined $_[0] ? "$_[0]" : '';
		$s = $_->($s) for @$ops;
		return $term->($s);
	};
} ## end sub _build_chain

# Multi-output chain: the same pre-transforms, but the terminal is one of the
# multi-output ('into') mungers. Returns ($list_returning_code, $arity) like
# every multi builder; the arity is the terminal's.
sub _build_chain_multi {
	my ( $spec, $where ) = @_;

	my $ops = _chain_steps( $spec, $where );
	my ( $then, $name ) = _chain_terminal_spec( $spec, $where );
	my $builder = $MULTI_BUILDERS{$name}
		or croak "chain munger$where: terminal munger '$name' does not support "
		. "multiple outputs ('into'); only these do: "
		. join( ', ', sort keys %MULTI_BUILDERS );
	my ( $term, $arity ) = $builder->( $then, "$where (chain terminal)" );

	my $code = sub {
		my $s = defined $_[0] ? "$_[0]" : '';
		$s = $_->($s) for @$ops;
		return $term->($s);
	};
	return ( $code, $arity );
} ## end sub _build_chain_multi

=head2 eps

    { munger => 'eps', prefix => 'http-req:', from => 'src_ip' }
    { munger => 'eps', prefix => 'dns-nxd:',  from => 'src_ip',
      read => 'rate', mark => 0 }
    # multi-output: one daemon round trip fills several columns
    { munger => 'eps', prefix => 'http-req:', from => 'src_ip',
      parts => [ 'rate', 'count' ], into => [ 'req_rate', 'req_count' ] }

Per-entity sliding-window event rates via the C<iqbi-damiq> daemon shipped with
L<Algorithm::EventsPerSecond> (see
L<Algorithm::EventsPerSecond::Sukkal>). The input value becomes a meter B<key>
(after C<prefix> is prepended); by default the munger B<marks> one event against
that key and returns the key's current events-per-second, using the daemon's
C<MARKRATE> command -- mark and query in a single command with a single reply.
This is the munger behind rate columns like a per-source request rate: every
event marks its source's meter and stores the rate the meter now reads.

Unlike every other munger this one consults external state -- but the state
lives in the daemon, not here, so the munger itself remains a stateless client
and rows stay reproducible I<given> the daemon. Because the daemon is shared,
multiple writer processes marking the same keys see one B<global> rate, which an
in-process meter could never give.

Spec keys:

=over 4

=item * C<socket> - unix socket path of the daemon. Defaults to
C<$Algorithm::ToNumberMunger::EPS_SOCKET>
(C</var/run/iqbi-damiq.sock>).

=item * C<prefix> - string prepended to the input to form the key, namespacing
this column's meters (two columns keyed on the same field need different
prefixes or they share meters). No whitespace/control characters. Default C<''>.

=item * C<mark> - whether to mark the key (default C<1>). Marking rides
C<MARKRATE>: with C<< read => 'rate' >> that one command is the whole exchange;
with C<count>/C<total> the read is pipelined after it (the C<MARKRATE> rate
reply is discarded), so a marking failure still comes back as an ordinary
first reply. With C<< mark => 0 >> the munger only reads, for columns whose
marking is done elsewhere -- e.g. an NXDOMAIN rate is I<marked> by the pipeline
only on NXDOMAIN responses but I<read> on every row.

=item * C<read> - what to read: C<rate> (events/sec over the daemon's window,
default), C<count> (events inside the window), or C<total> (lifetime).

=item * C<parts> + C<into> - multi-output form (see L</compile>): read several
of C<rate>/C<count>/C<total> for the one key in a single round trip, filling one
column each. When marking, the C<MARKRATE> reply itself serves the first C<rate>
part, so C<< parts => ['rate', 'count'] >> costs exactly two commands.

=item * C<on_error> - C<'die'> (default) croaks the write when the daemon is
unreachable or replies C<ERR>; a number is returned instead as a quiet fallback.
Note C<0> is indistinguishable from a genuinely idle key, so quiet fallback
biases the column -- loud is the default on purpose.

=item * C<timeout> - per-operation socket timeout in seconds (default 5,
best-effort via C<SO_RCVTIMEO>/C<SO_SNDTIMEO>), so a wedged daemon cannot hang a
writer forever.

=back

Semantics worth knowing: a marked read B<includes the event just marked>; keys
have whitespace/control bytes replaced with C<_> to satisfy the daemon's key
rules; connections are made lazily on first use and kept open (reconnecting
transparently after a fork or an error), so compiling a plan -- including the
eager validation in C<write_info> -- needs no running daemon. Each eps column
costs one unix-socket round trip per row; the multi-output form exists so
rate+count of the same key costs one round trip, not two.

=cut

# Default socket path of the iqbi-damiq daemon.
our $EPS_SOCKET = '/var/run/iqbi-damiq.sock';

# Persistent daemon connections, keyed by socket path, shared by every eps
# munger in the process. Entries record the pid that opened them so a forked
# writer transparently reopens instead of sharing a socket with its parent.
# Connections are made lazily on first use -- never at munger build time, so a
# plan can compile (eager validation) with no daemon running.
my %EPS_CONN;

sub _eps_conn {
	my ( $path, $timeout ) = @_;
	my $c = $EPS_CONN{$path};
	return $c->{fh} if $c && $c->{pid} == $$;

	require Socket;
	require IO::Socket::UNIX;
	my $fh = IO::Socket::UNIX->new(
		Type => Socket::SOCK_STREAM(),
		Peer => $path,
	) or die "cannot connect to iqbi-damiq at $path: $!\n";

	# Best-effort read/write timeouts so a wedged daemon cannot hang a writer.
	eval {
		my $tv = pack( 'l!l!', $timeout, 0 );
		setsockopt( $fh, Socket::SOL_SOCKET(), Socket::SO_RCVTIMEO(), $tv );
		setsockopt( $fh, Socket::SOL_SOCKET(), Socket::SO_SNDTIMEO(), $tv );
	};

	$EPS_CONN{$path} = { fh => $fh, pid => $$ };
	return $fh;
} ## end sub _eps_conn

# One pipelined transaction: send $cmd (possibly several lines) and read
# $nreplies "OK n" lines, one per command sent. The munger only ever sends
# commands that reply exactly once -- MARKRATE (which marks AND returns the
# rate in one go), RATE, COUNT, TOTAL; never a bare MARK, whose reply-only-on-
# error behavior would let a failure desynchronize the reply stream. Dies on
# ERR, EOF, or timeout; the caller still drops the cached connection on error
# as belt and braces.
sub _eps_txn {
	my ( $path, $timeout, $cmd, $nreplies ) = @_;
	my $fh = _eps_conn( $path, $timeout );
	print {$fh} $cmd or die "write to iqbi-damiq failed: $!\n";
	my @out;
	for ( 1 .. $nreplies ) {
		my $reply = <$fh>;
		die "iqbi-damiq closed the connection (or timed out)\n"
			unless defined $reply;
		$reply =~ /\AOK (\S+)/
			or die "iqbi-damiq replied: $reply";
		push @out, $1 + 0;
	}
	return @out;
} ## end sub _eps_txn

# Validate the spec keys shared by the scalar and multi-output eps builders.
sub _eps_spec {
	my ( $spec, $where ) = @_;

	my $socket = defined $spec->{socket} ? $spec->{socket} : $EPS_SOCKET;
	croak "eps munger$where: 'socket' must be a non-empty path"
		unless length $socket;

	my $prefix = defined $spec->{prefix} ? $spec->{prefix} : '';
	croak "eps munger$where: 'prefix' may not contain whitespace or control " . 'characters'
		if $prefix =~ /[\s[:cntrl:]]/;

	my $mark = exists $spec->{mark} ? ( $spec->{mark} ? 1 : 0 ) : 1;

	my $timeout = defined $spec->{timeout} ? $spec->{timeout} : 5;
	croak "eps munger$where: 'timeout' must be a positive number"
		unless looks_like_number($timeout) && $timeout > 0;

	my $on_error = defined $spec->{on_error} ? $spec->{on_error} : 'die';
	croak "eps munger$where: 'on_error' must be 'die' or a number"
		unless $on_error eq 'die' || looks_like_number($on_error);

	return ( $socket, $prefix, $mark, $timeout, $on_error );
} ## end sub _eps_spec

my %EPS_READ = map { $_ => 1 } qw(rate count total);

sub _build_eps {
	my ( $spec, $where ) = @_;

	croak "eps munger$where: 'parts' is for the multi-output form (needs " . "'into'); use 'read' for a single column"
		if defined $spec->{parts};

	my ( $socket, $prefix, $mark, $timeout, $on_error ) = _eps_spec( $spec, $where );

	my $read = defined $spec->{read} ? $spec->{read} : 'rate';
	croak "eps munger$where: unknown read '$read' (known: " . join( ', ', sort keys %EPS_READ ) . ')'
		unless $EPS_READ{$read};

	# Command plan, fixed at build time. The common case -- mark and read the
	# rate -- is the daemon's single MARKRATE command. mark+count/total rides
	# MARKRATE too (its rate reply is discarded) so marking failures come back
	# as an ordinary first reply instead of a bare MARK's error-only surprise.
	my @cmds
		= !$mark          ? ( uc $read )
		: $read eq 'rate' ? ('MARKRATE')
		:                   ( 'MARKRATE', uc $read );

	return sub {
		my ($v) = @_;
		my $key = $prefix . ( defined $v ? "$v" : '' );
		$key =~ s/[\s[:cntrl:]]/_/g;
		my @replies = eval {
			die "empty key\n" unless length $key;
			_eps_txn( $socket, $timeout, join( '', map { "$_ $key\n" } @cmds ), scalar @cmds );
		};
		if ($@) {
			my $err = $@;
			delete $EPS_CONN{$socket};    # reconnect fresh next call
			croak "eps munger$where: $err" if $on_error eq 'die';
			return $on_error + 0;
		}
		return $replies[-1];              # the requested read is always the last reply
	}; ## end sub
} ## end sub _build_eps

# Multi-output eps: one key, several reads (rate/count/total), one round trip.
# Returns ($list_returning_code, $arity) for compile()'s 'into' check.
sub _build_eps_multi {
	my ( $spec, $where ) = @_;

	my $parts = $spec->{parts};
	croak "eps munger$where: 'parts' must be a non-empty arrayref"
		unless ref $parts eq 'ARRAY' && @$parts;
	for my $p (@$parts) {
		croak "eps munger$where: unknown part '"
			. ( defined $p ? $p : 'undef' )
			. "' (known: "
			. join( ', ', sort keys %EPS_READ ) . ')'
			unless defined $p && $EPS_READ{$p};
	}

	my ( $socket, $prefix, $mark, $timeout, $on_error ) = _eps_spec( $spec, $where );

	# Command plan, fixed at build time. When marking, the mark is a MARKRATE
	# whose own reply serves the first 'rate' part for free; the remaining
	# parts become one read command each. @take maps each part to the reply
	# index that answers it, so the output stays in 'parts' order.
	my ( @cmds, @take );
	my $rate_served = 0;
	push @cmds, 'MARKRATE' if $mark;
	for my $i ( 0 .. $#$parts ) {
		if ( $mark && !$rate_served && $parts->[$i] eq 'rate' ) {
			$take[$i] = 0;       # MARKRATE's reply is the rate
			$rate_served = 1;
			next;
		}
		push @cmds, uc $parts->[$i];
		$take[$i] = $#cmds;
	}
	my $n        = @$parts;
	my $nreplies = @cmds;

	my $code = sub {
		my ($v) = @_;
		my $key = $prefix . ( defined $v ? "$v" : '' );
		$key =~ s/[\s[:cntrl:]]/_/g;
		my @replies = eval {
			die "empty key\n" unless length $key;
			_eps_txn( $socket, $timeout, join( '', map { "$_ $key\n" } @cmds ), $nreplies );
		};
		if ($@) {
			my $err = $@;
			delete $EPS_CONN{$socket};
			croak "eps munger$where: $err" if $on_error eq 'die';
			return ( $on_error + 0 ) x $n;
		}
		return @replies[@take];
	}; ## end $code = sub
	return ( $code, $n );
} ## end sub _build_eps_multi

# A compiled munging plan for one set, produced by Mungers->compile. It turns an
# input record into a fully-numeric row in tags order; the Writer then only has
# to validate and append. Kept in its own package so the assembly logic is
# testable without a Writer or the filesystem.
package Algorithm::ToNumberMunger::Plan;

use strict;
use warnings;
use Carp qw(croak);

sub tags { return $_[0]->{tags} }

# Assemble a row from a name-keyed record. Scalar/raw columns read their own tag
# (or the munger's 'from'); expanding mungers read one source and fill several
# columns; combining mungers read several sources and fill one. This is the only
# form that supports expanders and combiners.
sub apply_named {
	my ( $self, $hash ) = @_;
	croak 'apply_named requires a hashref' unless ref $hash eq 'HASH';

	my @row;
	for my $s ( @{ $self->{scalar} } ) {
		croak "missing value for '$s->{from}'"
			unless exists $hash->{ $s->{from} };
		my $v = $hash->{ $s->{from} };
		$row[ $self->{pos}{ $s->{tag} } ] = $s->{code} ? $s->{code}->($v) : $v;
	}

	for my $e ( @{ $self->{expand} } ) {
		croak "missing value for '$e->{from}'"
			unless exists $hash->{ $e->{from} };
		my @vals = $e->{code}->( $hash->{ $e->{from} } );
		croak "expanding munger for [@{ $e->{into} }] returned "
			. scalar(@vals)
			. ' value(s), expected '
			. scalar( @{ $e->{into} } )
			unless @vals == @{ $e->{into} };
		for my $i ( 0 .. $#{ $e->{into} } ) {
			$row[ $self->{pos}{ $e->{into}[$i] } ] = $vals[$i];
		}
	} ## end for my $e ( @{ $self->{expand} } )

	for my $c ( @{ $self->{combine} } ) {
		my @vals;
		for my $f ( @{ $c->{from} } ) {
			croak "missing value for '$f'"
				unless exists $hash->{$f};
			push @vals, $hash->{$f};
		}
		$row[ $self->{pos}{ $c->{tag} } ] = $c->{code}->(@vals);
	}

	return \@row;
} ## end sub apply_named

# Assemble a row from an already-ordered positional row, applying scalar mungers
# in place. Expanding and combining mungers cannot be expressed positionally
# (there is no named source), so a set that has any is a hard error here -- use
# apply_named.
sub apply_positional {
	my ( $self, $row ) = @_;
	croak 'apply_positional requires an arrayref row' unless ref $row eq 'ARRAY';
	croak 'positional write is unsupported for a set with expanding mungers; ' . 'use write_named'
		if @{ $self->{expand} };
	croak 'positional write is unsupported for a set with multi-input mungers; ' . 'use write_named'
		if @{ $self->{combine} };
	croak 'row has ' . scalar(@$row) . ' fields but info.json declares ' . scalar( @{ $self->{tags} } )
		unless @$row == @{ $self->{tags} };

	my @out = @$row;
	for my $s ( @{ $self->{scalar} } ) {
		next unless $s->{code};
		my $i = $self->{pos}{ $s->{tag} };
		$out[$i] = $s->{code}->( $out[$i] );
	}
	return \@out;
} ## end sub apply_positional

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1;    # End of Algorithm::ToNumberMunger
