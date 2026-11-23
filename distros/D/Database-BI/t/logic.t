use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use Readonly;
use Hash::Util qw(lock_keys);

# ---------------------------------------------------------------------------
# Logic tests: the boolean gates, invariants and refusals of the modules,
# proved by exhausting the truth table of each gate (not by sampling), by
# checking the law that relates two ways of writing it (De Morgan,
# complement, partition, trichotomy), and by feeding the contradictions the
# documented rules forbid.
#
# Method.  For a gate G over inputs A, B, ...: each input has a small set of
# classes (true-making, and one or more false-making).  Every combination of
# classes is built and run, and the observed result is compared with the
# result of the gate written in the other form.  A mismatch names the
# combination.  Contradictory inputs must be refused by the guard that owns
# them, with its exact message.
# ---------------------------------------------------------------------------

Readonly my %CONFIG => (
	rounds     => 10_000,	# the least Password accepts
	salt       => 'S' x 16,
	login_min  => 60,
	secret_min => 16,
);

Test::Mojo->new('Database::BI');	# loads the application modules after CHECK
require Database::BI::Password;
require Database::BI::SafeUA;
require Database::BI::Calc;
require Database::BI::Util;
require Database::BI::I18N;
require Database::BI::Model::Boundary;
require Database::BI::Model::Geocode;

my $FILTER = \&Database::BI::Controller::Dashboard::_apply_filter_spec;
my $message_of = sub { my ($code) = @_; local $@; return eval { $code->(); 1 } ? undef : ($@ =~ s/ at \S+ line \d+\.?\n?\z//r) };

# Every combination of one class from each list, as an array of picks.
sub product {
	my @lists = @_;
	my @rows = ([]);
	for my $list (@lists) {
		@rows = map { my $row = $_; map { [ @{$row}, $_ ] } @{$list} } @rows;
	}
	return @rows;
}

# ===========================================================================
# 1. verify_password: yes = A and B and C and D and E
#    A defined, B not a reference, C not empty, D no trailing NUL,
#    E the stored value is a hash.  Contrapositive (De Morgan): no = not A
#    or not B or not C or not D or not E.  Only the all-true row may say yes.
# ===========================================================================
subtest 'verify_password: one false premise is enough to refuse (De Morgan over five gates)' => sub {
	my $good = Database::BI::Password::hash_password('secret', rounds => $CONFIG{rounds}, salt => $CONFIG{salt});
	# Each class is [ label, value, is_true_making ].
	my @password_classes = (
		[ 'right', 'secret', 1 ], [ 'undef', undef, 0 ], [ 'reference', [], 0 ],
		[ 'empty', '', 0 ], [ 'trailing NUL', "secret\0", 0 ], [ 'wrong text', 'Secret', 0 ],
	);
	my @hash_classes = ([ 'a hash', $good, 1 ], [ 'text', 'secret', 0 ], [ 'undef', undef, 0 ], [ 'near miss', "$good\n", 0 ]);
	for my $combo (product(\@password_classes, \@hash_classes)) {
		my ($pw, $hash) = @{$combo};
		my $all_true  = $pw->[2] && $hash->[2];
		my $any_false = !$pw->[2] || !$hash->[2];	# De Morgan of the line above
		my $got = Database::BI::Password::verify_password($pw->[1], $hash->[1]);
		is $got, ($all_true ? 1 : 0), "password $pw->[0] with $hash->[0]: " . ($all_true ? 'yes' : 'no');
		ok $got == !$any_false, '... and equals the negated any-false form';
	}
};

subtest 'hash and verify: verify(p, hash(p)) is true and verify(q, hash(p)) is false for q ne p' => sub {
	# Invariant: a hash accepts exactly the password it was made from.
	my @passwords = ('a', 'secret', 'p' x 63, 'p' x 64, 'p' x 65, "M\x{FC}ller", "x\0y");
	for my $p (@passwords) {
		my $hash = Database::BI::Password::hash_password($p, rounds => $CONFIG{rounds}, salt => $CONFIG{salt});
		is Database::BI::Password::verify_password($p, $hash), 1, 'accepts its own password (' . length($p) . ' chars)';
		for my $q (grep { $_ ne $p } @passwords) {
			is Database::BI::Password::verify_password($q, $hash), 0, 'refuses another password' or last;
		}
		is Database::BI::Password::is_password_hash($hash), 1, 'and a made hash is a hash';
	}
	# Two salts: the same password, two hashes, each verifying.
	my @pair = map { Database::BI::Password::hash_password('same', rounds => $CONFIG{rounds}, salt => $_ x 16) } qw(A B);
	isnt $pair[0], $pair[1], 'different salts give different hashes';
	ok Database::BI::Password::verify_password('same', $_), 'and each verifies' for @pair;
};

subtest 'hash_password: contradictions of its premises fail at the first guard' => sub {
	# The order of the guards is part of the rule: password, then rounds, then salt.
	my $pw  = 'hash_password: a password is required';
	my $rnd = sprintf('hash_password: rounds must be a whole number from %d to %d', 10_000, 100_000_000);
	my $slt = 'hash_password: a salt is 16 bytes';
	is $message_of->(sub { Database::BI::Password::hash_password('', rounds => 1, salt => 'x') }), $pw, 'bad password and bad rounds and bad salt: the password is named';
	is $message_of->(sub { Database::BI::Password::hash_password('x', rounds => 1, salt => 'x') }), $rnd, 'bad rounds and bad salt: the rounds are named';
	is $message_of->(sub { Database::BI::Password::hash_password('x', rounds => 10_000, salt => 'x') }), $slt, 'only the salt bad: the salt is named';
	is $message_of->(sub { Database::BI::Password::hash_password("x\0", rounds => 1, salt => 'x') }), 'hash_password: a password may not end in a NUL byte', 'a NUL-ended password is refused before rounds are looked at';
};

# ===========================================================================
# 2. private_host_allowed: yes = exact or (wildcard and longer and ends-with)
#    The wildcard "*.s" matches host h iff length(h) > length(".s") and h ends
#    with ".s": a subdomain, never the bare suffix or a longer look-alike.
# ===========================================================================
subtest 'private_host_allowed: the wildcard gate is the conjunction of its two tests' => sub {
	my $ua = Database::BI::SafeUA->new(private_hosts => [ '*.corp.example', 'Intranet' ]);
	my $suffix = '.corp.example';
	my @hosts = ('a.corp.example', 'A.CORP.EXAMPLE', 'x.y.corp.example', 'corp.example', '.corp.example', 'evilcorp.example',
		'a.corp.example.evil', 'intranet', 'INTRANET', 'intranet2', '', undef);
	for my $host (@hosts) {
		my $h = lc($host // '');
		my $exact    = $h eq 'intranet';
		my $longer   = length($h) > length($suffix);
		my $endswith = length($h) >= length($suffix) && substr($h, -length($suffix)) eq $suffix;
		my $expected = ($exact || ($longer && $endswith)) ? 1 : 0;
		# De Morgan: not allowed = not exact and (not longer or not ends-with)
		my $negated  = (!$exact && (!$longer || !$endswith)) ? 1 : 0;
		is $ua->private_host_allowed($host), $expected, 'host ' . ($host // 'undef') . ' gives ' . $expected;
		is $expected, 1 - $negated, '... and the negated form agrees';
	}
	# Contradiction: a list naming a host as a bare suffix "corp.example" does not
	# allow the subdomain, and vice versa: the two forms are different premises.
	my $bare = Database::BI::SafeUA->new(private_hosts => ['corp.example']);
	is $bare->private_host_allowed('a.corp.example'), 0, 'a bare name allows only itself';
	is $bare->private_host_allowed('corp.example'), 1, '... which it does allow';
};

# ===========================================================================
# 3. blocked_address: the IPv4-in-IPv6 premise.  An address written as
#    ::ffff:a.b.c.d (mapped) or 64:ff9b::a.b.c.d (NAT64) reaches a.b.c.d, so it
#    is blocked exactly when a.b.c.d is.  Equivalence: blocked(f(x)) = blocked(x).
# ===========================================================================
subtest 'blocked_address: an IPv4 address and its IPv6 spellings are blocked together' => sub {
	my $blocked = \&Database::BI::SafeUA::blocked_address;
	my @v4 = ('10.0.0.1', '127.0.0.1', '169.254.169.254', '192.168.1.1', '172.16.0.1', '172.31.255.255', '172.32.0.1', '172.15.0.1',
		'8.8.8.8', '1.1.1.1', '100.64.0.1', '224.0.0.1', '255.255.255.255', '0.0.0.0', '203.0.113.5', '198.51.100.7');
	for my $v4 (@v4) {
		my $plain = defined $blocked->($v4) ? 1 : 0;
		my ($a, $b, $c, $d) = split /\./, $v4;
		my $hex = sprintf('%02x%02x:%02x%02x', $a, $b, $c, $d);
		my %spelling = (
			mapped      => "::ffff:$v4",
			mapped_hex  => "::ffff:$hex",
			nat64       => "64:ff9b::$v4",
			sixtofour   => sprintf('2002:%02x%02x:%02x%02x::', $a, $b, $c, $d),
		);
		for my $kind (sort keys %spelling) {
			is defined($blocked->($spelling{$kind})) ? 1 : 0, $plain, "$v4 as $kind ($spelling{$kind}) is blocked iff the plain address is";
		}
	}
	# Complement: for the private ranges the plain address is blocked, so its
	# negation (public) is false; the public ones are the other way round.
	for my $v4 (@v4) {
		my $is_public = !defined($blocked->($v4));
		my %public = map { $_ => 1 } ('8.8.8.8', '1.1.1.1', '172.32.0.1', '172.15.0.1');
		is $is_public ? 1 : 0, $public{$v4} ? 1 : 0, "$v4 is " . ($public{$v4} ? 'public' : 'refused');
	}
};

subtest 'numeric_host: every spelling of one address is that address (the same value, written five ways)' => sub {
	my $numeric = \&Database::BI::SafeUA::numeric_host;
	my %spellings = (
		'127.0.0.1' => [ '127.0.0.1', '2130706433', '0x7f000001', '0177.0.0.1', '127.1', '0x7f.0.0.1' ],
		'10.0.0.5'  => [ '10.0.0.5', '167772165', '0xa000005', '012.0.0.5', '10.5' ],
		'8.8.8.8'   => [ '8.8.8.8', '134744072', '0x8080808', '010.8.8.8' ],
	);
	for my $address (sort keys %spellings) {
		for my $spelling (@{ $spellings{$address} }) {
			is $numeric->($spelling), $address, "$spelling is $address";
		}
	}
	# Consequence: whatever the spelling, the blocking decision is one decision.
	for my $address (sort keys %spellings) {
		my %verdicts = map { (defined(Database::BI::SafeUA::blocked_address($numeric->($_))) ? 'blocked' : 'public') => 1 } @{ $spellings{$address} };
		is scalar(keys %verdicts), 1, "all spellings of $address get one verdict";
	}
};

# ===========================================================================
# 4. point_key: valid = lat_ok and lon_ok, where each is
#    defined and plain-decimal and within range.  Exhaust 5 classes each.
# ===========================================================================
subtest 'point_key: a key exists exactly when both coordinates are valid (25 combinations)' => sub {
	my @lat = ([ 'valid', 45, 1 ], [ 'edge', 90, 1 ], [ 'undef', undef, 0 ], [ 'format', '4e1', 0 ], [ 'range', 91, 0 ]);
	my @lon = ([ 'valid', 100, 1 ], [ 'edge', -180, 1 ], [ 'undef', undef, 0 ], [ 'format', ' 5', 0 ], [ 'range', 181, 0 ]);
	for my $combo (product(\@lat, \@lon)) {
		my ($lat, $lon) = @{$combo};
		my $expect = $lat->[2] && $lon->[2];
		my $key = Database::BI::Model::Boundary->point_key($lat->[1], $lon->[1]);
		is defined($key) ? 1 : 0, $expect ? 1 : 0, "lat $lat->[0], lon $lon->[0]: " . ($expect ? 'a key' : 'no key');
		# Invariant: a key is itself a point that gives the same key.
		if (defined $key) {
			my ($la, $lo) = split /,/, $key;
			is(Database::BI::Model::Boundary->point_key($la, $lo), $key, '... and the key of a key is the key (idempotent)');
		}
	}
	# Symmetry: the sign of zero never makes two keys.
	is(Database::BI::Model::Boundary->point_key(-0.0001, -0.0001), Database::BI::Model::Boundary->point_key(0, 0), 'minus a tiny amount is the same point as zero');
};

subtest 'check_ranks: lower-casing is idempotent and the gates are a conjunction' => sub {
	my $class = 'Database::BI::Model::Boundary';
	my $once  = $class->check_ranks({ LK => 10, In => '8', es => 12 });
	is_deeply $class->check_ranks($once), $once, 'applying it twice is applying it once';
	# code_ok and rank_ok and not duplicate: each combination.
	my @codes = ([ 'two letters', 'lk', 1 ], [ 'three', 'lka', 0 ]);
	my @ranks = ([ 'rank 10', 10, 1 ], [ 'rank 9', 9, 0 ]);
	for my $combo (product(\@codes, \@ranks)) {
		my ($code, $rank) = @{$combo};
		my $ok = eval { $class->check_ranks({ $code->[1] => $rank->[1] }); 1 } ? 1 : 0;
		is $ok, ($code->[2] && $rank->[2]) ? 1 : 0, "$code->[0] with $rank->[0]";
	}
	# The first guard that fails names the entry.
	is $message_of->(sub { $class->check_ranks({ abc => 9 }) }), "'abc' is not a two-letter country code", 'code before rank when both are bad';
	is $message_of->(sub { $class->check_ranks({ LK => 10, lk => 12 }) }), "'lk' is given twice", 'a duplicate in another case is a contradiction';
	is $message_of->(sub { $class->check_ranks([]) }), 'Boundary ranks must be a hash of country codes to place ranks', 'the table guard comes first';
};

# ===========================================================================
# 5. Startup checks: refuse = defined and (ref or not-digits or too-small).
# ===========================================================================
subtest '_check_login: refuse = defined and (reference or not digits or below 60)' => sub {
	my $check = \&Database::BI::_check_login;
	my @values = (
		[ 'undef', undef ], [ 'reference', [] ], [ 'text', 'abc' ], [ 'signed', '-60' ], [ 'fraction', '60.5' ],
		[ 'below', 59 ], [ 'edge', 60 ], [ 'above', 61 ], [ 'zero', 0 ], [ 'empty', '' ],
	);
	for my $case (@values) {
		my ($label, $v) = @{$case};
		my $defined = defined $v;
		my $ref     = ref $v ? 1 : 0;
		my $digits  = $defined && !ref($v) && $v =~ /\A[0-9]+\z/;
		my $small   = $digits && $v < $CONFIG{login_min};
		my $refuse  = $defined && ($ref || !$digits || $small);
		# De Morgan: accept = not defined or (not ref and digits and not small)
		my $accept  = !$defined || (!$ref && $digits && !$small);
		is $refuse ? 1 : 0, $accept ? 0 : 1, "$label: the two forms of the rule agree";
		my $got = $message_of->(sub { $check->(undef, $v) });
		is defined($got) ? 1 : 0, $refuse ? 1 : 0, "$label: " . ($refuse ? 'refused' : 'accepted');
	}
};

subtest '_check_share_secret: each guard fires alone, and in order' => sub {
	my $check = \&Database::BI::_check_share_secret;
	my %says = (
		ref     => 'share_secret: give a string of at least 16 characters, or leave it out',
		default => 'share_secret: that is the default from the source, which anyone can read; choose another',
		short   => 'share_secret: give at least 16 characters, so a share link cannot be forged by guessing it',
	);
	is $message_of->(sub { $check->([ 'x' ]) }), $says{ref}, 'a reference, however short, is named a reference first';
	is $message_of->(sub { $check->('BI_DEFAULT_INSECURE_SECRET') }), $says{default}, 'the old default is refused as the default, not as short';
	is $message_of->(sub { $check->('short') }), $says{short}, 'short';
	for my $ok (undef, '', 'x' x $CONFIG{secret_min}, 'y' x 40) {
		is $message_of->(sub { $check->($ok) }), undef, 'accepted: ' . (defined $ok ? length($ok) . ' chars' : 'undef');
	}
	# Boundary of the third gate: it is length < 16 that refuses.
	is defined($message_of->(sub { $check->('x' x ($CONFIG{secret_min} - 1)) })) ? 1 : 0, 1, '15 is refused';
	is defined($message_of->(sub { $check->('x' x $CONFIG{secret_min}) })) ? 1 : 0, 0, '16 is accepted';
};

# ===========================================================================
# 6. Filters: operators that are complements partition every table.
#    eq/ne, empty/notempty, lt/ge, gt/le, differ/(equal text): for every row
#    exactly one of the pair keeps it (excluded middle, and not both).
# ===========================================================================
subtest 'filter operators: complements split the rows into two disjoint sets that make the whole' => sub {
	my @rows = map { my %r = %{$_}; lock_keys(%r); \%r } (
		{ id => 1, n => '5',  s => 'North', e => 'x', a => 'p',  b => 'p' },
		{ id => 2, n => '10', s => 'north', e => '',  a => 'p',  b => 'q' },
		{ id => 3, n => '10', s => 'South', e => 'y', a => '',   b => '' },
		{ id => 4, n => '1',  s => 'N',     e => '',  a => undef, b => '' },
		{ id => 5, n => '10.0', s => '',    e => 'z', a => 'Q',  b => 'q' },
	);
	my $ids = sub { join ',', map { $_->{id} } @{ $FILTER->(\@rows, $_[0]) } };
	my %complement = (
		'n:eq:10'      => 'n:ne:10',
		's:eq:north'   => 's:ne:north',
		'e:empty:'     => 'e:notempty:',
		'n:lt:10'      => 'n:ge:10',
		'n:gt:5'       => 'n:le:5',
		'a:differ:b'   => undef,
	);
	for my $op (sort keys %complement) {
		my $comp = $complement{$op};
		my %kept = map { $_ => 1 } split /,/, $ids->($op);
		if (defined $comp) {
			my %other = map { $_ => 1 } split /,/, $ids->($comp);
			is_deeply [ sort grep { $kept{$_} && $other{$_} } 1 .. 5 ], [], "$op and $comp keep no row in common (not both)";
			is_deeply [ sort grep { $kept{$_} || $other{$_} } 1 .. 5 ], [ 1 .. 5 ], "$op and $comp together keep every row (excluded middle)";
		}
	}
	# differ is the complement of equal text, with the absent/undef/empty cells all equal.
	my %differ = map { $_ => 1 } split /,/, $ids->('a:differ:b');
	for my $row (@rows) {
		my ($ta, $tb) = map { $_ // '' } @{$row}{qw(a b)};
		is $differ{ $row->{id} } ? 1 : 0, ($ta ne $tb) ? 1 : 0, "row $row->{id}: kept iff the texts differ";
	}
	# Chaining filters is the intersection: a and b keep exactly the rows both keep.
	my %both = map { $_ => 1 } split /,/, $ids->('n:eq:10') ;
	my $chained = join ',', map { $_->{id} } @{ $FILTER->($FILTER->(\@rows, 'n:eq:10'), 's:ne:north') };
	my %expect_chain = map { $_ => 1 } grep { $both{$_} } split /,/, $ids->('s:ne:north');
	is $chained, join(',', sort { $a <=> $b } keys %expect_chain), 'filtering twice keeps what each keeps (and)';
};

# ===========================================================================
# 7. Calc comparisons: trichotomy and De Morgan over the expression language.
# ===========================================================================
subtest 'Calc: for numbers exactly one of <, =, > holds, and <= and != are their negations' => sub {
	my $run = sub {
		my ($expr, $row) = @_;
		my $calc = Database::BI::Calc->new(expr => $expr, columns => [qw(a b)]);
		is $calc->error, undef, "compiles: $expr" or return;
		return $calc->evaluate($row);
	};
	for my $pair ([ 1, 2 ], [ 2, 2 ], [ 3, 2 ], [ -1, 0 ], [ 0, 0 ], [ '1.5', '1.50' ], [ 10, 9 ]) {
		my %row = (a => $pair->[0], b => $pair->[1]);
		my ($lt, $eq, $gt, $le, $ge, $ne) = map { $run->($_, \%row) } ('a < b', 'a = b', 'a > b', 'a <= b', 'a >= b', 'a != b');
		is $lt + $eq + $gt, 1, "$pair->[0] vs $pair->[1]: exactly one of less, equal, greater";
		is $le, 1 - $gt, '<= is not >';
		is $ge, 1 - $lt, '>= is not <';
		is $ne, 1 - $eq, '!= is not =';
		# De Morgan through if(): not(a<b and b<a) always, and (a<=b and b<=a) iff a=b
		is $run->('if(a <= b, if(b <= a, 1, 0), 0)', \%row), $eq, '(a <= b and b <= a) iff a = b';
		is $run->('if(a < b, 1, if(a > b, 1, 0))', \%row), $ne, '(a < b or a > b) iff a != b';
	}
	# if() evaluates only the branch taken: the other may be undefined behaviour.
	is $run->('if(b = 0, 0, a / b)', { a => 1, b => 0 }), 0, 'the untaken branch (division by zero) is never evaluated';
	is $run->('a / b', { a => 1, b => 0 }), undef, 'taken, the same division is undef, not an error';
};

subtest 'Calc: isnull and coalesce are the definedness gate' => sub {
	my $calc = Database::BI::Calc->new(expr => 'isnull(a, b)', columns => [qw(a b)]);
	is $calc->evaluate({ a => 5, b => 9 }), 5, 'defined: the value';
	is $calc->evaluate({ a => undef, b => 9 }), 9, 'undefined: the default';
	is $calc->evaluate({ a => 0, b => 9 }), 0, 'zero is defined';
	is $calc->evaluate({ a => '', b => 9 }), '', 'empty is defined';
	my $first = Database::BI::Calc->new(expr => 'coalesce(a, b, 7)', columns => [qw(a b)]);
	is $first->evaluate({ a => undef, b => undef }), 7, 'all undefined: the last';
	is $first->evaluate({ a => undef, b => 3 }), 3, 'the first defined wins';
	# Contradiction: an expression naming a column that does not exist never compiles.
	my $bad = Database::BI::Calc->new(expr => 'a + nosuch', columns => ['a']);
	ok defined $bad->error, 'an unknown column is a compile error, caught before any row';
	is $bad->evaluate({ a => 1 }), undef, '... and evaluates nothing';
	my $assign = Database::BI::Calc->new(expr => 'a == b', columns => [qw(a b)]);
	ok defined $assign->error, '== is a compile error (use =)';
	my $long = Database::BI::Calc->new(expr => '1' . (' + 1' x 200), columns => []);
	ok defined $long->error, 'over 512 characters is refused';
};

# ===========================================================================
# 8. parse_number: the fast path and the full path are one function.
#    Premise: a plain ASCII decimal is read the same whether or not it takes
#    the shortcut.  A padded copy cannot take the shortcut.
# ===========================================================================
subtest 'parse_number: the shortcut and the full path agree, and signs obey algebra' => sub {
	my $num = \&Database::BI::Util::parse_number;
	for my $plain ('0', '7', '-7', '12', '-12.5', '3.14159', '1000000', '0.001', '123456789012345678', '9' x 300) {
		my $fast = $num->($plain);
		my $slow = $num->(" $plain ");	# the space sends it through the full path
		ok defined($fast) && defined($slow), "$plain is a number on both paths";
		is $slow, $fast, '... the same number';
	}
	# Accounting: (x) = -x for x > 0; and double negation is identity.
	for my $x ('5', '12.5', '1,234.50') {
		my $pos = $num->($x);
		is $num->("($x)"), -$pos, "($x) is minus $x";
		is $num->('-' . $x =~ s/,//gr), -$pos, "-$x is minus $x";
	}
	# Idempotence: reading a number that was read gives itself.
	for my $x ('1,234.5', '$99', '(7)', '45%', 'USD 7') {
		my $once = $num->($x);
		is $num->($once), $once, "$x: read twice is read once";
	}
	# Excluded middle: a value is a number or it is not, and a non-number stays one.
	for my $text ('abc', '1.2.3', '', 'T27', '2026-09-09') {
		is $num->($text), undef, "$text is not a number";
	}
};

# ===========================================================================
# 9. I18N: the closure invariant.  Whatever the input, the answer is one of
#    the supported languages; choice never leaves the set.
# ===========================================================================
subtest 'I18N::choose: the result always lies in languages() (closure), and defaults obey the same rule' => sub {
	my %supported = map { $_ => 1 } Database::BI::I18N::languages();
	my @accept  = (undef, '', 'en', 'en-US', 'en-GB', 'fr', 'de-DE,fr;q=0.5', '*', 'xx', "en\n", 'EN-us', 'en-US;q=0');
	my @default = (undef, 'en', 'en-us', 'fr', '', 'EN');
	for my $combo (product(\@accept, \@default)) {
		my ($accept, $default) = @{$combo};
		my $got = Database::BI::I18N::choose(accept => $accept, default => $default);
		ok $supported{$got}, 'accept ' . ($accept // 'undef') . ', default ' . ($default // 'undef') . " -> $got is supported";
	}
	# Modus ponens: with no usable header the answer is the default when it is supported, else en.
	for my $default (@default) {
		my $expect = (defined $default && $supported{$default}) ? $default : 'en';
		is Database::BI::I18N::choose(default => $default), $expect, 'no header, default ' . ($default // 'undef') . " -> $expect";
	}
};

# ===========================================================================
# 10. place_text: the three gates (reference, control character, length) and
#     the tidy step that precedes the length gate.
# ===========================================================================
subtest 'place_text: refuse = reference or control character or too long after tidying' => sub {
	my $text = sub { Database::BI::Model::Geocode->place_text(@_) };
	my @ref   = ([ 'plain', 'abc', 0 ], [ 'reference', [], 1 ]);
	my @ctrl  = ([ 'no control', '', 0 ], [ 'control', "\x01", 1 ]);
	my @len   = ([ 'short', 'x', 0 ], [ 'edge', 'x' x 200, 0 ], [ 'long', 'x' x 201, 1 ]);
	for my $combo (product(\@ref, \@ctrl, \@len)) {
		my ($r, $c, $l) = @{$combo};
		# The length class is the whole text; a control character replaces the last character, so the length is unchanged.
		my $text_value = $c->[2] ? substr($l->[1], 0, -1) . $c->[1] : $l->[1];
		my $value = ref $r->[1] ? $r->[1] : $text_value;
		my $refuse = $r->[2] || $c->[2] || $l->[2];
		my @got = $text->($value);
		is scalar(@got) ? 0 : 1, $refuse ? 1 : 0, "$r->[0] / $c->[0] / $l->[0]: " . ($refuse ? 'refused' : 'accepted');
	}
	# Tidy before count: padding does not push a text over the edge.
	is_deeply [ $text->(('x' x 200) . ' ' x 50) ], [ 'x' x 200 ], 'trailing spaces are not counted';
	is_deeply [ $text->(undef) ], [ '' ], 'undef is empty, not refused';
};

done_testing();
