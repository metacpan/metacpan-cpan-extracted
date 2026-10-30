package Database::BI::Insights;

use strict;
use warnings;

our $VERSION = '0.018.0';

use Database::BI::Util  qw(urlencode);
use List::Util          qw(sum min max);
use Scalar::Util        qw(looks_like_number);
use Readonly;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# IQR fence multiplier (Tukey, 1977).
Readonly my $IQR_FENCE => 1.5;

# Minimum distinct periods required for period-over-period and seasonality.
Readonly my $MIN_PERIODS_POP   => 2;
Readonly my $MIN_PERIODS_SEASON => 8;

# Minimum rows in a group to attempt outlier detection.
Readonly my $MIN_ROWS_OUTLIER => 4;

# Autocorrelation threshold above which we call a pattern "seasonal".
Readonly my $SEASON_R_THRESHOLD => 0.6;

# Maximum outliers reported per column (keeps the panel readable).
Readonly my $MAX_OUTLIERS_PER_COL => 5;

# Maximum top-mover rows reported.
Readonly my $MAX_TOP_MOVERS => 5;

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# compute( records => \@rows, columns => \@cols, spec_key => $l, base_url => $url )
#   -> \@insights
#
# Each insight hashref has:
#   kind      -- 'outlier' | 'top_mover' | 'period_delta' | 'seasonality'
#   headline  -- one short sentence
#   detail    -- one sentence giving the numbers
#   view_url  -- absolute-path URL (without host) linking to the view that shows it
#                (always present; the spec says "an insight you cannot click through is a bug")
#   method    -- key into %METHOD_NOTES documenting the algorithm used
#
# Arguments:
#   records  -- arrayref of row hashrefs (pre-filtered, post-calc)
#   columns  -- arrayref of column names in order
#   spec_key -- the l= value (e.g. "table:sales" or "path:/data/x.csv")
#   base_url -- base request URL to build view_url from (e.g. "/stats?l=table:sales")
#
# NOTE: This sub is pure arithmetic -- no LLM, no external calls.
sub compute {
	my (%args) = @_;
	my $records  = $args{records}  // [];
	my $columns  = $args{columns}  // [];
	my $spec_key = $args{spec_key} // '';
	my $base_url = $args{base_url} // "/insights?l=$spec_key";

	return [] unless @$records && @$columns;

	my @insights;

	# Identify date columns (ISO-8601 YYYY-MM-DD) and numeric columns.
	my (@date_cols, @numeric_cols);
	for my $col (@$columns) {
		my @vals = grep { defined $_ && length $_ } map { $_->{$col} } @$records;
		next unless @vals;
		if (_is_date_col(\@vals)) {
			push @date_cols, $col;
		} elsif (_is_numeric_col(\@vals)) {
			push @numeric_cols, $col;
		}
	}

	# Outlier detection: for each numeric column scan all distinct category
	# groups formed by each non-numeric, non-date column.  When the dataset
	# has no categorical column, treat all rows as one group.
	my @cat_cols = grep {
		my $c = $_;
		!grep { $_ eq $c } (@date_cols, @numeric_cols)
	} @$columns;

	for my $num_col (@numeric_cols) {
		my @found = _find_outliers($records, $num_col, \@cat_cols, $spec_key, $base_url);
		push @insights, @found;
	}

	# Period-over-period and top movers: need a date column + at least one
	# numeric column.
	if (@date_cols && @numeric_cols) {
		my $date_col = $date_cols[0];	# use the first date column found
		for my $num_col (@numeric_cols) {
			push @insights,
				_period_over_period($records, $date_col, $num_col, $spec_key, $base_url);
			push @insights,
				_top_movers($records, $date_col, $num_col, \@cat_cols, $spec_key, $base_url);
			push @insights,
				_seasonality($records, $date_col, $num_col, $spec_key, $base_url);
		}
	}

	return \@insights;
}

# method_note($method_key) -> $string
#
# Returns a one-sentence human-readable description of the algorithm behind
# a given insight method key.  Used by the template's tooltip/footnote.
sub method_note {
	my $key = shift;
	my %notes = (
		iqr_fence  => 'Outlier: value beyond 1.5 x IQR from Q1 or Q3 (Tukey fence).',
		pop_delta  => 'Period-over-period: sum for the most-recent period vs. the prior period.',
		top_mover  => 'Top mover: dimension member with the largest period-over-period absolute change.',
		autocorr   => 'Seasonality: lag-1 autocorrelation on period sums; r >= 0.6 flagged.',
	);
	return $notes{$key} // $key;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# _looks_like_date($v) -> bool
#
# Returns true when $v matches any common date format.  Checked BEFORE numeric
# classification so that slash-dates (e.g. 12/22/2025 from US bank exports),
# EU slash-dates (22/12/2025), and dash-Mon dates (22-Oct-2026) are never
# stripped of their punctuation and misread as large integers like 12222025.
sub _looks_like_date {
	my $v = shift;
	return 0 unless defined $v && length $v;
	return 1 if $v =~ /\A\d{4}-\d{2}-\d{2}\z/;            # ISO-8601
	return 1 if $v =~ /\A\d{1,2}\/\d{1,2}\/\d{4}\z/;      # M/D/YYYY or D/M/YYYY
	return 1 if $v =~ /\A\d{1,2}-[A-Za-z]{3}-\d{4}\z/;    # DD-Mon-YYYY
	return 0;
}

sub _is_date_col {
	my $vals = shift;
	my $n = @$vals > 20 ? 20 : scalar @$vals;
	my $ok = 0;
	for my $v (@{$vals}[0 .. $n - 1]) {
		return 0 unless _looks_like_date($v);
		$ok++;
	}
	return $ok ? 1 : 0;
}

sub _is_numeric_col {
	my $vals = shift;
	return 0 unless @$vals;
	my $ok = 0;
	my $n  = @$vals > 20 ? 20 : scalar @$vals;
	for my $v (@{$vals}[0 .. $n - 1]) {
		return 0 if _looks_like_date($v);   # date values are not numeric measures
		my $num = _to_num($v);
		return 0 unless defined $num;
		$ok++;
	}
	return $ok ? 1 : 0;
}

sub _to_num {
	my $v = shift;
	return undef unless defined $v && length $v;
	my $is_acct = ($v =~ /\A\s*\(/);
	(my $n = $v) =~ s/[^\d.-]//g;
	$n = "-$n" if $is_acct && $n =~ /\A\d/;
	return undef unless $n =~ /\A-?\d+(?:\.\d+)?\z/;
	return $n + 0;
}

# _quartiles(\@sorted_nums) -> ($q1, $median, $q3)
#
# Uses the "inclusive" method: for n values, Q1 is the median of the lower
# half (not including the overall median when n is odd), Q3 the median of the
# upper half.  This matches R's type=2 and Excel's QUARTILE.INC.
sub _quartiles {
	my $s = shift;	# already sorted
	my $n = scalar @$s;
	return (undef, undef, undef) unless $n >= 4;

	my $mid  = int($n / 2);
	my @lo   = @{$s}[0 .. $mid - 1];
	my @hi   = @{$s}[$n % 2 ? $mid + 1 : $mid .. $n - 1];

	my $q1 = _median(\@lo);
	my $q2 = _median($s);
	my $q3 = _median(\@hi);
	return ($q1, $q2, $q3);
}

sub _median {
	my $s = shift;
	my $n = scalar @$s;
	return undef unless $n;
	my $m = int($n / 2);
	return $n % 2 ? $s->[$m] : ($s->[$m - 1] + $s->[$m]) / 2;
}

# _find_outliers($records, $num_col, \@cat_cols, $spec_key, $base_url) -> @insights
#
# For each categorical group (or all rows when @cat_cols is empty), apply the
# Tukey IQR fence to the numeric column.  Report up to MAX_OUTLIERS_PER_COL
# values that fall outside [Q1 - 1.5*IQR, Q3 + 1.5*IQR].
sub _find_outliers {
	my ($records, $num_col, $cat_cols, $spec_key, $base_url) = @_;

	my @insights;

	# Group records by category key (empty string when no cat_cols).
	my (%groups, %group_example);
	for my $row (@$records) {
		my $key = join("\x00", map { $row->{$_} // '' } @$cat_cols);
		my $val = _to_num($row->{$num_col});
		push @{ $groups{$key} }, $val if defined $val;
		$group_example{$key} //= $row;
	}

	for my $key (sort keys %groups) {
		my @nums = @{ $groups{$key} };
		next if @nums < $MIN_ROWS_OUTLIER;

		my @sorted = sort { $a <=> $b } @nums;
		my ($q1, undef, $q3) = _quartiles(\@sorted);
		next unless defined $q1 && defined $q3;

		my $iqr     = $q3 - $q1;
		my $lo_fence = $q1 - $IQR_FENCE * $iqr;
		my $hi_fence = $q3 + $IQR_FENCE * $iqr;

		# Find outlier rows.
		my @outlier_rows;
		for my $row (@$records) {
			my $gkey = join("\x00", map { $row->{$_} // '' } @$cat_cols);
			next unless $gkey eq $key;
			my $val = _to_num($row->{$num_col});
			next unless defined $val;
			next unless $val < $lo_fence || $val > $hi_fence;
			push @outlier_rows, { val => $val, row => $row };
		}
		next unless @outlier_rows;

		# Sort by distance from nearest fence, descending.
		@outlier_rows = sort {
			_fence_distance($b->{val}, $lo_fence, $hi_fence) <=>
			_fence_distance($a->{val}, $lo_fence, $hi_fence)
		} @outlier_rows;

		splice @outlier_rows, $MAX_OUTLIERS_PER_COL if @outlier_rows > $MAX_OUTLIERS_PER_COL;

		# Build one insight per outlier.
		for my $o (@outlier_rows) {
			my $val = $o->{val};
			my $row = $o->{row};

			# Build a human-readable group label.
			my $group_label = '';
			if (@$cat_cols) {
				my @parts;
				for my $c (@$cat_cols) {
					push @parts, "$c=" . ($row->{$c} // '');
				}
				$group_label = join(', ', @parts);
			}

			my $dir = $val > $hi_fence ? 'high' : 'low';
			my $headline = $group_label
				? "Unusual $num_col in $group_label: " . _fmt_num($val) . " is unusually $dir"
				: "Unusual $num_col value: " . _fmt_num($val) . " is unusually $dir";

			my $detail = sprintf(
				'Expected range %s \x2013 %s (IQR fence on %d values)',
				_fmt_num($lo_fence), _fmt_num($hi_fence), scalar @nums
			);

			# Build view_url: link to /bar for cat_cols, /stats otherwise.
			my $view_url;
			if (@$cat_cols) {
				my $cat = urlencode($cat_cols->[0]);
				my $val_enc = urlencode($num_col);
				$view_url = "/bar?l=${\urlencode($spec_key)}&cat=$cat&val=$val_enc&sort=value";
			} else {
				$view_url = "/stats?l=" . urlencode($spec_key);
			}

			# Build drill_url: data table filtered to category group so the
			# outlier row is visible in context of its peers.  The hl_col /
			# hl_op / hl_val params tell dashboard.html.tt to highlight and
			# scroll to the specific outlier row(s) within those 75+ peers.
			my $drill_url;
			if (@$cat_cols) {
				my $base = _spec_to_data_url($spec_key);
				if ($base) {
					my $cat_enc  = urlencode($cat_cols->[0]);
					my $gval     = (split /\x00/, $key)[0] // '';
					my $gv_enc   = urlencode($gval);
					my $sep      = ($base =~ /\?/) ? '&' : '?';
					$drill_url   = $base . $sep . 'f=' . $cat_enc . ':eq:' . $gv_enc;
					# Highlight the outlier row(s): beyond the IQR fence.
					my $hl_op    = ($val > $hi_fence) ? 'gt' : 'lt';
					my $hl_fence = ($val > $hi_fence) ? $hi_fence : $lo_fence;
					$drill_url  .= '&hl_col=' . urlencode($num_col)
					            .  '&hl_op='  . $hl_op
					            .  '&hl_val=' . urlencode(sprintf('%.10g', $hl_fence));
					if ($base_url) {
						$drill_url .= '&back2=' . urlencode($base_url)
						           . '&back2_label=Back+to+insights';
					}
				}
			}

			push @insights, {
				kind      => 'outlier',
				headline  => $headline,
				detail    => $detail,
				view_url  => $view_url,
				($drill_url ? (drill_url => $drill_url) : ()),
				method    => 'iqr_fence',
			};
		}
	}

	return @insights;
}

sub _fence_distance {
	my ($val, $lo, $hi) = @_;
	return $val > $hi ? $val - $hi
	     : $val < $lo ? $lo - $val
	     :              0;
}

# _period_over_period($records, $date_col, $num_col, $spec_key, $base_url) -> @insights
#
# Aggregates $num_col by year-month period, then reports the delta between the
# most recent two periods.
sub _period_over_period {
	my ($records, $date_col, $num_col, $spec_key, $base_url) = @_;

	my %period_totals;
	for my $row (@$records) {
		my $date = $row->{$date_col} // '';
		next unless $date =~ /\A(\d{4}-\d{2})/;
		my $period = $1;
		my $val    = _to_num($row->{$num_col});
		next unless defined $val;
		$period_totals{$period} += $val;
	}

	my @periods = sort keys %period_totals;
	return () unless @periods >= $MIN_PERIODS_POP;

	my $cur  = $periods[-1];
	my $prev = $periods[-2];
	my $cur_val  = $period_totals{$cur};
	my $prev_val = $period_totals{$prev};

	my $delta = $cur_val - $prev_val;
	my $pct   = $prev_val != 0 ? $delta / abs($prev_val) * 100 : undef;

	my $dir  = $delta >= 0 ? 'up' : 'down';
	my $sign = $delta >= 0 ? '+' : '';

	my $headline = sprintf('%s is %s %s vs prior period (%s)',
		$num_col, $dir, _fmt_num(abs($delta)), $prev);

	my $detail = defined $pct
		? sprintf('%s: %s  %s: %s  (%s%s%%)',
			$prev, _fmt_num($prev_val), $cur, _fmt_num($cur_val),
			$sign, sprintf('%.1f', $pct))
		: sprintf('%s: %s  %s: %s',
			$prev, _fmt_num($prev_val), $cur, _fmt_num($cur_val));

	my $enc_spec = urlencode($spec_key);
	my $enc_date = urlencode($date_col);
	my $enc_num  = urlencode($num_col);
	my $view_url = "/graph?l=$enc_spec&x=$enc_date&y=$enc_num";

	# Drill into the data table filtered to the current period.
	my $drill_url;
	my $base = _spec_to_data_url($spec_key);
	if ($base) {
		my $sep = ($base =~ /\?/) ? '&' : '?';
		$drill_url = $base . $sep
		           . 'f=' . $enc_date . ':starts:' . urlencode($cur);
		if ($base_url) {
			$drill_url .= '&back2=' . urlencode($base_url)
			           . '&back2_label=Back+to+insights';
		}
	}

	return ({
		kind      => 'period_delta',
		headline  => $headline,
		detail    => $detail,
		view_url  => $view_url,
		($drill_url ? (drill_url => $drill_url) : ()),
		method    => 'pop_delta',
	});
}

# _top_movers($records, $date_col, $num_col, \@cat_cols, $spec_key, $base_url) -> @insights
#
# For each categorical group, compute period-over-period delta between the two
# most recent periods, and report the top MAX_TOP_MOVERS movers.
sub _top_movers {
	my ($records, $date_col, $num_col, $cat_cols, $spec_key, $base_url) = @_;
	return () unless @$cat_cols;

	# Collect totals keyed by (period, group_key).
	my (%totals, %group_labels);
	my %all_periods;
	for my $row (@$records) {
		my $date = $row->{$date_col} // '';
		next unless $date =~ /\A(\d{4}-\d{2})/;
		my $period = $1;
		$all_periods{$period}++;
		my $gkey = join("\x00", map { $row->{$_} // '' } @$cat_cols);
		my $val  = _to_num($row->{$num_col});
		next unless defined $val;
		$totals{$period}{$gkey} += $val;
		$group_labels{$gkey} //= join(', ', map { $row->{$_} // '' } @$cat_cols);
	}

	my @periods = sort keys %all_periods;
	return () unless @periods >= $MIN_PERIODS_POP;

	my $cur  = $periods[-1];
	my $prev = $periods[-2];

	my (@movers);
	for my $gkey (keys %group_labels) {
		my $cur_val  = $totals{$cur}{$gkey}  // 0;
		my $prev_val = $totals{$prev}{$gkey} // 0;
		my $delta    = $cur_val - $prev_val;
		push @movers, { gkey => $gkey, label => $group_labels{$gkey},
		                delta => $delta, cur => $cur_val, prev => $prev_val };
	}

	return () unless @movers;

	# Sort by absolute delta descending.
	@movers = sort { abs($b->{delta}) <=> abs($a->{delta}) } @movers;
	splice @movers, $MAX_TOP_MOVERS if @movers > $MAX_TOP_MOVERS;

	my $cat_col  = $cat_cols->[0];
	my $enc_spec = urlencode($spec_key);
	my $enc_date = urlencode($date_col);
	my $enc_num  = urlencode($num_col);
	my $enc_cat  = urlencode($cat_col);

	my @insights;
	for my $m (@movers) {
		my $dir  = $m->{delta} >= 0 ? 'up' : 'down';
		my $sign = $m->{delta} >= 0 ? '+' : '';
		my $headline = sprintf('%s %s %s by %s from %s to %s',
			$m->{label}, $num_col, $dir, _fmt_num(abs($m->{delta})), $prev, $cur);
		my $detail = sprintf('%s: %s  %s: %s',
			$prev, _fmt_num($m->{prev}), $cur, _fmt_num($m->{cur}));

		# Encode the group value for the filter.
		my $gval_enc = urlencode((split /\x00/, $m->{gkey})[0] // '');
		my $view_url = "/graph?l=$enc_spec&x=$enc_date&y=$enc_num"
		             . "&f=$enc_cat:eq:$gval_enc";

		# Drill into data table filtered to category + current period.
		my $drill_url;
		my $base = _spec_to_data_url($spec_key);
		if ($base) {
			my $sep = ($base =~ /\?/) ? '&' : '?';
			$drill_url = $base . $sep
			           . 'f=' . $enc_date . ':starts:' . urlencode($cur)
			           . '&f=' . $enc_cat  . ':eq:'     . $gval_enc;
			if ($base_url) {
				$drill_url .= '&back2=' . urlencode($base_url)
				           . '&back2_label=Back+to+insights';
			}
		}

		push @insights, {
			kind      => 'top_mover',
			headline  => $headline,
			detail    => $detail,
			view_url  => $view_url,
			($drill_url ? (drill_url => $drill_url) : ()),
			method    => 'top_mover',
		};
	}

	return @insights;
}

# _seasonality($records, $date_col, $num_col, $spec_key, $base_url) -> @insights
#
# Computes period sums (year-month), then calculates the lag-1 autocorrelation
# coefficient on the sequence of sums.  A coefficient >= SEASON_R_THRESHOLD
# is flagged as seasonal.
#
# Autocorrelation formula:
#   r(1) = sum_{t=1}^{n-1}[(x_t - xbar)(x_{t+1} - xbar)] / sum_{t=0}^{n-1}[(x_t - xbar)^2]
#
# This is the Pearson correlation between the series and itself shifted by one
# period.  For a regular, evenly-spaced time series this is the lag-1 Moran
# coefficient.  With uneven spacing it is an approximation, but adequate for
# detecting year-over-year periodicity in monthly business data.
sub _seasonality {
	my ($records, $date_col, $num_col, $spec_key, $base_url) = @_;

	my %period_totals;
	for my $row (@$records) {
		my $date = $row->{$date_col} // '';
		next unless $date =~ /\A(\d{4}-\d{2})/;
		my $period = $1;
		my $val    = _to_num($row->{$num_col});
		next unless defined $val;
		$period_totals{$period} += $val;
	}

	my @periods = sort keys %period_totals;
	return () unless @periods >= $MIN_PERIODS_SEASON;

	my @y     = map { $period_totals{$_} } @periods;
	my $n     = scalar @y;
	my $ybar  = (sum(@y)) / $n;

	my $num   = 0;
	my $denom = 0;
	for my $i (0 .. $n - 1) {
		my $dev = $y[$i] - $ybar;
		$denom += $dev * $dev;
		$num   += $dev * ($y[$i + 1] - $ybar) if $i < $n - 1;
	}

	return () unless $denom > 0;
	my $r = $num / $denom;

	return () unless $r >= $SEASON_R_THRESHOLD;

	my $headline = sprintf('%s shows a repeating period-over-period pattern (r=%.2f)',
		$num_col, $r);
	my $detail = sprintf(
		'Lag-1 autocorrelation %.2f across %d periods (%s to %s)',
		$r, $n, $periods[0], $periods[-1]
	);

	my $enc_spec = urlencode($spec_key);
	my $enc_date = urlencode($date_col);
	my $enc_num  = urlencode($num_col);
	my $view_url = "/graph?l=$enc_spec&x=$enc_date&y=$enc_num";

	return ({
		kind     => 'seasonality',
		headline => $headline,
		detail   => $detail,
		view_url => $view_url,
		method   => 'autocorr',
	});
}

# _fmt_num($n) -> $string
# Format a number to 4 significant figures, stripping trailing zeros.
sub _fmt_num {
	my $n = shift;
	return 'N/A' unless defined $n;
	return sprintf('%s', $n) if $n == int($n) && abs($n) < 1e12;
	return sprintf('%s', 0 + sprintf('%.4g', $n));
}


# _spec_to_data_url($spec_key) -> $url_or_undef
#
# Converts a l= spec key to the root-relative URL of the data table page.
#   table:sales           -> /view/sales
#   path:/abs/path/f.csv  -> /open?path=%2Fabs%2Fpath%2Ff.csv
# Returns undef for unrecognised spec forms.
sub _spec_to_data_url {
	my $spec = shift // '';
	if ($spec =~ /\Atable:(.+)\z/) {
		return '/view/' . urlencode($1);
	}
	if ($spec =~ /\Apath:(.+)\z/) {
		return '/open?path=' . urlencode($1);
	}
	return undef;
}

1;

__END__

=head1 NAME

Database::BI::Insights - Automatic statistical insights for Database::BI (Phase 5.2)

=head1 SYNOPSIS

    use Database::BI::Insights;

    my $insights = Database::BI::Insights::compute(
        records  => \@rows,
        columns  => \@cols,
        spec_key => 'table:sales',
        base_url => '/insights?l=table:sales',
    );

=head1 DESCRIPTION

Pure-arithmetic insight detection.  No LLM, no external service calls.
Detects four classes of insight:

=over

=item outlier

A value beyond the Tukey IQR fence (Q1 - 1.5*IQR or Q3 + 1.5*IQR).

=item period_delta

Overall period-over-period delta between the most recent two month-periods
visible in a date column.

=item top_mover

The dimension member with the largest period-over-period absolute change.
Requires at least one categorical column and one date column.

=item seasonality

Detected via lag-1 autocorrelation on monthly totals.  A coefficient >= 0.6
is flagged.  Requires at least 8 distinct month-periods.

=back

Every insight includes a C<view_url> that links to the chart or stats view
showing the underlying data.  An insight without a clickable view_url is a bug.

=head1 FUNCTIONS

=head2 compute(%args)

    my $insights = Database::BI::Insights::compute(
        records  => \@rows,     # arrayref of row hashrefs
        columns  => \@cols,     # arrayref of column names
        spec_key => $l,         # l= spec string
        base_url => $url,       # request URL, used only as a fallback
    );

Returns an arrayref of insight hashrefs.  Each hashref has:

    kind      -- 'outlier' | 'top_mover' | 'period_delta' | 'seasonality'
    headline  -- one short sentence
    detail    -- numbers that substantiate the headline
    view_url  -- URL to the view showing the data
    method    -- key for method_note()

=head3 API SPECIFICATION

=head4 INPUT

	{
	    records  => 'arrayref',  # row hashrefs, already filtered and with calculated fields
	    columns  => 'arrayref',  # column names, in order
	    spec_key => 'string',    # optional; the l= spec (default '')
	    base_url => 'string',    # optional; default "/insights?l=<spec_key>"
	}

=head4 OUTPUT

	[ { kind => 'string', headline => 'string', detail => 'string',
	    view_url => 'string', method => 'string' }, ... ]

No rows or no columns returns C<[]>.  Outliers need a numeric column.
Period-over-period, top movers and seasonality also need an ISO
C<YYYY-MM-DD> date column; only the first one found is used.  Every insight
has a C<view_url>.  The function is pure arithmetic: it makes no network
call and does not croak.

=head2 method_note($key)

Returns a one-sentence description of the algorithm behind C<$key>.

=head3 API SPECIFICATION

=head4 INPUT

	$key   # 'iqr_fence' | 'pop_delta' | 'top_mover' | 'autocorr'

=head4 OUTPUT

	'string'   # the note; an unknown key is returned unchanged

=head1 ALGORITHM NOTES

=head3 Outliers

Tukey IQR fence: Q1 - 1.5*IQR and Q3 + 1.5*IQR.  Requires at least 4 values
per group.  Results are sorted by distance from the nearest fence; up to 5
outliers are reported per column.

=head3 Period-over-period

Year-month (YYYY-MM) buckets from ISO-8601 date columns.  Requires at least
2 distinct periods.

=head3 Seasonality

Lag-1 autocorrelation r(1) on the sequence of period sums.
Formula: r(1) = cov(y[t], y[t+1]) / var(y[t]).
Threshold: r >= 0.6.  Requires at least 8 distinct month-periods.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
