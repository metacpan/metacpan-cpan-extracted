#!/usr/bin/env perl

# Tests that kill the mutants which survived the rest of the suite, as listed in
# xt/mutant_20261101_020930.t.
#
# Each subtest says what it asserts and which mutation that catches.  Every
# assertion is about what the code is meant to do, taken from its comments and
# POD: a boundary mutant dies on a value AT the boundary, an inverted condition
# on one input from each side, and a replaced return value on an exact is().
#
# The line numbers in the stub file do not match the mutator's own for the same
# source, so the subtests name the function and the mutated expression instead.
# Mutations that no input can tell from the original are listed in EQUIVALENT
# MUTANTS at the end of this file, with the reason.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Test::Mojo;
use Test::Most;
use Test::Returns qw(returns_is);

# ---------------------------------------------------------------------------
# DataSource must be loaded through the app, or Sub::Private cleans its stash
# (see the note at the top of t/unit.t).
# ---------------------------------------------------------------------------
my $t = Test::Mojo->new('Database::BI');
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

require Database::BI::Extract;
require Database::BI::Insights;
require Database::BI::Model::DataSource;
require Database::BI::Model::Geocode;
require Database::BI::Util;

Readonly my $DS       => 'Database::BI::Model::DataSource';
Readonly my $INSIGHTS => 'Database::BI::Insights';

Readonly my $SPEC      => 'table:sales';
Readonly my $PATH_SPEC => 'path:/tmp/sales.csv';
Readonly my $URL_SPEC  => 'url:http://example.com/t';
Readonly my $BASE_URL  => '/insights?l=table:sales';
Readonly my $AMOUNT    => 'amount';
Readonly my $DATE_COL  => 'day';
Readonly my $CAT_COL   => 'region';

# Thresholds the code has as private constants; the tests restate them, so that
# changing one is a decision the tests notice.
Readonly my $SAMPLE_SIZE       => 20;
Readonly my $MAX_OUTLIERS      => 5;
Readonly my $MAX_MOVERS        => 5;
Readonly my $MIN_SEASON        => 8;
Readonly my $FMT_INT_LIMIT     => 1_000_000_000_000;
Readonly my $BDB_LIMIT         => 100 * 1024 * 1024;

# ---------------------------------------------------------------------------
# Stand-ins for the backend and the cache
# ---------------------------------------------------------------------------
{
	package Local::Backend;

	sub new { my ($class, %args) = @_; return bless { calls => [], %args }, $class }
	sub selectall_arrayref {
		my ($self, @args) = @_;
		push @{ $self->{calls} }, [ 'selectall_arrayref', @args ];
		return $self->{rows};
	}
	sub selectall_hashref {
		my ($self) = @_;
		push @{ $self->{calls} }, [ 'selectall_hashref' ];
		die $self->{die} if $self->{die};
		return $self->{rows};
	}
	sub columns   { return $_[0]{columns} }
	sub count     { return $_[0]{count} }
	sub aggregate { my ($self, @args) = @_; return { aggregated => \@args } }
	sub updated   { return $_[0]{updated} }
	sub schema {
		my ($self) = @_;
		die 'no schema' if $self->{schema_dies};
		return $self->{schema};
	}
	sub dbi_source {
		my ($self) = @_;
		die 'no dbi' if $self->{dbi_dies};
		return $self->{dbi};
	}
}
{
	# A backend with none of the optional methods.
	package Local::BareBackend;

	sub new { return bless {}, shift }
}
{
	package Local::Cache;

	sub new { return bless { store => {}, sets => [], gets => 0 }, shift }
	sub get { my ($self, $key) = @_; $self->{gets}++; return $self->{store}{$key} }
	sub set {
		my ($self, @args) = @_;
		push @{ $self->{sets} }, \@args;
		$self->{store}{ $args[0] } = $args[1];
		return;
	}
}
{
	package Local::I18n;

	sub new { return bless {}, shift }
	sub maketext { my ($self, $key, @args) = @_; return join ':', 'translated', $key, @args }
}
{
	# A geocoder that knows where everything is.
	package Local::Geocoder;

	sub new            { return bless {}, shift }
	sub valid_location { return 1 }
	sub geocode_many {
		my ($self, $values) = @_;
		return { map { $_ => { lat => 1, lon => 2 } } @{$values} };
	}
}
{
	# Serves one remote file, whatever it is called, as Net::SFTP::Foreign does.
	package Local::SFTP;

	my %files;
	sub serve { my ($class, %serve) = @_; %files = %serve; return }
	sub new   { return bless { error => 0 }, shift }
	sub error { return $_[0]{error} }
	sub get {
		my ($self, $remote, $local) = @_;
		return unless exists $files{$remote};
		open my $fh, '>', $local or die "$local: $!";
		print {$fh} $files{$remote};
		close $fh or die "$local: $!";
		return 1;
	}
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub _diag { diag(@_) if $ENV{TEST_VERBOSE}; return }

sub _enc { return Database::BI::Util::urlencode(@_) }

# Row of one numeric value, with an optional category.
sub _rows {
	my ($values, $cat) = @_;
	return [ map { { $AMOUNT => $_, (defined $cat ? ($CAT_COL => $cat) : ()) } } @{$values} ];
}

# Rows for a sequence of period totals, the first in January of $year.
sub _monthly {
	my ($totals, $year) = @_;
	my ($y, $m) = ($year // 2026, 1);
	my @rows;
	for my $total (@{$totals}) {
		push @rows, { $DATE_COL => sprintf('%04d-%02d-15', $y, $m), $AMOUNT => $total };
		if (++$m > 12) {
			$m = 1;
			$y++;
		}
	}
	return \@rows;
}

sub _outliers {
	my ($rows, $cats, $spec, $base) = @_;
	return Database::BI::Insights::_find_outliers($rows, $AMOUNT, $cats // [], $spec // $SPEC, $base);
}

# A file the given text, at $dir/$name.
sub _write_file {
	my ($dir, $name, $text, $mode) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, ($mode // '>:raw'), $path or die "$path: $!";
	print {$fh} $text;
	close $fh or die "$path: $!";
	return $path;
}

# A DataSource holding a stand-in backend, without going near a file.
sub _source {
	my (%fields) = @_;
	return bless { _table => 'sales', _raw_table => 'sales', %fields }, $DS;
}

sub _warnings_of {
	my ($code) = @_;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @result = $code->();
	return (\@warnings, @result);
}

# ===========================================================================
# Extract
# ===========================================================================

subtest 'Extract: put, get and evict' => sub {
	# put() must make the extracts directory itself and answer the path.  With
	# "unless (-d)" inverted the directory is never made and the write croaks; a
	# negated or undef return fails the is() against path().
	my $model = tempdir(CLEANUP => 1);
	my $store = Database::BI::Extract->new(model_dir => $model);
	isa_ok($store, 'Database::BI::Extract');
	returns_is($store->_extract_dir, { type => 'string' }, 'the extract directory is a string');
	is($store->_extract_dir, File::Spec->catdir($model, 'extracts'), 'and is under the model directory');

	# evict() on a store with no directory answers exactly 0: not 1 (negated) and
	# not undef (replaced).
	is($store->evict('x'), 0, 'evict with no extracts directory removes nothing, and says 0');

	my $fp = Database::BI::Extract::_fingerprint('x', 1, 2);
	like($fp, qr/\A[0-9a-f]{32}\z/, 'the fingerprint is an md5');
	isnt($fp, Database::BI::Extract::_fingerprint('x', 1, 3), 'and depends on the size');

	my $expected = File::Spec->catfile($model, 'extracts', "$fp.db");
	is($store->path('x', 1, 2), $expected, 'path() names the file');
	is($store->get('x', 1, 2), undef, 'get() misses before anything is stored');

	is($store->put('x', 1, 2, 'bytes'), $expected, 'put() answers the path it wrote');
	ok(-f $expected, 'and the file is there');
	is($store->get('x', 1, 2), $expected, 'get() then hits, with the path');

	# A second extract and a file that is not one.  evict() counts what it removed,
	# so "unless (unlink)" counts 0, and a negated return gives '' not 2.
	$store->put('y', 1, 2, 'bytes');
	my $other = _write_file(File::Spec->catdir($model, 'extracts'), 'keep.txt', 'text');
	is($store->evict('x'), 2, 'evict counts the extracts it removed');
	ok(!-f $expected, 'and they are gone');
	ok(-f $other, 'and a file that is not an extract stays');
	is($store->evict('x'), 0, 'evict of an empty directory counts 0');

	# A second put into an existing directory must not need to make it: "if (-d)"
	# inverted would call make_path only here, and still has to write.
	is($store->put('z', 1, 2, 'bytes'), $store->path('z', 1, 2), 'put into an existing directory works');

	throws_ok { Database::BI::Extract->new } qr/model_dir is required/, 'new needs a model directory';
};

# ===========================================================================
# Insights: classifying values and columns
# ===========================================================================

subtest 'Insights: _looks_like_date answers exactly 1 or 0' => sub {
	# is() on the exact value kills both the negation and the undef replacement of
	# each return, and each format needs its own line.
	my $fn = \&Database::BI::Insights::_looks_like_date;
	for my $date ('2026-10-22', '12/22/2025', '22/12/2025', '22-Oct-2026', '1/2/2026') {
		is($fn->($date), 1, "$date is a date");
	}
	for my $other ('hello', '12345', '2026-10', '22-10-2026') {
		is($fn->($other), 0, "$other is not a date");
	}
	is($fn->(undef), 0, 'undef is not a date');
	is($fn->(''),    0, 'nor is an empty string');
};

subtest 'Insights: _is_date_col samples the first 20 values' => sub {
	# With "> 20" turned into "<" or "<=", a short column reads past its end, finds
	# undef and is no longer a date column.  With "<" again, a long one is read in
	# full, and the bad value after the sample is seen.
	my $fn = \&Database::BI::Insights::_is_date_col;
	is($fn->([ '2026-01-01', '2026-01-02', '2026-01-03' ]), 1, 'a short column of dates');
	is($fn->([ ('2026-01-01') x $SAMPLE_SIZE, 'not a date' ]), 1, 'what follows the sample is not read');
	is($fn->([ 'not a date', '2026-01-02' ]), 0, 'one bad value in the sample decides it');
	is($fn->([]), 0, 'an empty column is not one');
};

subtest 'Insights: _is_numeric_col samples the first 20 values' => sub {
	my $fn = \&Database::BI::Insights::_is_numeric_col;
	is($fn->([ 1, 2, 3 ]), 1, 'a short column of numbers');
	is($fn->([ (1) x $SAMPLE_SIZE, 'text' ]), 1, 'what follows the sample is not read');
	is($fn->([ 'text', 2 ]), 0, 'text in the sample decides it');
	is($fn->([ '2026-01-01', 2 ]), 0, 'a date is not a measure');
	is($fn->([]), 0, 'an empty column is not one');
};

subtest 'Insights: _to_num' => sub {
	# The negated return gives '' for a number; the undef replacement, undef.
	my $fn = \&Database::BI::Insights::_to_num;
	is($fn->('42'), 42, 'a plain number');
	is($fn->('(1,234.50)'), -1234.5, 'an accounting negative');
	is($fn->('text'), undef, 'text has no value');
};

# ===========================================================================
# Insights: quartiles
# ===========================================================================

subtest 'Insights: _quartiles and _median' => sub {
	# Quartiles need four values.  At exactly 4 ">=" and "<=" agree and ">" and "<"
	# do not; at 3, "<" and "<=" answer values where there should be none; at 5,
	# "<=" answers none.
	my @none = (undef, undef, undef);
	is_deeply([ Database::BI::Insights::_quartiles([ 1, 2, 3 ]) ], \@none, 'three values are too few');
	is_deeply([ Database::BI::Insights::_quartiles([ 1, 2, 3, 4 ]) ], [ 1.5, 2.5, 3.5 ], 'four are enough');
	is_deeply([ Database::BI::Insights::_quartiles([ 1, 2, 3, 4, 5 ]) ], [ 1.5, 3, 4.5 ],
		'an odd count leaves the median out of both halves');

	# _median([]) is undef: "!(undef)" would be 1.
	is(Database::BI::Insights::_median([]), undef, 'the median of nothing');
	is(Database::BI::Insights::_median([ 1, 2, 9 ]), 2, 'the median of an odd count');
	is(Database::BI::Insights::_median([ 1, 2, 3, 9 ]), 2.5, 'the median of an even count');
};

# ===========================================================================
# Insights: outliers
# ===========================================================================

subtest 'Insights: a value exactly on the fence is not an outlier' => sub {
	# q1 = 10, q3 = 20, so the fences are exactly -5 and 35, and both are values
	# here.  "<=" on the low side or ">=" on the high side reports them.  The doc
	# says outside the fences, so this list must report nothing.
	my @on_the_fence = _outliers(_rows([ -5, 10, 10, 15, 15, 20, 20, 35 ]));
	is_deeply(\@on_the_fence, [], 'nothing is reported');
};

subtest 'Insights: a value past each fence is, and in the right direction' => sub {
	# The fences are both 10, and every 10 is on them.  ">" on the low side or "<"
	# on the high side also reports all of the tens.  The direction lines die on
	# "<" and "<=" of the "val > hi_fence" that picks high or low.
	my @found = _outliers(_rows([ (10) x 8, 100, -100 ]));
	is(scalar(@found), 2, 'the two values past the fences, no others') or _diag(explain(\@found));

	my ($high) = grep { $_->{headline} =~ /100 is unusually high/ } @found;
	my ($low)  = grep { $_->{headline} =~ /-100 is unusually low/ } @found;
	ok($high, 'the high one is called high');
	ok($low,  'the low one is called low');

	is($high->{kind},   'outlier',   'the kind');
	is($high->{method}, 'iqr_fence', 'the method');
	is($high->{headline}, 'Unusual amount value: 100 is unusually high', 'no group: the plain headline');
	like($high->{detail}, qr/\AExpected range 10 .+ 10 \(IQR fence on 10 values\)\z/, 'the detail states the range');
};

subtest 'Insights: small groups are skipped' => sub {
	# A group of 6 can hold an outlier and is reported; "next if @nums >= 4" and
	# "next if @nums > 4" both skip it.
	my @found = _outliers(_rows([ 1, 1, 1, 1, 1, 100 ]));
	is(scalar(@found), 1, 'a group of 6 is examined');
	is_deeply([ _outliers(_rows([ 1, 2, 3 ])) ], [], 'a group of 3 is not');
};

subtest 'Insights: the five furthest outliers, furthest first' => sub {
	# 40 tens hold both fences at 10.  Seven outliers at distances 60, 40, 35, 20,
	# 15, 10 and 3.  The limit dies on "<" and "<=" (seven are kept); the order
	# dies on any change to _fence_distance, since a high and a low value only sort
	# together if each is measured from its own fence.
	my @found = _outliers(_rows([ (10) x 40, 20, 30, 50, 70, 7, -5, -25 ]));
	is(scalar(@found), $MAX_OUTLIERS, 'only five are reported');
	my @values = map { $_->{headline} =~ /value: (-?\d+) is/ ? $1 : '?' } @found;
	is_deeply(\@values, [ 70, 50, -25, 30, -5 ], 'and they are the furthest, in order');
};

subtest 'Insights: _fence_distance' => sub {
	# Inside the fences is 0.  "<=" or "<" on the high test makes that negative,
	# and ">" on the low test does too.  Each side is measured from its own fence.
	my $fn = \&Database::BI::Insights::_fence_distance;
	is($fn->(15, 0, 10), 5, 'above the high fence');
	is($fn->(-3, 0, 10), 3, 'below the low fence');
	is($fn->(5,  0, 10), 0, 'between them');
	is($fn->(10, 0, 10), 0, 'on the high fence');
	is($fn->(0,  0, 10), 0, 'on the low fence');
};

subtest 'Insights: outlier links with categories' => sub {
	# Every "if" here is inverted by a mutant.  With a category the headline names
	# the group, the view is a bar chart, and the drill is the group's rows with the
	# outlier highlighted.  gt and the high fence for a high value, lt and the low
	# fence for a low one: the two lines that choose them each have a mutant.
	my @found = _outliers(_rows([ (10) x 8, 100, -100 ], 'North'), [$CAT_COL], $SPEC, $BASE_URL);
	my ($high) = grep { $_->{headline} =~ /unusually high/ } @found;
	my ($low)  = grep { $_->{headline} =~ /unusually low/ }  @found;

	is($high->{headline}, 'Unusual amount in region=North: 100 is unusually high', 'the headline names the group');
	my $spec_enc = _enc($SPEC);
	is($high->{view_url}, "/bar?l=$spec_enc&cat=region&val=amount&sort=value", 'the view is a bar chart');

	my $back = '&back2=' . _enc($BASE_URL) . '&back2_label=Back+to+insights';
	is($high->{drill_url}, "/view/sales?f=region:eq:North&hl_col=amount&hl_op=gt&hl_val=10$back",
		'a high value drills to values above the fence');
	is($low->{drill_url}, "/view/sales?f=region:eq:North&hl_col=amount&hl_op=lt&hl_val=10$back",
		'a low value drills to values below it');

	# Now fences that differ, so a swap of hl_fence shows.  q1 = 2, q3 = 8.
	my @spread = _outliers(_rows([ 1, 2, 2, 3, 4, 5, 6, 7, 8, 8, 9, 100, -100 ], 'N'), [$CAT_COL], $SPEC);
	my ($s_high) = grep { $_->{headline} =~ /unusually high/ } @spread;
	my ($s_low)  = grep { $_->{headline} =~ /unusually low/ }  @spread;
	like($s_high->{drill_url}, qr/hl_op=gt&hl_val=17(?:&|\z)/, 'the high fence for a high value') or _diag($s_high->{drill_url});
	like($s_low->{drill_url},  qr/hl_op=lt&hl_val=-7(?:&|\z)/, 'the low fence for a low value') or _diag($s_low->{drill_url});
	unlike($s_high->{drill_url}, qr/back2/, 'no base URL: no way back named');

	# Two categories: the label has both, the filter the first.
	my @two = _outliers([ map { { %{$_}, kind => 'A' } } @{ _rows([ (10) x 8, 100 ], 'N') } ], [ $CAT_COL, 'kind' ], $SPEC);
	like($two[0]{headline}, qr/in region=N, kind=A:/, 'several categories are all named');
};

subtest 'Insights: outlier links without categories, or without a table to open' => sub {
	my ($no_cat) = _outliers(_rows([ (10) x 8, 100 ]), [], $SPEC, $BASE_URL);
	is($no_cat->{view_url}, '/stats?l=' . _enc($SPEC), 'no category: the view is the statistics page');
	ok(!exists $no_cat->{drill_url}, 'and there is no group to drill into');

	my ($no_table) = _outliers(_rows([ (10) x 8, 100 ], 'N'), [$CAT_COL], $URL_SPEC, $BASE_URL);
	ok(!exists $no_table->{drill_url}, 'a source with no data page: nothing to drill into');

	my ($file) = _outliers(_rows([ (10) x 8, 100 ], 'N'), [$CAT_COL], $PATH_SPEC, $BASE_URL);
	like($file->{drill_url}, qr{\A/open\?path=[^?]+&f=region:eq:N}, 'a data page with a query string: joined with &');
};

# ===========================================================================
# Insights: period over period
# ===========================================================================

subtest 'Insights: period over period' => sub {
	my $fn = \&Database::BI::Insights::_period_over_period;

	# Two periods is the minimum.  One period dies on "<" and "<=" of ">= 2"; two
	# dies on ">".
	is_deeply([ $fn->(_monthly([100]), $DATE_COL, $AMOUNT, $SPEC, $BASE_URL) ], [], 'one period: nothing to compare');

	my ($up) = $fn->(_monthly([ 100, 150 ]), $DATE_COL, $AMOUNT, $SPEC, $BASE_URL);
	ok($up, 'two periods: one insight');
	is($up->{kind},   'period_delta', 'the kind');
	is($up->{method}, 'pop_delta',    'the method');
	is($up->{headline}, 'amount is up 50 vs prior period (2026-01)', 'a rise is up');
	is($up->{detail}, '2026-01: 100  2026-02: 150  (+50.0%)', 'with a plus sign and the percentage');
	is($up->{view_url}, '/graph?l=' . _enc($SPEC) . "&x=$DATE_COL&y=$AMOUNT", 'the view is a line chart');
	is($up->{drill_url},
		"/view/sales?f=$DATE_COL:starts:2026-02&back2=" . _enc($BASE_URL) . '&back2_label=Back+to+insights',
		'the drill is the current period');

	# Only the last two count, once there are three.
	my ($last) = $fn->(_monthly([ 1, 100, 150 ]), $DATE_COL, $AMOUNT, $SPEC);
	is($last->{headline}, 'amount is up 50 vs prior period (2026-02)', 'three periods: the latest two');
	unlike($last->{drill_url}, qr/back2/, 'no base URL: no way back named');

	my ($down) = $fn->(_monthly([ 200, 150 ]), $DATE_COL, $AMOUNT, $SPEC);
	is($down->{headline}, 'amount is down 50 vs prior period (2026-01)', 'a fall is down');
	is($down->{detail}, '2026-01: 200  2026-02: 150  (-25.0%)', 'with no plus sign');

	# No change is "up" with "+": ">= 0", so ">" flips both.
	my ($flat) = $fn->(_monthly([ 100, 100 ]), $DATE_COL, $AMOUNT, $SPEC);
	is($flat->{headline}, 'amount is up 0 vs prior period (2026-01)', 'no change counts as up');
	is($flat->{detail}, '2026-01: 100  2026-02: 100  (+0.0%)', 'with a plus sign');

	# A prior total of 0 has no percentage.  "==" divides by that zero.
	my ($from_zero) = $fn->(_monthly([ 0, 50 ]), $DATE_COL, $AMOUNT, $SPEC);
	is($from_zero->{detail}, '2026-01: 0  2026-02: 50', 'from zero: no percentage');

	my ($no_page) = $fn->(_monthly([ 1, 2 ]), $DATE_COL, $AMOUNT, $URL_SPEC, $BASE_URL);
	ok(!exists $no_page->{drill_url}, 'a source with no data page: nothing to drill into');
	my ($file) = $fn->(_monthly([ 1, 2 ]), $DATE_COL, $AMOUNT, $PATH_SPEC);
	like($file->{drill_url}, qr{\A/open\?path=[^?]+&f=$DATE_COL:starts:}, 'a data page with a query string: joined with &');
};

# ===========================================================================
# Insights: top movers
# ===========================================================================

subtest 'Insights: top movers' => sub {
	my $fn = \&Database::BI::Insights::_top_movers;

	# One row for each group in each of two periods.
	my $moves = sub {
		my (%delta) = @_;
		my @rows;
		for my $group (sort keys %delta) {
			push @rows,
				{ $DATE_COL => '2026-01-15', $CAT_COL => $group, $AMOUNT => 100 },
				{ $DATE_COL => '2026-02-15', $CAT_COL => $group, $AMOUNT => 100 + $delta{$group} };
		}
		return \@rows;
	};

	is_deeply([ $fn->(_monthly([ 1, 2 ]), $DATE_COL, $AMOUNT, [], $SPEC) ], [], 'no category: no movers');

	my $one_period = [ { $DATE_COL => '2026-01-15', $CAT_COL => 'A', $AMOUNT => 1 } ];
	is_deeply([ $fn->($one_period, $DATE_COL, $AMOUNT, [$CAT_COL], $SPEC) ], [], 'one period: no movers');

	# Six groups.  The limit dies on "<" and "<=", where all six stay.
	my @top = $fn->($moves->(A => 1, B => -2, C => 3, D => -4, E => 5, F => 6), $DATE_COL, $AMOUNT, [$CAT_COL], $SPEC, $BASE_URL);
	is(scalar(@top), $MAX_MOVERS, 'only five are reported');
	is_deeply([ map { (split / /, $_->{headline})[0] } @top ], [qw(F E D C B)], 'the biggest changes, either way, first');

	is($top[0]{headline}, 'F amount up by 6 from 2026-01 to 2026-02', 'a rise is up');
	is($top[2]{headline}, 'D amount down by 4 from 2026-01 to 2026-02', 'a fall is down');
	is($top[0]{detail}, '2026-01: 100  2026-02: 106', 'the detail has both totals');
	is($top[0]{kind},   'top_mover', 'the kind');
	is($top[0]{method}, 'top_mover', 'the method');

	is($top[0]{view_url},
		'/graph?l=' . _enc($SPEC) . "&x=$DATE_COL&y=$AMOUNT&f=$CAT_COL:eq:F",
		'the view is that group over time');
	is($top[0]{drill_url},
		"/view/sales?f=$DATE_COL:starts:2026-02&f=$CAT_COL:eq:F&back2=" . _enc($BASE_URL) . '&back2_label=Back+to+insights',
		'the drill is that group in the current period');

	# No change is "up": ">= 0", so ">" says down.
	my ($flat) = $fn->($moves->(A => 0), $DATE_COL, $AMOUNT, [$CAT_COL], $SPEC);
	is($flat->{headline}, 'A amount up by 0 from 2026-01 to 2026-02', 'no change counts as up');
	unlike($flat->{drill_url}, qr/back2/, 'no base URL: no way back named');

	my ($no_page) = $fn->($moves->(A => 1), $DATE_COL, $AMOUNT, [$CAT_COL], $URL_SPEC, $BASE_URL);
	ok(!exists $no_page->{drill_url}, 'a source with no data page: nothing to drill into');
	my ($file) = $fn->($moves->(A => 1), $DATE_COL, $AMOUNT, [$CAT_COL], $PATH_SPEC);
	like($file->{drill_url}, qr{\A/open\?path=[^?]+&f=$DATE_COL:starts:}, 'a data page with a query string: joined with &');
};

# ===========================================================================
# Insights: seasonality
# ===========================================================================

subtest 'Insights: seasonality' => sub {
	my $fn = \&Database::BI::Insights::_seasonality;

	# 1..8 has lag-1 r = 26.25 / 42 = 0.625.  The exact value in the detail kills
	# the changes to "$i < $n - 1", which add or drop terms of the sum.  Eight
	# periods dies on "<" and ">" of ">= 8".
	my ($eight) = $fn->(_monthly([ 1 .. $MIN_SEASON ]), $DATE_COL, $AMOUNT, $SPEC);
	ok($eight, 'eight periods with a pattern are reported');
	is($eight->{kind},   'seasonality', 'the kind');
	is($eight->{method}, 'autocorr',    'the method');
	my $r = sprintf '%.2f', 26.25 / 42;
	is($eight->{detail}, "Lag-1 autocorrelation $r across 8 periods (2026-01 to 2026-08)", 'the detail has the exact r');
	is($eight->{headline}, "amount shows a repeating period-over-period pattern (r=$r)", 'the headline does too');
	is($eight->{view_url}, '/graph?l=' . _enc($SPEC) . "&x=$DATE_COL&y=$AMOUNT", 'the view is a line chart');

	# Seven is too few, and nine is plenty: "<=" of ">= 8" returns nothing at nine.
	is_deeply([ $fn->(_monthly([ 1 .. $MIN_SEASON - 1 ]), $DATE_COL, $AMOUNT, $SPEC) ], [], 'seven periods are too few');
	my ($nine) = $fn->(_monthly([ 1 .. $MIN_SEASON + 1 ]), $DATE_COL, $AMOUNT, $SPEC);
	ok($nine, 'nine are plenty');

	# This series has r equal to the threshold in floating point, so ">" drops it.
	my ($at_limit) = $fn->(_monthly([ 5, 8, 6, 1, 1, 1, 0, 2 ]), $DATE_COL, $AMOUNT, $SPEC);
	ok($at_limit, 'r exactly at the threshold counts');
	like($at_limit->{headline}, qr/\(r=0\.60\)/, 'and is what it says');

	# Alternating has r well below it: "<" and "<=" report this one.
	is_deeply([ $fn->(_monthly([ 1, 9, 1, 9, 1, 9, 1, 9 ]), $DATE_COL, $AMOUNT, $SPEC) ], [], 'no pattern: nothing reported');

	# A flat series has a zero denominator.  ">=" divides by it; "<" and "<=" of
	# "> 0" are killed by the reports above.
	my @flat;
	lives_ok { @flat = $fn->(_monthly([ (5) x $MIN_SEASON ]), $DATE_COL, $AMOUNT, $SPEC) } 'a flat series does not divide by zero';
	is_deeply(\@flat, [], 'and has no pattern');
};

# ===========================================================================
# Insights: formatting and URLs
# ===========================================================================

subtest 'Insights: _fmt_num' => sub {
	my $fn = \&Database::BI::Insights::_fmt_num;

	is($fn->(undef), 'N/A', 'undef');
	returns_is($fn->(5), { type => 'string' }, 'an answer is a string');
	is($fn->(5), '5', 'a whole number');
	is($fn->(0), '0', 'zero: the negated return would be 1 here');

	# Under the limit whole numbers keep every digit.  ">" and ">=" send this to
	# the four-figure path; "!=" sends the fraction below to the whole-number path.
	is($fn->(123456), '123456', 'a whole number keeps every digit');
	is($fn->(-123456), '-123456', 'and a negative one, by size');
	is($fn->(1234.5678), '1235', 'a fraction is cut to four figures');
	is($fn->(0.12345), '0.1235', 'and a small one');

	# Just below the limit every digit stays, and just above it they are cut to four
	# figures.  The limit itself prints the same by either route: see EQUIVALENT
	# MUTANTS.
	is($fn->($FMT_INT_LIMIT - 1), '999999999999', 'just below the limit a whole number is whole');
	is($fn->($FMT_INT_LIMIT + 1), '1000000000000', 'and just above it, it is cut to four figures');
};

subtest 'Insights: _spec_to_data_url' => sub {
	my $fn = \&Database::BI::Insights::_spec_to_data_url;

	is($fn->('table:sales'), '/view/sales', 'a table');
	is($fn->($PATH_SPEC), '/open?path=' . _enc('/tmp/sales.csv'), 'a file');
	is($fn->($URL_SPEC), undef, 'anything else has no data page');
	is($fn->(undef), undef, 'nor has nothing');
	is($fn->('table:'), undef, 'nor a table with no name');
};

subtest 'Insights: compute and method_note' => sub {
	# The classification decides everything: an inverted "if" on the date column
	# makes it a measure or a category.  The URL's default comes from the spec.
	my @rows = (
		(map { { $DATE_COL => '2026-01-15', $CAT_COL => 'N', $AMOUNT => 10 } } 1 .. 8),
		{ $DATE_COL => '2026-02-15', $CAT_COL => 'N', $AMOUNT => 100 },
	);
	my $found = Database::BI::Insights::compute(records => \@rows, columns => [ $DATE_COL, $CAT_COL, $AMOUNT ], spec_key => $SPEC);
	returns_is($found, { type => 'arrayref' }, 'compute answers an array');
	my %kinds = map { $_->{kind} => 1 } @{$found};
	is_deeply([ sort keys %kinds ], [qw(outlier period_delta top_mover)], 'and the kinds that apply to these rows');
	my ($pop) = grep { $_->{kind} eq 'period_delta' } @{$found};
	like($pop->{drill_url}, qr/back2=%2Finsights/, 'a base URL is made from the spec when none is given');

	# No date column: only outliers, since the rest need a date.  "unless" on that
	# test would try to use a date column that is not there.
	my $no_date = Database::BI::Insights::compute(records => _rows([ (10) x 8, 100 ]), columns => [$AMOUNT], spec_key => $SPEC);
	is_deeply([ map { $_->{kind} } @{$no_date} ], ['outlier'], 'no date column: only outliers');

	is_deeply(Database::BI::Insights::compute(records => [], columns => [$AMOUNT]), [], 'no rows: nothing');

	like(Database::BI::Insights::method_note('iqr_fence'), qr/IQR/, 'a known method has its note');
	is(Database::BI::Insights::method_note('other'), 'other', 'an unknown one is named as it is');
};

# ===========================================================================
# Geocode: loading the default geocoder
# ===========================================================================

subtest 'Geocode: _load_geocoder answers a geocoder' => sub {
	# _load_geocoder must hand back the object it built: "return undef" and
	# "return !(...)" both lose it.  The stand-in means this runs without the real
	# Geo::Coder::Free, and records what it was given, so openaddr is checked too.
	my %given;
	my $loaded = bless {}, 'Local::FakeFree';

	no warnings qw(redefine once);
	local $INC{'Geo/Coder/Free.pm'} = __FILE__;
	local $Geo::Coder::Free::VERSION = '99';
	local *Geo::Coder::Free::new = sub { my ($class, %args) = @_; %given = %args; return $loaded };
	local $ENV{OPENADDR_HOME};

	my $with = Database::BI::Model::Geocode->new(openaddr => '/data/oa');
	is($with->_load_geocoder, $loaded, 'it answers the object that was built');
	is_deeply(\%given, { openaddr => '/data/oa' }, 'told where the addresses are');

	%given = ();
	my $without = Database::BI::Model::Geocode->new;
	is($without->_load_geocoder, $loaded, 'and without an address directory');
	is_deeply(\%given, {}, 'when it is told nothing');
};

subtest 'Geocode: _has_position and _check_interface' => sub {
	# Exact answers: a false return of 0 is what the code documents, so undef is
	# wrong.  Three elements still hold a position, which kills "<=" of ">= 2".
	my $fn = \&Database::BI::Model::Geocode::_has_position;
	is($fn->([ 1, 2 ]), 1, 'a pair is a position');
	is($fn->([ 1, 2, 3 ]), 1, 'and so is a longer list');
	is($fn->([1]), 0, 'one number is not');
	is($fn->([ 1, undef ]), 0, 'nor is half a pair');
	is($fn->(0), 0, 'nor a remembered failure');

	my $geocoder = Local::Geocoder->new;
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);
	is($geocode->_check_interface($geocoder), 1, 'a geocoder with both methods passes');
	throws_ok { $geocode->_check_interface(Local::BareBackend->new) } qr/valid_location/,
		'one without them does not';
};

subtest 'Geocode: the cap on new lookups' => sub {
	# Exactly at the cap nothing is held back, and it is not reported as capped.
	# ">=" of "$wanted > $max" reports it.  One over the cap is.
	my $geocoder = Local::Geocoder->new;
	my $geocode  = Database::BI::Model::Geocode->new(geocoder => $geocoder);

	my $at = $geocode->resolve_values([qw(a b)], max => 2);
	ok(!$at->{capped}, 'exactly at the cap: not capped');
	is_deeply($at->{not_attempted}, [], 'and nothing is held back');

	my $over = $geocode->resolve_values([qw(a b c)], max => 2);
	ok($over->{capped}, 'one over: capped');
	is_deeply($over->{not_attempted}, ['c'], 'and it is held back');
};

# ===========================================================================
# DataSource: constructors
# ===========================================================================

subtest 'DataSource: each constructor answers the object' => sub {
	# new() dispatches on url and redis, and the file path falls through.  Each
	# "return" has a negated and an undef mutant, so each path is asked for a blessed
	# object.  The backends are out of the way: what they do is tested elsewhere.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'plain.csv', "name,value\nA,1\n");

	my $file = $DS->new(directory => $dir, table => 'plain');
	isa_ok($file, $DS, 'a file source');
	is($file->table_name, 'plain', 'with its table name');

	no warnings qw(redefine once);
	local *Database::BI::Model::DataSource::_init_url_backend   = sub { return };
	local *Database::BI::Model::DataSource::_init_redis_backend = sub { return };

	my $from_url = $DS->new(url => 'http://example.com/a/table.html');
	isa_ok($from_url, $DS, 'a URL source');
	is($from_url->source_url, 'http://example.com/a/table.html', 'with its address');

	my $from_redis = $DS->new(redis => 'redis://localhost:6379', table => 'orders');
	isa_ok($from_redis, $DS, 'a Redis source');
	is($from_redis->table_name, 'orders', 'with its table name');
};

# ===========================================================================
# DataSource: BerkeleyDB detection
# ===========================================================================

subtest 'DataSource: _detect_file_info on a .db that is not SQLite' => sub {
	# Every test on the way to DB_File has a mutant: too short to hold a magic number,
	# a magic number at offset 0 or 12, and the size guard.  An answer of {} means
	# "not a database", so that is what plain bytes must get, and the sentinel what a
	# magic number on a file DB_File cannot open must get.
	my $fn = \&Database::BI::Model::DataSource::_detect_file_info;
	my $dir = tempdir(CLEANUP => 1);

	_write_file($dir, 'short.db', 'ab');
	is_deeply($fn->($dir, 'short'), {}, 'too short for a magic number: not a database');

	_write_file($dir, 'twelve.db', 'x' x 13);
	is_deeply($fn->($dir, 'twelve'), {}, 'too short for one at offset 12: not a database');

	_write_file($dir, 'plain.db', 'x' x 64);
	is_deeply($fn->($dir, 'plain'), {}, 'no magic number: not a database');

	_write_file($dir, 'big.db', pack('N', 0x00061561) . ('x' x 60));
	my $at_start = $fn->($dir, 'big');
	ok($at_start->{_unknown_binary_db}, 'a magic number at the start that will not open: refused');
	is($at_start->{file_size}, 64, 'and its size is reported');

	_write_file($dir, 'little.db', pack('V', 0x00053162) . ('x' x 60));
	ok($fn->($dir, 'little')->{_unknown_binary_db}, 'little-endian: refused the same way');

	_write_file($dir, 'at12.db', ('x' x 12) . pack('H*', '61150600') . ('x' x 48));
	ok($fn->($dir, 'at12')->{_unknown_binary_db}, 'the hash magic at offset 12');
	_write_file($dir, 'at12b.db', ('x' x 12) . pack('H*', '15610000') . ('x' x 48));
	ok($fn->($dir, 'at12b')->{_unknown_binary_db}, 'and in the other byte order');

	SKIP: {
		eval { require DB_File; 1 } or skip 'DB_File is not installed', 4;

		# A real file opens, and is a table of entry and value.
		no warnings 'once';
		my $real = File::Spec->catfile($dir, 'real.db');
		{
			my %db;
			tie %db, 'DB_File', $real, Fcntl::O_CREAT() | Fcntl::O_RDWR(), 0644, $DB_File::DB_HASH
				or skip "DB_File cannot create a file: $!", 4;
			$db{key} = 'value';
			untie %db;
		}
		my $opened = $fn->($dir, 'real');
		is_deeply($opened->{columns}, [qw(entry value)], 'a real BerkeleyDB file is a table');
		is($opened->{id}, 'entry', 'keyed by entry');
		ok($opened->{file_size} > 0, 'of a known size');
		ok(!$opened->{_unknown_binary_db}, 'and is not refused');
	}
};

subtest 'DataSource: the BerkeleyDB size guard' => sub {
	# The guard stops DB_File from opening a huge file, so what matters is whether
	# the tie is attempted.  A stand-in tie that always works tells them apart at
	# exactly the limit, where ">=" refuses and the original opens, and one byte over.
	my $fn  = \&Database::BI::Model::DataSource::_detect_file_info;
	my $dir = tempdir(CLEANUP => 1);

	SKIP: {
		eval { require DB_File; 1 } or skip 'DB_File is not installed', 2;

		my $sparse = sub {
			my ($name, $size) = @_;
			my $path = _write_file($dir, "$name.db", pack('N', 0x00061561));
			truncate($path, $size) or skip "cannot make a sparse file: $!", 2;
			return;
		};
		$sparse->('limit', $BDB_LIMIT);
		$sparse->('over', $BDB_LIMIT + 1);

		no warnings qw(redefine once);
		local *DB_File::TIEHASH = sub { return bless {}, 'Local::FakeBDB' };
		local *Local::FakeBDB::UNTIE = sub { return };

		is_deeply($fn->($dir, 'limit')->{columns}, [qw(entry value)], 'at the limit it is opened');
		ok($fn->($dir, 'over')->{_unknown_binary_db}, 'over it, it is refused unopened');
	}
};

subtest 'DataSource: a file that claims to be a database, through new()' => sub {
	# _init_backend must refuse the sentinel rather than read binary as CSV text.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'broken.db', pack('N', 0x00061561) . ('x' x 60));
	throws_ok { $DS->new(directory => $dir, table => 'broken') } qr/./, 'refused';
};

# ===========================================================================
# DataSource: XLSX detection
# ===========================================================================

subtest 'DataSource: _detect_file_info on an XLSX' => sub {
	my $fn = \&Database::BI::Model::DataSource::_detect_file_info;

	SKIP: {
		eval { require Excel::Writer::XLSX; require Spreadsheet::ParseXLSX; 1 }
			or skip 'Excel::Writer::XLSX and Spreadsheet::ParseXLSX are needed', 6;

		my $dir = tempdir(CLEANUP => 1);

		my $write = sub {
			my ($name, @rows) = @_;
			my $wb = Excel::Writer::XLSX->new(File::Spec->catfile($dir, "$name.xlsx"));
			my $ws = $wb->add_worksheet;
			$ws->write_row($_, 0, $rows[$_]) for 0 .. $#rows;
			$wb->close;
			return;
		};

		# Inverting "-r" reads a file that is not there.
		is_deeply($fn->($dir, 'absent'), {}, 'no file: nothing is known');

		$write->('sheet', [qw(b a)], [ 1, 2 ]);
		is_deeply($fn->($dir, 'sheet')->{columns}, [qw(b a)], 'the columns are in the order of the sheet');

		# A blank sheet is empty: row_range answers max < min.  A sheet of only a header
		# has max == min and is not, so "<=" dies on it.  ">" and ">=" die on the sheet
		# with rows above.
		$write->('blank');
		ok($fn->($dir, 'blank')->{_file_is_empty}, 'a blank sheet is an empty file');
		$write->('header', [qw(x y)]);
		is_deeply($fn->($dir, 'header')->{columns}, [qw(x y)], 'a sheet of only a header is not');

		# A parse that finds no sheet at all: inverting "unless ($ws)" goes on to read
		# the sheet that is not there.
		no warnings qw(redefine once);
		local *Spreadsheet::ParseXLSX::parse = sub { return };
		my $empty = $fn->($dir, 'sheet');
		ok($empty->{_file_is_empty}, 'a workbook with no sheet is an empty file');
		ok($empty->{file_size} > 0, 'of its size on disc');
	}
};

# ===========================================================================
# DataSource: _detect_file_info on a text file
# ===========================================================================

subtest 'DataSource: _detect_file_info chooses the separator and the id' => sub {
	my $fn  = \&Database::BI::Model::DataSource::_detect_file_info;
	my $dir = tempdir(CLEANUP => 1);

	# One field holding "!" means "!" separates.  A line with a comma as well means
	# the "!" is only text.  "!=" of "@probe == 1" swaps these two.
	_write_file($dir, 'bang.csv', "a!b\n1!2\n");
	is($fn->($dir, 'bang')->{sep_char}, '!', 'a .csv that uses "!"');
	_write_file($dir, 'comma.csv', "a,b!c\n1,2\n");
	is($fn->($dir, 'comma')->{sep_char}, ',', 'a .csv with a "!" in a name');

	# The id is the first safe column with a value in the first row.  Column a is
	# empty there, and D::A drops rows with an empty id, so b it must be.  Inverting
	# "defined $data_line" or "length $val" leaves a.  A blank line before the row
	# is not the row.
	_write_file($dir, 'gap.csv', "a,b\n\n,2\n");
	is($fn->($dir, 'gap')->{id}, 'b', 'the first column with a value is the id');

	# With nothing to go on, the first safe column.
	_write_file($dir, 'header.csv', "a,b\n");
	is($fn->($dir, 'header')->{id}, 'a', 'a file of only a header');

	# No safe name in line 1.  Values that look like data make it header-less; words
	# do not, and are left for _init_backend to refuse.  Inverting "defined $safe_id"
	# skips this for the first and tries it on every file with a good header, and
	# inverting "values_are_data_like" swaps the two.
	_write_file($dir, 'bank.csv', "2026-01-02,12.50,Two words\n");
	my $bank = $fn->($dir, 'bank');
	is_deeply($bank->{columns}, [qw(Date Amount Description)], 'data in line 1: the columns are made up');
	is($bank->{id}, 'Date', 'the first of them is the id');
	ok($bank->{_headerless}, 'and the file is marked');

	_write_file($dir, 'words.csv', "First Name,Last Name\nA,B\n");
	my $words = $fn->($dir, 'words');
	is($words->{id}, undef, 'names with no safe one: no id');
	ok(!$words->{_headerless}, 'and it is not header-less');
	ok(!$fn->($dir, 'gap')->{_headerless}, 'nor is a file with a good header');
};

subtest 'DataSource: names that need a safe alias, through new()' => sub {
	# A file whose stem is not a safe identifier is reached through a symlink with a
	# safe one.  Inverting "$raw_table ne $table" or "defined $safe_ext" leaves D::A
	# looking for a name it refuses, or a file that is not there.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'my data.csv', "name,value\nA,1\n");
	my $alias = $DS->new(directory => $dir, table => 'my data');
	is($alias->table_name, 'my_data', 'the table has a safe name');
	is_deeply($alias->fetch_all, [ { name => 'A', value => 1 } ], 'and the file is read');
	throws_ok { $DS->new(directory => $dir, table => 'no such file')->fetch_all } qr/./, 'and no file is still an error';
};

subtest 'DataSource: choosing a table in a SQLite file, through new()' => sub {
	# The table asked for, the one named after the file, or the first by name that
	# can be opened.  "defined $desired" and "$target ne $dbname" each read the wrong table
	# when inverted, and "$desired !~ $TABLE_NAME_RE" lets a refused name through to
	# D::A, or refuses a good one.
	my $dir = tempdir(CLEANUP => 1);
	require DBI;
	my $make = sub {
		my ($stem, @tables) = @_;
		my $dbh = DBI->connect('dbi:SQLite:dbname=' . File::Spec->catfile($dir, "$stem.sqlite"), '', '',
			{ RaiseError => 1, PrintError => 0 });
		for my $table (@tables) {
			$dbh->do(qq{CREATE TABLE "$table" (label TEXT)});
			$dbh->do(qq{INSERT INTO "$table" VALUES ('in $table')});
		}
		$dbh->disconnect;
		return;
	};
	$make->('shop', 'orders', 'customers', 'odd name');
	$make->('named', 'first', 'named');

	my $labels = sub { return [ map { $_->{label} } @{ $_[0]->fetch_all } ] };

	is_deeply($labels->($DS->new(directory => $dir, table => 'shop', internal_table => 'orders')),
		['in orders'], 'the table asked for');
	is_deeply($labels->($DS->new(directory => $dir, table => 'shop')), ['in customers'], 'otherwise the first by name');
	is_deeply($labels->($DS->new(directory => $dir, table => 'named')), ['in named'],
		'or the one named after the file');
	is_deeply([ sort @{ $DS->new(directory => $dir, table => 'shop')->sqlite_tables } ],
		[ 'customers', 'odd name', 'orders' ], 'and all of them are listed');

	throws_ok { $DS->new(directory => $dir, table => 'shop', internal_table => 'absent') }
		qr/absent/, 'a table it does not have is an error';
	throws_ok { $DS->new(directory => $dir, table => 'shop', internal_table => 'odd name') }
		qr/odd_name/, 'and one D::A refuses says what to call it';
};

# ===========================================================================
# DataSource: small pure functions
# ===========================================================================

subtest 'DataSource: _values_are_data_like answers exactly 1 or 0' => sub {
	my $fn = \&Database::BI::Model::DataSource::_values_are_data_like;
	is($fn->([ '2026-10-22', 'x' ]), 1, 'an ISO date');
	is($fn->([ 'x', '10/22/2026' ]), 1, 'a slash date');
	is($fn->([ '-1,234.50' ]),       1, 'a signed number');
	is($fn->([ '(1,234.50)' ]),      1, 'an accounting negative');
	is($fn->([ 'First Name', 'Last Name' ]), 0, 'words are not');
	is($fn->([]), 0, 'nor is nothing');
};

subtest 'DataSource: _sniff_data_ext' => sub {
	my $fn  = \&Database::BI::Model::DataSource::_sniff_data_ext;
	my $dir = tempdir(CLEANUP => 1);
	my %cases = (
		db  => "SQLite format 3\0more",
		xml => qq{<?xml version="1.0"?><a/>},
		tsv => "a\tb\n",
		psv => "a|b\n",
		csv => "a,b\n",
	);
	for my $ext (sort keys %cases) {
		is($fn->(_write_file($dir, "$ext.log", $cases{$ext})), $ext, "$ext is recognised");
	}
	is($fn->(_write_file($dir, 'tag.log', "  <rows/>\n")), 'xml', 'a tag with no preamble is XML');
	is($fn->(_write_file($dir, 'empty.log', '')), 'csv', 'an empty file falls back to CSV');
};

subtest 'DataSource: _safe_table_name and _url_label' => sub {
	my $safe = \&Database::BI::Model::DataSource::_safe_table_name;
	is($safe->('First Name'), 'First_Name', 'a name is made safe');

	my $label = \&Database::BI::Model::DataSource::_url_label;
	is($label->('http://example.com/a/Sales.html'), 'sales', 'a URL is named after its last part');
	like($label->('http://example.com/9'), qr/\A[a-z_]/, 'and always starts as a table name must');
};

subtest 'DataSource: _unsafe_sort and _sorted_page' => sub {
	my $unsafe = \&Database::BI::Model::DataSource::_unsafe_sort;

	# A hashref and a flat list are the two forms, and "!=" picks the wrong one.
	my ($rest, @page) = $unsafe->({ sort_by => 'First Name', limit => 2, offset => 1, query => 'q' });
	is_deeply($rest, { query => 'q' }, 'a hashref: what is left for the backend');
	is_deeply(\@page, [ 'First Name', 'ASC', 2, 1 ], 'and how to page it');

	($rest, @page) = $unsafe->(sort_by => [ 'First Name', 'desc' ]);
	is_deeply($rest, {}, 'a flat list');
	is_deeply(\@page, [ 'First Name', 'DESC', undef, undef ], 'with a direction');

	is_deeply([ $unsafe->(sort_by => 'safe_name') ], [], 'a safe name is for the backend');
	is_deeply([ $unsafe->('odd') ], [], 'an odd list is not options');
	is_deeply([ $unsafe->() ], [], 'nor is nothing');

	# Sorted, then paged.  A limit of 1 dies on ">" and ">=" of "limit < rows", which
	# leave the page whole.
	my $sorted = \&Database::BI::Model::DataSource::_sorted_page;
	my @rows   = map { { n => $_ } } qw(b c a);
	my $names  = sub { return [ map { $_->{n} } @{ $_[0] } ] };

	is_deeply($names->($sorted->(\@rows, 'n', 'ASC')), [qw(a b c)], 'ascending');
	is_deeply($names->($sorted->(\@rows, 'n', 'DESC')), [qw(c b a)], 'descending');
	is_deeply($names->($sorted->(\@rows, 'absent', 'ASC')), [qw(b c a)], 'a column it does not have leaves the order alone');
	is_deeply($names->($sorted->(\@rows, 'n', 'ASC', 1)), ['a'], 'a limit');
	is_deeply($names->($sorted->(\@rows, 'n', 'ASC', 9)), [qw(a b c)], 'a limit past the end');
	is_deeply($names->($sorted->(\@rows, 'n', 'ASC', 1, 1)), ['b'], 'and an offset');
	is_deeply($names->($sorted->(undef, 'n', 'ASC')), [], 'no rows');
};

subtest 'DataSource: _split_csv_line and _synthesize_col_names' => sub {
	my $split = \&Database::BI::Model::DataSource::_split_csv_line;
	my $names = \&Database::BI::Model::DataSource::_synthesize_col_names;

	# A line that parses honours its quotes.  One that does not (the quote carries on
	# over the next line) falls through to the plain split, whose return has a negated
	# and an undef mutant.
	is_deeply([ $split->(q{a,"b,c"}, ',') ], [ 'a', 'b,c' ], 'a line that parses: quotes count');
	is_deeply([ $split->(q{"a,b,}, ',') ], [ '"a', 'b', '' ], 'one that does not: split, keeping the empty end');

	is_deeply([ $names->([ '2026-01-02', '12.50', 'Coffee' ]) ], [qw(Date Amount Description)], 'types are named');
	is_deeply([ $names->([ '1/2/2026', '2026-01-02' ]) ], [qw(Date Date2)], 'and numbered when there are two');
};

subtest 'DataSource: _copy_with_header' => sub {
	# A header-less file becomes a copy with this header.  Rows that are too long
	# have their extra fields folded into the last column, and short ones are padded,
	# so "> names" has mutants in both directions.  The id is the column with the
	# fewest unusable values.
	my $dir  = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'in.csv', ",2,3\n\n,5,6,7\n8\n");
	my $self = _source();

	my ($tmp, $best, $size) = $self->_copy_with_header(
		{ path => $path, ext => 'csv' }, [qw(a b c)], ',', 'in');
	my $copy = File::Spec->catfile("$tmp", 'in.csv');
	ok(-f $copy, 'the copy is made') or return;
	open my $fh, '<:raw', $copy or die "$copy: $!";
	my @lines = <$fh>;
	close $fh or die "$copy: $!";
	chomp @lines;

	is_deeply(\@lines, [ 'a,b,c', ',2,3', ',5,"6,7"', '8,,' ],
		'a header, no blank line, a long row folded and a short one padded');
	is($best, 'b', 'the column with the fewest empty values is the id');
	is($size, -s $copy, 'and the size of the copy is answered');

	# Only a real parse failure is an error, not the plain end of the file.
	my $bad = _write_file($dir, 'bad.csv', qq{a,b\n"unterminated,x\n});
	throws_ok {
		$self->_copy_with_header({ path => $bad, ext => 'csv' }, [qw(a b)], ',', 'bad')
	} qr/cannot parse/, 'a file that cannot be parsed is reported';
};

# ===========================================================================
# DataSource: the cache key and the read paths
# ===========================================================================

subtest 'DataSource: _cache_key' => sub {
	my $url = _source(_url => 'http://x/y');
	is($url->_cache_key, 'bi:url:http://x/y:0', 'a URL, at the first table');
	is(_source(_url => 'http://x/y', _html_table_index => 2)->_cache_key, 'bi:url:http://x/y:2', 'and at another');

	my $dir  = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'f.csv', "a\n1\n");
	my $mtime = (stat $path)[9];
	is(_source(_file_path => $path)->_cache_key, "bi:file:$path:$mtime", 'a file: its path and its time');

	is(_source(_file_path => File::Spec->catfile($dir, 'gone.csv'))->_cache_key, undef, 'a file that is gone: no key');
	is(_source()->_cache_key, undef, 'nothing to go on: no key');
};

subtest 'DataSource: selectall_arrayref' => sub {
	my $rows = [ { n => 1 } ];

	is_deeply(_source(_file_is_empty => 1)->selectall_arrayref, [], 'an empty file: no rows');

	# No cache: straight through.
	my $plain = Local::Backend->new(rows => $rows);
	is(_source(_db => $plain)->selectall_arrayref, $rows, 'the rows are answered, as they are');

	# A miss reads and stores.  The next call is a hit and does not read again.
	my $dir   = tempdir(CLEANUP => 1);
	my $path  = _write_file($dir, 'f.csv', "n\n1\n");
	my $mtime = (stat $path)[9];
	my $cache = Local::Cache->new;
	my $back  = Local::Backend->new(rows => $rows);
	my $file  = _source(_db => $back, _cache => $cache, _file_path => $path);

	is($file->selectall_arrayref, $rows, 'a miss answers the rows');
	is_deeply($cache->{sets}, [ [ "bi:file:$path:$mtime", $rows ] ], 'and stores them with no time limit');
	is($file->selectall_arrayref, $rows, 'a hit answers the same rows');
	is(scalar @{ $back->{calls} }, 1, 'without reading again');

	# A URL's entry has a time limit.
	my $url_cache = Local::Cache->new;
	my $url = _source(_db => Local::Backend->new(rows => $rows), _cache => $url_cache, _url => 'http://x/y', _cache_ttl_url => '15 min');
	$url->selectall_arrayref;
	is_deeply($url_cache->{sets}, [ [ 'bi:url:http://x/y:0', $rows, '15 min' ] ], 'a URL is stored with its time limit');

	# A narrowed query must not be mistaken for the whole table.
	my $narrow_cache = Local::Cache->new;
	my $narrow = _source(_db => Local::Backend->new(rows => $rows), _cache => $narrow_cache, _file_path => $path);
	$narrow->selectall_arrayref({ n => 1 });
	is($narrow_cache->{gets}, 0, 'a narrowed query does not look in the cache');
	is_deeply($narrow_cache->{sets}, [], 'nor store in it');

	# No key: nothing to look up or store under.
	my $keyless_cache = Local::Cache->new;
	my $keyless = _source(_db => Local::Backend->new(rows => $rows), _cache => $keyless_cache);
	is($keyless->selectall_arrayref, $rows, 'no key: the rows still come back');
	is($keyless_cache->{gets}, 0, 'and nothing is looked up');
	is_deeply($keyless_cache->{sets}, [], 'or stored');

	# Nothing read: nothing stored.
	my $none_cache = Local::Cache->new;
	_source(_db => Local::Backend->new(rows => undef), _cache => $none_cache, _file_path => $path)->selectall_arrayref;
	is_deeply($none_cache->{sets}, [], 'no answer is not stored');

	# A column whose name is not a safe identifier is sorted here.
	my @people = map { { 'First Name' => $_ } } qw(Bob Al);
	my $sort_back = Local::Backend->new(rows => \@people);
	my $sorted = _source(_db => $sort_back)->selectall_arrayref(sort_by => 'First Name', limit => 1);
	is_deeply($sorted, [ { 'First Name' => 'Al' } ], 'an unsafe sort column is sorted and paged here');
	is_deeply($sort_back->{calls}[0], ['selectall_arrayref'], 'and the backend is not told about it');

	# What a URL answers need not be rows.
	throws_ok {
		_source(_db => Local::Backend->new(rows => [ 1, 2 ]), _url => 'http://x/y')->selectall_arrayref
	} qr/./, 'a URL answering with anything but rows is an error';
};

subtest 'DataSource: fetch_all' => sub {
	my $rows = [ { n => 1 } ];

	is_deeply(_source(_file_is_empty => 1)->fetch_all, [], 'an empty file: no rows');
	is(_source(_db => Local::Backend->new(rows => $rows))->fetch_all, $rows, 'the rows are answered as they are');
	is_deeply(_source(_db => Local::Backend->new(rows => undef))->fetch_all, [], 'no answer is no rows');

	throws_ok { _source(_db => Local::Backend->new(die => 'broken'))->fetch_all } qr/broken/, 'a backend failure is reported';

	# A hash keyed by id is turned into rows, with a warning; an empty answer warns
	# too.  Inverting either test warns on the wrong rows.
	my ($warned, $normal) = _warnings_of(sub { _source(_db => Local::Backend->new(rows => { a => { n => 1 } }))->fetch_all });
	is_deeply($normal, $rows, 'a hash becomes rows');
	is(scalar @{$warned}, 1, 'and it warns once');

	($warned) = _warnings_of(sub { _source(_db => Local::Backend->new(rows => $rows))->fetch_all });
	is_deeply($warned, [], 'rows do not warn');

	($warned, my $none) = _warnings_of(sub { _source(_db => Local::Backend->new(rows => []))->fetch_all });
	is_deeply($none, [], 'no rows');
	is(scalar @{$warned}, 1, 'warns once');

	throws_ok {
		_source(_db => Local::Backend->new(rows => [ 1, 2 ]), _url => 'http://x/y')->fetch_all
	} qr/./, 'a URL answering with anything but rows is an error';

	# The cache, as for selectall_arrayref.
	my $dir   = tempdir(CLEANUP => 1);
	my $path  = _write_file($dir, 'f.csv', "n\n1\n");
	my $mtime = (stat $path)[9];
	my $cache = Local::Cache->new;
	my $back  = Local::Backend->new(rows => $rows);
	my $file  = _source(_db => $back, _cache => $cache, _file_path => $path);

	is($file->fetch_all, $rows, 'a miss answers the rows');
	is_deeply($cache->{sets}, [ [ "bi:file:$path:$mtime", $rows ] ], 'and stores them with no time limit');
	is($file->fetch_all, $rows, 'a hit answers the same rows');
	is(scalar @{ $back->{calls} }, 1, 'without reading again');

	my $url_cache = Local::Cache->new;
	_source(_db => Local::Backend->new(rows => $rows), _cache => $url_cache, _url => 'http://x/y', _cache_ttl_url => '15 min')->fetch_all;
	is_deeply($url_cache->{sets}, [ [ 'bi:url:http://x/y:0', $rows, '15 min' ] ], 'a URL is stored with its time limit');

	my $keyless_cache = Local::Cache->new;
	is(_source(_db => Local::Backend->new(rows => $rows), _cache => $keyless_cache)->fetch_all, $rows, 'no key: the rows still come back');
	is($keyless_cache->{gets}, 0, 'and nothing is looked up');
	is_deeply($keyless_cache->{sets}, [], 'or stored');
};

subtest 'DataSource: the accessors answer what they hold' => sub {
	# Each is a one-line return with a negated and an undef mutant.
	my $self = _source(_table => 'sales', _sqlite_tables => [qw(a b)], _id_col => 'id', _url => 'http://x/y');
	is($self->table_name, 'sales', 'table_name');
	is_deeply($self->sqlite_tables, [qw(a b)], 'sqlite_tables');
	is($self->id_column, 'id', 'id_column');
	is($self->source_url, 'http://x/y', 'source_url');
};

subtest 'DataSource: columns' => sub {
	is_deeply(_source(_columns => [qw(a b)])->columns, [qw(a b)], 'known columns');
	is(_source(_url => 'http://x/y')->columns, undef, 'a URL has none until it is read');
	is(_source()->columns, undef, 'no backend has none');

	is_deeply(_source(_db => Local::Backend->new(columns => [qw(x y)]))->columns, [qw(x y)], 'otherwise the backend says');

	# Redis: the id column is added, once, and first.
	my $redis = _source(_redis_url => 'redis://h', _id_col => 'entry', _db => Local::Backend->new(columns => [qw(a entry b)]));
	is_deeply($redis->columns, [qw(entry a b)], 'Redis: the id column first');
	is_deeply($redis->{_columns}, [qw(entry a b)], 'and kept');
	is(_source(_redis_url => 'redis://h')->columns, undef, 'Redis with no backend: none');
};

subtest 'DataSource: dbi_source' => sub {
	# undef is the answer on every path out but the last: "!(undef)" is true, and a
	# caller guarding with "if ($source->dbi_source)" would believe in a database.
	is(_source(_file_is_empty => 1, _db => Local::Backend->new(dbi => 'dsn'))->dbi_source, undef, 'an empty file');
	is(_source()->dbi_source, undef, 'no backend');
	is(_source(_db => Local::BareBackend->new)->dbi_source, undef, 'a backend that cannot say');
	is(_source(_db => Local::Backend->new(dbi_dies => 1))->dbi_source, undef, 'a backend that fails');
	is(_source(_db => Local::Backend->new(dbi => 'dsn'))->dbi_source, 'dsn', 'a backend that can');
};

subtest 'DataSource: aggregate, updated, schema and count' => sub {
	is_deeply(_source(_db => Local::Backend->new)->aggregate('sum'), { aggregated => ['sum'] }, 'aggregate asks the backend');

	my $dir  = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'f.csv', "n\n1\n");
	is(_source(_file_path => $path, _db => Local::Backend->new(updated => 1))->updated, (stat $path)[9], 'updated: the file comes first');
	is(_source(_db => Local::Backend->new(updated => 42))->updated, 42, 'and the backend second');
	is(_source()->updated, undef, 'and neither: unknown');

	is_deeply(_source(_db => Local::Backend->new(schema => { a => 1 }))->schema, { a => 1 }, 'schema asks the backend');
	is_deeply(_source(_db => Local::Backend->new(schema => [1]))->schema, {}, 'and anything but a hash is nothing');
	is_deeply(_source(_db => Local::Backend->new(schema_dies => 1))->schema, {}, 'as is a failure');
	is_deeply(_source(_db => Local::BareBackend->new)->schema, {}, 'as is a backend that cannot say');

	is(_source(_file_is_empty => 1)->count, 0, 'count of an empty file');
	is(_source(_db => Local::Backend->new(count => 7))->count, 7, 'count asks the backend');
};

subtest 'DataSource: messages' => sub {
	# _msg translates when it has something to translate with.
	is(_source(_i18n => Local::I18n->new)->_msg('some_key', 'a'), 'translated:some_key:a', 'with a translator');
	like(_source()->_msg('error_table_required'), qr/\S/, 'without one, the English');
	like(Database::BI::Model::DataSource::_fmt('error_directory_missing', '/x'), qr{/x}, '_fmt fills in its arguments');
	like(Database::BI::Model::DataSource::_fmt('error_table_required'), qr/\S/, 'and copes with none');
};

# ===========================================================================
# DataSource: table names the backend keeps for itself
# ===========================================================================

subtest 'DataSource: a table may be called data' => sub {
	# Found while writing the remote test below.  Database::Abstraction before 0.54
	# kept its handle in $self->{$table}, the same hash as its own fields, so a
	# table called data overwrote its rows, and fetch_all died with "Not an ARRAY
	# reference".  The same went for id, directory and others.  The app's own
	# SQLite export names its table "data", so an export could not be opened again.
	# 0.54 keeps handles in $self->{_dbh}{$table}, and is the minimum.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'data.csv', "name,value\nA,1\n");

	my $export_dir = tempdir(CLEANUP => 1);
	my $export     = File::Spec->catfile($export_dir, 'export.sqlite');
	require DBI;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$export", '', '', { RaiseError => 1, PrintError => 0 });
	$dbh->do('CREATE TABLE "data" (name TEXT, value TEXT)');
	$dbh->do(q{INSERT INTO "data" VALUES ('A', '1')});
	$dbh->disconnect;

	for my $case ([ $dir, 'data', 'a file called data.csv' ], [ $export_dir, 'export', 'a SQLite export' ]) {
		my ($from, $table, $what) = @{$case};
		my $rows = eval { $DS->new(directory => $from, table => $table)->fetch_all };
		is_deeply($rows, [ { name => 'A', value => 1 } ], "$what can be read");
	}
};

# ===========================================================================
# DataSource: a remote file with an extension of its own
# ===========================================================================

subtest 'DataSource: a remote file is renamed to what its content says' => sub {
	# _init_backend renames a download with an unknown extension to the one its
	# content calls for, or nothing can read it.  "if ($KNOWN_EXT...)" inverted skips
	# that, and renames known ones.  Running through new() with a stand-in connection
	# is the only way to reach this code.
	SKIP: {
		eval { require Net::SFTP::Foreign; 1 } or skip 'Net::SFTP::Foreign is not installed', 4;

		no warnings qw(redefine once);
		local *Net::SFTP::Foreign::new = sub { return Local::SFTP->new };

		Local::SFTP->serve('/remote/feed.log' => "name\tvalue\nA\t1\n", '/remote/other.csv' => "name,value\nB,2\n");

		my $log = $DS->new(directory => '/remote', table => 'feed', host => 'h.example', file_ext => 'log');
		like($log->{_file_path}, qr/feed\.tsv\z/, 'a .log holding tabs is read as TSV');
		is_deeply([ map { $_->{name} } @{ $log->fetch_all } ], ['A'], 'and its rows are found');

		my $csv = $DS->new(directory => '/remote', table => 'other', host => 'h.example');
		like($csv->{_file_path}, qr/other\.csv\z/, 'a .csv keeps its name');
		is_deeply([ map { $_->{value} } @{ $csv->fetch_all } ], [2], 'and its rows are found');
	}
};

done_testing();

__END__

=head1 EQUIVALENT MUTANTS

These mutations cannot be told from the original by any input, so no test here
tries.  Each should be excluded from the score, or marked with C<## MUTANT_SKIP>.

=over 4

=item C<_is_date_col>, C<_is_numeric_col>: C<@$vals E<gt>= 20>

At exactly 20 both branches give 20.

=item C<_find_outliers>: C<@nums E<lt>= 4>

Four values can never hold an outlier.  The top value is (x4 - x3) / 2 above Q3,
and the IQR is at least that, so the fence at 1.5 * IQR is further out.  The bottom
value is the same by symmetry.  So skipping a group of 4 changes nothing.

=item C<_find_outliers>, C<_top_movers>: C<splice ... if @list E<gt>= limit>

At exactly the limit the splice removes nothing.

=item C<_find_outliers>: C<$val E<gt>= $hi_fence> (three lines)

These choose high or low for a value already known to be outside the fences, so it
is never equal to the high fence.

=item C<_fence_distance>: C<$val E<gt>= $hi>, C<$val E<lt>= $lo>

At the fence the distance is 0 by either branch.

=item C<_detect_file_info>: C<return undef unless $db_obj>

The result only goes to C<if ($opens)>, and undef and 0 are both false.

=item C<_sorted_page>: C<$limit E<lt>= @page>

A limit equal to the number of rows removes none.

=item C<_fmt_num>: C<abs($n) E<lt>= 1e12>

1e12 prints as 1000000000000 by both routes.

=item C<_copy_with_header>: C<@{$row} E<gt>= @{$names}>

A row of exactly the right length loses its last field and gets it back.

=item C<_top_movers>: all three changes to C<my $sign = ...>

The variable is never used.

=item C<RETURN_UNDEF> on a C<return undef>

The mutant is the original.

=back

=cut
