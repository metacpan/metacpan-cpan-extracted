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
use Database::BI::Controller::Dashboard ();

# ---------------------------------------------------------------------------
# Relative time ranges -- "the last 30 days", "this quarter".
#
# A range is named in the URL (?range=<name>&rcol=<column>) and resolved when
# the request arrives, so a link or a saved canvas keeps meaning the same thing
# every time it is opened.  It resolves to two f= filters on one column, which
# is what every data route already applies, so the table view, the charts, the
# exports and a canvas all narrow to the same rows.
#
# The dates in the fixture are computed from this run's own clock, so a run on
# any day means the same thing; the boundaries -- month, leap year, quarter,
# year -- are pinned to fixed clocks in the unit tests.
# ---------------------------------------------------------------------------

my $bounds = \&Database::BI::Controller::Dashboard::_time_range_bounds;
my $preset = \&Database::BI::Controller::Dashboard::_time_range_preset;
my $specs  = \&Database::BI::Controller::Dashboard::_time_range_specs;
my $filter = \&Database::BI::Controller::Dashboard::_apply_filter_spec;

sub _midday {
	my ($mday, $mon, $year) = @_;
	return POSIX::mktime(0, 0, 12, $mday, $mon, $year);
}

sub _iso_day {
	my @lt = localtime($_[0]);
	return sprintf '%04d-%02d-%02d', $lt[5] + 1900, $lt[4] + 1, $lt[3];
}

# _day($days_ago) -> 'YYYY-MM-DD'
sub _day {
	my @lt = localtime(time());
	return _iso_day(_midday($lt[3] - $_[0], $lt[4], $lt[5]));
}

# _us_day($days_ago) -> 'M/D/YYYY'
sub _us_day {
	my @lt = localtime(time() - $_[0] * 86400);
	return sprintf '%d/%d/%d', $lt[4] + 1, $lt[3], $lt[5] + 1900;
}

# _stamp($hours_ago) -> 'YYYY-MM-DDTHH:MM:SS'
sub _stamp {
	my @lt = localtime(time() - $_[0] * 3600);
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02d',
		$lt[5] + 1900, $lt[4] + 1, $lt[3], $lt[2], $lt[1], $lt[0];
}

# _day_at($days_ago, $hour, $min) -> a timestamp on the day that many days ago.
# Anchored to a clock time rather than to now, so which day a stamp falls in
# does not depend on the hour the suite happens to run at.
sub _day_at {
	my ($days_ago, $hour, $min) = @_;
	my @lt = localtime(time());
	my @at = localtime(_midday($lt[3] - $days_ago, $lt[4], $lt[5]) - 12 * 3600 + $hour * 3600 + $min * 60);
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02d',
		$at[5] + 1900, $at[4] + 1, $at[3], $at[2], $at[1], $at[0];
}

# ---------------------------------------------------------------------------
# The boundaries, pinned to fixed clocks
# ---------------------------------------------------------------------------

subtest 'A window is resolved against the clock it is given' => sub {
	my $now = _midday(27, 9, 126);	# 2026-10-27, noon

	my %expected = (
		today         => [ '2026-10-27', '2026-10-27' ],
		yesterday     => [ '2026-10-26', '2026-10-26' ],
		last_7_days   => [ '2026-10-21', '2026-10-27' ],
		last_30_days  => [ '2026-09-28', '2026-10-27' ],
		last_90_days  => [ '2026-07-30', '2026-10-27' ],
		this_month    => [ '2026-10-01', '2026-10-27' ],
		last_month    => [ '2026-09-01', '2026-09-30' ],
		this_quarter  => [ '2026-10-01', '2026-10-27' ],
		last_quarter  => [ '2026-07-01', '2026-09-30' ],
		this_year     => [ '2026-01-01', '2026-10-27' ],
		last_year     => [ '2025-01-01', '2025-12-31' ],
	);

	for my $name (sort keys %expected) {
		is_deeply [ $bounds->($preset->($name), $now) ], $expected{$name},
			"$name at 2026-10-27";
	}

	is_deeply [ $bounds->($preset->('last_24_hours'), $now) ],
		[ '2026-10-26T12:00:00', '2026-10-27T12:00:00' ],
		'last_24_hours is the 24 hours ending now, to the second';

	is_deeply $specs->('when', '2026-10-01', '2026-10-27'),
		[ 'when:ge:2026-10-01', 'when:le:2026-10-27' ],
		'a window is two inclusive bounds on one column';

	is_deeply $specs->('when', '', ''), [], 'a window with no bounds has no filters';
	is_deeply $specs->('', '2026-10-01', '2026-10-27'), [], 'a window needs a column';
};

subtest 'Month, quarter and year boundaries roll over' => sub {
	my $new_year = _midday(1, 0, 126);	# 2026-01-01, noon

	is_deeply [ $bounds->($preset->('yesterday'), $new_year) ],
		[ '2025-12-31', '2025-12-31' ], 'yesterday crosses into the old year';
	is_deeply [ $bounds->($preset->('last_month'), $new_year) ],
		[ '2025-12-01', '2025-12-31' ], 'last month is the December before January';
	is_deeply [ $bounds->($preset->('last_quarter'), $new_year) ],
		[ '2025-10-01', '2025-12-31' ], 'last quarter is Q4 of the old year';
	is_deeply [ $bounds->($preset->('this_quarter'), $new_year) ],
		[ '2026-01-01', '2026-01-01' ], 'this quarter starts today';
	is_deeply [ $bounds->($preset->('last_7_days'), $new_year) ],
		[ '2025-12-26', '2026-01-01' ], 'a day window crosses the year';
	is_deeply [ $bounds->($preset->('last_year'), $new_year) ],
		[ '2025-01-01', '2025-12-31' ], 'last year is the whole of the old year';

	my $march_end = _midday(31, 2, 126);	# 2026-03-31, the last day of Q1
	is_deeply [ $bounds->($preset->('this_quarter'), $march_end) ],
		[ '2026-01-01', '2026-03-31' ], 'this quarter ends on its own last day';

	# 2028 is a leap year: the previous month ends on the 29th.
	my $leap = _midday(1, 2, 128);	# 2028-03-01
	is_deeply [ $bounds->($preset->('last_month'), $leap) ],
		[ '2028-02-01', '2028-02-29' ], 'February is as long as the year says';
};

subtest 'An unknown name has no window and no preset' => sub {
	ok !$preset->('last_fortnight'), 'last_fortnight is not a preset';
	ok !$preset->(''), 'a blank name is not a preset';

	my @none = $bounds->(undef, _midday(27, 9, 126));
	is scalar(@none), 0, 'a missing preset resolves to no window';
};

# ---------------------------------------------------------------------------
# A date bound compared against a column of timestamps
#
# The bound names a day, so the cell is compared at the day it falls in; before
# this, a cell string longer than the bound sorted after it, and "le 2026-10-27"
# dropped every row on the 27th.
# ---------------------------------------------------------------------------

subtest 'A day bound compares at the day, a timestamp bound at the second' => sub {
	my $rows = [
		{ when => '2026-10-26T09:15:00' },
		{ when => '2026-10-27 09:15:00' },
		{ when => '2026-10-27T23:45:00' },
		{ when => '2026-10-28T00:05:00' },
	];

	my $matching = sub {
		my ($spec) = @_;
		return join ',', map { $_->{when} } @{ $filter->($rows, $spec) };
	};

	is $matching->('when:le:2026-10-27'),
		'2026-10-26T09:15:00,2026-10-27 09:15:00,2026-10-27T23:45:00',
		'a day bound includes every row of that day, whatever the separator';
	is $matching->('when:ge:2026-10-27'),
		'2026-10-27 09:15:00,2026-10-27T23:45:00,2026-10-28T00:05:00',
		'a day bound starts at the beginning of that day';
	is $matching->('when:between:2026-10-26:2026-10-27'),
		'2026-10-26T09:15:00,2026-10-27 09:15:00,2026-10-27T23:45:00',
		'a between window covers both its days in full';
	is $matching->('when:ge:2026-10-27T12:00:00'),
		'2026-10-27T23:45:00,2026-10-28T00:05:00',
		'a timestamp bound is exact where a day bound is not';
	is $matching->('when:eq:2026-10-27'),
		'2026-10-27 09:15:00,2026-10-27T23:45:00',
		'equality on a date means the whole day';

	my $words = [ { w => 'Beta' }, { w => 'alpha' } ];
	is_deeply [ map { $_->{w} } @{ $filter->($words, 'w:eq:beta') } ],
		[ 'Beta' ], 'a plain string filter stays case-insensitive';
	is_deeply [ map { $_->{w} } @{ $filter->($words, 'w:contains:ALP') } ],
		[ 'alpha' ], 'a plain contains filter is unchanged';
};

# ---------------------------------------------------------------------------
# The fixture
# ---------------------------------------------------------------------------

my $data_dir  = File::Temp::tempdir(CLEANUP => 1);
my $model_dir = File::Temp::tempdir(CLEANUP => 1);

# range.csv: one row per age in days.  The age-2 row is written in the US
# format the application already normalises, so a range has to reach it too.
my @AGES   = (0, 1, 2, 3, 10, 40, 200);
my %MARKER = map { $_ => "AG$_" } @AGES;

my @rows = ('id,when,amount');
for my $age (@AGES) {
	push @rows, join(',', $MARKER{$age}, ($age == 2 ? _us_day(2) : _day($age)),
		10 + $age * 0.5);
}
Mojo::File->new($data_dir)->child('range.csv')->spew(join("\n", @rows) . "\n");

# stamps.csv: hours ago, for the one preset that is not day-granular.
my @stamps = ('id,when,amount');
push @stamps, join(',', 'S30', _stamp(30), '3000');
push @stamps, join(',', 'S3',  _stamp(3),  '300');
Mojo::File->new($data_dir)->child('stamps.csv')->spew(join("\n", @stamps) . "\n");

# days.csv: timestamps anchored to a clock time on a known day, so which day a
# row falls in does not depend on the hour this suite runs at.
my @days = ('id,when,amount');
push @days, join(',', 'D3', _day_at(3, 12, 0),  '30');
push @days, join(',', 'D1', _day_at(1, 23, 30), '10');
push @days, join(',', 'D0', _day_at(0, 0,  30), '1');
Mojo::File->new($data_dir)->child('days.csv')->spew(join("\n", @days) . "\n");

# The data directory is passed at construction, not afterwards: open_table
# closes over the directory it was given when the application starts, so a
# later config change would leave the application reading one directory while
# this file watched another.
my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir,
	model_dir => $model_dir,
});

# The ids a rendered table shows, in file order.  The table view names its
# table bi-table; a canvas card is a table inside .visual-table-wrap.
sub _ids_in {
	my ($body, $selector) = @_;
	my $dom = Mojo::DOM->new($body);
	my @tables = $selector
		? @{ $dom->find($selector)->to_array }
		: @{ $dom->find('table')->to_array };
	return () unless @tables;
	my @ids;
	for my $tbl (@tables) {
		push @ids, map {
			my $id = $_->at('td');
			defined $id ? $id->text : ()
		} @{ $tbl->find('tbody tr')->to_array };
	}
	return @ids;
}

sub _sorted { return sort @_ }

sub _card_ids {
	my ($body) = @_;
	my @cards = @{ Mojo::DOM->new($body)->find('.visual-table-wrap table')->to_array };
	return map {
		[ map { my $id = $_->at('td'); defined $id ? $id->text : () }
			@{ $_->find('tbody tr')->to_array } ]
	} @cards;
}

subtest 'The table view honours each preset' => sub {
	my %window = (
		today        => [ 'AG0' ],
		yesterday    => [ 'AG1' ],
		last_7_days  => [ 'AG0', 'AG1', 'AG2', 'AG3' ],
		last_30_days => [ 'AG0', 'AG1', 'AG2', 'AG3', 'AG10' ],
		last_90_days => [ 'AG0', 'AG1', 'AG2', 'AG3', 'AG10', 'AG40' ],
	);

	for my $name (sort keys %window) {
		$t->get_ok("/view/range?range=$name&rcol=when")->status_is(200);

		is_deeply [ _sorted(_ids_in($t->tx->res->body, '#bi-table')) ],
			[ sort @{ $window{$name} } ],
			"$name narrows the table to its window";
	}

	$t->get_ok('/view/range')->status_is(200);
	is scalar(_ids_in($t->tx->res->body, '#bi-table')), scalar(@AGES),
		'with no range the table shows every row';

	$t->get_ok('/view/range?range=last_7_days&rcol=when&f=' . url_escape('id:ne:AG1'))
		->status_is(200);
	is_deeply [ _sorted(_ids_in($t->tx->res->body, '#bi-table')) ],
		[ 'AG0', 'AG2', 'AG3' ],
		'a range and an f= filter are both applied';
};

subtest 'A range that cannot be honoured is refused, not ignored' => sub {
	$t->get_ok('/view/range?range=last_fortnight&rcol=when')
		->status_is(400)
		->content_like(qr/Unknown time range "last_fortnight"/,
			'the refusal names the value it refused')
		->content_like(qr/last_7_days/, 'and lists the vocabulary');

	$t->get_ok('/view/range?range=last_7_days')
		->status_is(400)
		->content_like(qr/rcol=/, 'a range with no column names the missing parameter');

	$t->get_ok('/view/range?range=&rcol=when')->status_is(200);
	is scalar(_ids_in($t->tx->res->body, '#bi-table')), scalar(@AGES),
		'an empty range is no range';

	$t->get_ok('/view/range?rcol=when')->status_is(200);
	is scalar(_ids_in($t->tx->res->body, '#bi-table')), scalar(@AGES),
		'a column with no range is no range';
};

subtest 'The range is one chip, and stays relative in the URL' => sub {
	$t->get_ok('/view/range?range=last_7_days&rcol=when')->status_is(200);

	my $body = $t->tx->res->body;
	my $dom  = Mojo::DOM->new($body);

	my @chips = grep { defined } map { $_->text } @{ $dom->find('.filter-chip')->to_array };
	is scalar(@chips), 1, 'the window is one chip, not one per resolved bound';
	like $chips[0], qr/\QLast 7 days\E/, 'the chip names the range';
	like $chips[0], qr/\Qwhen\E/, 'the chip names the column it applies to';
	unlike $body, qr/when:ge:/, 'the resolved bounds are not chips of their own';

	like $body, qr/name="range" value="last_7_days"/,
		'the merge/filter form keeps the range relative';
	like $body, qr/name="rcol" value="when"/, 'and keeps its column';

	my @options = @{ $dom->find('#dash-range-preset option')->to_array };
	is scalar(grep { ($_->{value} // '') eq 'last_7_days' } @options), 1,
		'the menu offers last_7_days once';

	like $body, qr{<option value="last_7_days"[^>]*\sselected>},
		'the menu shows the range that is active';
	like $body, qr{<option value="when"[^>]*\sselected>},
		'and the column it applies to';
	like $body, qr/id="dash-range-col"/, 'the filter bar offers a column for the range';
};

subtest 'The hour preset keeps its time of day' => sub {
	$t->get_ok('/view/stamps?range=last_24_hours&rcol=when')->status_is(200);
	is_deeply [ _sorted(_ids_in($t->tx->res->body, '#bi-table')) ], [ 'S3' ],
		'last_24_hours keeps the row from three hours ago and drops the one from thirty';
};

subtest 'A day range reads a timestamp column by the day it falls in' => sub {
	# days.csv: D0 today just after midnight, D1 yesterday late evening, D3 three
	# days ago at noon.
	$t->get_ok('/view/days?range=today&rcol=when')->status_is(200);
	is_deeply [ _sorted(_ids_in($t->tx->res->body, '#bi-table')) ], [ 'D0' ],
		'today selects the row stamped today, whatever the hour';

	$t->get_ok('/view/days?range=yesterday&rcol=when')->status_is(200);
	is_deeply [ _sorted(_ids_in($t->tx->res->body, '#bi-table')) ], [ 'D1' ],
		'yesterday selects the row stamped yesterday, at any time of day';

	$t->get_ok('/view/days?range=last_7_days&rcol=when')->status_is(200);
	is_deeply [ _sorted(_ids_in($t->tx->res->body, '#bi-table')) ],
		[ 'D0', 'D1', 'D3' ],
		'a day window keeps every timestamped row inside it';
};

subtest 'A chart, an export and a pivot all see the window' => sub {
	$t->get_ok('/bar?l=table:range&cat=id&val=amount&range=last_7_days&rcol=when')
		->status_is(200)
		->content_like(qr/AG3/, 'the bar chart draws a row from inside the window')
		->content_unlike(qr/AG10/, 'and leaves out a row from outside it');

	$t->get_ok('/export?l=table:range&format=csv&range=last_7_days&rcol=when')
		->status_is(200);
	my $csv = $t->tx->res->body;
	like   $csv, qr/AG3/,  'the export carries a row from inside the window';
	unlike $csv, qr/AG10/, 'and not a row from outside it';

	$t->get_ok('/pivot?l=table:range&rows=id&m=amount:sum:total&range=last_7_days&rcol=when')
		->status_is(200)
		->content_like(qr/AG3/, 'the pivot aggregates the narrowed rows')
		->content_unlike(qr/AG10/, 'and leaves out the row outside the window');
};

# ---------------------------------------------------------------------------
# Saved canvases
# ---------------------------------------------------------------------------

my $canvas_id;

subtest 'A canvas applies the range to its cards' => sub {
	$canvas_id = $t->post_ok('/api/analyses',
		{ 'Content-Type' => 'application/json' },
		encode_json({
			name     => 'Range canvas',
			datasets => [ { spec => 'table:range', alias => 'left' } ],
			visuals  => [ { kind => 'table', encode => {}, title => 'Rows' } ],
		})
	)->status_is(201)->tx->res->json->{id};

	ok $canvas_id, 'the canvas was created';

	$t->get_ok("/a/$canvas_id")->status_is(200);
	is scalar(_ids_in($t->tx->res->body, '.visual-table-wrap table')), scalar(@AGES),
		'with no range the card shows every row';

	$t->get_ok("/a/$canvas_id?range=last_7_days&rcol=when")->status_is(200);

	my $body = $t->tx->res->body;
	is_deeply [ _sorted(_ids_in($body, '.visual-table-wrap table')) ],
		[ 'AG0', 'AG1', 'AG2', 'AG3' ],
		'the card is narrowed to the window';

	my $dom = Mojo::DOM->new($body);
	ok $dom->at('#canvas-range-form'), 'the canvas has a control for the range';

	my $chip = $dom->at('#canvas-range-chip');
	ok $chip, 'and shows the range that is active as a chip';
	like $chip->all_text, qr/\QLast 7 days\E/, 'the chip names the range';
	like $chip->all_text, qr/\Qwhen\E/, 'and the column it applies to';
	like $chip->at('a')->{href}, qr{\A/a/}, 'the chip can clear it';
	unlike $chip->at('a')->{href}, qr/range=/, 'the clear link carries no range';

	ok $dom->at('#canvas-range-preset'), 'the control offers the preset menu';
	is $dom->at('#canvas-range-preset')->{name} // '', 'range',
		'the preset control names the parameter the range travels in';
	is $dom->at('#canvas-range-col')->{name} // '', 'rcol',
		'the column control names the parameter the column travels in';
};

subtest 'A card added while a range is active is drawn through it' => sub {
	$t->post_ok("/api/analyses/$canvas_id/visuals",
		{ 'Content-Type' => 'application/json' },
		encode_json({
			kind   => 'table',
			encode => {},
			title  => 'Added with a range',
			query  => 'range=last_7_days&rcol=when',
		})
	)->status_is(201);

	my $html = $t->tx->res->json->{html};

	like   $html, qr/AG3/,   'the new card carries a row from inside the window';
	unlike $html, qr/AG10/,  'and not a row from outside it';
	unlike $html, qr/AG200/, 'nor the oldest row';

	my $stored  = decode_json(Mojo::File->new($model_dir)->child('analyses.json')->slurp);
	my $visuals = $stored->{$canvas_id}{visuals};
	is scalar(@$visuals), 2, 'the card was appended to the canvas';

	# The range lives in the canvas's URL, not in the stored card: a later
	# visit without one must not show a frozen window.
	$t->get_ok("/a/$canvas_id")->status_is(200);
	my @cards = _card_ids($t->tx->res->body);
	is scalar(@cards), 2, 'the canvas draws both cards';
	for my $i (0 .. $#cards) {
		is scalar(@{ $cards[$i] }), scalar(@AGES),
			'card ' . ($i + 1) . ' shows every row again when the range is not asked for';
	}

	$t->get_ok("/a/$canvas_id?range=last_7_days&rcol=when")->status_is(200);
	my @narrowed = _card_ids($t->tx->res->body);
	for my $i (0 .. $#narrowed) {
		is_deeply [ sort @{ $narrowed[$i] } ], [ 'AG0', 'AG1', 'AG2', 'AG3' ],
			'card ' . ($i + 1) . ' is narrowed with the range asked for';
	}
};

subtest 'A canvas refuses a range it cannot honour' => sub {
	$t->get_ok("/a/$canvas_id?range=last_fortnight&rcol=when")->status_is(400);
	$t->get_ok("/a/$canvas_id?range=last_7_days")->status_is(400);
};

done_testing();
