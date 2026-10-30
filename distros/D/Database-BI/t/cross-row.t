use strict;
use warnings;

use Test::More;
use Test::Mojo;
use Mojo::DOM  ();
use Mojo::File ();
use File::Temp ();
use Mojo::Util qw(url_escape);

use Database::BI::Controller::Dashboard ();

# ---------------------------------------------------------------------------
# Cross-row pass -- Phase 7 item 7.2.
#
# cs=<column>:<function>:<alias>[:<parameter>] writes one row's value from many
# rows: a running total, a moving average, a rank, a share of the whole.  by=
# partitions and order= orders, because the streamstats family reads its rows in
# order and an unordered running total is not a number anybody can act on.
#
# The pass is stage 6 of BI-Phase-7.md's pipeline: after the filters (a window
# is over what the filters left) and before pagination (or page 2 would restart
# every running total).  The page-2 test below is the one that keeps it there.
# ---------------------------------------------------------------------------

# _controller($t, $url) -> a Dashboard controller for that request
#
# build_controller returns the Mojolicious::Controller base, and the pass calls
# helpers on itself, so the controller has to be the real class: construct it
# the way Mojo's own build_controller does.
# The controller holds the transaction weakly, so the test keeps it alive.
my @HOLD;

sub _controller {
	my ($t, $url) = @_;
	my $tx = $t->ua->build_tx(GET => $url);
	push @HOLD, $tx;
	return Database::BI::Controller::Dashboard->new(app => $t->app, tx => $tx);
}

# _pass($c, $records, \@columns) -> ($records, \@columns)
sub _pass {
	my ($c, $records, $columns) = @_;
	return $c->_apply_cross_row($records, $columns);
}

# _vals($fn, \@values, $arg) -> arrayref, the arithmetic of one spec
sub _vals {
	my ($fn, $v, $arg) = @_;
	return [ Database::BI::Controller::Dashboard::_cross_row_values($fn, $v, $arg) ];
}

# _is($got, $want, $name) -> float-tolerant comparison
sub _is {
	my ($got, $want, $name) = @_;
	my $ok = defined $got && defined $want && abs($got - $want) < 1e-9;
	ok($ok, $name) or diag("got " . (defined $got ? $got : 'undef') . ", wanted $want");
}

# --- the functions ---------------------------------------------------------

subtest 'running_total, running_count and running_pct' => sub {
	my @v = (10, 20, undef, 5);

	is_deeply(_vals('running_total', \@v, undef), [10, 30, undef, 35],
		'running_total sums what it has seen, and is undef where the cell is not numeric');
	is_deeply(_vals('running_count', \@v, undef), [1, 2, 3, 4],
		'running_count counts rows, not numbers');
	is_deeply(_vals('running_count', [], undef), [], 'and an empty partition has none');

	my $pct = _vals('running_pct', \@v, undef);
	_is($pct->[0], 10 / 35, 'running_pct is the running total over the partition total');
	_is($pct->[1], 30 / 35, 'at the second row');
	ok(!defined $pct->[2], 'undef where the cell is not numeric');
	_is($pct->[3], 1, 'and it ends at 1');
};

subtest 'window_sum and window_avg' => sub {
	my @v = (10, 20, undef, 5);

	is_deeply(_vals('window_sum', \@v, 2), [10, 30, 20, 5],
		'a window of two sums the last two numeric values, this row included');
	is_deeply(_vals('window_avg', \@v, 2), [10, 15, 20, 5], 'and averages them');

	# A window longer than the partition is the partition.
	is_deeply(_vals('window_avg', [10, 20], 5), [10, 15],
		'a window longer than the partition averages what there is');
	is_deeply(_vals('window_sum', [undef, 4], 3), [undef, 4],
		'and a window with no numeric value is undef');
};

subtest 'lag, delta and pct_change' => sub {
	my @v = (10, 20, undef, 5);

	is_deeply(_vals('lag', \@v, undef), [undef, 10, 20, undef],
		'lag is the previous row, and the first row has none');
	is_deeply(_vals('delta', \@v, undef), [undef, 10, undef, undef],
		'delta is this row less the previous one, undef where either is not numeric');
	is_deeply(_vals('pct_change', \@v, undef), [undef, 1, undef, undef],
		'pct_change is that difference over the previous value');

	my $zero = _vals('pct_change', [0, 5], undef);
	ok(!defined $zero->[1], 'and a previous value of zero has no percentage');
};

subtest 'pct_of_total, rank and zscore' => sub {
	my @v = (10, 20, undef, 5);
	my $share = _vals('pct_of_total', \@v, undef);
	_is($share->[0], 10 / 35, 'pct_of_total is the value over the total');
	ok(!defined $share->[2], 'undef where the cell is not numeric');

	my $sum = 0;
	$sum += $_ for grep { defined } @$share;
	_is($sum, 1, 'so the shares of a partition sum to 1');

	# Ties share a rank and the next rank skips: SQL RANK(), and the reason a
	# reader who knows RANK() will not be surprised by 1, 1, 3.
	is_deeply(_vals('rank', [30, 10, 30, 20], undef), [1, 4, 1, 3],
		'rank counts the values strictly greater, so ties share and skip');

	# mean 5, sample stdev 2.13809... for 2,4,4,4,5,5,7,9
	my $z = _vals('zscore', [2, 4, 4, 4, 5, 5, 7, 9], undef);
	_is($z->[0], (2 - 5) / sqrt(32 / 7), 'zscore standardises against the partition');
	is($z->[4], 0, 'a value at the mean has a z-score of zero');

	my $flat = _vals('zscore', [4, 4, 4], undef);
	ok(!defined $flat->[0], 'and a partition with no spread has no z-score');
	my $one = _vals('zscore', [4], undef);
	ok(!defined $one->[0], 'nor does a partition with one value');
};

# --- the pass itself -------------------------------------------------------

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;

# orders.csv: five orders, four North and ... no: three North, two South, with
# amounts that make every running total, partition total and rank different
# from every other.
my @orders = ('day,region,amount');
push @orders, '2026-01-01,North,10';
push @orders, '2026-01-02,North,20';
push @orders, '2026-01-03,South,30';
push @orders, '2026-01-04,North,40';
push @orders, '2026-01-05,South,50';
Mojo::File->new($data_dir)->child('orders.csv')->spew(join("\n", @orders) . "\n");

# ties.csv: two rows with the same amount, so a rank can be seen to share and
# then skip.
my @ties = ('id,amount');
push @ties, 'a,10';
push @ties, 'b,30';
push @ties, 'c,30';
push @ties, 'd,20';
Mojo::File->new($data_dir)->child('ties.csv')->spew(join("\n", @ties) . "\n");

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir,
	model_dir => $model_dir,
});

# _table($body) -> { headers => [...], rows => [[...], ...] }
sub _table {
	my $dom = Mojo::DOM->new($_[0]);
	my $tbl = $dom->at('#bi-table');
	return { headers => [], rows => [] } unless $tbl;
	my $head = $tbl->at('thead');
	my @headers = $head ? map { $_->text } @{ $head->find('th')->to_array } : ();
	my @rows = map {
		[ map { $_->text } @{ $_->find('td')->to_array } ]
	} @{ $tbl->at('tbody')->find('tr')->to_array };
	return { headers => \@headers, rows => \@rows };
}

# _col(\%table, $name) -> index of a column, or -1
sub _col {
	my ($table, $name) = @_;
	my @h = @{ $table->{headers} };
	for my $i (0 .. $#h) {
		return $i if $h[$i] eq $name;
	}
	return -1;
}

subtest 'the pass writes a column onto every row, and appends it to the list' => sub {
	my $c = _controller($t, '/view/orders?cs=amount:running_total:ytd&order=day:asc');

	my @records = map { { %$_ } } (
		{ day => '2026-01-01', region => 'North', amount => 10 },
		{ day => '2026-01-02', region => 'North', amount => 20 },
		{ day => '2026-01-03', region => 'South', amount => 30 },
	);

	my ($out, $cols) = _pass($c, \@records, [qw(day region amount)]);
	is_deeply([@$cols], [qw(day region amount ytd)], 'the produced column is appended to the list');
	is_deeply([map { $_->{ytd} } @$out], [10, 30, 60], 'and written onto every row in order');
	ok($c->stash('_virtual_columns')->{ytd},
		'and registered as virtual, so no backend is asked for a column it has never heard of');
	is_deeply([@{ $c->stash('_cross_row_columns') }], ['ytd'],
		'and named for the routes that ask for their columns after the slice');
};

subtest 'by= partitions, and each partition starts again' => sub {
	my $c = _controller($t,
		'/view/orders?cs=amount:running_total:sub&by=region&order=day:asc');

	my @records = map { { %$_ } } (
		{ day => '2026-01-01', region => 'North', amount => 10 },
		{ day => '2026-01-02', region => 'South', amount => 30 },
		{ day => '2026-01-03', region => 'North', amount => 20 },
	);
	my ($out) = _pass($c, \@records, [qw(day region amount)]);
	is_deeply([map { $_->{sub} } @$out], [10, 30, 30],
		'the North total after the first North row is 10, and the second North row continues it');

	# An empty partition key is a partition, not a row to drop: the pivot drops
	# such rows because a cell needs a label, but a windowed column has to cover
	# every displayed row, so the unlabelled rows add up together.
	my @blank = map { { %$_ } } (
		{ day => '2026-01-01', region => '', amount => 5 },
		{ day => '2026-01-02', region => 'North', amount => 10 },
		{ day => '2026-01-03', amount => 7 },
	);
	my ($blank_out) = _pass($c, \@blank, [qw(day region amount)]);
	is_deeply([map { $_->{sub} } @$blank_out], [5, 10, 12],
		'so the two rows with no region add up together, and neither is dropped');
};

subtest 'order= sorts stably, and numbers sort as numbers' => sub {
	my $c = _controller($t, '/view/orders?cs=amount:running_total:run&order=day:desc');

	my @records = map { { %$_ } } (
		{ day => '2026-01-02', amount => 20 },
		{ day => '2026-01-01', amount => 10 },
		{ day => '2026-01-03', amount => 30 },
	);
	my ($out) = _pass($c, \@records, [qw(day amount)]);
	is_deeply([map { $_->{day} } @$out], [qw(2026-01-02 2026-01-01 2026-01-03)],
		'order= decides the order the pass reads the rows in; it does not reorder the table');
	is_deeply([map { $_->{run} } @$out], [50, 60, 30],
		'so each row carries the total reading 30, then 20, then 10');
};

subtest 'the functions reach /view, page after page' => sub {
	$t->get_ok('/view/orders?cs=amount:running_total:ytd&order=day:asc&per_page=2')
		->status_is(200);

	my $p1 = _table($t->tx->res->body);
	my $col = _col($p1, 'ytd');
	ok($col >= 0, 'the table shows the running total as a column of its own');
	is(scalar @{ $p1->{rows} }, 2, 'page one holds two rows');
	is_deeply([ map { $_->[$col] } @{ $p1->{rows} } ], [10, 30],
		'with the running total of the first two orders');

	# The whole point of stage 6 running before the slice: page 2 must carry on,
	# not start again.  A pass applied to the sliced page would show 10 and 40.
	$t->get_ok('/view/orders?cs=amount:running_total:ytd&order=day:asc&per_page=2&page=2')
		->status_is(200);
	my $p2 = _table($t->tx->res->body);
	my $c2 = _col($p2, 'ytd');
	is_deeply([ map { $_->[$c2] } @{ $p2->{rows} } ], [60, 100],
		'and page two continues it rather than restarting');

	$t->get_ok('/view/orders?cs=amount:running_total:ytd&order=day:asc&per_page=2&page=3')
		->status_is(200);
	my $p3 = _table($t->tx->res->body);
	my $c3 = _col($p3, 'ytd');
	is_deeply([ map { $_->[$c3] } @{ $p3->{rows} } ], [150], 'and page three ends at the total');

	# A window is over the rows the filters left, not over the file: the three
	# orders above 20 are 30, 40 and 50, so their running total ends at 120.
	$t->get_ok('/view/orders?f=amount:gt:20&cs=amount:running_total:ytd&order=day:asc')
		->status_is(200);
	my $filtered = _table($t->tx->res->body);
	my $fc = _col($filtered, 'ytd');
	is_deeply([ map { $_->[$fc] } @{ $filtered->{rows} } ], [30, 70, 120],
		'so a filter narrows the window as well as the rows');
};

subtest 'the export carries the same column and the same numbers' => sub {
	$t->get_ok('/export?l=' . url_escape('table:orders')
			. '&cs=' . url_escape('amount:running_total:ytd') . '&order=day:asc')
		->status_is(200)
		->content_type_like(qr/csv/);

	my @lines = split /\r?\n/, $t->tx->res->body;
	my @header = split /,/, $lines[0] // '';
	my ($at) = grep { $header[$_] eq 'ytd' } 0 .. $#header;
	ok(defined $at, 'the export has the running-total column');

	my @col = map { (split /,/, $_)[$at] } grep { length } @lines[1 .. $#lines];
	is_deeply(\@col, [10, 30, 60, 100, 150], 'with the numbers the page shows');
};

subtest 'pct_of_total and rank on the page' => sub {
	$t->get_ok('/view/orders?cs=amount:pct_of_total:share')->status_is(200);
	my $table = _table($t->tx->res->body);
	my $at = _col($table, 'share');
	ok($at >= 0, 'a share column appears without any order= (the eventstats family is order-free)');

	my $total = 0;
	$total += $_->[$at] for @{ $table->{rows} };
	_is($total, 1, 'and the shares of the whole set sum to 1');

	$t->get_ok('/view/ties?cs=amount:rank:place&order=amount:desc')->status_is(200);
	my $ranks = _table($t->tx->res->body);
	my $rcol = _col($ranks, 'place');
	my %rank = map { $_->[0] => $_->[$rcol] } @{ $ranks->{rows} };
	is($rank{b}, 1, 'the highest value ranks 1');
	is($rank{c}, 1, 'a tie shares that rank');
	is($rank{d}, 3, 'and the next rank skips the one the tie used');
	is($rank{a}, 4, 'so four rows give ranks 1, 1, 3, 4');
};

subtest 'a moving average' => sub {
	$t->get_ok('/view/orders?cs=amount:window_avg:ma2:2&order=day:asc')->status_is(200);
	my $table = _table($t->tx->res->body);
	my $at = _col($table, 'ma2');
	ok($at >= 0, 'the window column appears');
	my @got = map { $_->[$at] } @{ $table->{rows} };
	_is($got[0], 10, 'the first window holds one value');
	_is($got[1], 15, 'the second averages 10 and 20');
	_is($got[2], 25, 'and the third averages 20 and 30');
};

subtest 'a cross-row column can be aggregated' => sub {
	# North's running totals are 10, 30 and 70; South's are 30 and 80.  The
	# column is virtual, so the fold has to happen in Perl rather than being
	# pushed to a backend that has never heard of "ytd".
	$t->get_ok('/bar?l=' . url_escape('table:orders') . '&cat=region'
			. '&val=ytd&cs=' . url_escape('amount:running_total:ytd') . '&order=day:asc')
		->status_is(200);

	my $body = $t->tx->res->body;
	# The rows' running totals are 10, 30, 60, 100, 150; North's are the first,
	# second and fourth of those, and South's are the third and fifth.
	# The JSON encoder does not promise a key order, so ask for the pair.
	like($body, qr/(?:"value":140,"label":"North"|"label":"North","value":140)/,
		'North sums the running totals of its rows');
	like($body, qr/(?:"value":210,"label":"South"|"label":"South","value":210)/,
		'and so does South');
};

subtest 'what a run refuses, and with which status' => sub {
	my @cases = (
		[ 'cs=' . url_escape('amount:running_total:ytd'), 400,
			qr/needs order=/, 'the streamstats family without order=' ],
		[ 'cs=' . url_escape('amount:window_avg:ma'), 400,
			qr/takes a whole number/, 'a window function with no window' ],
		[ 'cs=' . url_escape('amount:window_avg:ma:x'), 400,
			qr/takes a whole number/, 'and with a window that is not a number' ],
		[ 'cs=' . url_escape('amount:rank:place:7'), 400,
			qr/takes no parameter/, 'a parameter on a function that takes none' ],
		[ 'cs=' . url_escape('nosuch:rank:place'), 400,
			qr/not in this view/, 'a column that is not in the view' ],
		[ 'cs=' . url_escape('amount:nosuch:place'), 400,
			qr/Unknown cross-row function/, 'an unknown function' ],
		[ 'cs=' . url_escape('amount:rank:amount'), 400,
			qr/already a column/, 'an alias that is already a column' ],
		[ 'cs=' . url_escape('amount:rank:place') . '&by=nosuch', 400,
			qr/by=nosuch names "nosuch"/, 'a partition column that is not in the view' ],
		[ 'cs=' . url_escape('amount:running_total:ytd') . '&order=nosuch', 400,
			qr/order=nosuch names "nosuch"/, 'an order column that is not in the view' ],
		[ 'cs=' . url_escape('amount:running_total:ytd') . '&order=day:sideways', 400,
			qr/must be <column>/, 'a direction that is neither asc nor desc' ],
	);

	for my $case (@cases) {
		my ($query, $status, $pattern, $name) = @$case;
		$t->get_ok("/view/orders?$query")->status_is($status, "$name is a $status")
			->content_like($pattern, "$name says so");
	}

	$t->get_ok('/bar?l=' . url_escape('table:orders') . '&cat=region&val=amount'
			. '&cs=' . url_escape('amount:running_total:ytd'))
		->status_is(400)
		->content_like(qr/needs order=/, 'and an aggregating route refuses it too');

	# The export answers a missing table with a 404, so it has to know that the
	# 400 it has already rendered is the answer, not an empty table.
	$t->get_ok('/export?l=' . url_escape('table:orders')
			. '&cs=' . url_escape('amount:window_avg:x'))
		->status_is(400)
		->content_like(qr/takes a whole number/, 'and the export keeps its 400 rather than turning it into a 404');
};

done_testing;
