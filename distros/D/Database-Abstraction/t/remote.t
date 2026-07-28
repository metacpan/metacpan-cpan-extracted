# Tests for the File::Slurp::Remote integration in Database::Abstraction.
#
# No real SSH is attempted.  File::Slurp::Remote::read_remote_file() is
# overridden with a local stub that returns in-memory fixture data, making
# the entire test suite runnable offline and without a configured SSH agent.

use strict;
use warnings;

use File::Spec;
use Test::Most;

use Test::Needs 'File::Slurp::Remote';

BEGIN {
	package Database::remote;
	use base 'Database::Abstraction';
}

BEGIN {
	package Database::remotene;	# no_entry variant
	use base 'Database::Abstraction';
}

# ---------------------------------------------------------------------------
# Fixture data keyed by "$host:$remote_path"
# ---------------------------------------------------------------------------

my %FIXTURE = (
	'myhost:/data/remote.csv' =>
		"entry!name!score\none!Alice!10\ntwo!Bob!20\nthree!Carol!30\n",
	'myhost:/data/remotene.csv' =>
		"city,pop\nLondon,9000000\nParis,2000000\n",
	'myhost:/data/remote.xml' =>
		'<databases><database entry="x1"><name>Rex</name><age>5</age></database></databases>',
);

# Override read_remote_file so no SSH connection is made.
# The stub maps "$host + $file" to fixture text; dies for unknown paths.
{
	no warnings 'redefine';
	*File::Slurp::Remote::read_remote_file = sub {
		my ($host, $file) = @_;
		my $key = "$host:$file";
		die "remote: no fixture for $key\n" unless exists $FIXTURE{$key};
		return $FIXTURE{$key};
	};
}

# ---------------------------------------------------------------------------
# Section 1: CSV remote backend (keyed)
# ---------------------------------------------------------------------------

my $dao = new_ok('Database::remote' => [
	host      => 'myhost',
	directory => '/data',
]);

my $all = $dao->selectall_arrayref();
is(ref($all), 'ARRAY', 'selectall_arrayref returns arrayref');
is(scalar @{$all}, 3, 'remote CSV: 3 rows fetched');

my %by_entry = map { $_->{'entry'} => $_ } @{$all};
is($by_entry{'one'}{'name'},   'Alice', 'row one: name correct');
is($by_entry{'two'}{'score'},  20,      'row two: score correct');
is($by_entry{'three'}{'name'},'Carol',  'row three: name correct');

# Filtered fetch
my $one_rows = $dao->selectall_arrayref(entry => 'one');
is(scalar @{$one_rows}, 1,          'filtered by entry returns 1 row');
is($one_rows->[0]{'name'}, 'Alice', 'filtered row name correct');

# selectall_array
my @arr = $dao->selectall_array();
is(scalar @arr, 3, 'selectall_array returns 3 rows');

# fetchrow_hashref
my $row = $dao->fetchrow_hashref(entry => 'two');
is(ref($row), 'HASH',   'fetchrow_hashref returns hashref');
is($row->{'name'}, 'Bob', 'fetchrow_hashref name correct');

my $missing = $dao->fetchrow_hashref(entry => 'nosuch');
ok(!defined($missing), 'fetchrow_hashref returns undef for missing key');

# count
is($dao->count(), 3,         'count() returns 3');
is($dao->count(name => 'Bob'), 1, 'count(name=>Bob) returns 1');
is($dao->count(name => 'Nobody'), 0, 'count for non-existent name returns 0');

# AUTOLOAD
is($dao->name(entry => 'one'), 'Alice', 'AUTOLOAD name(entry=>one) returns Alice');
my @names = $dao->name();
is(scalar @names, 3, 'AUTOLOAD name() list context returns 3');
ok((grep { $_ eq 'Bob' } @names), 'list includes Bob');

# columns / schema
my $cols = $dao->columns();
is(ref($cols), 'ARRAY', 'columns() returns arrayref');
ok((grep { $_ eq 'entry' } @{$cols}), 'columns includes entry');
ok((grep { $_ eq 'name'  } @{$cols}), 'columns includes name');
ok((grep { $_ eq 'score' } @{$cols}), 'columns includes score');

# Query builder
my $q_all = $dao->query()->all();
is(scalar @{$q_all}, 3, 'query()->all() returns all rows');

my $q_first = $dao->query()->where(name => 'Alice')->first();
is($q_first->{'entry'}, 'one', 'query()->where()->first() correct entry');

my $q_count = $dao->query()->where(name => 'Carol')->count();
is($q_count, 1, 'query()->where()->count() returns 1');

# type is set to DBI (CSV goes via DBI::CSV, not slurp for larger files;
# for tiny fixtures it may slurp — just verify the object works)
ok(defined($dao->{'type'}), 'type is set after first data access');

# ---------------------------------------------------------------------------
# Section 2: no_entry CSV remote backend
# ---------------------------------------------------------------------------

my $ne = new_ok('Database::remotene' => [
	host      => 'myhost',
	directory => '/data',
	no_entry  => 1,
	sep_char  => ',',
]);

my $ne_all = $ne->selectall_arrayref();
is(scalar @{$ne_all}, 2, 'no_entry remote CSV: 2 rows');

my ($london) = grep { $_->{'city'} eq 'London' } @{$ne_all};
ok(defined $london, 'London row found');
is($london->{'pop'}, 9000000, 'London pop correct');

# ---------------------------------------------------------------------------
# Section 3: DESTROY cleans up temp directory
# ---------------------------------------------------------------------------

my $tmpdir_path;
{
	my $tmp_dao = Database::remote->new(host => 'myhost', directory => '/data');
	$tmp_dao->selectall_arrayref();	# trigger _open
	my $obj = $tmp_dao->{'_remote_tmpdir'};
	$tmpdir_path = ref($obj) ? $obj->dirname() : undef;
	ok(defined($tmpdir_path) && -d $tmpdir_path, 'remote tmpdir exists while object alive');
}	# DESTROY fires here

ok(!-d $tmpdir_path, 'remote tmpdir removed after object destroyed')
	if defined($tmpdir_path);

# ---------------------------------------------------------------------------
# Section 4: Input validation — unsafe host name
# ---------------------------------------------------------------------------

throws_ok(
	sub { Database::remote->new(host => 'bad host; rm -rf /', directory => '/data') },
	qr/unsafe host/,
	'hostile host name with spaces/semicolon is rejected',
);

throws_ok(
	sub { Database::remote->new(host => '../../etc/passwd', directory => '/data') },
	qr/unsafe host/,
	'path-traversal host name is rejected',
);

throws_ok(
	sub { Database::remote->new(host => '$(evil)', directory => '/data') },
	qr/unsafe host/,
	'shell-expansion host name is rejected',
);

# Valid host forms accepted (no croak at construction time)
ok(
	eval { Database::remote->new(host => 'myserver.example.com', directory => '/data'); 1 },
	'plain hostname accepted',
);
ok(
	eval { Database::remote->new(host => 'user@myserver', directory => '/data'); 1 },
	'user@host form accepted',
);

done_testing();
