#!/usr/bin/env perl

# Rows per page: per_page= in the URL, else the bi_per_page cookie that
# /preferences sets, else 200; 0 is every row.  The same list (25, 50, 100,
# 200, All) is under a paged table, under a paged pivot and on /preferences.

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

# 250 rows: more than one default page of 200.
my $csv = join("\n", 'sku,qty', map { "s$_,$_" } 1 .. 250) . "\n";
Mojo::File->new($data, 'stock.csv')->spew($csv);

my $db  = File::Spec->catfile($data, 'items.sqlite');
my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE TABLE items (sku TEXT, qty INTEGER)');
$dbh->do('INSERT INTO items VALUES (?, ?)', undef, "s$_", $_) for 1 .. 250;
$dbh->disconnect;

my $t = Test::Mojo->new('Database::BI', { data_dir => $data, model_dir => tempdir(CLEANUP => 1) });

sub rows {
	my ($url, $cookie) = @_;
	$t->ua->cookie_jar->empty;
	$t->get_ok($url, defined $cookie ? { Cookie => "bi_per_page=$cookie" } : {})->status_is(200);
	return $t->tx->res->dom->find('#bi-table tbody tr')->size;
}

sub chosen {
	my $sel = $t->tx->res->dom->at('select.page-size-select option[selected]');
	return $sel ? $sel->attr('value') : undef;
}

subtest 'the default, the URL and All' => sub {
	for my $table (qw(stock items)) {
		is rows("/view/$table"), 200, "$table: 200 by default";
		is chosen(), 200, '... and the list says 200';
		like $t->tx->res->dom->at('.page-info')->all_text, qr/\APage 1 of 2\b/, '... two pages';

		is rows("/view/$table?per_page=25"), 25, "$table: per_page=25";
		is chosen(), 25, '... chosen in the list';
		like $t->tx->res->dom->at('.page-info')->all_text, qr/\APage 1 of 10\b/, '... ten pages';

		is rows("/view/$table?per_page=0"), 250, "$table: per_page=0 is every row";
		ok !$t->tx->res->dom->at('.page-info'), '... on one page, with no page buttons';
		is chosen(), 0, '... and the list, which stays to change it back, says All';

		is rows("/view/$table?per_page=0&page=3"), 250, "$table: All ignores page=";
	}
	is rows('/view/stock?per_page=10'), 10, 'a size not in the list';
	is chosen(), 10, '... is added to it, chosen';
};

subtest 'the cookie sets the default; the URL beats it' => sub {
	is rows('/view/stock', 50), 50, 'bi_per_page=50';
	is chosen(), 50, '... chosen';
	is rows('/view/stock', 0), 250, 'bi_per_page=0: every row';
	is chosen(), 0, '... and the list is there to change it';
	is rows('/view/stock?per_page=100', 25), 100, 'per_page= in the URL wins';
	is rows('/view/stock', 37), 200, 'a cookie not in the list is ignored';
	is rows('/view/stock', 'x'), 200, '... and so is one that is not a number';
	is rows('/view/items', 25), 25, 'a SQLite table reads it too';
};

subtest 'a short table shows no list unless the URL chose a size' => sub {
	Mojo::File->new($data, 'few.csv')->spew("sku,qty\na,1\nb,2\n");
	rows('/view/few');
	ok !$t->tx->res->dom->at('select.page-size-select'), 'two rows, default size: no list';
	rows('/view/few?per_page=25');
	ok $t->tx->res->dom->at('select.page-size-select'), 'per_page= in the URL: the list, to change it back';
};

subtest 'the list on a table page' => sub {
	rows('/view/stock?per_page=50&page=3');
	my $sel = $t->tx->res->dom->at('select#page-size');
	ok $sel, 'a select';
	is $sel->attr('data-page'), 3, 'it knows the page';
	is $sel->attr('data-size'), 50, '... and the size, to keep the first row on screen';
	is_deeply [ $sel->find('option')->map(attr => 'value')->each ], [qw(25 50 100 200 0)], 'the sizes, in order';
	is $sel->at('option[value="0"]')->text, 'All', '0 is All';
	like $t->tx->res->body, qr/data-page-size-view/, 'the script that reloads is bound to it';
};

subtest 'the pivot counts row groups the same way' => sub {
	my $url = '/pivot?l=table:stock&rows=sku&m=' . Mojo::Util::url_escape('qty:sum:total');
	$t->ua->cookie_jar->empty;
	$t->get_ok("$url&per_page=25")->status_is(200);
	like $t->tx->res->dom->at('.piv-page-info')->all_text, qr/\APage 1 of 10\b/, 'per_page=25: ten pages of groups';
	is chosen(), 25, 'the list says 25';
	$t->get_ok($url, { Cookie => 'bi_per_page=100' })->status_is(200);
	like $t->tx->res->dom->at('.piv-page-info')->all_text, qr/\APage 1 of 3\b/, 'the cookie: 100 a page';
	$t->get_ok("$url&per_page=0")->status_is(200);
	ok !$t->tx->res->dom->at('.piv-page-info'), 'All: one page';
	is chosen(), 0, '... and the list';
};

subtest '/preferences shows the list with the saved choice' => sub {
	$t->ua->cookie_jar->empty;
	$t->get_ok('/preferences')->status_is(200)->element_exists('select#pref-page-size');
	is chosen(), 200, 'nothing saved: 200';
	ok !$t->tx->res->dom->at('select#pref-page-size')->attr('data-page-size-view'), 'it does not reload the page';
	like $t->tx->res->body, qr/bi_per_page/, 'its script writes the cookie the server reads';
	$t->get_ok('/preferences', { Cookie => 'bi_per_page=0' })->status_is(200);
	is chosen(), 0, 'saved All: All';
	$t->get_ok('/preferences', { Cookie => 'bi_per_page=50' })->status_is(200);
	is chosen(), 50, 'saved 50: 50';
};

done_testing();
