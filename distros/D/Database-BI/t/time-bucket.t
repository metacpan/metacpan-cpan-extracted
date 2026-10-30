use strict;
use warnings;
use Test::More;
use Test::Mojo;
use POSIX       ();
use Mojo::DOM   ();
use Mojo::File  ();
use Mojo::JSON  qw(decode_json encode_json);
use File::Temp  ();
use Mojo::Util  qw(url_escape);
use Database::BI::Calc ();
use Database::BI::Controller::Dashboard ();

# ---------------------------------------------------------------------------
# Time buckets -- Phase 7 item 7.1.
#
# The primitive is two functions in the calc grammar, span() and epoch(), with
# hour()/minute()/second() beside them, and the sugar is span=/tcol=/as= on the
# aggregating routes (plus agg= on /graph, which turns it into a timechart).
# Everything is local time, as the date functions and the relative time ranges
# already are.
#
# The unit tests below are table-driven and locale-independent: a bucket is
# asserted against the local clock the value itself implies (POSIX::mktime for
# an epoch, the value's own date for a day), never against a hardcoded epoch,
# so the file passes in any time zone.  Most HTTP tests use fixed timestamps so
# that a bucket label can be asserted literally; the one test that applies a
# relative range dates its rows from the run's own clock, because a range is
# relative to now and a pinned date would stop being inside the window.
# ---------------------------------------------------------------------------

my $span  = \&Database::BI::Calc::_span_label;
my $parse = \&Database::BI::Calc::_parse_time;
my $iv    = \&Database::BI::Calc::span_interval;

# _calc($expr, \%row) -> value | '(unparseable)' for a value that did not read
sub _calc {
	my ($expr, $row) = @_;
	my $calc = Database::BI::Calc->new(expr => $expr, columns => [ sort keys %$row ]);
	die "compile error in $expr: " . $calc->error if $calc->has_error;
	my $v = $calc->evaluate($row);
	return defined $v ? $v : '(unparseable)';
}

# _local($y, $mon, $day, $h, $mi, $s) -> epoch, in the local zone
sub _local {
	my ($y, $mon, $day, $h, $mi, $s) = @_;
	return POSIX::mktime($s // 0, $mi // 0, $h // 0, $day, $mon - 1, $y - 1900);
}

sub _bucket {
	my ($value, $interval) = @_;
	my $spec = $iv->($interval);
	die "bad interval $interval" unless $spec;
	return $span->($value, $spec);
}

# _bucket_epoch($value, $interval) -> the epoch the bucket starts at, which is
# how a bucket is checked to contain its value in any time zone.
sub _bucket_epoch {
	my ($value, $interval) = @_;
	my $spec  = $iv->($interval);
	my $label = $span->($value, $spec);
	return undef unless defined $label;
	return $parse->($label)->{epoch};
}

# _stamp($epoch) -> 'YYYY-MM-DDTHH:MM:SS' in local time
sub _stamp {
	my @lt = localtime($_[0]);
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02d',
		$lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2], $lt[1], $lt[0];
}

# _pattern_stamp($epoch) -> '27/10/2026 14:05', the shape a European export
# writes and the stored pattern %d/%m/%Y %H:%M reads.
sub _pattern_stamp {
	my @lt = localtime($_[0]);
	return sprintf '%02d/%02d/%04d %02d:%02d',
		$lt[3], $lt[4] + 1, $lt[5] + 1900, $lt[2], $lt[1];
}

# _ts_stamp($epoch) -> 'YYYY-MM-DDTHH:MM:00', what as=timestamp normalises a
# %H:%M pattern to: seconds are not in the pattern, so they are zero.
sub _ts_stamp {
	my @lt = localtime($_[0]);
	return sprintf '%04d-%02d-%02dT%02d:%02d:00',
		$lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2], $lt[1];
}

# ---------------------------------------------------------------------------
# The bucket for a value, by unit.  Every expectation is the value's own local
# date or clock, so this is the same table in every time zone.
# ---------------------------------------------------------------------------

subtest 'span() returns the start of the interval a value falls in' => sub {
	my @cases = (
		# value                    interval  expected label
		[ '2026-10-27T14:05:03', '1s',  '2026-10-27T14:05:03' ],
		[ '2026-10-27T14:05:03', '30s', '2026-10-27T14:05:00' ],
		[ '2026-10-27T14:05:03', '1m',  '2026-10-27T14:05:00' ],
		[ '2026-10-27T14:05:03', '15m', '2026-10-27T14:00:00' ],
		[ '2026-10-27T14:05:03', '1h',  '2026-10-27T14:00:00' ],
		[ '2026-10-27T14:05:03', '1d',  '2026-10-27' ],
		[ '2026-10-27T14:05:03', '1w',  '2026-10-26' ],
		[ '2026-10-27T14:05:03', '1mon', '2026-10-01' ],
		[ '2026-10-27T14:05:03', '1q',  '2026-10-01' ],
		[ '2026-10-27T14:05:03', '1y',  '2026-01-01' ],
		# Boundaries belong to the later bucket.
		[ '2026-10-27T14:00:00', '1h',  '2026-10-27T14:00:00' ],
		[ '2026-10-27T13:59:59', '1h',  '2026-10-27T13:00:00' ],
		[ '2026-10-01T00:00:00', '1mon', '2026-10-01' ],
		[ '2026-09-30T23:59:59', '1mon', '2026-09-01' ],
		[ '2026-01-01T00:00:00', '1y',  '2026-01-01' ],
		[ '2025-12-31T23:59:59', '1y',  '2025-01-01' ],
		# A leap day, and the month it is in.
		[ '2028-02-29T12:00:00', '1d',  '2028-02-29' ],
		[ '2028-02-29T12:00:00', '1mon', '2028-02-01' ],
		[ '2028-02-29T12:00:00', '1q',  '2028-01-01' ],
		# Quarter edges.
		[ '2026-03-31T23:00:00', '1q',  '2026-01-01' ],
		[ '2026-04-01T00:00:00', '1q',  '2026-04-01' ],
		[ '2026-07-01T00:00:00', '1q',  '2026-07-01' ],
		# Weeks run Monday to Sunday, and the label is that Monday.
		[ '2026-10-25T10:00:00', '1w',  '2026-10-19' ],   # a Sunday
		[ '2026-10-26T00:00:00', '1w',  '2026-10-26' ],   # the Monday after
		[ '2027-01-01T00:00:00', '1w',  '2026-12-28' ],   # across the year end
		# A date that carries no time is read as local midnight.
		[ '2026-10-27',          '1d',  '2026-10-27' ],
		[ '2026-10-27',          '1h',  '2026-10-27T00:00:00' ],
	);

	for my $case (@cases) {
		my ($value, $interval, $want) = @$case;
		is _bucket($value, $interval), $want, "span($value, '$interval')";
	}
};

subtest 'a count above one widens the bucket and keeps the calendar' => sub {
	# Three-month buckets line up with the calendar, not with the first value
	# seen, which is what makes any three of them a quarter of the year.
	is _bucket('2026-11-15T00:00:00', '3mon'), '2026-10-01', '3mon puts November in Oct-Dec';
	is _bucket('2026-10-01T00:00:00', '3mon'), '2026-10-01', 'and October starts it';
	is _bucket('2026-09-30T23:00:00', '3mon'), '2026-07-01', 'September is in the bucket before';
	is _bucket('2026-05-05T00:00:00', '6mon'), '2026-01-01', '6mon puts May in Jan-Jun';
	is _bucket('2026-07-01T00:00:00', '6mon'), '2026-07-01', 'and July starts the next one';
	is _bucket('2024-02-29T00:00:00', '5y'),  '2020-01-01', '5y keeps the leap years inside it';
	is _bucket('2020-01-02T00:00:00', '5y'), '2020-01-01', 'and starts where the count says';

	# Two consecutive days share a 2d bucket, and so do the two weeks of a 2w
	# one: the widening does not move the calendar, only the width.
	is _bucket('2026-10-27T00:00:00', '2d'), _bucket('2026-10-26T00:00:00', '2d'),
		'two consecutive days share a 2d bucket';
	is _bucket('2026-10-27T00:00:00', '2w'), _bucket('2026-10-26T00:00:00', '2w'),
		'and the two weeks of a 2w one are Monday-aligned as well';

	# Sub-day intervals are floored out of the epoch, as the specification says,
	# so a bucket is checked the way it is defined: it contains its value, and
	# it is at most one step wide.  That holds in every time zone, which a
	# 'starts at local midnight' assertion for 6h would not.
	for my $case ([ '1s', 1 ], [ '30s', 30 ], [ '15m', 900 ], [ '1h', 3600 ], [ '6h', 21_600 ]) {
		my ($interval, $step) = @$case;
		my $value = _local(2026, 10, 27, 14, 37, 21);
		my $lo    = _bucket_epoch($value, $interval);
		cmp_ok $lo, '<=', $value, "span('$interval') does not start after its value";
		cmp_ok $value - $lo, '<', $step, "and is less than one $interval wide";
		is $lo % $step, 0, "and starts on a multiple of $interval from the epoch";
	}
};

subtest 'a day bucket is the local date, whatever the clock does' => sub {
	# The two dates a daylight-saving change falls on in the northern
	# hemisphere.  A value at either end of the day lands in the same bucket on
	# both of them: a day counted as 86,400 fixed seconds would move one of
	# these four into the neighbouring date wherever DST applies.  The
	# assertions hold in a zone without DST as well, which is the point of
	# expressing them this way rather than pinning a transition.
	for my $day ('2026-03-08', '2026-11-01') {
		is _bucket("${day}T00:30:00", '1d'), $day, "$day: the day starts where the clock says";
		is _bucket("${day}T23:30:00", '1d'), $day, "$day: and ends there, however many hours long it is";
	}

	# An hour bucket is the value's own clock hour, on that day too.  The
	# 23-hour day is the one a bucket derived by dividing the day would get
	# wrong, so this is the case worth asserting.
	for my $hour (0, 1, 2, 3, 23) {
		my $epoch = _local(2026, 3, 8, $hour, 30, 0);
		my @lt    = localtime($epoch);
		is _bucket(_stamp($epoch), '1h'),
			sprintf('%04d-%02d-%02dT%02d:00:00', $lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2]),
			"the hour bucket of a value at $hour:30 is its own hour";
	}
};

subtest 'the three input shapes, and the one rule that separates two of them' => sub {
	my $epoch = _local(2026, 10, 27, 14, 5, 3);

	is _calc("epoch(when)",           { when => '2026-10-27T14:05:03' }), $epoch, 'an ISO timestamp';
	is _calc("epoch(when)",           { when => '2026-10-27 14:05:03' }), $epoch, 'with a space instead of a T';
	is _calc("epoch(when)",           { when => '2026-10-27' }),          _local(2026, 10, 27), 'a date is midnight';
	is _calc("epoch(when)",           { when => $epoch }),                $epoch, 'ten digits are seconds';
	is _calc("epoch(when)",           { when => $epoch . '000' }),        $epoch, 'thirteen digits are milliseconds';
	is _calc("epoch(when, '%d/%m/%Y %H:%M')", { when => '27/10/2026 14:05' }),
		_local(2026, 10, 27, 14, 5), 'a pattern reads what ISO does not';

	is _calc("epoch(when, '%d-%b-%Y')", { when => '27-Oct-2026' }), _local(2026, 10, 27),
		'a month abbreviation is a month';

	is _calc("hour(when)",   { when => '2026-10-27T14:05:03' }),   14, 'hour() reads the clock';
	is _calc("minute(when)", { when => '2026-10-27T14:05:03' }),    5, 'minute()';
	is _calc("second(when)", { when => '2026-10-27T14:05:03' }),    3, 'second()';
	is _calc("hour(when)",   { when => '27/10/2026 14:05' }),  '(unparseable)',
		'a shape nobody told it about has no hour';
	is _calc("hour(when)",   { when => '2026-10-27' }), '(unparseable)',
		'and a date that carries no time has none either, rather than a made-up zero';

	# The time of day survives the round trip into a bucket and back.
	my @ld = localtime(_local(2026, 10, 27, 23, 59, 59));
	is _calc("hour(when)", { when => _calc("epoch(when)", { when => '2026-10-27T23:59:59' }) }),
		$ld[2], 'an epoch in means the same hour out';
};

subtest 'a value that cannot be read is unparseable, not silently elsewhere' => sub {
	for my $bad ('', 'not a date', '2026-13-01', '2026-02-31', '2026-10-27T25:00:00', '27/10/2026') {
		is _calc("epoch(when)", { when => $bad }), '(unparseable)', "epoch('$bad')";
		is _calc("span(when, '1d')", { when => $bad }), '(unparseable)', "span('$bad', '1d')";
	}

	is $parse->('2026-02-31'), undef, 'a date that does not exist does not read as one';
	is $parse->('2026-04-31'), undef, 'in any month';
	is $parse->('2028-02-29')->{epoch}, _local(2028, 2, 29), 'but a leap day in a leap year does';
	is $parse->('2028-02-29')->{has_time}, 0, 'and carries no time of day';
};

subtest 'the interval vocabulary is checked when the expression compiles' => sub {
	for my $good (qw(1s 30s 15m 1h 6h 1d 2d 1w 2w 1mon 3mon 1q 2q 1y 5y)) {
		ok $iv->($good), "$good is an interval";
	}
	for my $bad ('', '1', 'h', 'x', '1x', '0h', '0s', '-1d', '1H', '1mon ' . 'x', 'm1') {
		ok !$iv->($bad), "'" . $bad . "' is not";
	}

	my $calc = Database::BI::Calc->new(expr => "span(when, '1x')", columns => ['when']);
	like $calc->error, qr/Unknown time bucket '1x'/, 'a bad interval is a compile error';
	like $calc->error, qr/1h or 15m/, 'and the message offers the vocabulary';

	$calc = Database::BI::Calc->new(expr => "span(when, 1)", columns => ['when']);
	like $calc->error, qr/must be a quoted literal/, 'the interval is a literal, not an expression';

	$calc = Database::BI::Calc->new(expr => "epoch(when, '%Q')", columns => ['when']);
	like $calc->error, qr/Unsupported time format token %Q/, 'an unknown token is refused';

	$calc = Database::BI::Calc->new(expr => "epoch(when, '%H:%M')", columns => ['when']);
	like $calc->error, qr/must name a date/, 'a pattern with no date in it is refused';

	$calc = Database::BI::Calc->new(expr => 'span(when)', columns => ['when']);
	like $calc->error, qr/Unknown time bucket/, 'and the interval is required';

	# The functions are part of the documented vocabulary, so a misspelt one
	# still fails the way it always has.
	$calc = Database::BI::Calc->new(expr => 'spanx(when)', columns => ['when']);
	like $calc->error, qr/Unknown function 'spanx'/, 'a misspelt function is still unknown';
};

# ---------------------------------------------------------------------------
# The routes
# ---------------------------------------------------------------------------

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;

# hours.csv: three consecutive hours across two regions, so a bucket total is
# not the total of any one row.  09:00 holds 10 + 20, 10:00 holds 30 + 50,
# 11:00 holds 1000 -- three different answers for sum, count and max.
my @rows = ('id,when,region,amount');
push @rows, 'A1,2026-10-27T09:05:00,North,10';
push @rows, 'A2,2026-10-27T09:45:00,South,20';
push @rows, 'B1,2026-10-27T10:15:00,North,30';
push @rows, 'B2,2026-10-27T10:30:00,South,50';
push @rows, 'C1,2026-10-27T11:10:00,North,1000';
Mojo::File->new($data_dir)->child('hours.csv')->spew(join("\n", @rows) . "\n");

# local.csv: the same three hours written the way a European export writes them,
# which needs a stored pattern before anything can read the time of day.
my @local = ('id,when,amount');
push @local, 'L1,27/10/2026 14:05,5';
push @local, 'L2,27/10/2026 14:45,7';
push @local, 'L3,27/10/2026 15:10,9';
Mojo::File->new($data_dir)->child('local.csv')->spew(join("\n", @local) . "\n");

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir,
	model_dir => $model_dir,
});

# The numbers a page embedded for its chart, in the order they appear.
sub _values {
	my ($body) = @_;
	return [ $body =~ /"value":(-?\d+(?:\.\d+)?)/g ];
}

sub _title {
	my ($body) = @_;
	my ($t) = $body =~ m{<title>([^<]*)</title>};
	$t //= '';
	$t =~ s/ &#x2014;.*//;
	return $t;
}

subtest 'the aggregating routes bucket the dimension they already take' => sub {
	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1h')->status_is(200);
	my $bar = $t->tx->res->body;
	is_deeply _values($bar), [ 30, 80, 1000 ],
		'/bar sums the rows of each hour, in bucket order';
	is _title($bar), 'amount by when_span', 'and the title names the column it grouped by';

	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1h&as=hour')->status_is(200);
	is _title($t->tx->res->body), 'amount by hour', 'as= names the bucket column';

	# The same request without the sugar is the raw timestamps: three groups of
	# one row each, which is what "a bucket is a choice about the dimension"
	# means in numbers.
	$t->get_ok('/bar?l=table:hours&cat=when&val=amount')->status_is(200);
	is_deeply _values($t->tx->res->body), [ 10, 20, 30, 50, 1000 ],
		'and without span= the column is untouched';

	$t->get_ok('/graph?l=table:hours&x=when&y=amount&span=1mon&agg=max')->status_is(200);
	is_deeply _values($t->tx->res->body), [ 1000 ], 'a month bucket over every row, by max';

	$t->get_ok('/pivot?l=table:hours&rows=when&m=amount:sum:total&span=1h')->status_is(200);
	my $pivot = Mojo::DOM->new($t->tx->res->body)->all_text;
	like $pivot, qr/2026-10-27T09:00:00/, '/pivot buckets its row dimension too';
	like $pivot, qr/2026-10-27T11:00:00/, 'and shows every bucket';
	like $pivot, qr/30/, 'with the bucket total';

	# The bucket is a calculated field, so the filter stage sees it: a reader can
	# narrow to one bucket, which is what says the field is added before the rows
	# are filtered and not after they are grouped.
	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1h&f='
		. url_escape('when_span:eq:2026-10-27T10:00:00'))->status_is(200);
	is_deeply _values($t->tx->res->body), [80], 'a filter on the bucket column selects one bucket';

	# Every route that names a single dimension honours the sugar; the columns
	# differ, the arithmetic does not.
	for my $req (
		'/pie?l=table:hours&cat=when&val=amount&span=1d',
		'/stacked?l=table:hours&cat=when&series=region&val=amount&span=1h',
		'/treemap?l=table:hours&group=when&val=amount&span=1h',
		'/combo?l=table:hours&cat=when&bar_val=amount&line_val=amount&span=1h',
		'/heatmap?l=table:hours&x=when&y=region&val=amount&span=1h',
	) {
		$t->get_ok($req)->status_is(200, "$req renders");
		like $t->tx->res->body, qr/when_span/, "$req grouped by the bucket column";
	}
};

subtest 'the table view and the export gain the bucket column' => sub {
	$t->get_ok('/view/hours?span=1h&tcol=when')->status_is(200);
	my $body = $t->tx->res->body;
	like $body, qr/when_span/, 'the table has the bucket column';
	like $body, qr/2026-10-27T09:00:00/, 'with a bucket in it';
	like $body, qr/2026-10-27T09:05:00/, 'beside the raw timestamp it came from';
	# There is no exported href on this page -- Save export is a POST built by the
	# panel's own script -- so what carries the bucket is the parameter list that
	# script collects from the URL it was served with.
	like $body, qr/\['span', 'tcol', 'as'\]/, 'and its Save-export path carries the bucket';

	# The raw column is the route's own; the bucket is added, never swapped in.
	$t->get_ok('/view/hours?span=1d&tcol=when&as=bucket')->status_is(200);
	like $t->tx->res->body, qr/bucket/, 'as= names it here too';

	$t->get_ok('/export?l=table:hours&format=csv&span=1h&tcol=when')->status_is(200);
	my @csv = split /\n/, $t->tx->res->body;
	like $csv[0], qr/when_span/, 'the CSV header has the bucket column';
	like $csv[1], qr/2026-10-27T09:00:00/, 'and its rows hold buckets';

	# /export also accepts the aggregating routes' own dimension params, so a
	# chart's URL can be pasted into it and mean the same thing.
	$t->get_ok('/export?l=table:hours&format=csv&span=1h&cat=when')->status_is(200);
	like $t->tx->res->body, qr/when_span/, 'a chart URL works at /export';
};

subtest 'a request that cannot be bucketed is refused, not ignored' => sub {
	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1fortnight')
		->status_is(400)
		->content_like(qr/Unknown time bucket "1fortnight"/, 'the refusal names the interval')
		->content_like(qr/span=/, 'and the parameter it came from');

	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&tcol=when')
		->status_is(400)
		->content_like(qr/span=<interval> is missing/, 'tcol= without span= is refused');

	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1h&tcol=nope')
		->status_is(400)
		->content_like(qr/not in this view/, 'a column that is not there is refused');

	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1h&as=when')
		->status_is(400)
		->content_like(qr/already defined/, 'a name that is already a column is refused');

	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1h&as=not a name')
		->status_is(400)
		->content_like(qr/not a usable column name/, 'and so is a name no column could have');

	$t->get_ok('/bar?l=table:hours&cat=when&val=amount&span=1h&c=' . url_escape('when_span:1'))
		->status_is(400)
		->content_like(qr/already defined/, "the reader's own c= field is not silently overridden");

	# Ambiguity is a refusal, because guessing which of two dimensions the
	# reader meant is how a chart ends up grouping by the wrong one.
	$t->get_ok('/pivot?l=table:hours&rows=when,region&m=amount:sum:total&span=1h')
		->status_is(400)
		->content_like(qr/needs one column to bucket/, 'two row dimensions need tcol=');
	$t->get_ok('/pivot?l=table:hours&rows=when,region&m=amount:sum:total&span=1h&tcol=when')
		->status_is(200)
		->content_like(qr/2026-10-27T09:00:00/, 'and tcol= resolves which one');

	# A table view has no dimension, so it needs one named.
	$t->get_ok('/view/hours?span=1d')->status_is(400)->content_like(qr/tcol=/, 'a table needs tcol=');

	# Nothing about the sugar is on by default.
	$t->get_ok('/view/hours')->status_is(200);
	unlike $t->tx->res->body, qr/when_span/, 'no bucket without span=';
};

subtest '?agg= turns /graph into a timechart' => sub {
	$t->get_ok('/graph?l=table:hours&x=when&y=amount&span=1h&agg=sum')->status_is(200);
	my $body = $t->tx->res->body;
	is_deeply _values($body), [ 30, 80, 1000 ],
		'one point per bucket, summed the way /bar sums it';
	is _title($body), 'amount by when_span', 'with a title that says what was aggregated';

	# The measure vocabulary is the pivot's, so the Perl-computed ones work too.
	$t->get_ok('/graph?l=table:hours&x=when&y=amount&span=1h&agg=median')->status_is(200);
	is_deeply _values($t->tx->res->body), [ 15, 40, 1000 ],
		'a median per bucket, from the same arithmetic the pivot uses';
	is _title($t->tx->res->body), 'median(amount) by when_span', 'and the title names the function';

	$t->get_ok('/graph?l=table:hours&x=when&y=amount&span=1h&agg=count')->status_is(200);
	is_deeply _values($t->tx->res->body), [ 2, 2, 1 ], 'count counts rows, needing no column';
	is _title($t->tx->res->body), 'Count by when_span', 'and reads as a tally';

	$t->get_ok('/graph?l=table:hours&x=when&y=amount&span=1h&agg=p50')->status_is(200);
	is_deeply _values($t->tx->res->body), [ 15, 40, 1000 ], 'p50 is the median under its own name';

	$t->get_ok('/graph?l=table:hours&x=when&y=amount&span=1h&agg=sum&series=region')
		->status_is(200);
	my $series = $t->tx->res->body;
	like $series, qr/2026-10-27T09:00:00/, 'a series chart buckets the x axis as well';
	# One point per region per bucket: North 10/30/1000 and South 20/50, with no
	# bucket total standing in for a region's own row.
	is_deeply [ sort { $a <=> $b } @{ _values($series) } ], [ 10, 20, 30, 50, 1000 ],
		'with one line per region, each summed in its own bucket';

	$t->get_ok('/graph?l=table:hours&x=when&y=amount&agg=banana')
		->status_is(400)
		->content_like(qr/Unknown aggregate function "banana"/, 'a misspelt function is refused')
		->content_like(qr/median/, 'and the message carries the vocabulary');

	# Unchanged by default: no agg key, one point per row.
	$t->get_ok('/graph?l=table:hours&x=when&y=amount')->status_is(200);
	my $plain = $t->tx->res->body;
	is scalar(@{ _values($plain) }), 5, 'without agg= there is still one point per row';
	unlike $plain, qr/&quot;agg&quot;/, 'and nothing was aggregated';
};

subtest 'a stored time pattern makes a timestamp readable' => sub {
	# Before the pattern, the column is not a date this application can read.
	$t->get_ok('/graph?l=table:local&x=when&y=amount&span=1h&agg=sum')->status_is(200);
	like $t->tx->res->body, qr/\(unparseable\)/, 'an unread timestamp lands in one visible bucket';

	$t->post_ok('/dates/save' => form => {
		l => 'table:local', col => 'when', pattern => '%d/%m/%Y', time => '%H:%M',
	})->status_is(200)->json_is('/ok' => 1);

	$t->get_ok('/dates/list?l=table:local')->status_is(200);
	my $stored = $t->tx->res->json->{patterns}{when};
	is ref $stored, 'HASH', 'the stored pattern is the two-part shape';
	is $stored->{date}, '%d/%m/%Y', 'with the date part';
	is $stored->{time}, '%H:%M', 'and the time part';

	$t->get_ok('/graph?l=table:local&x=when&y=amount&span=1h&agg=sum')->status_is(200);
	my $body = $t->tx->res->body;
	is_deeply _values($body), [ 12, 9 ], 'the timestamps are read and bucketed by hour';
	like $body, qr/2026-10-27T14:00:00/, 'the label is the ISO timestamp of the bucket';

	# The normalised column is a timestamp, so hour() reads it and the shipped
	# relative ranges can filter on it -- which is the point of storing it in
	# this shape rather than truncating the column to a date.
	$t->get_ok('/bar?l=table:local&cat=when&val=amount&c=' . url_escape("h:hour(when)")
		. '&span=1mon')->status_is(200);
	like $t->tx->res->body, qr/2026-10-01/, 'a pattern and a bucket compose';

	# The window and the bucket (a relative range on a patterned timestamp) are
	# checked in the next subtest, which uses a fixture dated from this run's own
	# clock -- the rows above are pinned to a calendar date so that their bucket
	# labels can be asserted literally, and a range is relative to now.

	$t->post_ok('/dates/save' => form => {
		l => 'table:local', col => 'when', pattern => '%d/%m/%Y', time => '%M',
	})->status_is(400)->json_like('/error' => qr/Unsupported time format pattern/, 'a bad time pattern is refused');

	$t->post_ok('/dates/save' => form => {
		l => 'table:local', col => 'when', pattern => '%d/%m/%Y', as => 'nope',
	})->status_is(400)->json_like('/error' => qr/as= must be/, 'a bad as= is refused');

	# A date pattern on its own is still stored the way it always was.
	$t->post_ok('/dates/save' => form => {
		l => 'table:local', col => 'when', pattern => '%d/%m/%Y',
	})->status_is(200);
	$t->get_ok('/dates/list?l=table:local')->status_is(200);
	is $t->tx->res->json->{patterns}{when}, '%d/%m/%Y',
		'with no time, the stored value is the string it has always been';

	$t->get_ok('/graph?l=table:local&x=when&y=amount&span=1d&agg=sum')->status_is(200);
	is_deeply _values($t->tx->res->body), [ 21 ], 'and the column normalises to a day again';
};

subtest 'a relative range and a bucket in one URL' => sub {
	# Acceptance 4.7(2) and 4.7(5), on the URL they name: the window is resolved
	# when the request arrives and the buckets come from span(), so a bookmark
	# means the same thing tomorrow.  The fixture is dated from this run's own
	# clock, as t/time-range.t's are, because a range is relative to now and a
	# pinned date would only pass until it fell out of the window.
	#
	# The two hours are whole hours three and one hour back, not the last two
	# hours: a row must not sit in the future (the window's upper bound would cut
	# it off), and two hours apart keeps them in separate buckets through a DST
	# change, when a wall clock can repeat an hour an hour later.
	my $top   = time() - (time() % 3600);
	my @hours = ($top - 10_800, $top - 3600);

	my @recent = ('id,when,amount');
	push @recent, 'R1,' . _pattern_stamp($hours[0] + 300) . ',5';
	push @recent, 'R2,' . _pattern_stamp($hours[0] + 2700) . ',7';
	push @recent, 'R3,' . _pattern_stamp($hours[1] + 600) . ',9';
	Mojo::File->new($data_dir)->child('recent.csv')->spew(join("\n", @recent) . "\n");

	# The bucket labels, and the cells two of the rows normalise to: the minutes
	# survive the pattern, the seconds are not in it and so are zero.
	my @want = map { _ts_stamp($_) } @hours;
	my $cell_a = _ts_stamp($hours[0] + 300);
	my $cell_c = _ts_stamp($hours[1] + 600);
	$t->post_ok('/dates/save' => form => {
		l => 'table:recent', col => 'when', pattern => '%d/%m/%Y', time => '%H:%M',
	})->status_is(200)->json_is('/ok' => 1);

	# Acceptance 4.7(5): the normalised cell is YYYY-MM-DDTHH:MM:SS, not a date,
	# and the half-hour it was written with is still there.
	$t->get_ok('/view/recent?span=1d&tcol=when')->status_is(200);
	my $view = $t->tx->res->body;
	like $view, qr/\Q$cell_a\E/, 'the pattern normalises a row to a timestamp';
	like $view, qr/\Q$cell_c\E/, 'and every row, not only the first';

	# Acceptance 4.7(2): last_24_hours with span=1h is two buckets, in order.
	my $window = '/bar?l=table:recent&cat=when&val=amount&span=1h'
		. '&range=last_24_hours&rcol=when';
	$t->get_ok($window)->status_is(200);
	my $bar = $t->tx->res->body;
	is_deeply _values($bar), [ 12, 9 ], 'the window gives one bucket for each hour';
	like $bar, qr/\Q$want[0]\E/, 'the label is the bucket start, not the row time';
	cmp_ok index($bar, $want[0]), '<', index($bar, $want[1]),
		'and the buckets come out in chronological order';

	# The same grouping from a second route: the bucket is a column, so the
	# arithmetic does not depend on which view groups by it.
	$t->get_ok('/pivot?l=table:recent&rows=when&m=amount:sum:total&span=1h'
		. '&range=last_24_hours&rcol=when')->status_is(200);
	my $pivot = Mojo::DOM->new($t->tx->res->body)->all_text;
	like $pivot, qr/\Q$want[0]\E/, '/pivot buckets the same earlier hour';
	like $pivot, qr/\Q$want[1]\E/, 'and the same later one';
	like $pivot, qr/\b12\b/, 'with the same total for the first';
	like $pivot, qr/\b9\b/, 'and for the second';

	# The window is a filter, so the reader's own filters narrow inside it: a
	# bound at the later bucket's start drops the rows of the hour before.
	$t->get_ok($window . '&f=' . url_escape("when:ge:$want[1]"))->status_is(200);
	is_deeply _values($t->tx->res->body), [9], 'a filter inside the window drops its bucket';
};

subtest 'the panels offer the bucket and the aggregate' => sub {
	# The feature is not a URL dialect: the chart, pivot and line-graph panels
	# carry the controls, and their option values are the interval vocabulary
	# the routes accept -- a menu that offers an interval the server refuses
	# would be worse than no menu at all.
	$t->get_ok('/view/hours')->status_is(200);
	my $body = $t->tx->res->body;

	for my $panel (qw(bar pie heatmap stacked combo treemap graph pivot)) {
		like $body, qr/id="$panel-span-sel"/, "the $panel panel has a Time bucket menu";
	}
	like $body, qr/id="graph-agg-sel"/, 'the line graph panel has an Aggregate menu';
	like $body, qr/id="graph-agg-p-field"/, 'with a level for a percentile';
	like $body, qr/id="pivot-tcol-wrap"/, 'the pivot panel can name the column to bucket';
	like $body, qr/id="dates-time-sel"/, 'the date panel can store a clock time';

	my ($bar_menu) = $body =~ /(<select id="bar-span-sel".*?<\/select>)/s;
	my @offered = $bar_menu =~ /<option value="([^"]*)"/g;
	ok(@offered > 5, 'the menu offers more than a couple of intervals');
	for my $interval (grep { length } @offered) {
		ok $iv->($interval), "the menu offers $interval, which the routes accept";
	}

	$t->get_ok('/stats?l=table:hours')->status_is(200);
	like $t->tx->res->body, qr/id="stats-pctl"/,
		'the statistics page lets the reader choose the percentile';
};

subtest 'a value in a bucket is a virtual column, so both paths agree' => sub {
	SKIP: {
		my $dir = File::Temp::tempdir(CLEANUP => 1);
		my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$dir/bucket.sql", '', '', { RaiseError => 1 }) };
		skip 'DBD::SQLite not available', 6 unless $dbh;
		$dbh->do('CREATE TABLE bucket_src (when_ts TEXT, region TEXT, amount INTEGER)');
		$dbh->do('INSERT INTO bucket_src VALUES (?,?,?)', {}, @$_)
			for [ '2026-10-27T09:05:00', 'North', 10 ],
			    [ '2026-10-27T09:45:00', 'South', 20 ],
			    [ '2026-10-27T10:15:00', 'North', 30 ],
			    [ '2026-10-27T11:10:00', 'North', 1000 ];
		$dbh->disconnect;
		my $l = url_escape("path:$dir/bucket.sql");

		# With a bucket in play the push path cannot be taken: the column does
		# not exist in the backend.  The two paths must still agree, which is
		# what says the bucket was registered as virtual rather than pushed.
		my $push = $t->get_ok("/bar?l=$l&cat=when_ts&val=amount&span=1h")
			->status_is(200)->tx->res->body;
		{
			local $ENV{BI_FORCE_PERL_AGG} = 1;
			my $fold = $t->get_ok("/bar?l=$l&cat=when_ts&val=amount&span=1h")
				->status_is(200)->tx->res->body;
			is_deeply _values($fold), _values($push), 'span=: the fold and the page agree';
		}
		is_deeply _values($push), [ 30, 30, 1000 ], 'and the numbers are the bucket sums';

		# agg= on a plain column can be pushed, so this one runs both paths for real.
		my $pushed = $t->get_ok("/graph?l=$l&x=region&y=amount&agg=sum")
			->status_is(200)->tx->res->body;
		{
			local $ENV{BI_FORCE_PERL_AGG} = 1;
			my $folded = $t->get_ok("/graph?l=$l&x=region&y=amount&agg=sum")
				->status_is(200)->tx->res->body;
			is_deeply [ sort { $a <=> $b } @{ _values($folded) } ],
				[ sort { $a <=> $b } @{ _values($pushed) } ],
				'agg= sum: pushed and folded totals agree';
		}
	}
};

subtest 'a canvas card can carry a bucket and a measure' => sub {
	my $cid = $t->post_ok('/api/analyses', { 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Bucketed canvas',
			datasets => [ { spec => 'table:hours' } ],
			visuals  => [
				{ kind => 'bar',
				  encode => { cat => 'when_span', value => 'amount' } },
				{ kind => 'line',
				  encode => { x => 'when_span', y => 'amount', agg => 'sum' } },
			],
		})
	)->status_is(201)->tx->res->json->{id};

	# The bucket column is a calc field like any other, so the canvas page
	# carries its definition the way it carries any other -- which is how a
	# saved card reproduces what the page it was saved from drew.
	$t->get_ok("/a/$cid?c=" . url_escape("when_span:span(when,'1h')"))->status_is(200);
	my $canvas = $t->tx->res->body;
	like $canvas, qr/2026-10-27T09:00:00/, 'the bar card draws a bucket';
	is_deeply _values($canvas), [ 30, 80, 1000, 30, 80, 1000 ],
		'the bar card sums a bucket and the line card sums it too';

	# Without the definition the column is simply not there, and the card says
	# so rather than grouping by something else.
	$t->get_ok("/a/$cid")->status_is(200);
	like $t->tx->res->body, qr/when_span/, 'the card names the column it cannot find';

	# A measure the fold cannot compute is the card's own error.
	my $bad = $t->post_ok('/api/analyses', { 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Bad measure',
			datasets => [ { spec => 'table:hours' } ],
			visuals  => [ { kind => 'line', encode => { x => 'when', y => 'amount', agg => 'banana' } } ],
		})
	)->status_is(201)->tx->res->json->{id};
	$t->get_ok("/a/$bad")->status_is(200);
	like $t->tx->res->body, qr/Unknown aggregate function/, 'a card says which function it could not compute';
};

done_testing;
