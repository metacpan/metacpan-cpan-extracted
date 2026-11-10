#!/usr/bin/env perl

# Sorting a table that runs to more than one page.
#
# The table's header sort orders the rows it was given, and a long table is
# given one page of them (200 by default).  Sorting there put that page in
# order, so page 1 was not the first page of the sorted table -- with a file of
# 682 band pieces sorted by Title, page 1 held 200 titles from all through the
# alphabet.  A page of several now asks the server (sort=, dir=), which sorts
# every row before it cuts the page, by the rule the browser uses on a page
# (biValueComparator): dates as dates, numbers as numbers, else text with case
# and accents ignored and digits compared as numbers.
#
#   prove -l t/sort.t

use strict;
use warnings;

use File::Temp qw(tempdir);
use Mojo::File;
use Mojo::Util qw(url_escape);
use Test::Most;
use Test::Mojo;

my $data_dir  = Mojo::File->new(tempdir(CLEANUP => 1));
my $model_dir = tempdir(CLEANUP => 1);

# Titles out of order, numbers whose text order is not their order, dates
# written month first, and a column with a tie.
my @rows = (
	[ 1, 'zebra crossing', '9',     '12/25/2025', 'b' ],
	[ 2, 'Apple',          '10',    '1/2/2026',   'a' ],
	[ 3, 'track 10',       '(5)',   '2/1/2025',   'b' ],
	[ 4, 'Track 2',        '"$1,000"', '',        'a' ],
	[ 5, 'banana',         '',      '11/30/2024', 'b' ],
	[ 6, "\x{c9}clair",    '2.5',   '3/3/2025',   'a' ],
	[ 7, 'Cherry',         '-3',    '7/4/2025',   'b' ],
);
$data_dir->child('pieces.csv')->spew(join("\n",
	'id,title,amount,when,grp',
	map { join ',', @$_ } @rows,
) . "\n", 'UTF-8');

my $t = Test::Mojo->new('Database::BI', { data_dir => $data_dir->to_string, model_dir => $model_dir });

# The values of one column, page by page, until a page is empty.
sub column_pages {
	my ($url, $column, $per_page) = @_;
	my @pages;
	for my $page (1 .. 20) {
		$t->get_ok("$url&per_page=$per_page&page=$page")->status_is(200);
		my $dom  = $t->tx->res->dom;
		my @head = $dom->find('#bi-table thead th')->map('all_text')->each;
		my ($at) = grep { $head[$_] eq $column } 0 .. $#head;
		my @cells = $dom->find('#bi-table tbody tr')->map(sub { $_->find('td')->[$at]->all_text })->each;
		last unless @cells;
		push @pages, \@cells;
	}
	return @pages;
}

sub sorted_by {
	my ($column, $dir, $per_page, %extra) = @_;
	my $query = join '', map { "&$_=" . url_escape($extra{$_}) } sort keys %extra;
	return map { @$_ } column_pages("/view/pieces?sort=$column&dir=$dir$query", $column, $per_page);
}

subtest 'page 1 is the first page of the sorted table' => sub {
	my @pages = column_pages('/view/pieces?sort=title&dir=asc', 'title', 3);
	is(scalar @pages, 3, 'seven rows, three a page');
	is_deeply($pages[0], [ 'Apple', 'banana', 'Cherry' ], 'page 1 starts at the top of the alphabet');
	is_deeply([ map { @$_ } @pages ],
		[ 'Apple', 'banana', 'Cherry', "\x{c9}clair", 'Track 2', 'track 10', 'zebra crossing' ],
		'and the pages run on in order: case and accents ignored, 2 before 10');

	is_deeply([ sorted_by('title', 'desc', 3) ],
		[ 'zebra crossing', 'track 10', 'Track 2', "\x{c9}clair", 'Cherry', 'banana', 'Apple' ],
		'descending');
};

subtest 'numbers sort as numbers, dates as dates, across pages' => sub {
	is_deeply([ sorted_by('amount', 'asc', 2) ], [ '', '(5)', '-3', '2.5', '9', '10', '$1,000' ],
		'an empty cell first, (5) is -5, $1,000 is 1000, 9 before 10');
	is_deeply([ sorted_by('when', 'asc', 2) ],
		[ '', '11/30/2024', '2/1/2025', '3/3/2025', '7/4/2025', '12/25/2025', '1/2/2026' ],
		'month-first dates in date order');
	is_deeply([ sorted_by('amount', 'desc', 2) ], [ '$1,000', '10', '9', '2.5', '-3', '(5)', '' ],
		'descending, the empty cell last');
};

subtest 'a code with digits in it is text, not a number' => sub {
	# T27 was read as 27 (every letter dropped), so CT4 came before T27 and
	# a column of catalogue numbers sorted by its digits alone.
	$data_dir->child('codes.csv')->spew(join("\n", 'id,code,price',
		'1,T27,$5', '2,CT4,USD 7', '3,T3,(2)', '4,B10,45%', '5,T100,"1,000"') . "\n");
	is_deeply([ map { @$_ } column_pages('/view/codes?sort=code&dir=asc', 'code', 2) ],
		[ 'B10', 'CT4', 'T3', 'T27', 'T100' ], 'by letters, then the digits as a number');
	is_deeply([ map { @$_ } column_pages('/view/codes?sort=price&dir=asc', 'price', 2) ],
		[ '(2)', '$5', 'USD 7', '45%', '1,000' ], 'what only dresses a number up is still a number');
};

subtest 'rows that tie keep their order in either direction' => sub {
	my @ids = map { $_->{id} } @{ _rows('grp', 'asc') };
	is_deeply(\@ids, [ 2, 4, 6, 1, 3, 5, 7 ], 'ascending: a, then b, each in file order');
	@ids = map { $_->{id} } @{ _rows('grp', 'desc') };
	is_deeply(\@ids, [ 1, 3, 5, 7, 2, 4, 6 ], 'descending: b, then a, each still in file order');
};

# Every row of the view, through the page, as hashes of id and the column.
sub _rows {
	my ($column, $dir) = @_;
	$t->get_ok("/view/pieces?sort=$column&dir=$dir&per_page=100")->status_is(200);
	my $dom  = $t->tx->res->dom;
	my @head = $dom->find('#bi-table thead th')->map('all_text')->each;
	return [ $dom->find('#bi-table tbody tr')->map(sub {
		my @td = $_->find('td')->map('all_text')->each;
		+{ map { $head[$_] => $td[$_] } 0 .. $#head };
	})->each ];
}

subtest 'the page says what it shows' => sub {
	$t->get_ok('/view/pieces?sort=title&dir=desc&per_page=3')->status_is(200)
		->element_exists('#bi-table[data-paged="1"]', 'one page of several')
		->element_exists('#bi-table[data-sort-col="title"][data-sort-dir="desc"]', 'sorted by the server')
		->element_exists('#bi-table th[data-col="title"]', 'each header names its column')
		->element_exists('nav.pagination a[href*="sort=title"][href*="dir=desc"][href*="page=2"]',
			'and Next keeps the sort');

	$t->get_ok('/view/pieces?per_page=100')->status_is(200)
		->element_exists_not('#bi-table[data-paged]', 'a table on one page sorts in the browser')
		->element_exists_not('#bi-table[data-sort-col]', 'nothing sorted on the server');

	$t->get_ok('/view/pieces?sort=nosuch&per_page=3')->status_is(200)
		->element_exists_not('#bi-table[data-sort-col]', 'a column the view lacks is not sorted on');
	my @ids = map { $_->{id} } @{ _rows('nosuch', 'asc') };
	is_deeply(\@ids, [ 1 .. 7 ], 'and the rows keep the file order');
};

subtest 'filters, calculated fields and /open sort the same way' => sub {
	is_deeply([ sorted_by('title', 'asc', 2, f => 'grp:eq:b') ],
		[ 'banana', 'Cherry', 'track 10', 'zebra crossing' ], 'the filtered rows, sorted');

	my @doubled = sorted_by('id2', 'desc', 3, c => 'id2:id * 2');
	is_deeply(\@doubled, [ 14, 12, 10, 8, 6, 4, 2 ], 'a calculated field, every row computed first');

	my $path = url_escape($data_dir->child('pieces.csv')->to_string);
	my @open = map { @$_ } column_pages("/open?path=$path&sort=title&dir=asc", 'title', 3);
	is($open[0], 'Apple', '/open sorts every row too');
	is(scalar @open, 7, 'each row once');
};

subtest 'the browser reads numbers by the server\'s rule' => sub {
	my $js = Mojo::File->new('templates/web/en/layouts/parse_accounting.html.tt')->slurp;
	like($js, qr/^function parseAccounting\(v\)/m, 'parseAccounting is defined once, in a layout');
	my ($codes) = $js =~ /BI_CURRENCY_CODES = '([A-Z|]+)'/;
	my $util = Mojo::File->new('lib/Database/BI/Util.pm')->slurp;
	my ($perl) = $util =~ /\$CURRENCY_CODES\s*=>\s*join '\|', qw\(([A-Z ]+)\)/;
	is($codes, join('|', split ' ', $perl // ''), 'with the same currency codes');
	for my $page ('dashboard', 'pivot') {
		like(Mojo::File->new("templates/web/en/$page.html.tt")->slurp,
			qr{PROCESS "web/en/layouts/parse_accounting\.html\.tt"}, "$page uses it");
	}
	unlike(Mojo::File->new('templates/web/en/pivot.html.tt')->slurp, qr/\[\^\\d\.\\-\]/,
		'the pivot no longer strips letters to find a number');
};

subtest 'the page asks the server when there is more than one page' => sub {
	my $tt = Mojo::File->new('templates/web/en/dashboard.html.tt')->slurp;
	like($tt, qr/var PAGED = table\.dataset\.paged === '1';/, 'the table script knows when it holds one page of several');
	like($tt, qr/if \(PAGED\) \{\s*saveState\(\);[^}]*location\.assign\(serverSort\(sortColIdx, sortAsc\)\);/s,
		'a header click then reloads with sort= and dir=');
	like($tt, qr/url\.searchParams\.delete\('page'\);/, 'from page 1');
	like($tt, qr/location\.replace\(serverSort\(sortColIdx, sortAsc\)\);/, 'and a remembered sort is asked for too');
};

done_testing();
