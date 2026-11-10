#!/usr/bin/env perl

# "Page N of M" under a paged table.  Every path counts: from the rows read,
# or, for a SQL table paged on the server, from DataSource::count, which
# remembers a file's count until the file changes.

use strict;
use warnings;

use DBI;
use File::Spec;
use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::Util ();
use Test::Mojo;
use Test::Most;

my $data = tempdir(CLEANUP => 1);

# 25 rows: 3 pages of 10, the last holding 5.
my $csv = join("\n", 'sku,colour,qty', map { "s$_," . ($_ % 2 ? 'Red' : 'Blue') . ",$_" } 1 .. 25) . "\n";
Mojo::File->new($data, 'stock.csv')->spew($csv);

my $db  = File::Spec->catfile($data, 'items.sqlite');
my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE TABLE items (sku TEXT, colour TEXT, qty INTEGER)');
$dbh->do('INSERT INTO items VALUES (?, ?, ?)', undef, "s$_", ($_ % 2 ? 'Red' : 'Blue'), $_) for 1 .. 25;
$dbh->disconnect;

my $t = Test::Mojo->new('Database::BI', { data_dir => $data, model_dir => tempdir(CLEANUP => 1) });

sub info {
	my ($url) = @_;
	$t->get_ok($url)->status_is(200);
	my $el = $t->tx->res->dom->at('.page-info');
	return $el ? $el->all_text : undef;
}

subtest 'a file read whole: the number of pages' => sub {
	like info('/view/stock?per_page=10'), qr/\APage 1 of 3\b/, 'page 1 of 3';
	like info('/view/stock?per_page=10&page=3'), qr/\APage 3 of 3\b/, 'the last page';
	like info('/view/stock?per_page=4'), qr/\APage 1 of 7\b/, 'a part page counts';
	like info('/view/stock?per_page=10&f=colour:eq:red'), qr/\APage 1 of 2\b/, 'counted after the filter (13 rows)';
	is info('/view/stock?per_page=25'), undef, 'one page: no pagination at all';
};

subtest 'SQLite paged on the server is counted too' => sub {
	like info('/view/items?per_page=10'), qr/\APage 1 of 3\b/, 'paged in SQL: page 1 of 3';
	like info('/view/items?per_page=10&page=3'), qr/\APage 3 of 3\b/, 'the last page';
	like info('/view/items?per_page=10&f=colour:eq:blue'), qr/\APage 1 of 2\b/, 'a filter reads every row (12 rows)';
	like info('/view/items?per_page=10&sort=qty&dir=desc'), qr/\APage 1 of 3\b/, 'so does a sort';
	is info('/view/items?per_page=25'), undef, 'one page: no pagination at all';

	# The count is remembered; a file that changes is counted again.
	my $h = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
	$h->do('INSERT INTO items VALUES (?, ?, ?)', undef, "s$_", 'Red', $_) for 26 .. 31;
	$h->disconnect;
	utime undef, time + 5, $db;	# a new mtime even within the same second
	like info('/view/items?per_page=10'), qr/\APage 1 of 4\b/, 'after six more rows: page 1 of 4';
};

subtest 'a count that fails costs only the "of"' => sub {
	no warnings 'redefine';
	local *Database::BI::Model::DataSource::count = sub { Carp::croak('no count here') };
	like info('/view/items?per_page=10&page=2'), qr/\APage 2\s*\x{2014}/, 'the page alone';
	unlike info('/view/items?per_page=10&page=2'), qr/ of /, 'with no count';
};

subtest '/combine counts the stacked rows' => sub {
	like info('/combine?l=table:stock&c=table:items&per_page=10'), qr/\APage 1 of 6\b/, '56 rows (25 + 31), 6 pages';
};

subtest 'the pivot counts its row groups' => sub {
	my $url = '/pivot?l=table:stock&rows=sku&m=' . Mojo::Util::url_escape('qty:sum:total') . '&per_page=10';
	for ([ '', 1 ], [ '&page=3', 3 ]) {
		my ($q, $n) = @$_;
		$t->get_ok("$url$q")->status_is(200);
		my $el = $t->tx->res->dom->at('.piv-page-info');
		like $el ? $el->all_text : '', qr/\APage $n of 3\b/, "page $n of 3 (25 groups)";
	}
	$t->get_ok('/pivot?l=table:stock&rows=colour&m=' . Mojo::Util::url_escape('qty:sum:total') . '&per_page=10')->status_is(200);
	ok !$t->tx->res->dom->at('.piv-page-info'), 'two groups: one page, no pagination';
};

subtest '_page_count' => sub {
	my $pc = \&Database::BI::Controller::Dashboard::_page_count;
	is $pc->(0, 10), 1, 'no rows: one (empty) page';
	is $pc->(10, 10), 1, 'exactly one page';
	is $pc->(11, 10), 2, 'one row over';
	is $pc->(5, 0), 1, 'a page size of 0 is not a division by zero';
};

done_testing();
