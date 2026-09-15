#!perl -w

use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

use lib 't/lib';
use Database::test1;

# ---------------------------------------------------------------------------
# Section A: XLS binary format (DBD::Excel / Spreadsheet::ParseExcel)
# Fixture created with Spreadsheet::WriteExcel; opened with DBD::Excel.
# ---------------------------------------------------------------------------
SKIP: {
	eval { require DBD::Excel; require Spreadsheet::WriteExcel; 1 }
		or skip('DBD::Excel and/or Spreadsheet::WriteExcel not installed', 10);

	pass('DBD::Excel and Spreadsheet::WriteExcel available');

	my $tmpdir = tempdir(CLEANUP => 1);
	my $xls    = File::Spec->catfile($tmpdir, 'test1.xls');

	{
		my $wb = Spreadsheet::WriteExcel->new($xls);

		my $ws1 = $wb->add_worksheet('test1');
		$ws1->write(0, 0, 'entry');  $ws1->write(0, 1, 'number');
		$ws1->write(1, 0, 'one');    $ws1->write(1, 1, 1);
		$ws1->write(2, 0, 'two');    $ws1->write(2, 1, 2);
		$ws1->write(3, 0, 'three');  $ws1->write(3, 1, 3);

		my $ws2 = $wb->add_worksheet('sheet2');
		$ws2->write(0, 0, 'entry');  $ws2->write(0, 1, 'score');
		$ws2->write(1, 0, 'alpha');  $ws2->write(1, 1, 90);
		$ws2->write(2, 0, 'beta');   $ws2->write(2, 1, 75);

		$wb->close();
	}

	ok(-r $xls, 'XLS: fixture test1.xls written');

	my $db = new_ok('Database::test1' => [$tmpdir], 'XLS: Database::test1 on .xls directory');

	is($db->count(), 3, 'XLS: count() returns 3 rows');
	is($db->{'type'}, 'Excel', 'XLS: type is Excel after first query');
	is($db->number('two'), 2, 'XLS: AUTOLOAD number(two) == 2');
	is($db->number('four'), undef, 'XLS: AUTOLOAD number(four) is undef (miss)');

	my $row = $db->fetchrow_hashref(entry => 'one');
	is($row->{'entry'},  'one', 'XLS: fetchrow_hashref entry == one');
	is($row->{'number'}, 1,     'XLS: fetchrow_hashref number == 1');

	my $db2 = Database::test1->new(directory => $tmpdir, table => 'sheet2');
	isa_ok($db2, 'Database::test1', 'XLS: table-override instance');
	is($db2->count(), 2, 'XLS: sheet2 has 2 rows via table override');
}

# ---------------------------------------------------------------------------
# Section B: XLSX OOXML format (Spreadsheet::ParseXLSX, in-memory slurp)
# Fixture created with Excel::Writer::XLSX; parsed with Spreadsheet::ParseXLSX.
# ---------------------------------------------------------------------------
SKIP: {
	eval { require Excel::Writer::XLSX; require Spreadsheet::ParseXLSX; 1 }
		or skip('Excel::Writer::XLSX and/or Spreadsheet::ParseXLSX not installed', 20);

	pass('Excel::Writer::XLSX and Spreadsheet::ParseXLSX available');

	my $tmpdir = tempdir(CLEANUP => 1);
	my $xlsx   = File::Spec->catfile($tmpdir, 'test1.xlsx');

	{
		my $wb = Excel::Writer::XLSX->new($xlsx);

		my $ws1 = $wb->add_worksheet('test1');
		$ws1->write(0, 0, 'entry');  $ws1->write(0, 1, 'number');
		$ws1->write(1, 0, 'one');    $ws1->write(1, 1, 1);
		$ws1->write(2, 0, 'two');    $ws1->write(2, 1, 2);
		$ws1->write(3, 0, 'three');  $ws1->write(3, 1, 3);

		my $ws2 = $wb->add_worksheet('sheet2');
		$ws2->write(0, 0, 'entry');  $ws2->write(0, 1, 'score');
		$ws2->write(1, 0, 'alpha');  $ws2->write(1, 1, 90);
		$ws2->write(2, 0, 'beta');   $ws2->write(2, 1, 75);

		$wb->close();
	}

	ok(-r $xlsx, 'XLSX: fixture test1.xlsx written');

	# Basic keyed-mode queries via in-memory slurp path
	my $db = new_ok('Database::test1' => [$tmpdir], 'XLSX: Database::test1 on .xlsx directory');

	is($db->count(), 3, 'XLSX: count() returns 3 rows');
	is($db->{'type'}, 'XLSX', 'XLSX: type is XLSX after first query');
	ok defined($db->{'data'}), 'XLSX: data loaded into memory (slurp path)';

	is($db->number('two'), 2,    'XLSX: AUTOLOAD number(two) == 2');
	is($db->number('four'), undef, 'XLSX: AUTOLOAD number(four) is undef (miss)');

	my $row = $db->fetchrow_hashref(entry => 'one');
	is($row->{'entry'},  'one', 'XLSX: fetchrow_hashref entry == one');
	is($row->{'number'}, 1,     'XLSX: fetchrow_hashref number == 1');

	my $all = $db->selectall_arrayref();
	is(scalar(@{$all}), 3, 'XLSX: selectall_arrayref returns 3 rows');

	# no_entry mode — slurped as ARRAY ref
	my $db_ne = Database::test1->new(directory => $tmpdir, no_entry => 1);
	isa_ok($db_ne, 'Database::test1', 'XLSX: no_entry instance');
	$db_ne->count();  # trigger slurp
	is($db_ne->{'type'}, 'XLSX', 'XLSX: no_entry type is XLSX');
	ok(ref($db_ne->{'data'}) eq 'ARRAY', 'XLSX: no_entry data is ARRAY ref');
	cmp_ok($db_ne->count(), '>', 0, 'XLSX: no_entry count > 0');

	# Table override — queries the sheet2 worksheet
	my $db2 = Database::test1->new(directory => $tmpdir, table => 'sheet2');
	isa_ok($db2, 'Database::test1', 'XLSX: table-override instance');
	is($db2->count(), 2, 'XLSX: sheet2 has 2 rows via table override');
	is($db2->{'type'}, 'XLSX', 'XLSX: table override type is XLSX');
	is($db2->score('alpha'), 90, 'XLSX: AUTOLOAD score(alpha) == 90 via sheet2');

	# Chained query builder delegates to in-memory path for XLSX
	my $q_count = $db->query->count();
	is($q_count, 3, 'XLSX: query->count() returns 3');

	my $q_first = $db->query->where(entry => 'two')->first();
	is($q_first->{'number'}, 2, 'XLSX: query->where(entry=>two)->first() number == 2');

	my $q_all = $db->query->all();
	is(scalar(@{$q_all}), 3, 'XLSX: query->all() returns 3 rows');

	# Unsafe table name is rejected at construction time
	throws_ok {
		Database::test1->new(directory => $tmpdir, table => 'bad; DROP TABLE x--');
	} qr/unsafe table name/, 'XLSX: unsafe table name rejected at new()';
}

done_testing();
