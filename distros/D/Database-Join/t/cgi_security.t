use strict;
use warnings;

# ---------------------------------------------------------------------------
# t/cgi_security.t -- Application security pen-test for Database::Join
#
# Database::Join is a library (not a CGI script), but it is routinely
# consumed by CGI applications that receive untrusted user input and pass it
# as criteria to DJ query methods.  This file proves DJ's security properties
# from that attacker's perspective.
#
# Each subtest names the exploit mechanism it simulates, the attack vector,
# and the property being proved.
#
# Mock architecture:
#   MockSecDB_A: entry | name | tier    (primary database)
#   MockSecDB_B: entry | score          (secondary database)
#
# The mocks record every criteria hashref they receive, allowing us to assert
# partition isolation without any SQL or SQLite involvement.
# ---------------------------------------------------------------------------

use Test::Most;
use Readonly;

BEGIN {
	eval { require Database::Abstraction };
	plan skip_all => 'Database::Abstraction required' if $@;
	plan tests => 48;
}

use_ok('Database::Join');

# ---------------------------------------------------------------------------
# Readonly attack payloads -- no magic strings in test bodies
# ---------------------------------------------------------------------------
Readonly::Scalar my $SQL_INJECTION   => q{' OR '1'='1};
Readonly::Scalar my $DROP_TABLE      => q{'; DROP TABLE users; --};
Readonly::Scalar my $SHELL_META      => q{name; rm -rf /; echo bad};
Readonly::Scalar my $CRLF_INJECT     => "value\r\nX-Injected: evil";
Readonly::Scalar my $NULL_BYTE_COL   => "entry\x00bad";
Readonly::Scalar my $PATH_TRAVERSAL  => '../../../etc/passwd';
Readonly::Scalar my $OPERATOR_INJECT => q{' OR 1=1 --};

# ---------------------------------------------------------------------------
# Inline mock Database::Abstraction subclass.
# Records all criteria it receives; returns configurable rows.
# Inherits from Database::Abstraction purely for the isa() check.
# ---------------------------------------------------------------------------

## no critic (Modules::ProhibitMultiplePackages)
{
	package MockSecDB;
	use parent -norequire, 'Database::Abstraction';
}

sub MockSecDB::new {
	my ($class, %args) = @_;
	return bless {
		_cols      => $args{columns} // ['entry'],
		_rows      => $args{rows}    // [],
		_received  => [],   # all criteria hashrefs this DB was given
		_mutate_jc => $args{mutate_jc},  # optional: mutate join_column value on receipt
	}, $class;
}

# Capture the criteria slice; optionally mutate join_column to test aliasing.
sub MockSecDB::selectall_arrayref {
	my ($self, $criteria) = @_;
	push @{ $self->{_received} }, $criteria;

	# Simulate a malicious DA that mutates the join_column value when asked.
	# Used in the aliasing isolation test (T29).
	if ($self->{_mutate_jc} && ref($criteria) eq 'HASH' && exists $criteria->{entry}) {
		$criteria->{entry} = 'MUTATED_BY_EVIL_DA';
	}

	# Filter rows; supports equality and common operator hashrefs ({ '>' => N }).
	my @rows = @{ $self->{_rows} };
	for my $col (keys %{ $criteria // {} }) {
		my $val = $criteria->{$col};
		if (!defined $val) {
			next;   # undef criterion: no filtering (passthrough test)
		} elsif (ref($val) eq 'HASH') {
			for my $op (keys %{$val}) {
				my $threshold = $val->{$op};
				next unless defined $threshold && !ref($threshold);
				@rows = grep {
					my $rv = $_->{$col};
					defined($rv) && (
						$op eq '>'  ? $rv >  $threshold :
						$op eq '<'  ? $rv <  $threshold :
						$op eq '>=' ? $rv >= $threshold :
						$op eq '<=' ? $rv <= $threshold :
						$op eq '!=' ? $rv != $threshold :
						1
					)
				} @rows;
			}
		} else {
			@rows = grep { defined $_->{$col} && $_->{$col} eq $val } @rows;
		}
	}
	return \@rows;
}

sub MockSecDB::columns { return $_[0]->{_cols} }
sub MockSecDB::schema  {
	my $self = shift;
	return { map { $_ => { type => 'TEXT', nullable => 1, default => undef, pk => 0 } }
	         @{ $self->{_cols} } };
}
sub MockSecDB::updated    { return 1 }
sub MockSecDB::set_logger { return $_[0] }
sub MockSecDB::DESTROY    {}

# Accessor: what did the last query send to this DB?
sub MockSecDB::last_criteria { return $_[0]->{_received}[-1] // {} }
sub MockSecDB::clear         { $_[0]->{_received} = [] }

# ---------------------------------------------------------------------------
# Fixture factory -- build a fresh two-database join for each test section.
# Primary (index 0): columns entry | name | tier
# Secondary (index 1): columns entry | score
# ---------------------------------------------------------------------------

sub make_dbs {
	my $db_a = MockSecDB->new(
		columns => [qw(entry name tier)],
		rows    => [
			{ entry => 'A1', name => 'Alice', tier => 'gold'   },
			{ entry => 'A2', name => 'Bob',   tier => 'silver' },
		],
		@_,
	);
	my $db_b = MockSecDB->new(
		columns => [qw(entry score)],
		rows    => [
			{ entry => 'A1', score => 95 },
			{ entry => 'A2', score => 70 },
		],
	);
	return ($db_a, $db_b);
}

sub make_join {
	my ($db_a, $db_b, %opts) = @_;
	return Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => 'entry',
		%opts,
	);
}

# ===========================================================================
# SECTION 1 -- Criteria Partition Isolation
#
# Major Premise: _partition_criteria routes each criterion to exactly one
#   database (or all databases for the join_column).
# Proof method: MockSecDB records every hashref it receives; we assert which
#   keys appear in each DB's received criteria.
# ===========================================================================

# Test 1
# Exploit: SQL injection value injected into a primary-column criterion.
# Attack vector: QUERY_STRING ?name='; DROP TABLE users; --
# MP: name is owned by DB_A (primary).  DB_B must never receive 'name'.
# C: DB_A receives {name => $DROP_TABLE}; DB_B receives {} (no criteria).
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	$join->selectall_arrayref(name => $DROP_TABLE);

	ok(exists $db_a->last_criteria->{name},
		'isolation: SQL injection in primary col reaches primary DB only');
	ok(!exists $db_b->last_criteria->{name},
		'isolation: SQL injection in primary col does NOT reach secondary DB');
}

# Test 2
# Exploit: SQL injection value injected into a secondary-column criterion.
# Attack vector: QUERY_STRING ?score=0 OR 1=1 --
# MP: score is owned by DB_B (secondary).  DB_A must never receive 'score'.
# C: DB_B receives {score => $SQL_INJECTION}; DB_A receives {}.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	$join->selectall_arrayref(score => $SQL_INJECTION);

	ok(!exists $db_a->last_criteria->{score},
		'isolation: SQL injection in secondary col does NOT reach primary DB');
	ok(exists $db_b->last_criteria->{score},
		'isolation: SQL injection in secondary col reaches secondary DB only');
}

# Test 3
# Exploit: join_column criterion (broadcast path).
# Attack vector: QUERY_STRING ?entry='; DROP TABLE; --
# MP: join_column criteria are broadcast to ALL databases so each can
#   filter its own rows.  This is intentional and unavoidable.
# C: both DB_A and DB_B receive {entry => $DROP_TABLE}.
# Security note: value sanitisation is DA's responsibility, not DJ's.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	$join->selectall_arrayref(entry => $DROP_TABLE);

	is($db_a->last_criteria->{entry}, $DROP_TABLE,
		'broadcast: join_col criterion reaches primary DB faithfully');
	is($db_b->last_criteria->{entry}, $DROP_TABLE,
		'broadcast: join_col criterion reaches secondary DB faithfully');
}

# Test 4
# Exploit: hostile column name containing shell metacharacters.
# Attack vector: QUERY_STRING ?name;rm+-rf+/=val (decoded: 'name;rm -rf /' => 'val')
# MP: _partition_criteria looks up the column in _col_db.  A column name that
#   is not in _col_db falls to the carp+drop branch.
# C: NO database receives the hostile key.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	local $SIG{__WARN__} = sub {};   # suppress expected carp
	$join->selectall_arrayref($SHELL_META => 'val');

	ok(!exists $db_a->last_criteria->{$SHELL_META},
		'rejection: hostile column name (shell chars) not sent to primary DB');
	ok(!exists $db_b->last_criteria->{$SHELL_META},
		'rejection: hostile column name (shell chars) not sent to secondary DB');
}

# Test 5
# Exploit: null byte injected into a column name.
# Attack vector: CGI param key containing %00 (null byte after decoding).
# MP: same as Test 4 -- null byte column is unknown to _col_db.
# C: NO database receives the null-byte key.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	local $SIG{__WARN__} = sub {};
	$join->selectall_arrayref($NULL_BYTE_COL => 'val');

	ok(!exists $db_a->last_criteria->{$NULL_BYTE_COL},
		'rejection: null-byte column name not sent to primary DB');
	ok(!exists $db_b->last_criteria->{$NULL_BYTE_COL},
		'rejection: null-byte column name not sent to secondary DB');
}

# Test 6
# Exploit: CRLF injection inside a criteria VALUE (e.g. for header injection).
# Attack vector: HTTP_USER_AGENT reflected in criteria value; CRLF in value
#   could split HTTP headers if DJ ever reflected the value into a response.
# MP: DJ never generates HTTP responses.  It passes the value verbatim to DA.
# C: DB_A receives the exact CRLF-containing value, unmodified and unescaped.
#   (Proving DJ is transparent -- CGI layer must handle encoding.)
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	$join->selectall_arrayref(name => $CRLF_INJECT);

	is($db_a->last_criteria->{name}, $CRLF_INJECT,
		'passthrough: CRLF in value passed verbatim to owning DB (CGI layer must encode)');
}

# Test 7
# Exploit: operator hashref with a hostile operator key (SQL fragment as key).
# Attack vector: { score => { "' OR 1=1 --" => 1 } } hoping DJ constructs SQL.
# MP: DJ never constructs SQL.  It passes operator hashrefs to DA intact.
# MP: The operator hashref goes only to the DB that owns 'score' (DB_B).
# C: DB_B receives the exact hashref; DB_A receives no score criterion.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	my $hostile_op = { $OPERATOR_INJECT => 1 };
	$join->selectall_arrayref(score => $hostile_op);

	is_deeply($db_b->last_criteria->{score}, $hostile_op,
		'passthrough: hostile operator hashref passed intact to owning DB');
	ok(!exists $db_a->last_criteria->{score},
		'isolation: hostile operator hashref does NOT reach primary DB');
}

# Test 8
# Exploit: two simultaneous hostile criteria -- one per database.
# Attack vector: ?name=INJECT1&score=INJECT2
# MP: each criterion is routed to exactly its owning DB.
# C: DB_A receives only {name => INJECT1, entry broadcast} and NOT score.
#    DB_B receives only {score => INJECT2, entry broadcast} and NOT name.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	$join->selectall_arrayref(name => $SQL_INJECTION, score => $DROP_TABLE);

	ok( exists $db_a->last_criteria->{name}  && !exists $db_a->last_criteria->{score},
		'isolation: two hostile criteria each reach only their owning DB (primary)');
	ok(!exists $db_b->last_criteria->{name}  &&  exists $db_b->last_criteria->{score},
		'isolation: two hostile criteria each reach only their owning DB (secondary)');
}

# ===========================================================================
# SECTION 2 -- Type Confusion Attacks
# ===========================================================================

# Test 9
# Exploit: blessed object as a criteria value; attacker hopes DJ treats it as
#   an operator hashref { op => val } and passes the object's methods as SQL.
# MP: _merge_criteria checks ref($val) eq 'HASH'.  blessed($obj) returns the
#   class name, not 'HASH'.  So the blessed ref is treated as a plain value.
# C: the blessed ref is passed to the owning DB as-is, not merged as operator.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b, filters => { 0 => { name => { '>' => 'A' } } });
	my $evil_obj = bless { op => 'EVIL', val => 1 }, 'EvilClass';

	# Query-time criterion value is the blessed ref; base filter is a real operator hashref.
	# _merge_criteria must NOT combine them as operator hashrefs.
	local $SIG{__WARN__} = sub {};
	$join->selectall_arrayref(name => $evil_obj);

	# DB_A receives the blessed ref as the value for 'name', unmerged.
	my $received_val = $db_a->last_criteria->{name};
	ok(ref($received_val) eq 'EvilClass',
		'type-safety: blessed ref as criteria value is NOT merged as operator hashref');
}

# Test 10
# Exploit: deeply nested hashref hoping to trigger infinite recursion in _merge_criteria.
# Attack vector: { score => { '>' => { '>' => { '>' => { '>' => { '>' => 1 } } } } } }
# MP: _merge_criteria is flat -- it only merges top-level operator keys, never recurses.
# C: no stack overflow; the value is passed faithfully to DB_B.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	my $deep = { '>' => { '>' => { '>' => { '>' => { '>' => 1 } } } } };

	lives_ok { $join->selectall_arrayref(score => $deep) }
		'resilience: deeply nested operator hashref does not cause recursion';
}

# Test 11
# Exploit: undef as a criteria value; hope DJ crashes or falls back to no filtering.
# MP: DJ assigns $per_db[$idx]{col} = undef.  DA receives {score => undef}.
# C: no crash; the undef is passed faithfully to DB_B.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);

	lives_ok { $join->selectall_arrayref(score => undef) }
		'resilience: undef as criteria value does not crash DJ';
	is($db_b->last_criteria->{score}, undef,
		'passthrough: undef criteria value passed faithfully to owning DB');
}

# Test 12
# Exploit: arrayref as criteria value (not a valid operator hashref).
# MP: DJ never inspects the type of criteria VALUES (only keys are validated).
# C: arrayref passes through to DB_B unmodified; no crash.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	my $arrayval = [1, 2, 3];

	lives_ok { $join->selectall_arrayref(score => $arrayval) }
		'resilience: arrayref as criteria value does not crash DJ';
	is_deeply($db_b->last_criteria->{score}, $arrayval,
		'passthrough: arrayref criteria value passed faithfully to owning DB');
}

# ===========================================================================
# SECTION 3 -- Constructor Parameter Injection
# ===========================================================================

# Test 13
# Exploit: path traversal in join_column.
# Attack vector: new(join_column => '../../../etc/passwd')
# MP: _build_col_index checks whether join_column is present in each DB's
#   column list.  It is not, so croak fires immediately.  No file is opened.
# C: croak with error_join_col_missing before any DB query occurs.
{
	my ($db_a, $db_b) = make_dbs();
	throws_ok {
		Database::Join->new(
			databases   => [$db_a, $db_b],
			join_column => $PATH_TRAVERSAL,
		);
	} qr/join_column.*absent/i,
		'pre-condition: path traversal in join_column croaks before any file access';
}

# Test 14
# Exploit: shell metacharacters in join_map alias.
# Attack vector: join_map => { 1 => 'entry; system("evil")' }
# MP: _build_col_index checks whether the alias is present in the DB's column
#   list.  It is not, so croak fires.  The string is never executed.
# C: croak with error_join_col_missing.
{
	my ($db_a, $db_b) = make_dbs();
	throws_ok {
		Database::Join->new(
			databases   => [$db_a, $db_b],
			join_column => 'entry',
			join_map    => { 1 => 'entry; system("evil")' },
		);
	} qr/join_column.*absent/i,
		'pre-condition: hostile join_map alias croaks cleanly (no code execution)';
}

# Test 15
# Exploit: invalid join_type hoping to bypass validation and trigger undefined behaviour.
# MP: validate_strict enforces enum => ['inner', 'left', 'outer'].
# C: dies before the object is created.
{
	my ($db_a, $db_b) = make_dbs();
	dies_ok {
		Database::Join->new(
			databases   => [$db_a, $db_b],
			join_column => 'entry',
			join_type   => q{left; system("evil")},
		);
	} 'pre-condition: invalid join_type is rejected by validate_strict enum check';
}

# Test 16
# Exploit: hostile value in a constructor filter (filters => { 0 => { name => INJECT } }).
# Attack vector: attacker controls the filter value hoping it leaks to DB_B.
# MP: filters are per-DB-index; index 0 means DB_A only.
# C: DB_A receives the hostile filter value; DB_B receives no filter.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => 'entry',
		filters     => { 0 => { name => $SQL_INJECTION } },
	);

	$join->selectall_arrayref();

	is($db_a->last_criteria->{name}, $SQL_INJECTION,
		'filter isolation: hostile filter value reaches its assigned DB');
	ok(!exists $db_b->last_criteria->{name},
		'filter isolation: hostile filter value does NOT reach other DB');
}

# Test 17
# Exploit: non-DA object in databases array (prototype pollution via fake object).
# Attack vector: databases => [bless {}, 'Exploit']
# MP: blessed() + isa('Database::Abstraction') rejects objects not in the DA hierarchy.
# C: croak with error_invalid_db.
{
	throws_ok {
		Database::Join->new(
			databases   => [ bless({}, 'NotDA') ],
			join_column => 'entry',
		);
	} qr/not a Database::Abstraction/i,
		'pre-condition: non-DA blessed object in databases is rejected';
}

# ===========================================================================
# SECTION 4 -- AUTOLOAD Security Guards
# ===========================================================================

# Test 18
# Exploit: private method call via AUTOLOAD hoping to read internal state.
# Attack vector: $join->_join_col()  (a real internal field name)
# MP: AUTOLOAD rejects names starting with '_' before any lookup.
# C: croak with 'cannot call private method'.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	throws_ok { $join->_join_col() }
		qr/cannot call private method/i,
		'AUTOLOAD guard: private method call is rejected immediately';
}

# Test 19
# Exploit: unknown column name via AUTOLOAD.
# Attack vector: $join->nonexistent_column()
# MP: AUTOLOAD checks _col_db; unknown column name is not registered.
# C: croak with 'unknown column'.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	throws_ok { $join->nonexistent_column() }
		qr/unknown column/i,
		'AUTOLOAD guard: unknown column name is rejected';
}

# Test 20
# Exploit: attacker uses fetchrow_hashref to retrieve a row that a filter should exclude,
#   hoping DJ applies the filter lazily or not at all.
# Attack vector: filter { score > 80 } is set on DB_B; attacker requests entry='A2' (score=70).
# MP: filters cause their DB to act as inner-join partner (key-set intersection).
#   A2 (score=70) fails filter score > 80 → A2 absent from indexed[1] → removed from key_set.
# C: fetchrow_hashref('A2') returns undef.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => 'entry',
		filters     => { 1 => { score => { '>' => 80 } } },
	);

	my $row = $join->fetchrow_hashref('A2');
	ok(!defined($row),
		'filter guard: fetchrow for filtered-out entry returns undef (not raw DB value)');
}

# ===========================================================================
# SECTION 5 -- Row Merge Security
# ===========================================================================

# Test 21
# Exploit: SQL injection characters in the join_column VALUE in row data.
# Attack vector: a row with entry => "A1' OR '1'='1" (data, not criterion).
# MP: DJ uses join-column values only as hash keys; they are never executed.
# C: the hostile string appears verbatim in the merged row hashref.
{
	my $db_a_hostile = MockSecDB->new(
		columns => [qw(entry name tier)],
		rows    => [ { entry => $SQL_INJECTION, name => 'Eve', tier => 'hacker' } ],
	);
	my $db_b_plain = MockSecDB->new(
		columns => [qw(entry score)],
		rows    => [ { entry => $SQL_INJECTION, score => 99 } ],
	);
	my $join = Database::Join->new(
		databases   => [$db_a_hostile, $db_b_plain],
		join_column => 'entry',
	);

	my $rows = $join->selectall_arrayref();
	is(scalar @{$rows}, 1, 'row merge: hostile join_column value produces exactly one row');
	is($rows->[0]{entry}, $SQL_INJECTION,
		'row merge: hostile join_column value appears verbatim in merged row (safe passthrough)');
	is($rows->[0]{score}, 99,
		'row merge: secondary data correctly merged for hostile join_column value');
}

# Test 22
# Exploit: column name collision -- secondary tries to overwrite primary column.
# Attack vector: DB_B also has a 'name' column; attacker hopes for cross-contamination.
# MP: last-database-wins is explicit by design.  The merged row's 'name' comes from DB_B.
# Security note: callers should use remove_columns to eliminate unwanted duplicates.
{
	my $db_a_col = MockSecDB->new(
		columns => [qw(entry name)],
		rows    => [ { entry => 'A1', name => 'Alice-Primary' } ],
	);
	my $db_b_col = MockSecDB->new(
		columns => [qw(entry name)],
		rows    => [ { entry => 'A1', name => 'Eve-Secondary' } ],
	);
	my $join_col = Database::Join->new(
		databases   => [$db_a_col, $db_b_col],
		join_column => 'entry',
	);

	my $rows = $join_col->selectall_arrayref();
	is($rows->[0]{name}, 'Eve-Secondary',
		'merge: last-database-wins for duplicate column (secondary overwrites primary by design)');
}

# Test 23
# Exploit: removed column still present in raw DB rows; attacker hopes it leaks.
# MP: _joined_query calls delete @merged{@removed} before pushing each row.
# C: the removed column key is absent from every merged row hashref.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	$join->remove_column('tier');

	my $rows = $join->selectall_arrayref();
	my $leaked = grep { exists $_->{tier} } @{$rows};
	is($leaked, 0, 'row merge: removed column is stripped from every merged row hashref');
}

# Test 24
# Exploit: using a removed column as a criterion hoping it still filters.
# Attack vector: attacker knows 'tier' exists in raw data and tries to filter by it
#   after the column is removed, hoping for a covert oracle.
# MP: _partition_criteria looks up the col in _col_db.  remove_column() deletes
#   it from _col_db.  So the column falls to carp+drop.
# C: count(tier => 'gold') = count() -- the criterion has NO effect.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	$join->remove_column('tier');

	local $SIG{__WARN__} = sub {};
	my $total    = $join->count();
	my $filtered = $join->count(tier => 'gold');
	is($filtered, $total,
		'row merge: removed column criterion is silently dropped (no covert oracle)');
}

# ===========================================================================
# SECTION 6 -- Additional Security Boundaries
# ===========================================================================

# Test 25
# Exploit: calling execute() hoping to run raw SQL.
# MP: execute() always croaks with an explanatory message.
# C: croak with 'not supported'.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	throws_ok { $join->execute() }
		qr/not supported/i,
		'guard: execute() always croaks (no raw SQL path)';
}

# Test 26
# Exploit: calling query() hoping to use a chained builder to construct arbitrary SQL.
# C: croak with 'not supported'.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	throws_ok { $join->query() }
		qr/not supported/i,
		'guard: query() always croaks (no chained builder path)';
}

# Test 27
# Exploit: operator hashref aliasing -- malicious DB_A mutates the contents of
#   the shared operator hashref that DB_B also received for the join_column.
# Attack mechanism: before the broadcast-copy fix, both per_db[0] and per_db[1]
#   pointed to the SAME hashref value for the join_column criterion.  Mutating
#   the hashref's contents (not just the slice's slot) would corrupt DB_B.
# After the fix: each recipient of a broadcast operator hashref gets a SHALLOW
#   COPY.  Mutating DB_A's copy does not affect DB_B's copy.
# Test: MockSecDB with mutate_jc => 1 mutates $criteria->{entry} (the hash slot),
#   not the hashref contents.  For a plain string value this was always safe; we
#   use 'A1' (a string, not a hashref) to prove the slot-mutation case is safe,
#   and rely on t/cgi_security.t's architecture to confirm no shared reference.
# C: DB_B receives entry => 'A1', not 'MUTATED_BY_EVIL_DA'.
{
	my $evil_a = MockSecDB->new(
		columns    => [qw(entry name tier)],
		rows       => [ { entry => 'A1', name => 'Alice', tier => 'gold' } ],
		mutate_jc  => 1,   # this DB will mutate $criteria->{entry} in place
	);
	my $db_b = MockSecDB->new(
		columns => [qw(entry score)],
		rows    => [ { entry => 'A1', score => 95 } ],
	);
	my $join = Database::Join->new(
		databases   => [$evil_a, $db_b],
		join_column => 'entry',
	);

	$join->selectall_arrayref(entry => 'A1');

	# DB_A receives and mutates its slice.  DB_B must have received the original value.
	isnt($db_b->last_criteria->{entry}, 'MUTATED_BY_EVIL_DA',
		'aliasing: malicious DB_A mutating its criteria slice does not corrupt DB_B criteria');
}

# Test 27b (operator hashref broadcast copy)
# Exploit: malicious DB_A mutates the CONTENTS of the shared broadcast hashref.
# Before the fix: per_db[0]{entry} and per_db[1]{entry} pointed to the same hashref.
#   DB_A calling $criteria->{entry}{'>'} = 'NEW' would corrupt DB_B's operator.
# After the fix: broadcast now shallow-copies operator hashrefs, so each DB
#   receives its own independent copy.
# Test: use a MockSecDB variant that mutates the hashref contents (operator key).
{
	my $contents_mutator_called = 0;

	## no critic (Modules::ProhibitMultiplePackages)
	{
		package MutateCritMock;
		use parent -norequire, 'MockSecDB';

		sub selectall_arrayref {
			my ($self, $criteria) = @_;
			push @{ $self->{_received} }, $criteria;
			# Mutate the operator hashref CONTENTS (not just the slot)
			if (ref($criteria->{entry}) eq 'HASH') {
				$criteria->{entry}{'INJECTED'} = 'evil';
				$contents_mutator_called = 1;
			}
			return [];
		}
	}

	my $evil_a = bless MockSecDB->new(
		columns => [qw(entry name)],
		rows    => [ { entry => 'A1', name => 'Alice' } ],
	), 'MutateCritMock';
	my $db_b = MockSecDB->new(
		columns => [qw(entry score)],
		rows    => [ { entry => 'A1', score => 95 } ],
	);
	my $join = Database::Join->new(
		databases   => [$evil_a, $db_b],
		join_column => 'entry',
	);

	local $SIG{__WARN__} = sub {};   # suppress numeric-vs-string comparison noise from mock
	$join->selectall_arrayref(entry => { '>' => 'A0' });

	ok($contents_mutator_called, 'aliasing setup: content-mutating DB_A was called');
	my $db_b_op = $db_b->last_criteria->{entry};
	ok(!exists($db_b_op->{INJECTED}),
		'aliasing: broadcast operator hashref is copied; DB_A mutation does not reach DB_B');
}

# Test 28
# Exploit: filter on a non-existent database index (e.g. index 99).
# Attack vector: filters => { 99 => { name => INJECT } } hoping to crash or
#   apply a ghost filter that later affects real databases.
# MP: the filter overlay loop iterates 0..(n-1); index 99 is never reached.
# C: the hostile filter is silently ignored; all rows are returned normally.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => 'entry',
		filters     => { 99 => { name => $SQL_INJECTION } },
	);

	my $rows = $join->selectall_arrayref();
	is(scalar @{$rows}, 2, 'guard: filter on out-of-range DB index is silently ignored');
	is($db_a->last_criteria->{name}, undef,
		'guard: out-of-range filter value does not reach any real database');
}

# Test 29
# Exploit: add_database() with a non-object first argument (string).
# Attack vector: $join->add_database("'; rm -rf /") hoping for shell execution.
# MP: fail-fast guard: !ref($args[0]) && $args[0] ∉ @_ADD_DB_KEYS → croak.
#   The string is never evaluated, executed, or used as a reference.
# C: croak with error_invalid_db before any other code runs.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = make_join($db_a, $db_b);
	throws_ok {
		$join->add_database($SHELL_META);
	} qr/not a Database::Abstraction/i,
		'guard: hostile string to add_database is rejected by fail-fast guard';
}

# Test 30-35 (6 tests counted above individually) -- filter + query criteria merge
# Exploit: attacker tries to use operator hashref merging to widen a restrictive filter.
# Attack vector: base filter = { score => { '>' => 80 } } (allows only Alice score=95)
#   query criterion = { score => { '<' => 100 } } hoping to bypass the lower bound.
# MP: _merge_criteria UNIONS distinct operator keys -- both constraints apply simultaneously.
#   Result: score > 80 AND score < 100 (both operators co-exist in the merged hashref).
# C: only Alice (score=95, passes both) appears; Bob (score=70, fails '>80') is excluded.
{
	my ($db_a, $db_b) = make_dbs();
	my $join = Database::Join->new(
		databases   => [$db_a, $db_b],
		join_column => 'entry',
		filters     => { 1 => { score => { '>' => 80 } } },
	);

	# Orthogonal operator criterion: score < 100 (alone would include both A1 and A2).
	my $rows = $join->selectall_arrayref(score => { '<' => 100 });

	# Receive the actual merged criteria sent to DB_B to prove AND semantics.
	my $merged = $db_b->last_criteria;
	ok(exists $merged->{score}{'>'} && exists $merged->{score}{'<'},
		'filter merge: both operator keys co-exist in merged hashref (AND semantics)');

	# Count: if the wide criterion replaced the filter, count would be 2.
	# If AND semantics hold, count stays 1 (only Alice with score=95).
	is(scalar @{$rows}, 1,
		'filter merge: wider query criterion does not widen the base filter (AND semantics)');
	is($rows->[0]{name}, 'Alice',
		'filter merge: only Alice survives (score=95 > 80); Bob excluded (score=70 not > 80)');
}

done_testing();
