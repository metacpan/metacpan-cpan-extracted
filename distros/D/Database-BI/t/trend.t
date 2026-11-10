#!/usr/bin/env perl

# The line graph's trend line: a least-squares fit (Statistics::LineFit) of Y
# against each point's place on the axis, offered beside Min, Avg and Max.

use strict;
use warnings;

use DBI;
use File::Spec;
use File::Temp qw(tempdir);
use Mojo::File;
use Test::Mojo;
use Test::Most;

my $data = tempdir(CLEANUP => 1);

# y = 3 + 2i exactly, then a noisy series, and a flat one.
Mojo::File->new($data, 'line.csv')->spew(join("\n", 'day,qty', map { "d$_," . (3 + 2 * $_) } 0 .. 9) . "\n");
Mojo::File->new($data, 'noisy.csv')->spew("day,qty\na,1\nb,3\nc,2\nd,5\ne,4\n");
Mojo::File->new($data, 'flat.csv')->spew("day,qty\na,7\nb,7\nc,7\n");
Mojo::File->new($data, 'one.csv')->spew("day,qty\na,7\n");

my $db  = File::Spec->catfile($data, 'items.sqlite');
my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '', { RaiseError => 1, PrintError => 0 });
$dbh->do('CREATE TABLE items (day TEXT, qty INTEGER)');
$dbh->do('INSERT INTO items VALUES (?, ?)', undef, "d$_", 3 + 2 * $_) for 0 .. 9;
$dbh->disconnect;

my $t = Test::Mojo->new('Database::BI', { data_dir => $data, model_dir => tempdir(CLEANUP => 1) });

sub trend_text {
	my ($table) = @_;
	$t->get_ok("/graph?l=table:$table&x=day&y=qty")->status_is(200);
	my $el = $t->tx->res->dom->at('#rl-trend-text');
	return $el ? $el->text : undef;
}

subtest '_trend_line' => sub {
	my $fit = \&Database::BI::Controller::Dashboard::_trend_line;
	my $r = $fit->([ map { 3 + 2 * $_ } 0 .. 9 ]);
	is sprintf('%.6f', $r->{slope}), '2.000000', 'slope';
	is sprintf('%.6f', $r->{intercept}), '3.000000', 'intercept';
	is sprintf('%.6f', $r->{r_squared}), '1.000000', 'a perfect fit';

	$r = $fit->([1, 3, 2, 5, 4]);
	is sprintf('%.2f', $r->{slope}), '0.80', 'noisy: slope 0.8';
	is sprintf('%.2f', $r->{intercept}), '1.40', '... intercept 1.4';
	is sprintf('%.2f', $r->{r_squared}), '0.64', '... R squared 0.64';

	$r = $fit->([7, 7, 7]);
	is $r->{slope} + 0, 0, 'flat: slope 0';
	is $r->{r_squared} + 0, 1, '... on its line';

	is $fit->([7]), undef, 'one point: no line';
	is $fit->([]), undef, 'none: no line';
};

subtest 'the graph page offers it' => sub {
	is trend_text('line'), "2 per point, R\x{B2} 1.00", 'a straight series';
	$t->element_exists('input#rl-trend[type=checkbox]', 'a checkbox beside Min, Avg and Max')
	  ->element_exists('#rl-max', 'they are still there')
	  ->content_like(qr/slope:\s+2,/, 'the script has the slope')
	  ->content_like(qr/intercept:\s+3,/, '... and the intercept');
	ok !$t->tx->res->dom->at('input#rl-trend[checked]'), 'off until ticked, as the others are';

	is trend_text('noisy'), "0.8 per point, R\x{B2} 0.64", 'a noisy series';
	is trend_text('flat'), "0 per point, R\x{B2} 1.00", 'a flat one';
	is trend_text('items'), "2 per point, R\x{B2} 1.00", 'SQLite, where min/max/avg are pushed to SQL';

	local $ENV{BI_FORCE_PERL_AGG} = 1;
	$t->get_ok('/graph?l=table:items&x=day&y=qty')->status_is(200);
	like $t->tx->res->body, qr/Avg \(12\)/,
		'the Perl path (Statistics::Lite) gives the same mean';
	like $t->tx->res->body, qr/Min \(3\).*Max \(21\)/s, '... min and max';
};

subtest 'not offered without two points or on a multi-series chart' => sub {
	is trend_text('one'), undef, 'one point: no trend checkbox';
	$t->get_ok('/graph?l=table:noisy&x=day&y=qty&series=day')->status_is(200);
	ok !$t->tx->res->dom->at('#rl-trend'), 'series=: no trend (nor Min/Avg/Max)';
};

done_testing();
