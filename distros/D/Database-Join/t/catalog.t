#!/usr/bin/env perl

# Database::Join::Catalog: listing tables and columns, a table's declared
# columns and key, and writing rows as a SQLite file.

use strict;
use warnings;

use Test::Most;
use DBI;
use File::Spec;
use File::Temp qw(tempdir);

use_ok('Database::Join::Catalog');
my $C = 'Database::Join::Catalog';

my $dir = tempdir(CLEANUP => 1);

sub sqlite_file {
	my ($name, @sql) = @_;
	my $file = File::Spec->catfile($dir, $name);
	my $dbh = DBI->connect("dbi:SQLite:dbname=$file", '', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do($_) for @sql;
	$dbh->disconnect;
	return $file;
}

sub error_of {
	my ($code) = @_;
	my $ok = eval { $code->(); 1 };
	return $ok ? undef : $@;
}

my $store = sqlite_file('store.db',
	'CREATE TABLE orders (entry TEXT PRIMARY KEY, item TEXT, qty INTEGER)',
	'CREATE TABLE customers (zeta TEXT, alpha TEXT)',
	q{CREATE TABLE "odd name" ("a b" TEXT)},
	q{INSERT INTO orders VALUES ('o1', 'pen', 2)});

subtest 'tables' => sub {
	is_deeply $C->tables(file => $store), [ 'customers', 'odd name', 'orders' ], 'every user table, sorted';
	is_deeply $C->tables(dsn => "dbi:SQLite:dbname=$store"), [ 'customers', 'odd name', 'orders' ], 'by dsn too';
	is_deeply $C->tables({ file => $store }), [ 'customers', 'odd name', 'orders' ], 'or a hashref';
	my $empty = sqlite_file('empty.db', 'CREATE TABLE t (x)', 'DROP TABLE t');
	is_deeply $C->tables(file => $empty), [], 'a database with none';
};

subtest 'schema' => sub {
	is_deeply $C->schema(file => $store), [
		{ name => 'customers', columns => [ 'zeta', 'alpha' ] },
		{ name => 'odd name',  columns => [ 'a b' ] },
		{ name => 'orders',    columns => [ 'entry', 'item', 'qty' ] },
	], 'columns in their declared order, not alphabetical';
};

subtest 'table_info' => sub {
	is_deeply $C->table_info(file => $store, table => 'orders'),
		{ columns => [ 'entry', 'item', 'qty' ], primary_key => [ 'entry' ] }, 'columns and key';
	is_deeply $C->table_info(file => $store, table => 'customers')->{primary_key}, [], 'no key';
	is_deeply $C->table_info(file => $store, table => 'odd name')->{columns}, [ 'a b' ], 'a name that needs quoting';
	my $e = error_of(sub { $C->table_info(file => $store, table => 'nope') });
	isa_ok $e, 'Database::Join::Catalog::Error';
	is $e->stage, 'query', 'a table that is not there fails the query';
	like "$e", qr/no such table/i, 'and reads as the driver\'s message';
	unlike "$e", qr/ at \S+ line \d+/, 'without a line number';
	throws_ok { $C->table_info(file => $store) } qr/A table name is required/, 'no table';
	my $inject = error_of(sub { $C->table_info(file => $store, table => 'orders WHERE 1=1; DROP TABLE orders; --') });
	is $inject->stage, 'query', 'a table name is quoted, never run as SQL';
	is_deeply $C->tables(file => $store), [ 'customers', 'odd name', 'orders' ], 'and nothing was dropped';
};

subtest 'what is not a SQLite database' => sub {
	my $missing = File::Spec->catfile($dir, 'missing.db');
	my $e = error_of(sub { $C->tables(file => $missing) });
	isa_ok $e, 'Database::Join::Catalog::Error';
	is $e->stage, 'connect', 'a file that is not there cannot be opened';
	ok !-e $missing, 'and is not made into an empty database';

	my $text = File::Spec->catfile($dir, 'text.db');
	open my $fh, '>', $text or BAIL_OUT("$text: $!");
	print {$fh} "id,name\n1,a\n" x 200;
	close $fh;
	my $before = -s $text;
	$e = error_of(sub { $C->tables(file => $text) });
	is $e->stage, 'query', 'a file that is not SQLite fails the query';
	is -s $text, $before, 'and is not changed';
};

subtest 'arguments' => sub {
	throws_ok { $C->tables() } qr/Give a file .* or a dsn/, 'neither file nor dsn';
	throws_ok { $C->tables(file => $store, dsn => 'dbi:SQLite:x') } qr/not both/, 'both';
	throws_ok { $C->schema(dsn => 'dbi:Pg:dbname=x') } qr/not "Pg"/, 'a driver it cannot list';
};

subtest 'write_sqlite and sqlite_bytes' => sub {
	my @rows = ({ id => 1, 'say "hi"' => 'x', name => 'a' }, { id => 2, name => undef });
	my $out = File::Spec->catfile($dir, 'out.db');
	is $C->write_sqlite(file => $out, table => 'data', columns => [ 'id', 'name', 'say "hi"' ], rows => \@rows), 1, 'written';
	is_deeply $C->schema(file => $out), [ { name => 'data', columns => [ 'id', 'name', 'say "hi"' ] } ], 'one table, columns in order';
	my $dbh = DBI->connect("dbi:SQLite:dbname=$out", '', '', { RaiseError => 1 });
	is_deeply $dbh->selectall_arrayref('SELECT * FROM data ORDER BY id'), [ [ 1, 'a', 'x' ], [ 2, undef, undef ] ],
		'the rows, a missing value as NULL';
	$dbh->disconnect;

	throws_ok { $C->write_sqlite(file => $out, columns => [ 'id' ]) } qr/already exists/, 'never replaces a file';
	throws_ok { $C->write_sqlite(columns => [ 'id' ]) } qr/Give a file/, 'needs a file';
	throws_ok { $C->sqlite_bytes(columns => []) } qr/At least one column/, 'no columns';
	throws_ok { $C->sqlite_bytes(columns => [ 'id' ], rows => [ [1] ]) } qr/rows\[0\] is not a hash/, 'a row that is not a hash';
	throws_ok { $C->sqlite_bytes(table => '', columns => [ 'id' ]) } qr/table name is required/, 'an empty table name';

	my $bytes = $C->sqlite_bytes(columns => [ 'id', 'name' ], rows => \@rows);
	like $bytes, qr/\ASQLite format 3\0/, 'the bytes of a SQLite file';
	my $copy = File::Spec->catfile($dir, 'copy.db');
	open my $fh, '>:raw', $copy or BAIL_OUT("$copy: $!");
	print {$fh} $bytes;
	close $fh;
	is_deeply $C->table_info(file => $copy, table => 'data')->{columns}, [ 'id', 'name' ], 'named data by default';

	my $tmp = tempdir(CLEANUP => 1);
	local $ENV{TMPDIR} = $tmp;
	$C->sqlite_bytes(columns => [ 'id' ], rows => \@rows);
	no warnings 'redefine';
	local *DBI::db::do = sub { die "disk full\n" };
	my $e = error_of(sub { $C->sqlite_bytes(columns => [ 'id' ]) });
	is $e->stage, 'query', 'a write that fails';
	like "$e", qr/disk full/, 'says why';
	opendir my $dh, $tmp or BAIL_OUT("$tmp: $!");
	is_deeply [ grep { !/\A\.\.?\z/ } readdir $dh ], [], 'and no temporary file is left, after success or failure';
	my $failed = File::Spec->catfile($dir, 'failed.db');
	error_of(sub { $C->write_sqlite(file => $failed, columns => [ 'id' ]) });
	ok !-e $failed, 'write_sqlite leaves no file when it fails';
};

subtest 'MariaDB and MySQL' => sub {
	my @asked;
	my $dbh = bless {}, 'Local::FakeDbh';
	no warnings qw(redefine once);
	local *Local::FakeDbh::selectall_arrayref = sub { push @asked, $_[1]; [ [ 'b', 'y' ], [ 'b', 'x' ], [ 'a', 'k' ] ] };
	local *Local::FakeDbh::disconnect = sub { 1 };
	local *DBI::connect = sub { $dbh };
	is_deeply $C->schema(dsn => 'dbi:MariaDB:database=shop', username => 'u', password => 'p'),
		[ { name => 'b', columns => [ 'y', 'x' ] }, { name => 'a', columns => [ 'k' ] } ], 'from information_schema, in its order';
	like $asked[0], qr/information_schema\.COLUMNS .*TABLE_SCHEMA = DATABASE\(\)/s, 'for the connection\'s database';
	is_deeply $C->tables(dsn => 'dbi:mysql:database=shop'), [ 'b', 'a' ], 'tables from the same';

	local *DBI::connect = sub { die "DBI connect('database=shop','u',...) failed: Access denied at x.pl line 3.\n" };
	my $e = error_of(sub { $C->schema(dsn => 'dbi:MariaDB:database=shop') });
	is $e->stage, 'connect', 'a server that refuses';
	is "$e", 'Access denied', 'says what it said';
};

subtest 'available_driver' => sub {
	is $C->available_driver('NoSuchDriverXyz', 'SQLite'), 'SQLite', 'the first that loads';
	is $C->available_driver('NoSuchDriverXyz'), undef, 'or none';
	is $C->available_driver('../../etc/passwd', 'SQLite'), 'SQLite', 'a name that is not a driver name is skipped';
};

subtest "the caller's \$@ and \$! survive" => sub {
	$@ = 'before';
	$! = 2;
	my $errno = $! + 0;
	$C->tables(file => $store);
	eval { $C->tables(file => File::Spec->catfile($dir, 'missing2.db')) };
	ok ref $@, 'a failure still reaches the caller';
	$@ = 'before';
	$C->schema(file => $store);
	is $@, 'before', '$@ after a success';
	is $! + 0, $errno, '$!';
};

subtest 'a driver that fails without a reason' => sub {
	no warnings 'redefine';
	local *DBI::connect = sub { return undef };
	my $out = File::Spec->catfile($dir, 'no-reason.db');
	eval { $C->write_sqlite(file => $out, columns => ['a'], rows => []) };
	my $err = $@;
	isa_ok $err, 'Database::Join::Catalog::Error';
	is eval { $err->stage }, 'connect', 'stage';
	like "$err", qr/gave no reason/, 'the message is never empty';
	ok !-e $out, 'no file is left';
};

done_testing();
