#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(:all);

use Cwd qw(abs_path);
use Data::Dumper;
use File::Basename qw(dirname basename);
use File::Glob ':glob';
use File::Path qw(make_path);
use File::Slurp;
use File::Spec;
use File::stat;
use Getopt::Long qw(GetOptions);
use IPC::Run3;
use JSON::MaybeXS;
use List::Util;
use POSIX qw(strftime);
use HTML::Entities;
use HTTP::Tiny;
use Readonly;
use Time::HiRes qw(sleep);
use URI::Escape qw(uri_escape);
use version;
use WWW::RT::CPAN;
use YAML::XS qw(Dump LoadFile);

=head1 NAME

generate_index.pl - Test coverage dashboard generator

=head1 DESCRIPTION

C<generate_index.pl> generates an HTML test coverage dashboard for
publication on GitHub Pages, combining four sources of test quality
data into a single report:

=over 4

=item * B<Statement and branch coverage> from L<Devel::Cover>, showing
which lines and branches were exercised by the test suite.

=item * B<LCSAJ path coverage> (TER3) from the LCSAJ runtime debugger,
showing which control-flow paths were executed. Displayed as blue
(covered) or red (uncovered) dots on per-file mutation pages.

=item * B<Mutation testing results> from C<bin/app-test-generator-mutate>,
showing which injected faults the test suite detected (killed) and
which it missed (survived).

=item * B<CPAN Testers failure analysis>, showing which Perl versions
and operating systems are failing, with automatic root cause detection
including Perl version cliffs, locale sensitivity, and dependency
version cliffs.

=back

In addition to the dashboard, the script drives the mutation-guided
test generation pipeline described in
L<App::Test::Generator/MUTATION-GUIDED TEST GENERATION>. Surviving
mutants are used to automatically generate new test stubs and fuzz
schemas that target the exact boundary conditions the test suite
missed:

=over 4

=item * C<--generate_mutant_tests=DIR> produces TODO stub files in
C<DIR/> for all surviving mutants, grouped by source file and
deduplicated by line.

=item * C<--generate_test=mutant> additionally attempts to produce
runnable YAML schemas in C<DIR/conf/> for NUM_BOUNDARY survivors
using L<App::Test::Generator::SchemaExtractor>.

=item * C<--generate_fuzz> augments existing schemas in C<DIR/conf/>
with boundary values from surviving mutants, writing timestamped
copies that are picked up automatically by C<t/fuzz.t>.

=back

The script is designed to be shared across projects. Copy it into the
C<scripts/> directory of each project that uses it:

    cp ../App-Test-Generator/scripts/generate_index.pl scripts/

It is invoked automatically by C<scripts/generate_test_dashboard> on
each CI push via C<.github/workflows/dashboard.yml>.

=head1 SYNOPSIS

  https://$github_user.github.io/$github_repo/coverage/

=head1 INPUTS

  cover_html/cover.json     - Devel::Cover JSON report (statement/branch/condition)
  mutation.json             - Mutation testing results from app-test-generator-mutate
  cover_html/lcsaj_hits.json - LCSAJ path hit data from the LCSAJ runtime debugger
  cover_html/mutation_html/lib/ - Per-file LCSAJ path definitions (.lcsaj.json)
  coverage_history/*.json   - Historical coverage snapshots for the trend chart

=head1 OUTPUTS

  cover_html/index.html     - Main dashboard (coverage table, trend chart,
                              CPAN Testers failures, mutation report)
  cover_html/mutation_html/ - Per-file mutation heatmap pages

=head1 OPTIONS

  --generate_mutant_tests=DIR
      Generate a timestamped test stub file in DIR (typically 't/') for
      surviving mutants. The file is named mutant_YYYYMMDD_HHMMSS.t and
      contains:
        - TODO test stubs for High/Medium difficulty survivors, with
          boundary value suggestions, environment variable hints, and
          the enclosing subroutine name for navigation context
        - Comment-only hints for Low difficulty survivors
      Multiple mutations on the same source line are deduplicated into
      one stub - one good test kills all variants on that line.
      File is skipped entirely if there are no survivors to report.
      If not given, no test stubs are generated.

  --generate_test=CLASS
      When combined with --generate_mutant_tests=DIR, attempts to produce
      runnable test artefacts for surviving mutants rather than TODO stubs.

      Currently supported classes:

        mutant  For NUM_BOUNDARY survivors, calls
                App::Test::Generator::SchemaExtractor to extract the schema
                for the enclosing subroutine and augments it with the
                boundary value from the mutant (plus one value either side).
                The resulting YAML schema is written to DIR/conf/ and is
                picked up automatically by t/fuzz.t on the next test run.
                Falls back to a TODO stub if SchemaExtractor fails, the
                enclosing sub cannot be determined, or the extracted schema
                confidence is too low (very_low or none).

      This option is designed to accept additional classes in future, for
      example corpus-driven or property-based test generation.
      If not given, only TODO stubs are produced.

   --generate_fuzz
      Scans t/conf/ for existing YAML schema files and augments copies
      of them with boundary values extracted from surviving NUM_BOUNDARY
      mutants whose enclosing subroutine matches the schema's function
      field. The original schema is never modified. Augmented copies are
      written to t/conf/mutant_fuzz_YYYYMMDD_HHMMSS_FUNCTION.yml and
      are picked up automatically by t/fuzz.t on the next test run.

      Schemas whose filename already starts with mutant_fuzz_ are skipped
      to avoid augmenting previously augmented schemas. Schemas with no
      matching survivors are skipped (with a note if --verbose is active).
      New boundary values are merged into whichever edge key already
      exists in the schema (edge_case_array or edge_cases), with
      deduplication against existing values.

      This flag is independent of --generate_test and can be used alone.

=head1 DASHBOARD SECTIONS

  Coverage Table    - Per-file statement/branch/condition/subroutine
                      percentages with delta vs previous snapshot,
                      sortable columns, and sparkline trend per file
  Coverage Trend    - Chart of total coverage over recent commits with
                      linear regression line, zoom and pan support
  RT Issues         - Count of open RT tickets for the distribution
  CPAN Testers      - Failure table for the current release, with
                      Perl version cliff detection, locale analysis,
                      dependency version cliff detection, and root
                      cause confidence scoring
  Mutation Report   - Per-file mutation score (killed/survived/total),
                      cyclomatic complexity, and TER3 (LCSAJ path
                      coverage) with raw fraction
  Per-file Pages    - Line-by-line mutation heatmap with TER1/TER2/TER3
                      metrics, LCSAJ path markers, and expandable
                      mutant details with suggested tests

=head1 DEPENDENCIES

  Cwd, Data::Dumper, File::Basename, File::Glob, File::Path,
  File::Slurp, File::Spec, File::stat, Getopt::Long, HTML::Entities,
  HTTP::Tiny, IPC::Run3, JSON::MaybeXS, List::Util, POSIX,
  Readonly, Time::HiRes, URI::Escape, WWW::RT::CPAN, version

=head1 AUTHOR

  Nigel Horne <njh@nigelhorne.com>

=cut

my ($github_user, $github_repo);

if (my $repo = $ENV{GITHUB_REPOSITORY}) {
	($github_user, $github_repo) = split m{/}, $repo, 2;
} else {
	die 'What repo are you?';
}

my $package_name = $github_repo;
$package_name =~ s/\-/::/g;

Readonly my %config => (
	github_user => 'nigelhorne',
	github_repo => $github_repo,
	package_name => $package_name,
	low_threshold => 70,
	med_threshold => 90,
	max_points => 10,	# Only display the last 10 commits in the coverage trend graph
	cover_db            => 'cover_html/cover.json',      # Devel::Cover JSON output
	mutation_db         => 'mutation.json',
	mutation_dir        => 'coverage/mutation_html',     # hrefs in published pages
	mutation_output_dir => 'cover_html/mutation_html',   # where files are written
	lcsaj_root => 'cover_html/mutation_html/lib',
	lcsaj_hits_file     => 'cover_html/lcsaj_hits.json', # Runtime.pm writes here
	output => 'cover_html/index.html',	# published to gh-pages
	max_retry => 3,
	min_locale_samples => 3,
	verbose => 1,
);

# --------------------------------------------------
# Parse command-line options.
# --generate_mutant_tests=dir enables test stub
# generation into the named directory.
# --generate_test=CLASS enables schema generation
# for surviving mutants.
# --generate_fuzz enables fuzz schema augmentation
# from surviving mutants.
# --------------------------------------------------
my $mutant_test_dir;
my $generate_test;
my $generate_fuzz;
GetOptions(
	'generate_mutant_tests=s' => \$mutant_test_dir,
	'generate_test=s'         => \$generate_test,
	'generate_fuzz'           => \$generate_fuzz,
) or die "Usage: $0 [--generate_mutant_tests=DIR] [--generate_test=mutant] [--generate_fuzz]";

# -------------------------------
# Dependency correlation analysis
# -------------------------------
my $MAX_REPORTS_PER_GRADE = 20;	# safety rail
my $ENABLE_DEP_ANALYSIS = 1;

# Read and decode data
my $cover_db = eval { decode_json(read_file($config{cover_db})) };
my $mutation_db = eval { decode_json(read_file($config{mutation_db})) };

# --------------------------------------------------
# Compute coverage percentage from only our own files,
# excluding absolute paths (installed CPAN modules)
# which inflate Devel::Cover's pre-aggregated Total.
# --------------------------------------------------
my ($coverage_pct, $badge_color) = (0, 'red');

if($cover_db->{summary}) {
	my ($sum, $count) = (0, 0);
	for my $f (keys %{ $cover_db->{summary} }) {
		next if $f eq 'Total';
		next if $f =~ /^\//;    # skip absolute paths
		$sum += $cover_db->{summary}{$f}{total}{percentage} // 0;
		$count++;
	}
	if($count) {
		my $pct = _own_file_coverage_pct($cover_db->{summary});

		$coverage_pct = defined $pct ? int($pct) : 0;
		$badge_color  = $coverage_pct > $config{med_threshold} ? 'brightgreen'
			: $coverage_pct > $config{low_threshold} ? 'yellow'
			: 'red';
	}
}

Readonly my $coverage_badge_url => "https://img.shields.io/badge/coverage-${coverage_pct}%25-${badge_color}";

# Start HTML
my @html;	# build in array, join later
push @html, <<"HTML";
<!DOCTYPE html>
<html>
	<head>
	<title>$config{package_name} Coverage Report</title>
	<style>
		body { font-family: sans-serif; }
		table { border-collapse: collapse; width: 100%; }
		th, td { border: 1px solid #ccc; padding: 8px; text-align: left; }
		th { background-color: #f2f2f2; }
		.low { background-color: #fdd; }
		.med { background-color: #ffd; }
		.high { background-color: #dfd; }
		.badges img { margin-right: 10px; }
		.disabled-icon {
			opacity: 0.4;
			cursor: default;
		}
		.icon-link {
			text-decoration: none;
		}
		.icon-link:hover {
			opacity: 0.7;
			cursor: pointer;
		}
		.coverage-badge {
			padding: 2px 6px;
			border-radius: 4px;
			font-weight: bold;
			color: white;
			font-size: 0.9em;
		}
		.badge-good { background-color: #4CAF50; }
		.badge-warn { background-color: #FFC107; }
		.badge-bad { background-color: #F44336; }
		.summary-row {
			font-weight: bold;
			background-color: #f0f0f0;
		}
		td.positive { color: green; font-weight: bold; }
		td.negative { color: red; font-weight: bold; }
		td.neutral { color: gray; }
		/* Show cursor points on the headers to show that they are clickable */
		th { background-color: #f2f2f2; cursor: pointer; }
		th.sortable {
			cursor: pointer;
			user-select: none;
			white-space: nowrap;
		}
		th .arrow {
			color: #aaa;	/* dimmed for inactive */
			font-weight: normal;
		}
		th .arrow.active {
			color: #000;	/* dark for active */
			font-weight: bold;
		}
		.sparkline {
			display: inline-block;
			vertical-align: middle;
		}
		tr.cpan-fail td {
			background-color: #fdd;
		}
		tr.cpan-unknown td {
			background-color: #eee;
			color: #666;
		}
		tr.cpan-na td {
			background-color: #ffffde;
			color: #666;
		}
		.new-failure {
			background: #c00;
			color: #fff;
			font-weight: bold;
			padding: 2px 6px;
			border-radius: 4px;
			font-size: 0.85em;
		}
		.notice {
			padding: 8px 12px;
			margin: 10px 0;
			border-radius: 4px;
			font-size: 0.95em;
		}
		.notice strong {
			font-weight: bold;
		}
		.notice.perl-version-cliff {
			background-color: #fff3cd; /* soft amber */
			border: 1px solid #ffeeba;
			color: #856404;
		}
		.notice.perl-version-cliff a {
			color: #533f03;
			text-decoration: underline;
		}
		.notice.perl-version-cliff a:hover {
			text-decoration: none;
		}
		.notice.locale-cliff {
			border-left: 4px solid #d97706;
			background: #fffbeb;
			padding: 0.5em 1em;
		}
		.notice.rt-issues {
			background: #fff6e5;
			border-left: 4px solid #d9822b;
		}
		table.root-causes {
			border-collapse: collapse;
			width: 100%;
			margin-bottom: 1.5em;
		}
		table.root-causes th,
		table.root-causes td {
			border: 1px solid #ccc;
			padding: 8px;
			vertical-align: top;
		}
		table.root-causes tr.high {
			background-color: #dfd;
		}
		table.root-causes tr.med {
			background-color: #ffd;
		}
		table.root-causes tr.low {
			background-color: #fdd;
		}
	</style>
</head>
<body>
<div class="badges">
	<a href="https://github.com/$config{github_user}/$config{github_repo}">
		<img src="https://img.shields.io/github/stars/$config{github_user}/$config{github_repo}?style=social" alt="GitHub stars">
	</a>
	<img src="$coverage_badge_url" alt="Coverage badge">
</div>
<h1>$config{package_name}</h1><h2>Coverage Report</h2>
<table data-sort-col="0" data-sort-order="asc">
<!-- Make the column headers clickable -->
<thead>
<tr>
	<th class="sortable" onclick="sortTable(this, 0)"><span class="label">File</span> <span class="arrow active">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(this, 1)"><span class="label">Stmt</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(this, 2)"><span class="label">Branch</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(this, 3)"><span class="label">Cond</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(this, 4)"><span class="label">Sub</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(this, 5)"><span class="label">Total</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(this, 6)"><span class="label">&Delta;</span> <span class="arrow">&#x25B2;</span></th>
</tr>
</thead>

<tbody>
HTML

my @history_files = bsd_glob("coverage_history/*.json");

# Cache historical data instead of reading for each file
my %historical_cache;
for my $hist_file (@history_files) {
	my $json = eval { decode_json(read_file($hist_file)) };
	$historical_cache{$hist_file} = $json if $json;
}

# Load previous snapshot for delta comparison
my @history = sort { $a cmp $b } @history_files;
my $prev_data;

if (@history >= 1) {
	my $prev_file = $history[-1];	# Most recent before current
	$prev_data = $historical_cache{$prev_file};
}

my %deltas;
if($prev_data) {
	for my $file (keys %{$cover_db->{summary}}) {
		next if $file eq 'Total';
		next if $file =~ /^\//;    # skip absolute paths
		my $curr = $cover_db->{summary}{$file}{total}{percentage} // 0;
		my $prev = $prev_data->{summary}{$file}{total}{percentage} // 0;
		my $delta = sprintf('%.1f', $curr - $prev);
		$deltas{$file} = $delta;
	}
}

# Check if we're in a git repository first
unless (run_git('rev-parse', '--git-dir')) {
	die 'Error: Not in a git repository or git is not available';
}

my $commit_sha = run_git('rev-parse', 'HEAD');
unless (defined $commit_sha && $commit_sha =~ /^[0-9a-f]{40}$/i) {
	die 'Error: Could not get valid git commit SHA';
}
my $github_base = "https://github.com/$config{github_user}/$config{github_repo}/blob/$commit_sha/";

# Add rows
my ($total_files, $total_coverage, $low_coverage_count) = (0, 0, 0);

for my $file (sort keys %{$cover_db->{summary}}) {
	next if $file eq 'Total';

	# Check it's in our repo e.g. bin or blib
	if($file =~ /^\//) {
		# delete $cover_db->{summary};
		next;
	}

	my $info = $cover_db->{summary}{$file};
	my $html_file = $file;
	$html_file =~ s|/|-|g;
	$html_file =~ s|\.pm$|-pm|;
	$html_file =~ s|\.pl$|-pl|;
	$html_file .= '.html';

	my $total = $info->{total}{percentage} // 0;
	$total_files++;
	$total_coverage += $total;
	$low_coverage_count++ if $total < $config{low_threshold};

	my $badge_class = $total >= $config{med_threshold} ? 'badge-good'
					: $total >= $config{low_threshold} ? 'badge-warn'
					: 'badge-bad';

	my $tooltip = $total >= $config{med_threshold} ? 'Excellent coverage'
				 : $total >= $config{low_threshold} ? 'Moderate coverage'
				 : 'Needs improvement';

	my $row_class = $total >= $config{med_threshold} ? 'high'
			: $total >= $config{low_threshold} ? 'med'
			: 'low';

	my $badge_html = sprintf(
		'<span class="coverage-badge %s" title="%s">%.1f%%</span>',
		$badge_class, $tooltip, $total
	);

	my $delta_html;
	if (exists $deltas{$file}) {
		my $delta = $deltas{$file};
		my $delta_class = $delta > 0 ? 'positive' : $delta < 0 ? 'negative' : 'neutral';
		my $delta_icon = $delta > 0 ? '&#9650;' : $delta < 0 ? '&#9660;' : '&#9679;';
		my $prev_pct = $prev_data->{summary}{$file}{total}{percentage} // 0;

		$delta_html = sprintf(
			'<td class="%s" title="Previous: %.1f%%">%s %.1f%%</td>',
			$delta_class, $prev_pct, $delta_icon, abs($delta)
		);
	} else {
		$delta_html = '<td class="neutral" title="No previous data">&#9679;</td>';
	}

	my $source_url = $github_base . $file;
	my $has_coverage = (
		defined $info->{statement}{percentage} ||
		defined $info->{branch}{percentage} ||
		defined $info->{condition}{percentage} ||
		defined $info->{subroutine}{percentage}
	);

	my $source_link = $has_coverage
		? sprintf('<a href="%s" class="icon-link" title="View source on GitHub">&#128269;</a>', $source_url)
		: '<span class="disabled-icon" title="No coverage data">&#128269;</span>';

	# Create the sparkline - limit to last N points like the main trend chart
	my @file_history;

	# Get the last max_points history files (same as trend chart)
	my @limited_history = (scalar(@history_files) > $config{max_points})
		? @history_files[-$config{max_points} .. -1]
		: @history_files;

	# Use the already-cached historical data
	for my $hist_file (sort @limited_history) {
		my $json = $historical_cache{$hist_file};
		next unless $json;	# Skip if not cached (shouldn't happen, but be safe)

		if($json->{summary}{$file}) {
			my $pct = $json->{summary}{$file}{total}{percentage} // 0;
			push @file_history, sprintf('%.1f', $pct);
		}
	}

	my $points_attr = join(',', @file_history);

	push @html, sprintf(
		qq{<tr class="%s"><td><a href="%s" title="View coverage line by line" target="_blank">%s</a> %s<canvas class="sparkline" width="80" height="20" data-points="$points_attr"></canvas></td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%s</td>%s</tr>},
		$row_class, $html_file, $file, $source_link,
		$info->{statement}{percentage} // 0,
		$info->{branch}{percentage} // 0,
		$info->{condition}{percentage} // 0,
		$info->{subroutine}{percentage} // 0,
		$badge_html,
		$delta_html
	);
}

# Summary row
my $avg_coverage = $total_files ? int($total_coverage / $total_files) : 0;

push @html, sprintf(
	qq{<tr class="summary-row nosort"><td colspan="2"><strong>Summary</strong></td><td colspan="2">%d files</td><td colspan="3">Avg: %d%%, Low: %d</td></tr>},
	$total_files, $avg_coverage, $low_coverage_count
);

# Add totals row
# Compute totals only across the files we actually displayed,
# ignoring Devel::Cover's pre-aggregated Total which includes
# all instrumented files (CPAN modules etc.) not just our own
my ($sum_stmt, $sum_branch, $sum_cond, $sum_sub, $sum_total) = (0, 0, 0, 0, 0);
my $counted = 0;

for my $file (keys %{$cover_db->{summary}}) {
	next if $file eq 'Total';
	next if $file =~ /^\//;	# skip absolute paths (installed modules)

	my $info = $cover_db->{summary}{$file};
	$sum_stmt   += $info->{statement}{percentage}  // 0;
	$sum_branch += $info->{branch}{percentage}     // 0;
	$sum_cond   += $info->{condition}{percentage}  // 0;
	$sum_sub    += $info->{subroutine}{percentage} // 0;
	$sum_total  += $info->{total}{percentage}      // 0;
	$counted++;
}

if($counted) {
	my $avg_total = $sum_total / $counted;
	my $class = $avg_total > 80 ? 'high' : $avg_total > 50 ? 'med' : 'low';

	push @html, sprintf(
		qq{<tr class="%s nosort"><td><strong>Total</strong></td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td colspan="2"><strong>%.1f</strong></td></tr>},
		$class,
		$sum_stmt   / $counted,
		$sum_branch / $counted,
		$sum_cond   / $counted,
		$sum_sub / $counted,
		$avg_total
	);
}

Readonly my $commit_url => "https://github.com/$config{github_user}/$config{github_repo}/commit/$commit_sha";
my $short_sha = substr($commit_sha, 0, 7);

push @html, '</tbody></table>';

# Inject chart if we have data
my %commit_times;
my $log_output = run_git('log', '--all', '--pretty=format:%H %h %ci');
if ($log_output) {
	for my $line (split /\n/, $log_output) {
		my ($full_sha, $short_sha, $datetime) = split ' ', $line, 3;
		$commit_times{$short_sha} = $datetime if $short_sha;
	}
}

my %commit_messages;
$log_output = run_git('log', '--pretty=format:%h %s');
if ($log_output) {
	for my $line (split /\n/, $log_output) {
		my ($short_sha, $message) = $line =~ /^(\w+)\s+(.*)$/;
		if ($message && $message =~ /^Merge branch /) {
			delete $commit_times{$short_sha};
		} else {
			$commit_messages{$short_sha} = $message if $message;
		}
	}
}

# Collect data points from non-merge commits
my @data_points_with_time;
my $processed_count = 0;

foreach my $file (reverse sort @history_files) {
	last if $processed_count >= $config{max_points};

	my $json = $historical_cache{$file};
	next unless $json->{summary};

	my ($sha) = $file =~ /-(\w{7})\.json$/;

	# Skip files that don't match the expected naming pattern
	# e.g. YYYY-MM-DD-XXXXXXX.json — $sha will be undef otherwise
	next unless defined $sha;
	next unless $commit_messages{$sha};	# skip merge commits

	# Compute average across our own files only
	my ($sum, $count) = (0, 0);
	for my $f (keys %{ $json->{summary} }) {
		next if $f eq 'Total';
		next if $f =~ /^\//;
		next unless $f =~ /^(?:lib|blib|bin)\//;	# only own project files
		$sum += $json->{summary}{$f}{total}{percentage} // 0;
		$count++;
	}
	next unless $count;

	my $timestamp = $commit_times{$sha} // strftime('%Y-%m-%dT%H:%M:%S', localtime((stat($file))->mtime));

	# Git log returns format like: "2024-01-15 14:30:45 -0500" or "2024-01-15 14:30:45 +0000"
	# We need ISO 8601 format: "2024-01-15T14:30:45-05:00"

	# Replace space between date and time with 'T'
	$timestamp =~ s/^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})/$1T$2/;

	# Fix timezone format: convert "-0500" to "-05:00" or " -05:00" to "-05:00"
	$timestamp =~ s/\s*([+-])(\d{2}):?(\d{2})$/$1$2:$3/;

	# Remove any remaining spaces (safety cleanup)
	$timestamp =~ s/\s+//g;

	my $pct = $sum / $count;
	my $color = 'gray';	# Will be set properly after sorting
	my $url = "https://github.com/$config{github_user}/$config{github_repo}/commit/$sha";
	my $comment = $commit_messages{$sha};

	# Store with timestamp for sorting
	push @data_points_with_time, {
		timestamp => $timestamp,
		pct => $pct,
		url => $url,
		comment => $comment
	};

	$processed_count++;
}

# Sort by timestamp to ensure chronological order
@data_points_with_time = sort { $a->{timestamp} cmp $b->{timestamp} } @data_points_with_time;

# Now calculate deltas and create JavaScript data points
my @data_points;
my $prev_pct;

foreach my $point (@data_points_with_time) {
	my $delta = defined $prev_pct ? sprintf('%.1f', $point->{pct} - $prev_pct) : 0;
	$prev_pct = $point->{pct};

	my $color = $delta > 0 ? 'green' : $delta < 0 ? 'red' : 'gray';

	my $comment = js_escape($point->{comment});
	push @data_points, qq{{ x: "$point->{timestamp}", y: $point->{pct}, delta: $delta, url: "$point->{url}", label: "$point->{timestamp}", pointBackgroundColor: "$color", comment: "$comment" }};
}

if(scalar(@data_points)) {
	push @html, <<'HTML';
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1em;">
	<div>
		<h2>Coverage Trend</h2>
		<label>
			<input type="checkbox" id="toggleTrend" checked>
			Show regression trend
		</label>
		<div>
		</div>
	</div>
	<div id="zoomControls" style="margin-top:8px;">
		<input type="button" value="Refresh" onClick="refresh(this)">
		<button id="resetZoomBtn" type="button">Reset Zoom</button>
	</div>
</div>
<canvas id="coverageTrend" width="600" height="300"></canvas>
<!-- Zoom controls for the trend chart -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<!-- Add chartjs-plugin-zoom (required for wheel/pinch/drag zoom & pan) -->
<script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-zoom\@2.1.1/dist/chartjs-plugin-zoom.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns"></script>
<script>
function linearRegression(data) {
	const xs = data.map(p => new Date(p.x).getTime());
	const ys = data.map(p => p.y);
	const n = xs.length;

	const sumX = xs.reduce((a, b) => a + b, 0);
	const sumY = ys.reduce((a, b) => a + b, 0);
	const sumXY = xs.reduce((acc, val, i) => acc + val * ys[i], 0);
	const sumX2 = xs.reduce((acc, val) => acc + val * val, 0);

	if (n < 2 || (n * sumX2 - sumX * sumX) === 0) {
		return [];
	}
	const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
	const intercept = (sumY - slope * sumX) / n;

	return xs.map(x => ({
		x: new Date(x).toISOString(),
		y: slope * x + intercept
	}));
}

HTML

	my $js_data = join(",\n", @data_points);
	push @html, "const dataPoints = [ $js_data ];";

	push @html, <<'HTML';
const regressionPoints = linearRegression(dataPoints);
// Try to register the zoom plugin (handles different UMD builds)
(function registerZoomPlugin(){
	try {
		const candidates = ['chartjsPluginZoom','ChartZoom','zoomPlugin','chartjs_plugin_zoom','ChartjsPluginZoom','chartjsPluginZoom'];
		for (const name of candidates) {
			if (window[name]) {
				try { Chart.register(window[name]); console.log('Registered zoom plugin:', name); return; } catch(e) { console.warn('zoom register failed for', name, e); }
			}
		}
		// Some CDN builds auto-register the plugin; if nothing found that's OK (feature disabled).
	} catch(e) {
		console.warn('registerZoomPlugin error', e);
	}
})();
const ctx = document.getElementById('coverageTrend').getContext('2d');
const chart = new Chart(ctx, {
	type: 'line',
	data: {
		datasets: [{
			label: 'Total Coverage (%)',
			data: dataPoints,
			borderColor: 'green',
			backgroundColor: 'rgba(0,128,0,0.1)',
			pointRadius: 5,
			pointHoverRadius: 7,
			pointStyle: 'circle',
			fill: false,
			tension: 0.3,
			pointBackgroundColor: function(context) {
				return context.raw.pointBackgroundColor || 'gray';
			}
		}, {
			label: 'Regression Line',
			data: regressionPoints,
			borderColor: 'blue',
			borderDash: [5, 5],
			pointRadius: 0,
			fill: false,
			tension: 0.0
		}]
	}, options: {
		scales: {
			x: {
				type: 'time',
				time: {
					tooltipFormat: 'MMM d, yyyy HH:mm:ss',
					unit: 'day'
				},
				title: { display: true, text: 'Commit Date' }
			},
			y: { beginAtZero: true, max: 100, title: { display: true, text: 'Coverage (%)' } }
		}, plugins: {
			legend: {
				display: true,
				position: 'top', // You can also use 'bottom', 'left', or 'right'
				labels: {
					boxWidth: 12,
					padding: 10,
					font: {
						size: 12,
						weight: 'bold'
					}
				}
			}, tooltip: {
				callbacks: {
					label: function(context) {
						const raw = context.raw;
						const coverage = raw.y.toFixed(1);
						const delta = raw.delta?.toFixed(1) ?? '0.0';
						const sign = delta > 0 ? '+' : delta < 0 ? '-' : '±';
						// const baseLine = `${raw.label}: ${coverage}% (${sign}${Math.abs(delta)}%)`;
						const baseLine = `${coverage}% (${sign}${Math.abs(delta)}%)`;
						const commentLine = raw.comment ? raw.comment : null;
						return commentLine ? [baseLine, commentLine] : [baseLine];
					}
				}
			} , zoom: {	// Enable zoom & pan on the x-axis for the trend chart
				pan: {
					enabled: true,
					mode: 'x'
				}, zoom: {
					wheel: {
						enabled: true
					}, pinch: {
						enabled: true
					}, mode: 'x'
				}
			}
		}, onClick: (e) => {
			const points = chart.getElementsAtEventForMode(e, 'nearest', { intersect: true }, true);
			if (points.length) {
				const url = chart.data.datasets[0].data[points[0].index].url;
				window.open(url, '_blank');
			}
		}
	}
});

document.getElementById('toggleTrend').addEventListener('change', function(e) {
	const show = e.target.checked;
	const trendDataset = chart.data.datasets.find(ds => ds.label === 'Regression Line');
	trendDataset.hidden = !show;
	chart.update();
});

// Reset Zoom button handler (calls plugin API if available)
const resetBtn = document.getElementById('resetZoomBtn');
if (resetBtn) {
	resetBtn.addEventListener('click', function() {
		try {
			if (chart && typeof chart.resetZoom === 'function') {
				chart.resetZoom();
			} else {
				console.warn('resetZoom not available; zoom plugin may not be registered.');
			}
		} catch (e) {
			console.warn('resetZoom call failed', e);
		}
	});
}

function sortTable(th, colIndex) {
	const table = th.closest("table");
	if (!table || !table.tBodies.length) return;

	const tbody = table.tBodies[0];
	const rows = Array.from(tbody.rows);

	const prevCol = table.getAttribute("data-sort-col");
	const prevOrder = table.getAttribute("data-sort-order") || "desc";
	const asc = (prevCol != colIndex) ? true : (prevOrder === "desc");

	const isNumeric = colIndex === 0; // Date column

	const normalRows = rows.filter(r => !r.classList.contains("nosort"));
	const fixedRows = rows.filter(r => r.classList.contains("nosort"));

	normalRows.sort((a, b) => {
		let x = a.cells[colIndex]?.innerText.trim() || "";
		let y = b.cells[colIndex]?.innerText.trim() || "";

		if (isNumeric) {
			x = Date.parse(x) || 0;
			y = Date.parse(y) || 0;
		} else {
			x = x.toLowerCase();
			y = y.toLowerCase();
		}

		if (x < y) return asc ? -1 : 1;
		if (x > y) return asc ? 1 : -1;
		return 0;
	});

	normalRows.forEach(r => tbody.appendChild(r));
	fixedRows.forEach(r => tbody.appendChild(r));

	// Update arrows
	const headers = table.tHead.rows[0].cells;
	for (let i = 0; i < headers.length; i++) {
		const arrow = headers[i].querySelector(".arrow");
		if (!arrow) continue;

		if (i === colIndex) {
			arrow.textContent = asc ? "▲" : "▼";
			arrow.classList.add("active");
		} else {
			arrow.textContent = "▲";
			arrow.classList.remove("active");
		}
	}

	table.setAttribute("data-sort-col", colIndex);
	table.setAttribute("data-sort-order", asc ? "asc" : "desc");
}


// Initial display.
// The table has been set up sorted in ascending order on the filename; reflect that in the GUI
document.addEventListener("DOMContentLoaded", () => {
	const table = document.querySelector("table");
	if (!table) return;

	const headers = table.tHead.rows[0].cells;
	for (let i = 0; i < headers.length; i++) {
		const arrow = headers[i].querySelector(".arrow");
		if (!arrow) continue;

		if (i === 0) {
			arrow.textContent = "▲";
			arrow.classList.add("active");
		} else {
			arrow.textContent = "▲";
			arrow.classList.remove("active");
		}
	}
});

document.addEventListener("DOMContentLoaded", () => {
	document.querySelectorAll("canvas.sparkline").forEach(canvas => {
		const raw = canvas.getAttribute("data-points");
		if (!raw) return;
		const points = raw.split(",").map(v => parseFloat(v));

		new Chart(canvas.getContext("2d"), {
			type: 'line',
			data: {
				labels: points.map((_, i) => i+1),
				datasets: [{
					data: points,
					borderColor: points.length > 1 && points[points.length-1] >= points[0] ? "green" : "red",
					borderWidth: 1,
					fill: false,
					tension: 0.3,
					pointRadius: 0
				}]
			}, options: {
				responsive: false,
				maintainAspectRatio: false,
				elements: { line: { borderJoinStyle: 'round' } },
				plugins: {
					legend: { display: false },
					tooltip: { enabled: false },
					zoom: {	// Enable zoom and pan
						pan: {
							enabled: true,
							mode: 'x',
						}, zoom: {
							wheel: {
								enabled: true,
							},
							pinch: {
								enabled: true
							},
							mode: 'x',
						}
					}
				}, scales: { x: { display: false }, y: { display: false } }
			}
		});
	});
});

function refresh(){
	window.location.reload("Refresh")
}
</script>
HTML

	push @html, '<p><center>Use mouse wheel or pinch to zoom; drag to pan</center></p>';
} else {
	push @html, '<p><i>No history to show coverage trend</i></p>';
}

# -------------------------------
# Issues flagged on RT
# -------------------------------
{
	my $rt_count = fetch_open_rt_ticket_count($config{github_repo});
	my $rt_url = "https://rt.cpan.org/Public/Dist/Display.html?Name=$config{github_repo}";

	if(defined $rt_count && $rt_count > 0) {
		push @html, '<p class="notice rt-issues">',
			'<strong>RT issues:</strong>',
			"<a href=\"$rt_url\" target=\"_blank\" rel=\"noopener\">",
			"$rt_count open ticket" . @{[ $rt_count == 1 ? '' : 's' ]},
			'</a>',
			'</p>';
	} else {
		push @html, "<p>No issues active on <a href=\"$rt_url\">RT</a></p>";
	}
}

# -------------------------------
# CPAN Testers failing reports table
# -------------------------------
my $dist_name = $config{github_repo};
my $cpan_api = "https://api.cpantesters.org/v3/summary/" . uri_escape($dist_name);

my $http = HTTP::Tiny->new(agent => 'cpan-coverage-html/1.0', timeout => 15);

my $retry = 0;
my $success = 0;

my $res;

# Try a number of times because the cpantesters website can get overloaded
while($retry < $config{max_retry}) {
	$res = $http->get($cpan_api);
	if($res->{success}) {
		$success = 1;
		last;
	}
	$retry++;
	sleep(2 ** $retry);
}

my $version;	# current version
my $prev_version;	# may be undef

if($success) {
	my $releases = eval { decode_json($res->{content}) };
	my @versions;

	foreach my $release (@{$releases}) {
		next unless defined $release->{version};
		push @versions, $release->{version};
	}

	@versions = sort { parse_version($b) <=> parse_version($a) } @versions;

	$version = $versions[0];	# current
	$prev_version = $versions[1];	# previous (may be undef)

	# push @html, "<p>CPAN Release: $version</p>";
} else {
	push @html, "<p><a href=\"$cpan_api\">$cpan_api</a>: $res->{status} $res->{reason}</p>";
}

# $version ||= 'latest';
my @fail_reports;
my @pass_reports;
if($version) {
	@fail_reports = fetch_reports_by_grades(
		$dist_name,
		$version,
		'fail',
		'unknown',
		'na',
	);

	# warn 'Fetched ', scalar(@fail_reports), ' rows from API';
	# use Data::Dumper;
	# warn Dumper($fail_reports[0]) if scalar(@fail_reports);

	@pass_reports = fetch_reports_by_grades(
		$dist_name,
		$version,
		'pass',
	);

	if(scalar(@fail_reports)) {
		push @html, "<h2>CPAN Testers Failures for $dist_name $version</h2>";
		my @prev_fail_reports;
		if ($prev_version) {
			@prev_fail_reports = fetch_reports_by_grades(
				$dist_name,
				$prev_version,
				'fail',
				'unknown',
				'na',
			);
		}

		if ($ENABLE_DEP_ANALYSIS) {
			my %dep_stats;

			# Split GUIDs by grade
			my @fail_guids = map { $_->{guid} } grep { lc($_->{grade} // '') eq 'fail' } @fail_reports;
			my @unknown_guids = map { $_->{guid} } grep { lc($_->{grade} // '') eq 'unknown' } @fail_reports;
			my @na_guids = map { $_->{guid} } grep { lc($_->{grade} // '') eq 'na' } @fail_reports;

			# FAIL reports
			aggregate_dependency_stats(
				guids => \@fail_guids,
				grade => 'fail',
				stats_ref => \%dep_stats,
			);

			# UNKNOWN reports (optional but useful)
			aggregate_dependency_stats(
				guids => \@unknown_guids,
				grade => 'unknown',
				stats_ref => \%dep_stats,
			);
			aggregate_dependency_stats(
				guids => \@na_guids,
				grade => 'na',
				stats_ref => \%dep_stats,
			);

			my @suspects = find_suspected_dependencies(\%dep_stats);

			if (@suspects) {
				push @html, '<h3>Suspected Dependency Interactions</h3>';
				push @html, '<ul>';

				for my $s (@suspects) {
					my $line = sprintf(
						'%s — FAIL: %d%s (%s)',
						$s->{module},
						$s->{fail},
						defined $s->{pass} ? ", PASS: $s->{pass}" : '',
						$s->{reason},
					);
					push @html, "<li>$line</li>";
				}

				push @html, '</ul>';
			}
			my %dep_versions;

			collect_dependency_versions(
				reports => \@fail_reports,
				grade => 'fail',
				store => \%dep_versions,
			);

			collect_dependency_versions(
				reports => \@pass_reports,
				grade => 'pass',
				store => \%dep_versions,
			);

			my @cliffs = detect_version_cliffs(\%dep_versions);

			if (@cliffs) {
				push @html, '<h3>Dependency Version Cliffs</h3>';
				push @html, '<ul>';

				for my $c (@cliffs) {
					push @html, sprintf(
						'<li><b>%s</b>: %s</li>',
						$c->{module},
						$c->{message},
					);
				}

				push @html, '</ul>';
			}

			my $perl_cliff = detect_perl_version_cliff(
				\@fail_reports,
				\@pass_reports,
			);

			if ($perl_cliff) {
				my $perl_cutoff = parse_version($perl_cliff->{fails_up_to});

				my $fail_support = 0;
				my $pass_contra = 0;

				for my $r (@fail_reports) {
					next unless $r->{perl};
					$fail_support++ if parse_version($r->{perl}) < $perl_cutoff;
				}

				for my $r (@pass_reports) {
					next unless $r->{perl};
					$pass_contra++ if parse_version($r->{perl}) < $perl_cutoff;
				}
				my ($score, $label) = confidence_score(
					fail => $fail_support,
					pass => $pass_contra,
				);

				my $confidence_html = confidence_badge_html(
					$score, $label,
					$fail_support, $pass_contra,
				);

				my $delta = perldelta_url($perl_cliff->{passes_from});

				push @html,
					'<p class="notice perl-version-cliff">',
					sprintf(
						'Fails on Perl &leq; %s; passes on Perl &geq; %s. ',
						$perl_cliff->{fails_up_to},
						$perl_cliff->{passes_from},
					),
					sprintf(
						'<a href="%s" target="_blank">See perldelta for this release</a>',
						$delta,
					),
					" $confidence_html</p>";
			}
			push @html, '<h3>Failure Summary</h3>';
			push @html, '<ul>';

			my %clusters = (
				perl_series => {},
				os => {},
				perl_os => {},
			);

			my %locale_stats;

			for my $r (@fail_reports) {
				my $perl = perl_series($r->{perl});
				my $os = $r->{osname} // 'unknown';

				$clusters{perl_series}{$perl}++ if $perl;
				$clusters{os}{$os}++;
				$clusters{perl_os}{"$perl / $os"}++ if $perl;

				if(lc($r->{grade} // '') eq 'fail') {
					# Don't include NA or Unknown in this list
					my $locale = extract_locale($r) // 'unknown';
					$locale_stats{$locale}{fail}++;
				}
			}

			my @top_perl_series = sort { $clusters{perl_series}{$b} <=> $clusters{perl_series}{$a} }
				keys %{ $clusters{perl_series} };

			my @top_os = sort { $clusters{os}{$b} <=> $clusters{os}{$a} }
				keys %{ $clusters{os} };

			my @top_perl_os = sort { $clusters{perl_os}{$b} <=> $clusters{perl_os}{$a} }
				keys %{ $clusters{perl_os} };

			if (@top_perl_series) {
				my $k = $top_perl_series[0];
				push @html, sprintf(
					'<li><b>Perl %s.x</b>: %d failures</li>',
					$k,
					$clusters{perl_series}{$k},
				);
				my $total = scalar @fail_reports;
				my $ratio_pct = ($clusters{perl_series}{$k} / $total) * 100;

				if ($ratio_pct >= $config{low_threshold}) {
					push @html, sprintf(
						'<p><em>%d%% of failures occur on Perl %s.x</em></p>',
						int($ratio_pct),
						$k,
					);
				}
			}

			if (@top_os) {
				my $k = $top_os[0];
				push @html, sprintf(
					'<li><b>%s</b>: %d failures</li>',
					$k,
					$clusters{os}{$k},
				);
			}

			if (@top_perl_os) {
				my $k = $top_perl_os[0];
				push @html, sprintf(
					'<li><b>%s</b>: %d failures</li>',
					$k,
					$clusters{perl_os}{$k},
				);
			}

			push @html, '</ul>';

			my @locale_clusters;

			for my $r (@pass_reports) {
				my $locale = extract_locale($r) // 'unknown';
				$locale_stats{$locale}{pass}++;
			}

			for my $loc (keys %locale_stats) {
				next if $loc eq 'unknown';

				my $fail = $locale_stats{$loc}{fail} // 0;
				my $pass = $locale_stats{$loc}{pass} // 0;
				my $total = $fail + $pass;

				next if $total < $config{min_locale_samples};

				my $ratio = $fail / $total * 100;

				if ($ratio >= $config{low_threshold} && is_non_english_locale($loc)) {
					push @locale_clusters, {
						locale => $loc,
						fail => $fail,
						pass => $pass,
						ratio => $ratio,
					};
				}
			}
			if(scalar(@locale_clusters)) {
				push @html,
					'<h3>Locale-sensitive failures detected</h3>',
					'<div class="notice locale-cliff">',
					'<ul>';
				foreach my $locale(@locale_clusters) {
					push @html, "<li><code>$locale->{locale}</code> - $locale->{fail} FAIL / $locale->{pass} PASS ($locale->{ratio}%)</li>";
				}
				push @html, '</ul>', '</div>';
			}

			my @fail_perl_versions = extract_perl_versions(\@fail_reports);
			my @pass_perl_versions = extract_perl_versions(\@pass_reports);

			my @root_causes = detect_root_causes(
				fail_reports => \@fail_reports,
				pass_reports => \@pass_reports,
				fail_perl_versions => \@fail_perl_versions,
				pass_perl_versions => \@pass_perl_versions,
			);
			if (@root_causes) {
				push @html, <<'HTML';
<h3>Likely Root Causes</h3>
<table class="root-causes">
<thead>
<tr>
	<th>Cause</th>
	<th>Confidence</th>
	<th>Evidence</th>
</tr>
</thead>
<tbody>
HTML

				for my $rc (@root_causes) {
					my $confidence_pct = int($rc->{confidence} * 100);

					my $confidence_class =
						$confidence_pct >= $config{med_threshold} ? 'high'
						: $confidence_pct >= $config{low_threshold} ? 'med'
						: 'low';

					my $confidence_label =
						$confidence_class eq 'high' ? 'Strong'
						: $confidence_class eq 'med' ? 'Moderate'
						: 'Weak';

					my $evidence_html = join(
						'',
						map { "<li>$_</li>" } @{ $rc->{evidence} || [] }
					);

					my $label = $rc->{label};

					# Optional perldelta link
					if ($rc->{type} eq 'perl' && $rc->{perldelta}) {
						$label .= sprintf(
							q{ (<a href="%s" target="_blank">perldelta</a>)},
							$rc->{perldelta}
						);
					}

					push @html, sprintf(<<'ROW',
<tr class="%s">
	<td halign="center"><strong>%s</strong></td>
	<td halign="center">%s (%d%%)</td>
	<td halign="center"><ul>%s</ul></td>
</tr>
ROW
						$confidence_class,
						$label,
						$confidence_label,
						$confidence_pct,
						$evidence_html,
					);
				}

				push @html, <<'HTML';
</tbody>
</table>
HTML
			}
		}

		push @html, <<"HTML";
<script>
document.addEventListener("DOMContentLoaded", function () {
	const toggleFail = document.getElementById('toggleFail');
	const toggleUnknown = document.getElementById('toggleUnknown');
	const toggleNA = document.getElementById('toggleNA');
	const toggleNew = document.getElementById('toggleNew');

	function update() {
		document.querySelectorAll('tr').forEach(row => {
			// Skip header rows
			if (row.querySelector('th')) return;

			// Determine row status
			const isFail = row.classList.contains('cpan-fail');
			const isUnknown = row.classList.contains('cpan-unknown');
			const isNA = row.classList.contains('cpan-na');
			const isNew = !!row.querySelector('.new-failure');

			// Decide whether to show the row
			let show = true;

			if (toggleFail && !toggleFail.checked && isFail) show = false;
			if (toggleUnknown && !toggleUnknown.checked && isUnknown) show = false;
			if (toggleNA && !toggleNA.checked && isNA) show = false;
			if (toggleNew && toggleNew.checked && !isNew) show = false;

			row.style.display = show ? '' : 'none';
		});
	}

	[toggleFail, toggleUnknown, toggleNA, toggleNew].forEach(cb => {
		if (cb) cb.addEventListener('change', update);
	});

	update();
});
document.addEventListener("DOMContentLoaded", () => {
	const th = document.querySelector("table.sortable-table th");
	if (th) sortTable(th, 0);
});
</script>

<p><em>Showing one failure per OS/Perl combination.</em></p>
<div style="margin-bottom: 0.5em;">
	<label>
		<input type="checkbox" id="toggleFail" checked>
		FAIL
	</label>
	<label style="margin-left: 1em;">
		<input type="checkbox" id="toggleUnknown">
		UNKNOWN
	</label>
	<label style="margin-left: 1em;">
		<input type="checkbox" id="toggleNA">
		NA
	</label>
	<label style="margin-left: 1em;">
		<input type="checkbox" id="toggleNew">
		NEW only
	</label>
</div>

<table class="sortable-table" data-sort-col="0" data-sort-order="asc">
<thead>
<tr>
	<th class="sortable" onclick="sortTable(this, 0)">
		<span class="label">Date</span> <span class="arrow">&#x25B2;</span>
	</th>
	<th class="sortable" onclick="sortTable(this, 1)">
		<span class="label">OS</span> <span class="arrow">&#x25B2;</span>
	</th>
	<th class="sortable" onclick="sortTable(this, 2)">
		<span class="label">Perl</span> <span class="arrow">&#x25B2;</span>
	</th>
	<th class="sortable" onclick="sortTable(this, 3)">
		<span class="label">Reporter</span> <span class="arrow">&#x25B2;</span>
	</th>
	<th class="sortable" onclick="sortTable(this, 4)" title="Marks failures that did not occur in the previous release. The same OS, Perl version, architecture, and platform were passing before.">
		<span class="label">New</span> <span class="arrow">&#x25B2;</span>
	</th>
	<th>Report</th>
</tr>
</thead>
<tbody>
HTML

		my %best;

		for my $r (@fail_reports) {
			my $key = make_key($r);

			if(!exists $best{$key} || (!$best{$key}{guid} && $r->{guid})) {
				$best{$key} = $r;
			}
		}

		my @deduped = values %best;

		my %prev_fail_set;

		for my $r (@prev_fail_reports) {
			my $key = make_key($r);

			$prev_fail_set{$key} = 1;
		}

		for my $r (@deduped) {
			my $date = $r->{date} // '';
			my $perl = $r->{perl} // '';
			my $os = $r->{osname} // '';
			my $grade = lc($r->{grade} // 'unknown');
			my $row_class = "cpan-$grade";	# cpan-fail or cpan-unknown
			my $reporter = $r->{reporter} // '';
			$reporter =~ s/"//g;
			$reporter =~ s/<.+>//g;
			$reporter =~ s/\s+$//g;
			my $guid = $r->{guid} // '';
			my $url = $guid ? "https://www.cpantesters.org/cpan/report/$guid" : '#';

			my $is_new = !$prev_fail_set{make_key($r)};
			my $new_html = $is_new ? '<span class="new-failure">NEW</span>' : '';

			push @html, sprintf(
				qq{<tr class="%s"><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>
				<td><a href="%s" target="_blank">View</a></td></tr>},
				$row_class,
				$date,
				$os,
				$perl,
				$reporter,
				$new_html,
				$url
			);
		}

		push @html, '</tbody></table>';
	} else {
		# @fail_reports is empty
		push @html, "<p>No <A HREF=\"https://fast2-matrix.cpantesters.org/?dist=$dist_name+$version\">CPAN Testers</A> failures reported for $dist_name $version</p>";
	}
} elsif($res->{status} == 404) {	# 404 means no fail reports
	# push @html, "<A HREF=\"$cpan_api\">$cpan_api</A>";
	push @html, "<p>No CPAN Testers failures reported for $dist_name $version.</p>";
} else {
	push @html, "<a href=\"$cpan_api\">$cpan_api</a>: $res->{status} $res->{reason}";
}

# Output the Mutation Overview
if($mutation_db) {
	my $lcsaj_hits;

	if($config{lcsaj_hits_file} && -f $config{lcsaj_hits_file}) {
		open my $lfh, '<', $config{lcsaj_hits_file};
		$lcsaj_hits = decode_json(do { local $/; <$lfh> });
		close $lfh;
	}

	my $files = _group_by_file($mutation_db);

	push @html, @{_mutation_index($mutation_db, $files, $cover_db, $config{lcsaj_root}, $lcsaj_hits)};

	# Pre-sort files worst-first so navigation order matches index order
	my @sorted_files = sort { _file_score($files->{$a}) <=> _file_score($files->{$b}) || $a cmp $b } keys %$files;

	for my $i (0 .. $#sorted_files) {
		my $file = $sorted_files[$i];

		# Only assign previous if this is NOT the first file
		my $prev = $i > 0 ? $sorted_files[$i - 1] : undef;

		# Only assign next if this is NOT the last file
		my $next = $i < $#sorted_files ? $sorted_files[$i + 1] : undef;

		_mutant_file_report($config{mutation_output_dir}, $file, $files->{$file}, $prev, $next, $cover_db, $config{lcsaj_root}, $lcsaj_hits);
	}
}

my $timestamp = 'Unknown';
if (my $stat = stat($config{cover_db})) {
	$timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime($stat->mtime));
}

push @html, <<"HTML";
<footer>
	<p>Project: <a href="https://github.com/$config{github_user}/$config{github_repo}">$config{github_repo}</a></p>
	<p><em>Last updated: $timestamp - <a href="$commit_url">commit <code>$short_sha</code></a></em></p>
</footer>

</body>
</html>
HTML

# Write to index.html
print "Writing output to $config{output}\n" if($config{verbose});
write_file($config{output}, join("\n", @html));

# Generate mutant test stubs only if --generate_mutant_tests=dir was given.
# This is opt-in to avoid surprising existing pipelines with new files.
if($mutation_db && $mutant_test_dir) {
	_generate_mutant_tests($mutation_db, $cover_db, $mutant_test_dir, $generate_test);
}

# Generate fuzz schema augmentations from surviving mutants
# if --generate_fuzz was passed on the command line
if($mutation_db && $generate_fuzz) {
	_generate_fuzz_schemas($mutation_db);
}

# Safe git command execution
sub run_git {
	my @cmd = @_;
	my ($out, $err);
	run3 ['git', @cmd], \undef, \$out, \$err;
	return unless $? == 0;
	chomp $out;
	return $out;
}

sub js_escape {
	my $str = $_[0];
	$str =~ s/\\/\\\\/g;
	$str =~ s/"/\\"/g;
	$str =~ s/\n/\\n/g;
	return $str;
}

sub fetch_reports_by_grades {
	my ($dist, $version, @grades) = @_;

	my %seen;
	my @reports;

	for my $grade (@grades) {
		my $url = 'https://api.cpantesters.org/v3/summary/'
			. uri_escape($dist)
			. '/' . uri_escape($version)
			. "?grade=$grade";

		my $res = $http->get($url);
		next unless $res->{success};

		my $arr = eval { decode_json($res->{content}) };
		next unless ref $arr eq 'ARRAY';

		for my $r (@$arr) {
			my $key = make_key($r);

			next if $seen{$key}++;
			push @reports, $r;
		}
	}

	return @reports;
}

sub aggregate_dependency_stats {
	my (%args) = @_;

	my $guids = $args{guids} || [];
	my $grade = $args{grade} || 'fail';
	my $stats = $args{stats_ref} || {};

	my $count = 0;

	for my $guid (@$guids) {
		last if $count++ >= $MAX_REPORTS_PER_GRADE;

		my $html = fetch_report_html($guid) or next;
		my $mods = extract_installed_modules($html);

		for my $m (keys %$mods) {
			$stats->{$m}{$grade}++;
			$stats->{$m}{versions}{ $mods->{$m} }{$grade}++;
		}
	}

	return $stats;
}

sub fetch_report_html {
	my $guid = $_[0];

	return unless $guid;

	my $url = "https://www.cpantesters.org/cpan/report/$guid";
	# print "fetching report HTML $url\n";

	my $res = $http->get($url);
	return unless $res->{success};

	return $res->{content};
}

sub extract_installed_modules {
	my ($html) = @_;
	my %mods;

	return \%mods unless $html;

	if ($html =~ /Installed modules:(.*?)(?:\n\n|\z)/s) {
		my $block = $1;
		while ($block =~ /^\s*([A-Z]\w*(?:::\w+)*)\s+v?([\d._]+)/mg) {
			my ($module, $version) = ($1, $2);

			# skip obvious noise
			next if $module =~ /^(Perl|OS|Reporter|Tester)$/;

			$mods{$module} = $version;
		}
	}

	return \%mods;
}

sub find_suspected_dependencies {
	my ($stats) = @_;
	my @suspects;

	for my $mod (sort keys %$stats) {
		my $fail = $stats->{$mod}{fail} || 0;
		my $pass = $stats->{$mod}{pass} || 0;

		next unless $fail >= 2;

		# signal 1: fail-only
		if ($fail && !$pass) {
			push @suspects, {
				module => $mod,
				fail => $fail,
				pass => 0,
				reason => 'Seen only in FAIL reports',
			};
			next;
		}

		# signal 2: strong skew
		my $ratio = $fail / ($fail + $pass);
		my $ratio_pct = $ratio * 100;
		if ($fail >= 3 && $ratio_pct >= $config{low_threshold}) {
			push @suspects, {
				module => $mod,
				fail => $fail,
				pass => $pass,
				ratio => sprintf('%.2f', $ratio),
				reason => 'Strong FAIL skew',
			};
		}
	}

	return @suspects;
}

sub collect_dependency_versions {
	my (%args) = @_;

	my $reports = $args{reports};	# arrayref of report hashrefs
	my $dep_store = $args{store};	# hashref
	my $grade = lc($args{grade});	# fail / pass / unknown

	for my $r (@$reports) {
		my $pr = $r->{prereqs} or next;
		my $rt = $pr->{runtime}{requires} or next;

		while (my ($mod, $ver) = each %$rt) {
			next unless defined $ver && $ver =~ /\d/;
			push @{ $dep_store->{$mod}{$grade} }, $ver;
		}
	}
}

sub detect_version_cliffs {
	my ($deps) = @_;
	my @suspects;

	for my $mod (sort keys %$deps) {
		my $d = $deps->{$mod};

		next unless $d->{fail} && $d->{pass};

		my @fail = sort { parse_version($a) <=> parse_version($b) } @{ $d->{fail} };
		my @pass = sort { parse_version($a) <=> parse_version($b) } @{ $d->{pass} };

		my $fail_min = parse_version($fail[0]);
		my $pass_max = parse_version($pass[-1]);

		# Classic cliff: PASS versions entirely below FAIL versions
		if ($pass_max < $fail_min) {
			push @suspects, {
				module => $mod,
				type => 'hard',
				message => sprintf(
					'PASS ≤ %s, FAIL ≥ %s',
					$pass[-1],
					$fail[0],
				),
			};
			next;
		}

		# Soft cliff: FAIL skewed higher than PASS
		my $fail_median = $fail[ int(@fail / 2) ];
		my $pass_median = $pass[ int(@pass / 2) ];

		if (parse_version($fail_median) > parse_version($pass_median)) {
			push @suspects, {
				module => $mod,
				type => 'soft',
				message => sprintf(
					'FAIL median %s &gt; PASS median %s',
					$fail_median,
					$pass_median,
				),
			};
		}
	}

	return @suspects;
}

sub detect_perl_version_cliff {
	my ($fail_reports, $pass_reports) = @_;

	my @fail_perls = extract_perl_versions($fail_reports);
	my @pass_perls = extract_perl_versions($pass_reports);

	return unless @fail_perls && @pass_perls;

	my $max_fail = (sort { $b <=> $a } @fail_perls)[0];
	my $min_pass = (sort { $a <=> $b } @pass_perls)[0];

	return unless $min_pass > $max_fail;

	return { fails_up_to => $max_fail, passes_from => $min_pass };
}

sub extract_perl_versions {
	my ($reports) = @_;
	my @v;

	for my $r (@$reports) {
		next unless $r->{perl};
		push @v, parse_version($r->{perl});
	}

	return @v;
}

sub perldelta_url {
	my ($v) = @_;
	my ($maj, $min) = $v =~ /^v?(\d+)\.(\d+)/;
	return "https://perldoc.perl.org/perl${maj}${min}0delta";
}

sub confidence_score {
	my (%args) = @_;

	my $fail = $args{fail} // 0;
	my $pass = $args{pass} // 0;

	return (0, 'none') if ($fail + $pass) == 0;

	my $score = $fail / ($fail + $pass);

	# Convert config thresholds from percent → fraction
	my $med = ($config{med_threshold} // 90) / 100;
	my $low = ($config{low_threshold} // 70) / 100;

	my $label =
		$score >= $med ? 'strong' :
		$score >= $low ? 'moderate' :
		'weak';

	return ($score, $label);
}

sub confidence_badge_html {
	my ($score, $label, $fail, $pass) = @_;

	my %class_for = (
		strong => 'badge-good',
		moderate => 'badge-warn',
		weak => 'badge-bad',
		none => 'badge-bad',
	);

	my $pct = sprintf('%.0f%%', $score * 100);

	return sprintf(
		q{<span class="coverage-badge %s" title="%d fails, %d passes">%s confidence</span>},
		$class_for{$label} // 'badge-bad',
		$fail, $pass,
		ucfirst($label)
	);
}

sub perl_series {
	my $perl = $_[0];
	return unless defined $perl;

	# map "5.16.3" to "5.16"
	if ($perl =~ /^(\d+\.\d+)/) {
		return $1;
	}
	return;
}

sub extract_locale {
	my $r = $_[0];

	# Preferred: explicit environment
	for my $k (qw(LANG LC_ALL LC_CTYPE)) {
		if (my $v = $r->{env}{$k}) {
			return $v;
		}
	}

	# Fallback: scan report body
	if (my $body = $r->{raw} || $r->{body}) {
		if ($body =~ /\b([a-z]{2}_[A-Z]{2})\b/) {
			return $1;
		}
	}

	my $url = "https://api.cpantesters.org/v3/report/$r->{guid}";

	my $res = $http->get($url);
	return unless $res->{success};

	my $report = eval { decode_json($res->{content}) };

	if($report->{result}->{output}->{uncategorized} =~ /\b([a-z]{2}_[A-Z]{2})\b/) {
		return $1;
	}
}

sub is_non_english_locale {
	my $locale = $_[0];

	return 0 unless $locale;

	# Treat C / POSIX / en_* as English
	return 0 if $locale =~ /^(C|POSIX|en(_|$))/i;

	return 1;
}

sub parse_version {
	my $v = $_[0];
	return eval { version->parse($v) };
}

sub fetch_open_rt_ticket_count {
	my $dist = $_[0];

	my @rc = @{WWW::RT::CPAN::list_dist_active_tickets(dist => $dist)};

	# Defensive checks
	return undef unless @rc >= 3;
	return undef unless $rc[0] == 200 && $rc[1] eq 'OK';

	my $tickets = $rc[2] && ref $rc[2] eq 'ARRAY' ? $rc[2] : [];

	return scalar @$tickets;
}

sub detect_os_root_cause {
	my ($reports, $config) = @_;

	my %count;
	$count{ $_->{osname} // 'unknown' }++ for @$reports;

	my $total = @$reports;
	return unless $total >= 3;

	for my $os (keys %count) {
		my $ratio = $count{$os} / $total;
		next unless $ratio >= ($config->{med_threshold} / 100);

		return {
			type => 'os',
			label => "OS-specific behavior ($os)",
			confidence => sprintf("%.2f", $ratio),
			evidence => [
				sprintf('%d/%d failures on %s', $count{$os}, $total, $os),
					"Passes observed on other operating systems",
				],
		};
	}

	return;
}

sub detect_perl_version_root_cause {
	my ($fail_versions, $pass_versions) = @_;

	return unless @$fail_versions && @$pass_versions;

	my $max_fail = List::Util::max(@$fail_versions);
	my $min_pass = List::Util::min(@$pass_versions);

	return unless $max_fail < $min_pass;

	return {
		type => 'perl',
		label => "Perl version regression (Perl &lt; $min_pass)",
		confidence => 1.00,
		evidence => [
			"All failures on Perl &leq; $max_fail",
			"All passes on Perl &geq; $min_pass",
		],
		perldelta => perldelta_url($min_pass),
	};
}

sub detect_locale_root_cause {
	my ($reports, $config) = @_;

	my %count;
	my $total = 0;

	for my $r (@$reports) {
		# Can get FPs if we take NA or Unknown into account
		if(lc($r->{grade} // '') eq 'fail') {
			my $loc = extract_locale($r) or next;
			next if $loc =~ /^en_/i;
			$count{$loc}++;
			$total++;
		}
	}

	return unless $total >= 2;

	for my $loc (keys %count) {
		my $ratio = $count{$loc} / $total;
		next unless $ratio >= ($config->{low_threshold} / 100);

		return {
			type => 'locale',
			label => "Locale-sensitive behavior ($loc)",
			confidence => sprintf("%.2f", $ratio),
			evidence => [
				"$count{$loc}/$total failures with LANG=$loc",
				'English locales show fewer or no failures',
			],
		};
	}

	return;
}

sub detect_root_causes {
	my (%args) = @_;
	my @hints;

	push @hints, detect_os_root_cause($args{fail_reports}, \%config) if $args{fail_reports};
	push @hints, detect_locale_root_cause($args{fail_reports}, \%config);

	if ($args{fail_perl_versions} && $args{pass_perl_versions}) {
		push @hints,
			detect_perl_version_root_cause(
				$args{fail_perl_versions},
				$args{pass_perl_versions},
			);
	}

	@hints = grep { defined } @hints;
	@hints = sort { $b->{confidence} <=> $a->{confidence} } @hints;

	return @hints;
}

sub make_key
{
	my $r = $_[0];

	return lc(join '|', $r->{osname} // '', $r->{perl} // '', $r->{arch} // '', $r->{platform} // '' );
}

# --------------------------------------------------
# _enclosing_sub
#
# Scan backwards through source lines from a given
# line number to find the enclosing subroutine name.
#
# Arguments:
#   $source_lines - arrayref of source lines (1-indexed content)
#   $line_no      - line number to search backwards from
#
# Returns:
#   The subroutine name string, or undef if not found
#   (e.g. for file-level code outside any sub)
# --------------------------------------------------
sub _enclosing_sub {
	my ($source_lines, $line_no) = @_;

	# Walk backwards from the mutated line looking for 'sub name'
	for(my $i = $line_no - 1; $i >= 0; $i--) {
		if($source_lines->[$i] =~ /^\s*sub\s+(\w+)/) {
			return $1;
		}
	}

	# No enclosing sub found — code is at file level
	return undef;
}

# --------------------------------------------------
# _boundary_edge_case_key
#
# Detect whether a schema uses positional
# or named parameters, to determine which
# YAML key to use for boundary edge cases.
# Positional functions use edge_case_array;
# named-parameter functions use edge_cases.
#
# Entry:      $schema is a hashref from SchemaExtractor.
#
# Exit:       Returns the string 'edge_case_array' or
#             'edge_cases'.
#
# Notes:      For named params, also returns the list
#             of numeric parameter names to annotate,
#             since we cannot always tell from the
#             mutant context which param the boundary
#             comparison is about.
# --------------------------------------------------
sub _boundary_edge_case_key {
	my ($schema) = @_;

	my $input = $schema->{input};

	# No input defined at all — default to positional
	return ('edge_case_array', []) unless $input && ref $input eq 'HASH';

	# Single unnamed param: SchemaExtractor emits { type => 'string' }
	# for simple single-argument positional functions
	if(scalar(keys %{$input}) == 1 && exists $input->{type}) {
		return ('edge_case_array', []);
	}

	# Count params with and without explicit positions
	my ($has_positions, $has_names) = (0, 0);
	my @numeric_params;

	for my $name (keys %{$input}) {
		my $p = $input->{$name};
		next unless ref $p eq 'HASH';

		# Track which params are numeric — these are the ones
		# a NUM_BOUNDARY mutant is most likely targeting
		if($p->{type} && $p->{type} =~ /^(integer|number|float)$/) {
			push @numeric_params, $name;
		}

		if(defined $p->{position}) {
			$has_positions++;
		} else {
			$has_names++;
		}
	}

	# All params have positions — treat as positional calling style
	if($has_positions && !$has_names) {
		return ('edge_case_array', []);
	}

	# Named or mixed — attach boundary value to all numeric params
	# since we can't know which one the mutant comparison targets
	return ('edge_cases', \@numeric_params);
}

# --------------------------------------------------
# _extract_schema_for_mutant
#
# Purpose:    Use SchemaExtractor to extract the schema
#             for the sub that contains a surviving mutant,
#             then augment it with the boundary value so
#             App::Test::Generator can produce a runnable
#             test targeting that boundary.
#
# Entry:      Named args:
#               file           - path to the source .pm file
#               enclosing_sub  - name of the sub containing
#                                the mutant
#               boundary_value - numeric boundary value
#                                extracted from the mutant id
#               module         - Perl module name (e.g.
#                                App::Test::Generator)
#
# Exit:       Returns a cleaned schema hashref ready for
#             YAML serialisation, or undef if extraction
#             failed or confidence was too low.
#
# Side effects: Loads SchemaExtractor and PPI transiently.
#               Does NOT write any files.
#
# Notes:      Only called when --generate_test=mutant is set.
#             Internal _ keys from SchemaExtractor are stripped
#             before returning, as App::Test::Generator does
#             not understand them.
# --------------------------------------------------
sub _extract_schema_for_mutant {
	my (%args) = @_;

	my $file           = $args{file}           or return;
	my $enclosing_sub  = $args{enclosing_sub}  or return;
	my $boundary_value = $args{boundary_value};
	my $module         = $args{module}         or return;

	# Bail out if the source file does not exist or is unreadable
	return unless -r $file;

	# Load SchemaExtractor — require here so it is only loaded
	# when --generate_test=mutant is actually in use
	require App::Test::Generator::SchemaExtractor;

	my $extractor = eval {
		App::Test::Generator::SchemaExtractor->new(
			input_file => $file,
			# no output_dir — we are using no_write => 1
			verbose    => 0,
		);
	};

	# If SchemaExtractor fails to instantiate, fall back gracefully
	if($@ || !$extractor) {
		warn "SchemaExtractor failed for $file: $@\n" if $@;
		return;
	}

	# Extract all schemas without writing any files to disk
	my $schemas = eval { $extractor->extract_all(no_write => 1) };

	if($@ || !$schemas) {
		warn "extract_all failed for $file: $@\n" if $@;
		return;
	}

	# Look up the schema for the specific sub containing the mutant
	my $schema = $schemas->{$enclosing_sub};
	return unless $schema;

	# Check confidence — skip if SchemaExtractor has very low or no
	# confidence in the extracted schema, as the generated test
	# would likely be meaningless or wrong
	my $confidence = $schema->{_analysis}{overall_confidence} // 'none';
	if($confidence eq 'very_low' || $confidence eq 'none') {
		return;
	}

	# Determine whether to use edge_case_array or edge_cases,
	# and which named params (if any) to annotate
	my ($edge_key, $numeric_params) = _boundary_edge_case_key($schema);

	# Augment the schema with the boundary value so the generated
	# test will probe around the exact value the mutant survived on
	if(defined $boundary_value) {
		if($edge_key eq 'edge_case_array') {
			# Positional / single-arg function
			$schema->{edge_case_array} ||= [];
			push @{$schema->{edge_case_array}}, $boundary_value;

			# Also add the values just either side of the boundary,
			# since the mutant flipped a comparison operator
			push @{$schema->{edge_case_array}}, $boundary_value - 1
				if $boundary_value > 0;
			push @{$schema->{edge_case_array}}, $boundary_value + 1;
		} else {
			# Named-parameter function — annotate all numeric params
			$schema->{edge_cases} ||= {};
			for my $param (@{$numeric_params}) {
				$schema->{edge_cases}{$param} ||= [];
				push @{$schema->{edge_cases}{$param}}, $boundary_value;
				push @{$schema->{edge_cases}{$param}}, $boundary_value - 1
					if $boundary_value > 0;
				push @{$schema->{edge_cases}{$param}}, $boundary_value + 1;
			}
		}
	}

	# Ensure the schema carries the correct module and function names,
	# since SchemaExtractor may have recorded them differently
	$schema->{module}   = $module;
	$schema->{function} = $enclosing_sub;

	# Strip all internal _ keys that App::Test::Generator does not
	# understand — these are SchemaExtractor analysis metadata
	_strip_internal_keys($schema);

	return $schema;
}

# --------------------------------------------------
# _strip_internal_keys
#
# Purpose:    Recursively remove keys beginning with _
#             from a schema hashref. These are internal
#             SchemaExtractor metadata keys that
#             App::Test::Generator does not accept.
#
# Entry:      $schema is a hashref (modified in place).
# Exit:       $schema with all _* keys removed at all
#             levels of nesting.
# Side effects: Modifies $schema in place.
# Notes:      Does not descend into arrayrefs — only
#             hashrefs are recursed into.
# --------------------------------------------------
sub _strip_internal_keys {
	my ($hash) = @_;

	return unless ref $hash eq 'HASH';

	for my $key (keys %{$hash}) {
		if($key =~ /^_/) {
			# Remove SchemaExtractor internal metadata key
			delete $hash->{$key};
		} elsif(ref $hash->{$key} eq 'HASH') {
			# Recurse into nested hashrefs (e.g. input params)
			_strip_internal_keys($hash->{$key});
		}
	}
}

# --------------------------------------------------
# _write_mutant_schema
#
# Purpose:    Serialise an augmented mutant schema to a
#             timestamped YAML file in t/conf/ so that
#             t/fuzz.t picks it up on the next test run.
#
# Entry:      $schema      - cleaned schema hashref
#             $test_dir    - base test directory (e.g. 't')
#             $module      - Perl module name for filename
#             $function    - function name for filename
#             $timestamp   - YYYYMMDD_HHMMSS string
#
# Exit:       Returns the path of the written file,
#             or undef if the write failed.
#
# Side effects: Creates t/conf/ if it does not exist.
#               Writes a YAML file to t/conf/.
#
# Notes:      Uses YAML::XS::Dump. The filename is
#             deterministic for a given timestamp so
#             duplicate runs in the same second are
#             skipped (same guard as TODO stubs).
# --------------------------------------------------
sub _write_mutant_schema {
	my ($schema, $test_dir, $module, $function, $timestamp) = @_;

	# Build a safe filename from the module and function names
	# by replacing :: and other non-word chars with underscores
	(my $safe_module   = $module)   =~ s/[^A-Za-z0-9]/_/g;
	(my $safe_function = $function) =~ s/[^A-Za-z0-9]/_/g;

	# Ensure t/conf/ exists before attempting to write
	my $conf_dir = "$test_dir/conf";
	unless(-d $conf_dir) {
		require File::Path;
		File::Path::make_path($conf_dir)
			or do { warn "Cannot create $conf_dir: $!\n"; return };
	}

	my $path = "$conf_dir/mutant_${safe_module}_${safe_function}_${timestamp}.yml";

	# Skip if a file for this timestamp already exists —
	# same guard used by the TODO stub generator
	return $path if -f $path;

	# Serialise the schema to a normalised YAML string
	my $yaml = _dump_schema_yaml($schema);
	if(!defined $yaml) {
		warn "YAML serialisation failed for $path\n";
		return;
	}

	# Write the YAML file and report success or failure
	open(my $fh, '>:encoding(UTF-8)', $path)
		or do { warn "Cannot write $path: $!\n"; return };
	print $fh $yaml;
	close $fh;

	return $path;
}

# --------------------------------------------------
# _dump_schema_yaml
#
# Purpose:    Serialise a schema hashref to a YAML
#             string with consistent formatting,
#             suitable for use as input to
#             App::Test::Generator.
#
# Entry:      $schema - hashref to serialise.
#             Must be a valid schema hashref.
#
# Exit:       Returns the YAML string, or undef if
#             serialisation failed.
#
# Side effects: None. Does not write any files.
#
# Notes:      Applies the following normalisation
#             before dumping:
#               - Removes output _STATUS: DIES if it
#                 is the only key in output, since
#                 SchemaExtractor incorrectly infers
#                 this from error-path returns.
#               - Sets indent to 2 for correct nested
#                 structure (yamllint compliant).
#               - Suppresses numeric string quoting so
#                 boundary values are numbers not
#                 quoted strings.
#               - Converts yes/no booleans to
#                 true/false (yamllint requires this).
# --------------------------------------------------
sub _dump_schema_yaml {
	my $schema = $_[0];

	# Replace spurious output _STATUS: DIES with a minimal
	# valid output spec. SchemaExtractor infers DIES from
	# error paths but the function does not always die.
	# Leaving output empty causes uninitialized value warnings
	# in App::Test::Generator, so we supply a safe default.
	if(ref $schema->{output} eq 'HASH' &&
	   ($schema->{output}{_STATUS} // '') eq 'DIES' &&
	   keys %{$schema->{output}} == 1) {
		$schema->{output} = { type => 'string' };
	}

	# Set indent and suppress numeric string quoting
	# so boundary values are written as numbers
	local $YAML::XS::QuoteNumericStrings = 0;
	local $YAML::XS::Indent              = 2;

	my $yaml = eval { YAML::XS::Dump($schema) };
	return undef if $@ || !defined $yaml;

	# Convert yes/no booleans to true/false —
	# YAML::XS writes Perl's 1/0 as yes/no but
	# yamllint requires true/false per YAML 1.2
	$yaml =~ s/:\s+yes$/: true/mg;
	$yaml =~ s/:\s+no$/: false/mg;

	# --------------------------------------------------
	# Fix YAML::XS indentation quirks.
	# YAML::XS does not reliably honour $Indent for:
	#   1. List items nested inside hash values — they
	#      should be indented 2 more than their parent
	#      key but sometimes appear at the same level.
	#   2. Top-level keys after a nested block — they
	#      sometimes lose their leading spaces entirely.
	# We correct both by scanning line by line and
	# tracking the expected indentation depth.
	# --------------------------------------------------
	my @lines  = split /\n/, $yaml, -1;
	my @fixed;
	my $last_key_indent = 0;

	for my $line (@lines) {
		# Track indentation of the most recent hash key line
		# so we know the expected depth for following list items
		if($line =~ /^( *)[\w][^:]*:/) {
			$last_key_indent = length($1);
		}

		# Fix list items that are not indented enough —
		# they should be at least last_key_indent + 2
		if($line =~ /^( *)- /) {
			my $current  = length($1);
			my $expected = $last_key_indent + 2;
			if($current < $expected) {
				$line = (' ' x $expected) . substr($line, $current);
			}
		}

		push @fixed, $line;
	}

	$yaml = join("\n", @fixed);

	return $yaml;
}

# --------------------------------------------------
# _generate_mutant_tests
#
# Generate a test stub file for surviving mutants,
# to be placed in the project's t/ directory.
#
# This sub is called from generate_index.pl which
# runs from the project root (e.g. CGI-Info/ or
# App-Test-Generator/). The t/ directory written to
# belongs to the project under test, not to
# App::Test::Generator itself.
#
# High/Medium difficulty survivors get TODO stubs.
# Low difficulty survivors get comment-only hints.
# Mutants on the same line are deduplicated into one
# stub listing all variants — one test kills them all.
# File is skipped entirely if nothing to report.
#
# Arguments:
#   $mutation_db  - decoded mutation JSON hashref
#   $cover_db     - decoded Devel::Cover JSON hashref
#   $test_dir     - directory to write the .t file (default: 't')
#
# Returns:
#   The filename written, or undef if nothing written
# --------------------------------------------------
sub _generate_mutant_tests {
	my ($mutation_db, $cover_db, $test_dir, $generate_test) = @_;

	# Default output directory is the project's t/ directory
	$test_dir //= 't';

	# --------------------------------------------------
	# Separate survivors into high/med (need TODO stubs)
	# and low (comment hints only), based on the
	# 'difficulty' string field in the mutation data
	# --------------------------------------------------
	my @stub_mutants;
	my @hint_mutants;

	for my $m (@{ $mutation_db->{survived} || [] }) {
		# Skip malformed entries missing required fields
		next unless ref $m && defined $m->{file} && defined $m->{line};

		# Route by difficulty string; default to stub if field is absent
		if(defined $m->{difficulty} && $m->{difficulty} eq 'LOW') {
			push @hint_mutants, $m;
		} else {
			push @stub_mutants, $m;
		}
	}

	# Skip file creation entirely if there is nothing to report
	return undef if !@stub_mutants && !@hint_mutants;

	# --------------------------------------------------
	# Group both sets by file then by line number.
	# Multiple mutations on the same line are deduplicated
	# into one stub — one good test kills all variants.
	# --------------------------------------------------
	my %stubs_by_file;
	my %hints_by_file;

	for my $m (@stub_mutants) {
		push @{ $stubs_by_file{ $m->{file} }{ $m->{line} } }, $m;
	}
	for my $m (@hint_mutants) {
		push @{ $hints_by_file{ $m->{file} }{ $m->{line} } }, $m;
	}

	# --------------------------------------------------
	# Build sorted list of all affected source files
	# --------------------------------------------------
	my %all_files;
	$all_files{$_}++ for keys %stubs_by_file, keys %hints_by_file;
	my @files = sort keys %all_files;

	# --------------------------------------------------
	# Derive Perl module names from file paths for use_ok()
	# e.g. lib/CGI/Info.pm       -> CGI::Info
	#      lib/App/Test/Foo.pm   -> App::Test::Foo
	# --------------------------------------------------
	my %module_for;
	for my $file (@files) {
		(my $mod = $file) =~ s{^lib/}{};
		$mod =~ s{\.pm$}{};
		$mod =~ s{/}{::}g;
		$module_for{$file} = $mod;
	}

	# --------------------------------------------------
	# Build a unique timestamped filename.
	# If a file for this exact second already exists,
	# skip rather than overwrite.
	# --------------------------------------------------
	my $timestamp = strftime('%Y%m%d_%H%M%S', localtime);
	my $filename  = File::Spec->catfile($test_dir, "mutant_${timestamp}.t");

	if(-e $filename) {
		warn "Mutant test file $filename already exists, skipping generation\n";
		return undef;
	}

	# --------------------------------------------------
	# Open the output file for writing
	# --------------------------------------------------
	open my $fh, '>', $filename
		or die "Cannot write mutant test file $filename: $!";

	# --------------------------------------------------
	# File header explaining purpose and provenance
	# --------------------------------------------------
	my $generated_at = strftime('%Y-%m-%d %H:%M:%S', localtime);
	print $fh <<"HEADER";
#!/usr/bin/env perl
# Auto-generated mutant test stubs
# Generated: $generated_at
# Generator: scripts/generate_index.pl
#
# DO NOT COMMIT without completing the TODO sections.
#
# HIGH/MEDIUM difficulty survivors have TODO stubs — these need real tests.
# LOW difficulty survivors appear as comment hints — worth improving.
#
# Note: new() is called with no arguments as a starting point.
# If a module requires constructor arguments, add them before running.

use strict;
use warnings;
use Test::More;

HEADER

	# --------------------------------------------------
	# Group all use_ok() calls at the top of the file,
	# one per affected source file/module
	# --------------------------------------------------
	for my $file (@files) {
		my $mod = $module_for{$file};
		print $fh "use_ok('$mod');\n";
	}
	print $fh "\n";

	# --------------------------------------------------
	# Emit stubs and hints grouped by source file,
	# sorted by line number within each file
	# --------------------------------------------------
	for my $file (@files) {
		# Section header for this source file
		print $fh '#' x 64 . "\n";
		print $fh "# FILE: $file\n";
		print $fh '#' x 64 . "\n\n";

		# Read source lines for context in comments (1-indexed)
		my @source_lines;
		if(-f $file) {
			open my $sfh, '<', $file
				or warn "Cannot read $file for context: $!";
			@source_lines = <$sfh>;
			close $sfh;
		}

		# --------------------------------------------------
		# High/Med survivors — one TODO stub per line,
		# listing all mutation variants for that line.
		# --------------------------------------------------
		if(my $lines = $stubs_by_file{$file}) {
			print $fh "# --- SURVIVORS (TODO stubs) ---\n\n";

			for my $line_no (sort { $a <=> $b } keys %$lines) {
				my @variants = @{ $lines->{$line_no} };

				# All variants share the same file/line/source —
				# use the first entry for the common fields
				my $first = $variants[0];
				my $id    = $first->{id}         // 'unknown';
				my $hint  = $first->{hint}       // '';
				my $diff  = $first->{difficulty} // '';
				my $mod   = $module_for{$file};
				my $count = scalar @variants;

				# Extract the source line for context
				my $source = '';
				if(@source_lines && $line_no >= 1 && $line_no <= scalar @source_lines) {
					$source = $source_lines[$line_no - 1];
					chomp $source;
					$source =~ s/^\s+//;    # strip leading whitespace
				}

				# Find the enclosing subroutine for location context
				my $sub_name = _enclosing_sub(\@source_lines, $line_no);
				my $location = $sub_name
					? "line $line_no in ${sub_name}()"
					: "line $line_no";

				# --------------------------------------------------
				# For NUM_BOUNDARY mutations, attempt to extract the
				# boundary value and suggest appropriate test values.
				# Constructs like scalar(), length(), scalar keys %h,
				# and scalar @a are always non-negative, so we clamp
				# the lower suggestion to 0 and deduplicate the list.
				# --------------------------------------------------
				my $boundary_hint = '';
				if($id =~ /NUM_BOUNDARY/ && $source) {
					my $bval;

					# Try right-hand side first: operator then number
					if($source =~ /(?:[><=!]=?)\s*(-?\d+)/) {
						$bval = $1;
					# Then try left-hand side: number then operator
					} elsif($source =~ /(-?\d+)\s*(?:[><=!]=?)/) {
						$bval = $1;
					}

					if(defined $bval) {
						# Compute the naive lower boundary
						my $lower = $bval - 1;

						# --------------------------------------------------
						# Clamp lower bound to 0 for non-negative contexts:
						# scalar(), length(), scalar keys %h, scalar @a
						# can never return a negative value, so suggesting
						# -1 as a test value would be misleading
						# --------------------------------------------------
						if($source =~ /\b(?:scalar|length)\b/) {
							$lower = $lower < 0 ? 0 : $lower;
						}

						# Deduplicate suggestions in case lower == bval
						# (e.g. scalar() == 0 gives lower=0, bval=0)
						my %seen;
						my @suggestions = grep { !$seen{$_}++ }
							($lower, $bval, $bval + 1);

						$boundary_hint = '    # Suggested boundary values to test: '
							. join(', ', @suggestions) . "\n";
					}
				}

				# --------------------------------------------------
				# Check for $ENV{ references in the source line
				# and suggest the environment variable setup needed
				# --------------------------------------------------
				my $env_hint = '';
				if($source =~ /\$ENV\{['"]([\w]+)['"]\}/) {
					$env_hint = "    # Hint: may need \$ENV{'$1'} set to exercise this line\n";
				}

				# --------------------------------------------------
				# Emit one TODO stub for this line, listing all
				# mutation variants as comments — one good test
				# should be sufficient to kill all of them
				# --------------------------------------------------
				my $variant_label = $count == 1
					? '1 variant'
					: "$count variants — one test should kill all";

				print $fh "# --- SURVIVOR: $id ($diff) $location ---\n";
				print $fh "# Source:  $source\n" if $source;
				print $fh "# Hint:    $hint\n";
				print $fh "# Mutations on this line ($variant_label):\n";

				# List each distinct mutation description
				for my $v (@variants) {
					print $fh "#   $v->{description}\n";
				}

				print $fh "TODO: {\n";
				print $fh "    local \$TODO = 'Complete: $id $location';\n";
				print $fh $boundary_hint if $boundary_hint;
				print $fh $env_hint      if $env_hint;
				print $fh "    # NOTE: new() called with no arguments as a starting point.\n";
				print $fh "    # If $mod requires constructor arguments, add them here.\n";
				print $fh "    my \$obj = new_ok('${mod}');\n";
				print $fh "    # TODO: exercise $location to detect the mutant\n";
				print $fh "    fail('$id: replace with real assertion');\n";
				print $fh "}\n\n";
			}
		}

		# --------------------------------------------------
		# Low difficulty survivors — one comment stub per
		# line, listing all variants. Easy to uncomment
		# and complete when time allows.
		# --------------------------------------------------
		if(my $lines = $hints_by_file{$file}) {
			print $fh "# --- LOW DIFFICULTY HINTS (comment stubs) ---\n\n";

			for my $line_no (sort { $a <=> $b } keys %$lines) {
				my @variants = @{ $lines->{$line_no} };

				# Use first variant for common fields
				my $first = $variants[0];
				my $id    = $first->{id}         // 'unknown';
				my $hint  = $first->{hint}       // '';
				my $mod   = $module_for{$file};
				my $count = scalar @variants;

				# Extract source line for context
				my $source = '';
				if(@source_lines && $line_no >= 1 && $line_no <= scalar @source_lines) {
					$source = $source_lines[$line_no - 1];
					chomp $source;
					$source =~ s/^\s+//;
				}

				# Find the enclosing subroutine for location context
				my $sub_name = _enclosing_sub(\@source_lines, $line_no);
				my $location = $sub_name
					? "line $line_no in ${sub_name}()"
					: "line $line_no";

				# Check for environment variable references
				my $env_hint = '';
				if($source =~ /\$ENV\{['"]([\w]+)['"]\}/) {
					$env_hint = "# Hint: may need \$ENV{'$1'} set to exercise this line\n";
				}

				# Number of variants on this line
				my $variant_label = $count == 1
					? '1 variant'
					: "$count variants — one test should kill all";

				# --------------------------------------------------
				# If --generate_test=mutant is set and this is a
				# NUM_BOUNDARY mutation, attempt to produce a
				# runnable .yml schema via SchemaExtractor rather
				# than a TODO stub. We already have the boundary
				# value from $boundary_hint extraction above.
				# Fall through to the TODO stub if extraction
				# fails or confidence is too low.
				# --------------------------------------------------
				if($generate_test && $generate_test eq 'mutant') {
					if($id =~ /NUM_BOUNDARY/) {

						# Extract the numeric boundary value from the
						# source line — default to 0 if not found
						my $boundary_value = 0;
						if($source =~ /(?:[><=!]=?)\s*(-?\d+)/) {
							$boundary_value = $1 + 0;
						} elsif($source =~ /(-?\d+)\s*(?:[><=!]=?)/) {
							$boundary_value = $1 + 0;
						}

						# Attempt schema extraction and augmentation
						# using the enclosing sub name already computed
						my $schema = _extract_schema_for_mutant(
							file           => $file,
							enclosing_sub  => $sub_name,
							boundary_value => $boundary_value,
							module         => $mod,
						);

						if($schema) {
							# Write the runnable schema to t/conf/
							# and skip the TODO stub for this mutant
							my $written = _write_mutant_schema(
								$schema, $test_dir, $mod,
								$sub_name, $timestamp
							);
							if($written) {
								print $fh "# SCHEMA GENERATED: $written\n";
								print $fh "# (runnable test via t/fuzz.t)\n\n";
								next;	# Skip TODO stub for this mutant
							}
							# Fall through to stub if write failed
						}
						# Fall through to stub if extraction failed
						# or confidence was too low
					}
				}

				# Emit as commented-out stub — uncomment and complete to use
				print $fh "# --- LOW HINT: $id $location ---\n";
				print $fh "# Source:  $source\n" if $source;
				print $fh "# Hint:    $hint\n";
				print $fh "# Mutations on this line ($variant_label):\n";

				# List each distinct mutation description
				for my $v (@variants) {
					print $fh "#   $v->{description}\n";
				}

				print $fh $env_hint if $env_hint;
				print $fh "# NOTE: new() called with no arguments as a starting point.\n";
				print $fh "# If $mod requires constructor arguments, add them here.\n";
				print $fh "# my \$obj = new_ok('${mod}');\n";
				print $fh "# ok(\$obj->..., '$id: add assertion here');\n\n";
			}
		}
	}

	# Standard TAP footer
	print $fh "done_testing();\n";

	close $fh;

	print "Generated mutant test stubs: $filename\n" if $config{verbose};

	return $filename;
}

# --------------------------------------------------
# _generate_fuzz_schemas
#
# Purpose:    Scan t/conf/ for existing YAML schema
#             files and augment copies of them with
#             boundary values extracted from surviving
#             NUM_BOUNDARY mutants whose enclosing sub
#             matches the schema's function field.
#             The original schema is never modified.
#             Augmented copies are written with a
#             timestamped mutant_fuzz_ prefix so they
#             are picked up by t/fuzz.t automatically.
#
# Entry:      $mutation_db - decoded mutation JSON
#                            hashref
#             $test_dir    - base test directory
#                            (default: 't')
#
# Exit:       Returns the number of augmented schema
#             files written. Returns 0 if no matching
#             survivors were found.
#
# Side effects: Writes .yml files to $test_dir/conf/.
#               Prints progress if $config{verbose}.
#
# Notes:      Skips schemas whose filename starts with
#             mutant_fuzz_ to avoid augmenting already-
#             augmented schemas.
#             Skips schemas where no matching NUM_BOUNDARY
#             survivors exist, printing a verbose note.
#             Merges new boundary values into whichever
#             edge key already exists in the schema
#             (edge_case_array or edge_cases), falling
#             back to _boundary_edge_case_key detection
#             if neither key is present yet.
#             Deduplicates boundary values before writing.
# --------------------------------------------------
sub _generate_fuzz_schemas {
	my ($mutation_db, $test_dir) = @_;

	# Default test directory is the project's t/ directory
	$test_dir //= 't';

	my $conf_dir  = "$test_dir/conf";
	my $written   = 0;

	# Nothing to do if t/conf/ does not exist yet
	unless(-d $conf_dir) {
		print "No $conf_dir directory found, skipping fuzz schema generation\n" if $config{verbose};
		return 0;
	}

	# --------------------------------------------------
	# Compute a single timestamp for all files written
	# in this run, consistent with mutant_YYYYMMDD.t
	# naming used by _generate_mutant_tests
	# --------------------------------------------------
	my $timestamp = strftime('%Y%m%d_%H%M%S', localtime);

	# --------------------------------------------------
	# Build a lookup of surviving NUM_BOUNDARY mutants
	# indexed by (normalised module name, function name)
	# so we can find matches efficiently per schema
	# --------------------------------------------------
	my %survivors_by_mod_func;

	for my $m (@{ $mutation_db->{survived} || [] }) {
		# Only process NUM_BOUNDARY mutations — these have
		# the clearest boundary value inference path
		next unless ref $m;
		next unless ($m->{id} // '') =~ /NUM_BOUNDARY/;
		next unless defined $m->{file} && defined $m->{line};

		# Derive module name from file path for matching
		# e.g. lib/CGI/Info.pm -> CGI::Info
		(my $mod = $m->{file}) =~ s{^lib/}{};
		$mod =~ s{\.pm$}{};
		$mod =~ s{/}{::}g;

		# Read source lines so we can find the enclosing sub
		# and extract the boundary value from the source line
		my @source_lines;
		if(-r $m->{file}) {
			open my $sfh, '<', $m->{file}
				or next;
			@source_lines = <$sfh>;
			close $sfh;
		}

		next unless @source_lines;

		# Find the enclosing subroutine name for this mutant
		my $func = _enclosing_sub(\@source_lines, $m->{line});
		next unless defined $func;

		# Extract the source line text for boundary value parsing
		my $source = '';
		if($m->{line} >= 1 && $m->{line} <= scalar @source_lines) {
			$source = $source_lines[$m->{line} - 1];
			chomp $source;
		}

		# --------------------------------------------------
		# Detect what kind of boundary this mutant is about.
		# If the comparison involves scalar(@_), the boundary
		# is about argument count (call arity), not argument
		# value. We handle these two cases differently:
		#   - arity boundaries -> generate cases entries
		#   - value boundaries -> generate edge_case_array entries
		# --------------------------------------------------
		my $key = "$mod\0$func";

		if($source =~ /scalar\s*\(\s*\@_\s*\)/) {
			# --------------------------------------------------
			# Arity boundary: scalar(@_) comparison.
			# Extract the operator and count from the source line
			# so we can generate cases that call with too few
			# or too many arguments to exercise the boundary.
			# e.g. scalar(@_) <= 1 means we need cases with
			# 0 args (dies) and 2 args (lives).
			# --------------------------------------------------
			my ($op, $count);
			if($source =~ /scalar\s*\(\s*\@_\s*\)\s*([<>!=]=?)\s*(\d+)/) {
				($op, $count) = ($1, $2 + 0);
			} elsif($source =~ /(\d+)\s*([<>!=]=?)\s*scalar\s*\(\s*\@_\s*\)/) {
				# Reversed form: 1 >= scalar(@_)
				($op, $count) = ($2, $1 + 0);
			}

			next unless defined $count;

			# Store as an arity boundary so _generate_fuzz_schemas
			# can emit cases entries instead of edge_case_array
			push @{ $survivors_by_mod_func{$key}{arity} }, {
				op    => $op,
				count => $count,
			};
		} else {
			# --------------------------------------------------
			# Value boundary: comparison against a literal number.
			# Extract the boundary value and store bval-1, bval,
			# bval+1 to probe either side of the boundary,
			# consistent with _extract_schema_for_mutant.
			# --------------------------------------------------
			my $bval;
			if($source =~ /(?:[><=!]=?)\s*(-?\d+)/) {
				$bval = $1 + 0;
			} elsif($source =~ /(-?\d+)\s*(?:[><=!]=?)/) {
				$bval = $1 + 0;
			}

			next unless defined $bval;

			# --------------------------------------------------
			# Skip value boundaries that are about internal
			# data structure sizes rather than argument values.
			# Patterns like scalar(keys %hash) == 0 are testing
			# the size of an internal hash, not an argument, so
			# adding these values to edge_case_array would pass
			# them as argument values which is meaningless.
			# --------------------------------------------------
			next if $source =~ /\bkeys\s+%/;
			next if $source =~ /scalar\s*\(\s*keys\b/;

			for my $v ($bval - 1, $bval, $bval + 1) {
				# Clamp to 0 for non-negative contexts such as
				# scalar(), length(), index() return values
				next if $v < 0 && $source =~ /\b(?:scalar|length|index)\b/;
				push @{ $survivors_by_mod_func{$key}{values} }, $v;
			}
		}
	}

	# --------------------------------------------------
	# Scan t/conf/ for existing YAML schema files
	# --------------------------------------------------
	opendir(my $dh, $conf_dir)
		or do { warn "Cannot read $conf_dir: $!\n"; return 0 };

	my @schema_files = grep {
		# Include only .yml files that are not already
		# fuzz-augmented schemas from a previous run
		/\.yml$/ && !/^mutant_fuzz_/
	} readdir($dh);

	closedir $dh;

	if($config{verbose}) {
		printf "Found %d candidate schema file(s) in %s\n",
			scalar(@schema_files), $conf_dir;
	}

	# --------------------------------------------------
	# Process each candidate schema file
	# --------------------------------------------------
	for my $schema_file (sort @schema_files) {
		my $schema_path = "$conf_dir/$schema_file";

		# Load the existing schema — skip if unreadable or malformed
		my $schema = eval { YAML::XS::LoadFile($schema_path) };
		if($@ || !$schema || ref $schema ne 'HASH') {
			warn "Cannot load schema $schema_path: $@" if $@;
			next;
		}

		# Extract module and function from the schema.
		# Both are required to match against survivors.
		my $mod  = $schema->{module}   // '';
		my $func = $schema->{function} // '';

		unless($mod && $func) {
			print "  Skipping $schema_file: missing module or function\n"
				if $config{verbose};
			next;
		}

		# Look up matching survivors for this module+function pair
		my $key      = "$mod\0$func";
		my $survivor = $survivors_by_mod_func{$key};

		# Skip this schema if no matching survivors exist at all
		unless($survivor &&
		       (($survivor->{values} && @{$survivor->{values}}) ||
		        ($survivor->{arity}  && @{$survivor->{arity}}))) {
			print "  Skipping $schema_file: no matching NUM_BOUNDARY survivors\n" if $config{verbose};
			next;
		}

		# Separate value boundaries from arity boundaries
		my $bvals = $survivor->{values} || [];
		my $arity_hints = $survivor->{arity}  || [];

		# --------------------------------------------------
		# Skip writing a fuzz schema if the only augmentation
		# is arity boundary cases and there are no value
		# boundary additions. Arity cases do not benefit from
		# random string fuzzing — the cases entries alone are
		# sufficient to exercise the boundary, and random
		# string fuzzing will only produce meaningless
		# file-not-found or type-error deaths that obscure
		# the real boundary condition.
		# --------------------------------------------------
		unless(@{$bvals}) {
			print "  Skipping $schema_file: only argument-count boundaries found, no value boundaries to fuzz\n" if $config{verbose};
			next;
		}

		# --------------------------------------------------
		# Determine which edge key to use for augmentation.
		# Option B: respect what the schema already has,
		# falling back to _boundary_edge_case_key detection.
		# --------------------------------------------------
		my ($edge_key, $numeric_params);

		if(exists $schema->{edge_case_array}) {
			# Schema already uses positional edge cases
			$edge_key = 'edge_case_array';
			$numeric_params = [];
		} elsif(exists $schema->{edge_cases}) {
			# Schema already uses named edge cases
			$edge_key = 'edge_cases';

			# Collect existing numeric param names from edge_cases
			$numeric_params = [ keys %{ $schema->{edge_cases} } ];
		} else {
			# Neither key exists yet — detect from schema structure
			($edge_key, $numeric_params) = _boundary_edge_case_key($schema);
		}

		# --------------------------------------------------
		# Make a deep copy of the schema so we never modify
		# the original data structure in memory
		# --------------------------------------------------
		require Storable;
		my $augmented = Storable::dclone($schema);

		# --------------------------------------------------
		# Merge boundary values into the appropriate key,
		# deduplicating against any values already present
		# --------------------------------------------------
		if($edge_key eq 'edge_case_array') {
			# Build a dedup set from existing values
			my %existing = map { $_ => 1 }
				@{ $augmented->{edge_case_array} || [] };

			# Add new boundary values not already present
			for my $v (@{$bvals}) {
				push @{ $augmented->{edge_case_array} }, $v
					unless $existing{$v}++;
			}
		} else {
			# Named parameter style — add to each numeric param.
			# If no numeric params were found, use all params
			# that exist in edge_cases already
			my @targets = @{$numeric_params};

			unless(@targets) {
				# Fall back to input params of numeric type
				for my $name (keys %{ $schema->{input} || {} }) {
					my $p = $schema->{input}{$name};
					next unless ref $p eq 'HASH';
					push @targets, $name
						if ($p->{type} // '') =~ /^(integer|number|float)$/;
				}
			}

			for my $param (@targets) {
				my %existing = map { $_ => 1 }
					@{ $augmented->{edge_cases}{$param} || [] };

				# Merge in new boundary values, deduplicating
				for my $v (@{$bvals}) {
					push @{ $augmented->{edge_cases}{$param} }, $v
						unless $existing{$v}++;
				}
			}
		}
		# --------------------------------------------------
		# Arity boundary cases: generate cases entries that
		# call the function with too few or too many args.
		# For each arity boundary (e.g. scalar(@_) <= 1),
		# we add:
		#   - a DIES case with count-1 args (too few)
		#   - a LIVES case with count+1 args (enough)
		# We use undef as a placeholder arg value since we
		# don't know what valid args look like beyond what
		# the schema already specifies.
		# --------------------------------------------------
		if(@{$arity_hints}) {
			$augmented->{cases} ||= {};

			for my $hint (@{$arity_hints}) {
				my ($op, $count) = @{$hint}{qw(op count)};

				# Determine which arg counts should die and
				# which should live, based on the operator.
				# e.g. scalar(@_) <= 1 means:
				#   0 args -> dies (too few)
				#   1 arg  -> dies (still too few, boundary)
				#   2 args -> lives (enough args)
				my ($die_count, $live_count);

				if($op eq '<=' || $op eq '<') {
					# Dies when arg count is at or below boundary
					$die_count  = $op eq '<=' ? $count : $count - 1;
					$live_count = $count + 1;
				} elsif($op eq '>=' || $op eq '>') {
					# Dies when arg count is at or above boundary
					$die_count  = $op eq '>=' ? $count : $count + 1;
					$live_count = $count - 1;
				} elsif($op eq '==' ) {
					# Dies when arg count equals boundary exactly
					$die_count  = $count;
					$live_count = $count + 1;
				} else {
					next;
				}

				# Add a DIES case for the too-few-args scenario.
				# Label includes the arg count so multiple arity
				# boundaries on the same function don't collide.
				my $die_label  = "arity_dies_${die_count}_args";
				my $live_label = "arity_lives_${live_count}_args";

				# Build placeholder input list — undef args,
				# since we only care about the count here
				my @die_inputs  = (undef) x $die_count;
				my @live_inputs = (undef) x $live_count;

				# Only add the DIES case — the live case with
				# undef placeholder args causes generated test
				# code to fail to compile since App::Test::Generator
				# cannot know how to call the function meaningfully
				# with placeholder arguments
				$augmented->{cases}{$die_label} = {
					input   => \@die_inputs,
					_STATUS => 'DIES',
				} unless exists $augmented->{cases}{$die_label};

				# Skip the live case — undef placeholders produce
				# uncompilable generated test code
				# $augmented->{cases}{$live_label} = {
					# input   => \@live_inputs,
					# _STATUS => 'OK',
				# } unless exists $augmented->{cases}{$live_label};
			}
		}

		# --------------------------------------------------
		# Build the output filename using the timestamp and
		# function name, safe for use as a filesystem path
		# --------------------------------------------------
		(my $safe_func = $func) =~ s/[^A-Za-z0-9]/_/g;
		my $out_name = "mutant_fuzz_${timestamp}_${safe_func}.yml";
		my $out_path = "$conf_dir/$out_name";

		# Skip if this exact file already exists —
		# same guard used by _generate_mutant_tests
		if(-f $out_path) {
			print "  Skipping $out_name: already exists\n"
				if $config{verbose};
			next;
		}

		# Serialise the augmented schema to a normalised YAML string
		my $yaml = _dump_schema_yaml($augmented);
		if(!defined $yaml) {
			warn "YAML serialisation failed for $out_path";
			next;
		}

		# Write the augmented schema file
		open(my $fh, '>:encoding(UTF-8)', $out_path)
			or do { warn "Cannot write $out_path: $!\n"; next };
		print $fh $yaml;
		close $fh;

		$written++;

		print "  Generated fuzz schema: $out_path\n"
			if $config{verbose};
	}

	# Report summary of what was written
	printf "Generated %d fuzz schema file(s) in %s\n",
		$written, $conf_dir
		if $config{verbose};

	return $written;
}

# Mutant helpers from App::Test::Generator::Report::HTML

# --------------------------------------------------
# _mutation_index
#
# Purpose:    Build the HTML mutation report section
#             for the main dashboard page. Produces
#             the mutation summary (score, totals),
#             the per-file mutation files table with
#             TER1/TER2/TER3 badges, and the
#             structural coverage and executive
#             summary blocks.
#
# Entry:      $data          - decoded mutation JSON
#                              hashref (score, total,
#                              killed, survived)
#             $files         - hashref of file =>
#                              { killed => [], survived => [] }
#                              as produced by _group_by_file
#             $coverage_data - decoded Devel::Cover JSON
#                              hashref, or undef
#             $lcsaj_dir     - root directory for LCSAJ
#                              .json files, or undef
#             $lcsaj_hits    - hashref of LCSAJ hit data
#                              as produced by the runtime
#                              debugger, or undef
#
# Exit:       Returns an arrayref of HTML strings
#             ready to be pushed onto @html.
#             Never returns undef.
#
# Notes:      TER1 and TER2 are sourced from
#             Devel::Cover via _coverage_for_file.
#             TER3 is sourced from LCSAJ runtime data
#             via _lcsaj_coverage_for_file.
#             All three are normalised to lib/ paths
#             at display time — neither data source
#             is modified.
#             The table is sorted worst-score-first
#             so the files most needing attention
#             appear at the top.
# --------------------------------------------------
sub _mutation_index {
	my ($data, $files, $coverage_data, $lcsaj_dir, $lcsaj_hits) = @_;

	my @html;

	# print $out _header('Mutation Report');
	push @html, '<h2>Mutation Report</h2>';

	push @html, '<h3>Mutation Summary</h3>';
	push @html, '<ul>';
	push @html, "<li><b>Score</b>: $data->{score}%</li>";
	push @html, "<li><b>Total</b>: $data->{total}</li>";
	push @html, '<li><b>Killed</b>: ', scalar(@{$data->{killed} || []}), '</li>';
	push @html, '<li><b>Survived</b>: ', scalar(@{$data->{survived} || []}), '</li>';
	push @html, '</ul>';

	push @html, "<h3>Mutation Files</h3>\n";
	push @html, "<table border='1' cellpadding='5'>\n";

	# Column headers for the mutation files table.
	# TER3 = Third level Test Effectiveness Ratio (LCSAJ path coverage).
	# Only shown when lcsaj_root is configured.
	if($config{lcsaj_root}) {
		push @html, "<tr><th>File</th><th>Total</th><th>Killed</th><th>Survivors</th><th>Score%</th><th>Complexity</th><th title=\"TER1=Statement, TER2=Branch, TER3=LCSAJ Path\">TER1 / TER2 / TER3</th></tr>\n";
	} else {
		push @html, "<tr><th>File</th><th>Total</th><th>Killed</th><th>Survivors</th><th>Score%</th><th>Complexity</th></tr>\n";
	}

	for my $file (
		sort { _file_score($files->{$a}) <=> _file_score($files->{$b}) || $a cmp $b } keys %$files
	) {
		my $killed = scalar @{ $files->{$file}{killed} || [] };
		my $survived = scalar @{ $files->{$file}{survived} || [] };
		my $total = $killed + $survived;

		my $score = $total ? sprintf('%.2f', ($killed / $total) * 100) : 0;

		my $badge_class = $score >= $config{med_threshold} ? 'badge-good'
					: $score >= $config{low_threshold} ? 'badge-warn'
					: 'badge-bad';

		my $tooltip = $score >= $config{med_threshold} ? 'Excellent'
				 : $score >= $config{low_threshold} ? 'Moderate'
				 : 'Needs improvement';

		my $row_class = $score >= $config{med_threshold} ? 'high'
			: $score >= $config{low_threshold} ? 'med'
			: 'low';

		my $badge_html = sprintf(
			'<span class="coverage-badge %s" title="%s">%.1f%%</span>',
			$badge_class, $tooltip, $score
		);
		my $html_file = "mutation_html/$file.html";

		my $source_url = $github_base . $file;
		my $source_link = $total
			? sprintf('<a href="%s" class="icon-link" title="View source on GitHub">&#128269;</a>', $source_url)
			: '<span class="disabled-icon" title="No coverage data">&#128269;</span>';

		# --------------------------------------------------
		# Calculate cyclomatic complexity for the file
		# --------------------------------------------------
		my $complexity = _cyclomatic_complexity($file);

		my $complexity_class = $complexity >= $config{med_threshold} ? 'badge-bad'
					: $score >= $config{low_threshold} ? 'badge-warn'
					: 'badge-good';
		my $complexity_tooltip = $complexity >= $config{med_threshold} ? 'Good'
				 : $complexity >= $config{low_threshold} ? 'Medium'
				 : 'Bad';

		my $complexity_html = sprintf(
			'<span class="coverage-badge %s" title="%s">%d</span>',
			$complexity_class, $complexity_tooltip, $complexity
		);

		# Try each candidate directory in turn, most-specific first.
		# _lcsaj_coverage_for_file returns (undef, undef) when the
		# .lcsaj.json file cannot be found, so we keep trying until
		# we get a defined result or exhaust all candidates.
		my ($lcsaj_cov, $lcsaj_total);
		for my $dir ($config{lcsaj_root}, $config{mutation_dir} . '/lib', $config{mutation_dir}) {
			next unless $dir;
			($lcsaj_cov, $lcsaj_total) = _lcsaj_coverage_for_file($file, $dir, $lcsaj_hits, \@html);
			last if defined $lcsaj_cov;
		}

		# --------------------------------------------------
		# Compute TER1/TER2/TER3 triple for this file.
		# TER1 = statement coverage  (Devel::Cover)
		# TER2 = branch coverage     (Devel::Cover)
		# TER3 = LCSAJ path coverage (LCSAJ runtime)
		# Paths normalised to lib/ at display time —
		# neither data source is modified.
		# --------------------------------------------------
		my ($ter1_pct, $ter2_pct);

		if(my $file_cov = _coverage_for_file($coverage_data, $file)) {
			my $stmt_total   = $file_cov->{statement}{total}   || 0;
			my $stmt_hit     = $file_cov->{statement}{covered} || 0;
			my $branch_total = $file_cov->{branch}{total}      || 0;
			my $branch_hit   = $file_cov->{branch}{covered}    || 0;

			$ter1_pct = $stmt_total ? ($stmt_hit / $stmt_total) * 100 : undef;

			$ter2_pct = $branch_total ? ($branch_hit / $branch_total) * 100 : undef;
		}

		# TER3 — LCSAJ path coverage (existing logic, unchanged)
		($lcsaj_cov, $lcsaj_total) = (undef, undef);
		for my $dir ($config{lcsaj_root}, $config{mutation_dir} . '/lib', $config{mutation_dir}) {
			next unless $dir;
			($lcsaj_cov, $lcsaj_total) = _lcsaj_coverage_for_file($file, $dir, $lcsaj_hits, \@html);
			last if defined $lcsaj_cov;
		}

		my $ter3_pct = (!defined $lcsaj_cov)  ? undef :
			(!$lcsaj_total)        ? undef :
			($lcsaj_cov / $lcsaj_total) * 100;

		# --------------------------------------------------
		# Render each component as a colour-coded badge,
		# falling back to a grey n/a badge if unavailable.
		# --------------------------------------------------
		my $ter_cell;
		if($lcsaj_dir) {
			my $ter1_badge = _ter_badge($ter1_pct, 'n/a');
			my $ter2_badge = _ter_badge($ter2_pct, 'n/a');
			my $ter3_badge = _ter_badge($ter3_pct, 'n/a');
			$ter_cell = "$ter1_badge / $ter2_badge / $ter3_badge";
		} else {
			# LCSAJ not configured — show TER1/TER2 only
			my $ter1_badge = _ter_badge($ter1_pct, 'n/a');
			my $ter2_badge = _ter_badge($ter2_pct, 'n/a');
			$ter_cell = "$ter1_badge / $ter2_badge";
		}

		push @html, sprintf(
			qq{<tr class="%s"><td><a href="%s" title="View mutation line by line" target="_blank">%s</a> %s</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td><td>%s</td><td>%s</td></tr>},
			$row_class,
			$html_file,
			$file,
			$source_link,
			$total,
			$killed,
			$survived,
			$badge_html,
			$complexity_html,
			$ter_cell,
		);
	}

	push @html, "</table>\n";

	# --------------------------------------------------
	# Structural Coverage Summary (if provided)
	# --------------------------------------------------
	if ($coverage_data) {
		my ($stmt_total, $stmt_hit, $branch_total, $branch_hit) = _coverage_totals($coverage_data);

		my $stmt_pct = $stmt_total ? sprintf('%.2f', ($stmt_hit / $stmt_total) * 100) : 0;

		my $branch_pct = $branch_total ? sprintf('%.2f', ($branch_hit / $branch_total) * 100) : 0;

		push @html, "<h2>Structural Coverage (Approximate)</h2>";
		push @html, "<div class='summary'>";
		push @html, "Statement Coverage: $stmt_pct% ($stmt_hit / $stmt_total)<br>";
		push @html, "Branch Coverage: $branch_pct% ($branch_hit / $branch_total)<br>";
		push @html, '<em>Approximate LCSAJ derived from branch and statement coverage.</em>';
		push @html, '</div>';

		# --------------------------------------------------
		# Executive summary
		# Statement coverage shows how much code runs.
		# Mutation score shows how well tests detect faults.
		# --------------------------------------------------
		push @html, '<h2>Executive Summary</h2>';
		push @html, "<div class='summary'>";
		push @html, "Tests execute $stmt_pct% of the code, but detect only $data->{score}% of injected faults.";
		push @html, '</div>';
	}

	# print $out _footer();

	return \@html;
}

sub _file_score {
	my $file_data = $_[0];

	my $killed = scalar @{ $file_data->{killed} || [] };
	my $survived = scalar @{ $file_data->{survived} || [] };
	my $total = $killed + $survived;

	return $total ? ($killed / $total) * 100 : 0;
}

# --------------------------------------------------
# _ter_badge
#
# Purpose:    Format a single TER percentage value as
#             a colour-coded HTML badge, consistent
#             with the coverage badge style used
#             elsewhere in the dashboard.
#
# Entry:      $pct   - percentage value (0-100), or
#                      undef if data is unavailable
#             $label - fallback text to display when
#                      $pct is undef (e.g. 'n/a')
#
# Exit:       Returns an HTML span string. Never
#             returns undef.
#
# Side effects: None.
#
# Notes:      Thresholds are taken from %config:
#               >= med_threshold -> green (badge-good)
#               >= low_threshold -> yellow (badge-warn)
#               <  low_threshold -> red (badge-bad)
#             Undef input produces a grey badge with
#             title="No data".
# --------------------------------------------------
sub _ter_badge {
	my ($pct, $label) = @_;

	unless(defined $pct) {
		return qq{<span class="coverage-badge" style="background-color:#999" title="No data">$label</span>};
	}

	my ($class, $tooltip) =
		$pct >= $config{med_threshold} ? ('badge-good', 'Excellent') :
		$pct >= $config{low_threshold} ? ('badge-warn', 'Moderate')  :
						 ('badge-bad',  'Needs improvement');

	return sprintf(
		'<span class="coverage-badge %s" title="%s">%.1f%%</span>',
		$class, $tooltip, $pct
	);
}

# --------------------------------------------------
# Group mutants by file
# --------------------------------------------------

sub _group_by_file {
	my $data = $_[0];

	my %files;

	for my $status (qw(survived killed)) {
		next unless $data->{$status};

		for my $m (@{ $data->{$status} }) {
			next unless ref $m;
			next unless defined $m->{file};

			push @{ $files{ $m->{file} }{$status} }, $m;
		}
	}

	return \%files;
}

# --------------------------------------------------
# Write per-file report with heatmap
# --------------------------------------------------
sub _mutant_file_report {
	my (
		$dir,
		$file,
		$mutants,
		$prev,
		$next,
		$coverage_data,
		$lcsaj_dir,
		$lcsaj_hits
	) = @_;

	return unless -f $file;

	open my $in, '<', $file or return;
	my @lines = <$in>;
	close $in;

	my $filename = $file;
	$filename =~ s{[\\/]}{_}g;

	# Preserve directory structure inside report
	my $relative_path = File::Spec->catfile($dir, $file . '.html');

	my $out_dir = File::Basename::dirname($relative_path);

	make_path($out_dir) unless -d $out_dir;

	open my $out, '>', $relative_path or die "$relative_path: $!";

	print $out _mutant_file_header("File: $file");

	print $out "<h1>$file</h1>\n";

	# Navigation bar
	print $out qq{<div class="nav">};
	if ($prev) {
		my $link = _relative_link($file, $prev);
		print $out qq{<a href="$link">⬅ Previous</a> };
	}

	# Calculate depth of $file within lib/ to build correct relative path back to index.html
	# $file is something like lib/CGI/Info.pm or lib/App/Test/Generator.pm
	(my $rel = $file) =~ s{^lib/}{};
	my @parts = File::Spec->splitdir($rel);
	my $depth = scalar(@parts) - 1;  # subdirs only, exclude filename
	my $ups = '../' x ($depth + 2);  # +2 for lib/ and mutation_html/
	my $index_link = "${ups}index.html";

	print $out qq{<a href="$index_link">Index</a>\n};

	if ($next) {
		my $link = _relative_link($file, $next);
		print $out qq{ <a href="$link">Next ➡</a>};
	}
	print $out qq{</div>};

	# --------------------------------------------------
	# File-level structural coverage (if available)
	# --------------------------------------------------
	if ($coverage_data) {
		if(my $file_cov = _coverage_for_file($coverage_data, $file)) {
			my $stmt_total = $file_cov->{statement}{total} || 0;
			my $stmt_hit = $file_cov->{statement}{covered} || 0;

			my $branch_total = $file_cov->{branch}{total} || 0;
			my $branch_hit = $file_cov->{branch}{covered} || 0;

			my $stmt_pct = $stmt_total ? sprintf('%.2f', ($stmt_hit / $stmt_total) * 100) : 0;

			my $branch_pct = $branch_total ? sprintf('%.2f', ($branch_hit / $branch_total) * 100) : 0;

			my $approx_lcsaj = $branch_total + 1;

			# Compute TER3 (LCSAJ path coverage) for this file if data is available.
			# TER3 = covered_paths / total_paths * 100
			my ($lcsaj_cov, $lcsaj_total) = _lcsaj_coverage_for_file(
				$file, $lcsaj_dir, $lcsaj_hits, []
			);
			my $ter3_str;
			if (!defined $lcsaj_cov) {
				# .lcsaj.json not found — TER3 unavailable for this file
				$ter3_str = 'n/a';
			} elsif (!$lcsaj_total) {
				# File found but no paths defined
				$ter3_str = '-';
			} else {
				# Format as percentage with raw fraction for clarity
				$ter3_str = sprintf('%.1f%% (%d/%d)',
					($lcsaj_cov / $lcsaj_total) * 100,
					$lcsaj_cov,
					$lcsaj_total
				);
			}

			# Display TER1/TER2/TER3 coverage metrics in the summary block.
			# TER1 = statement, TER2 = branch, TER3 = LCSAJ path coverage.
			print $out "<div class='summary'>\n";
			print $out "<strong>Structural Coverage (Approximate)</strong><p>\n";
			print $out "TER1 (Statement): $stmt_pct%<br>\n";
			print $out "TER2 (Branch): $branch_pct%<br>\n";
			print $out "TER3 (LCSAJ): $ter3_str<br>\n";
			print $out "Approximate LCSAJ segments: $approx_lcsaj<br>\n";
			print $out "</div>\n";

			print $out qq{
    <div class="legend">
        <h3>LCSAJ Legend</h3>

        <p>
        <span class="lcsaj-dot">●</span>
        <b>Covered</b> — this LCSAJ path was executed during testing.
        </p>

        <p>
        <span class="lcsaj-dot-uncovered">●</span>
        <b>Not covered</b> — this LCSAJ path was never executed. These are the paths to focus on.
        </p>

        <p>
        Multiple dots on a line indicate that multiple control-flow paths begin at that line.
        Hovering over any dot shows:
        </p>

        <pre>
        start → end → jump
        </pre>

        <ul>
        <li><b>start</b> – first line of the linear sequence</li>
        <li><b>end</b> – last line before control flow changes</li>
        <li><b>jump</b> – line execution jumps to next</li>
        </ul>

        <p>
        Uncovered paths show <b>[NOT COVERED]</b> in the tooltip.
	</p>
    </div>
};
		}
	}

	# --------------------------------------------------
	# Legend explaining line colours
	# --------------------------------------------------
	print $out qq{
		<div class="legend">
			<h3>Mutant Testing Legend</h3>
			<span class="legend-box survived-1"></span> Survived (tests missed this)
			<span class="legend-box killed"></span> Killed (tests detected this)
			<span class="legend-box none"></span> No mutation
		</div>
	};

	my %survived_by_line;
	my %killed_by_line;

	for my $m (@{ $mutants->{survived} || [] }) {
		next unless defined $m->{line};
		push @{ $survived_by_line{ $m->{line} } }, $m;
	}

	for my $m (@{ $mutants->{killed} || [] }) {
		next unless defined $m->{line};
		push @{ $killed_by_line{ $m->{line} } }, $m;
	}

	print $out "<pre>\n";

	my %lcsaj_by_line;

	# Pre-compute normalised hit map for this file so we can
	# colour LCSAJ dots covered/uncovered when building lcsaj_by_line
	my $norm = $file;
	$norm =~ s{^.*/blib/lib/}{lib/};
	$norm =~ s{^.*/lib/}{lib/};
	my $file_hits = $lcsaj_hits
		? (   $lcsaj_hits->{$norm}
		// $lcsaj_hits->{ abs_path($file) // $file }
		// {} )
		: {};

	if ($lcsaj_hits) {
		# Normalize the filename so it matches debugger paths
		$file = abs_path($file) if defined $file;

		my $base = basename($file);

		# convert absolute path to lib-relative path
		my $rel = $file;
		$rel =~ s{.*?/lib/}{};

		my $lcsaj_file = File::Spec->catfile(
			$lcsaj_dir,
			"$rel.lcsaj",
			"$base.lcsaj.json"
		);

		# warn "LCSAJ DEBUG\n";
		# warn "  file = $file\n";
		# warn "  base = $base\n";
		# warn "  lcsaj_dir = $lcsaj_dir\n";
		# warn "  lookup = $lcsaj_file\n";
		# warn "  exists = " . (-f $lcsaj_file ? "YES" : "NO") . "\n";

		if (-f $lcsaj_file) {
			open my $fh, '<', $lcsaj_file;
			my $paths = decode_json(do { local $/; <$fh> });
			close $fh;

			for my $p (@{ $paths || [] }) {
				next unless ref $p eq 'HASH';

				my $start = $p->{start};
				my $end   = $p->{end};
				my $jump  = $p->{jump} // $p->{target};

				next unless defined $start && defined $end;

				# Check if any line in the path range was hit
				my $covered = 0;
				for my $line ($start .. $end) {
					if ($file_hits->{$line}) {
						$covered = 1;
						last;
					}
				}

				push @{ $lcsaj_by_line{$start} }, {
					start   => $start,
					end     => $end,
					jump    => $jump,
					covered => $covered,
				};
			}
		}
	}

	for my $i (0 .. $#lines) {
		my $line_no = $i + 1;
		my $content = encode_entities($lines[$i]);

		# --------------------------------------------------
		# Determine mutation status for this line
		# --------------------------------------------------

		my $survivor_count = scalar @{ $survived_by_line{$line_no} || [] };
		my $killed_count = scalar @{ $killed_by_line{$line_no} || [] };

		my $class = '';
		my $tooltip;

		# -----------------------------
		# Survived mutations (red shades)
		# -----------------------------
		if ($survivor_count) {
			# Assign intensity class based on number of survivors
			if ($survivor_count == 1) { $class = 'survived-1'; }
			elsif ($survivor_count == 2) { $class = 'survived-2'; }
			else { $class = 'survived-3'; }

			# Collect smart advice per mutation type
			my %unique_advice;

			for my $m (@{ $survived_by_line{$line_no} }) {
				my $advice = _mutation_advice($m);
				$unique_advice{$advice} = 1 if $advice;
			}

			$tooltip = join(' ', keys %unique_advice);
		} elsif ($killed_count) {
			# -----------------------------
			# Killed mutations (green)
			# -----------------------------
			$class = 'killed';
			$tooltip = "Mutations here were killed. Tests are effectively covering this logic.";
		}

		# --------------------------------------------------
		# Render the line with colour + optional tooltip
		# Render LCSAJ markers for this line
		# --------------------------------------------------

		my $lcsaj_marker = '';

		if (my $paths = $lcsaj_by_line{$line_no}) {
			for my $p (@$paths) {
				my $start     = $p->{start};
				my $end       = $p->{end};
				my $jump      = $p->{jump} // 0;
				my $dot_class = $p->{covered} ? 'lcsaj-dot' : 'lcsaj-dot-uncovered';
				my $prefix    = $p->{covered} ? '' : '[NOT COVERED] ';

				$lcsaj_marker .= qq{<span class="lcsaj-tip"><span class="$dot_class">●</span><span class="lcsaj-tip-text">${prefix}$start → $end → $jump</span></span>};
			}
		}

		# Add tooltip class only if tooltip text exists
		my $extra_class = $tooltip ? ' tooltip' : '';

		# Escape tooltip text for HTML safety
		$tooltip =~ s/"/&quot;/g if $tooltip;

		my $tooltip_attr = $tooltip ? qq{ data-tooltip="$tooltip"} : '';

		print $out qq{<span class="$class$extra_class"$tooltip_attr>};
		print $out $lcsaj_marker, sprintf('%5d: %s', $line_no, $content);

		# --------------------------------------------------
		# Build expandable mutant details for this line
		# --------------------------------------------------

		my @line_mutants;

		push @line_mutants, @{ $survived_by_line{$line_no} || [] };
		push @line_mutants, @{ $killed_by_line{$line_no} || [] };

		my $details = '';

		if (@line_mutants) {
			# Count totals for summary label
			my $killed = scalar @{ $killed_by_line{$line_no} || [] };
			my $total = scalar @line_mutants;

			# Create expandable section
			if(my $survived = scalar @{ $survived_by_line{$line_no} || [] }) {
				$details = qq{
					<details class="mutant-details">
					<summary>Mutants (Total: $total, Killed: $killed, Survived: $survived)</summary>
					<ul>
				};

				for my $m (@line_mutants) {
					if($m->{status} eq 'Survived') {
						my $id = $m->{id} // 'unknown';
						my $type = $m->{type} // '';
						my $description = $m->{description} // '';

						$details .= "<li><b>$id: $description</b><br>";
						$details .= "$m->{difficulty}: $m->{hint}\n";

						# Show mutation type if available
						if ($type) {
							$details .= " ($type)";
						}

						if(my $suggest = _suggest_test($m)) {
							$suggest = encode_entities($suggest);
							$details .= qq{
								<div class="suggested-test">
								<div class="suggest-label">🧪 Suggested Test</div>
								<pre>$suggest</pre>
								</div>
							};
						}

						$details .= '</li>';
					}
				}

				$details .= "</ul></details>\n";
			} else {
				$details = "<p> <b> Mutants (Total: $total, Killed: $killed, Survived: 0)</b><p>";
			}
		}

		print $out "</span>$details";
	}

	print $out "</pre>\n";

	print $out _mutant_file_footer();

	close $out;
}

# --------------------------------------------------
# Generate smart advisory text based on mutation type
# --------------------------------------------------
sub _mutation_advice {
	my $mutant = $_[0];

	# Determine mutation type
	# Prefer explicit type field if present
	my $type = $mutant->{type};

	# Fallback: infer from ID prefix
	if (!$type && $mutant->{id}) {
		($type) = $mutant->{id} =~ /^([A-Z_]+)/;
	}

	# Default advice
	return 'Tests did not detect this behavioural change. Consider adding assertions.' unless $type;

	# Advice per mutation type
	return 'Boundary mutation survived. Add tests around edge values (e.g. min, max, off-by-one).' if $type =~ /NUM|BOUNDARY/;

	return 'Return value mutation survived. Add tests asserting exact return values.' if $type =~ /RETURN/;

	return 'Boolean logic mutation survived. Add tests covering both true and false paths.' if $type =~ /BOOL|NEGATION/;

	return 'Comparison mutation survived. Verify equality and inequality cases explicitly.' if $type =~ /COMPARE|EQUAL/;

	return 'Mutation survived. Add targeted tests to validate this branch.'
}

sub _suggest_test {
	my $m = $_[0];

	# ---------------------------------------------------------
	# Determine mutation type
	# ---------------------------------------------------------

	# Prefer explicit type if present
	my $type = $m->{type};

	# Fallback: infer from ID prefix
	if((!$type || (length($type) == 0)) && $m->{id}) {
		($type) = $m->{id} =~ /^([A-Z_]+)/;
	}

	# my $orig = $m->{original} // '';
	# my $new = $m->{transform} // '';

	# ---------------------------------------------------------
	# Boundary condition mutation
	# ---------------------------------------------------------

	if ($type && $type =~ /NUM|BOUNDARY/) {
		return <<"TEST";
# Boundary test suggestion
is( func(VALUE_AT_BOUNDARY), EXPECTED, 'Test boundary behaviour' );
TEST
	}

	# ---------------------------------------------------------
	# Boolean mutation
	# ---------------------------------------------------------

	if ($type && $type =~ /BOOL|NEGATION/) {
		return <<"TEST";
# Boolean branch test suggestion
ok( !func(INPUT), 'Verify boolean branch behaviour' );
TEST
	}

	# ---------------------------------------------------------
	# Return value mutation
	# ---------------------------------------------------------

	if ($type && $type =~ /RETURN/) {
		return <<"TEST";
# Return value assertion
is( func(INPUT), EXPECTED, 'Verify correct return value' );
TEST
	}

	return;
}

sub _survivor_class {
	my $count = $_[0];

	return 'survived-1' if $count == 1;
	return 'survived-2' if $count == 2;
	return 'survived-3' if $count >= 3;

	return 'survived';
}

# --------------------------------------------------
# Compute relative link between two files
# --------------------------------------------------
sub _relative_link {
	my ($from, $to) = @_;

	# Convert both to .html filenames
	$from .= '.html';
	$to .= '.html';

	# Use File::Spec to compute correct relative path
	return File::Spec->abs2rel($to, File::Basename::dirname($from));
}

sub _mutant_file_header {
	return qq{
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>

/* --------------------------------------------------
   CSS Variables (Light Mode Default)
-------------------------------------------------- */

:root {
    --bg: #ffffff;
    --text: #000000;
    --table-header: #333;
    --table-header-text: #ffffff;

    --survived-1: #f8d7da;
    --survived-2: #f5b7b1;
    --survived-3: #ec7063;

    --killed: #d4edda;
    --border: #cccccc;
}

/* --------------------------------------------------
   Dark Mode Overrides
-------------------------------------------------- */

html[data-theme='dark'] {
    --bg: #1e1e1e;
    --text: #dddddd;
    --table-header: #222;
    --table-header-text: #ffffff;

    --survived-1: #5c2b2e;
    --survived-2: #7b2c2f;
    --survived-3: #a93226;

    --killed: #1e4620;
    --border: #555;
}

/* --------------------------------------------------
   Global Styles
-------------------------------------------------- */

body {
	font-family: sans-serif;
	background: var(--bg);
	color: var(--text);
}

table {
    border-collapse: collapse;
    width: 100%;
}

th {
    background: var(--table-header);
    color: var(--table-header-text);
}

.survived-1 { background-color: var(--survived-1); }
.survived-2 { background-color: var(--survived-2); }
.survived-3 { background-color: var(--survived-3); }

.killed { background-color: var(--killed); }

.legend {
    border: 1px solid #ccc;
    background: #fafafa;
    padding: 10px;
    margin: 15px 0;
    font-size: 0.9em;
}

.legend pre {
    background: #f4f4f4;
    padding: 5px;
}

.legend-box {
    display: inline-block;
    width: 16px;
    height: 16px;
    margin: 0 6px 0 20px;
    vertical-align: middle;
    border: 1px solid var(--border);
}

/* White box for non-mutated lines */
.legend-box.none {
	background-color: var(--bg);
}

/* --------------------------------------------------
   Suggested Test Box Styling
   Theme-aware and readable in light & dark modes
-------------------------------------------------- */

.suggested-test {
    margin-top: 6px;
    margin-bottom: 12px;

    /* Use theme variables instead of hardcoded colors */
    background: var(--bg);
    color: var(--text);

    padding: 8px;
    border-radius: 4px;

    /* Subtle border for visual separation */
    border: 1px solid var(--border);
}

/* Label styling */
.suggest-label {
    font-weight: bold;
    margin-bottom: 4px;
}

/* Ensure the test code block inherits readable colors */
.suggested-test pre {
    background: transparent;   /* Prevent nested dark blocks */
    color: inherit;            /* Match theme text color */
    margin: 0;
    font-family: monospace;
}

pre { line-height: 1.4; }

pre > details {
    margin: 0.2em 0;
}

pre > details:first-child {
    margin-top: 0;
}

pre > details:last-child {
    margin-bottom: 0;
}

pre details,
pre summary,
pre ul,
pre li {
    white-space: normal;
    margin: 0;
    padding: 0;
    line-height: 1.2;
}

.nav { margin-bottom: 1em; }

.toggle {
    float: right;
    cursor: pointer;
    padding: 6px 10px;
    border: 1px solid var(--border);
    border-radius: 4px;
}

/* Tooltip container */
.tooltip {
	position: relative;
	cursor: help;
}

/* Tooltip bubble */
.tooltip:hover::after {
    content: attr(data-tooltip);
    position: absolute;
    left: 0;
    top: 100%;
    background: var(--table-header);
    color: var(--table-header-text);
    padding: 6px 10px;
    white-space: normal;
    max-width: 300px;
    min-width: 30ch;
    font-size: 12px;
    border-radius: 6px;
    z-index: 1000;
    margin-left: 10ch;   /* move tooltip ~10 characters to the right */
}

.mutant-details {
	margin-left: 2em;
	font-size: 0.9em;
}

/* Indent the list of mutations that displays when expanding by 8 characters */
pre details.mutant-details ul {
	padding-left: 8ch;
	margin: 0.2em 0;
}

.mutant-details summary {
	cursor: pointer;
	font-weight: bold;
}

.lcsaj-dot {
    color: #5555ff;
    font-size: 10px;
    margin-right: 3px;
}

.lcsaj-dot-uncovered {
    color: #cc4444;
    font-size: 10px;
    margin-right: 3px;
}

.lcsaj-tip {
	position: relative;
	display: inline-block;
}

.lcsaj-tip .lcsaj-tip-text {
	visibility: hidden;
	background-color: #333;
	color: #fff;
	padding: 4px 8px;
	border-radius: 4px;
	font-size: 11px;
	white-space: nowrap;
	position: fixed;
	z-index: 9999;
	pointer-events: none;
}

.lcsaj-tip:hover .lcsaj-tip-text {
	visibility: visible;
}

</style>
</head>
<body>
<button class="toggle" onclick="toggleTheme()">🌙 Toggle Theme</button>
};
}

sub _mutant_file_footer {
	return qq{
<script>
function toggleTheme() {
    const html = document.documentElement;
    const current = html.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
}

(function() {
    const saved = localStorage.getItem('theme');
    if (saved) {
        document.documentElement.setAttribute('data-theme', saved);
    }
})();

document.addEventListener("mousemove", function(e) {
	document.querySelectorAll(".lcsaj-tip-text").forEach(function(tip) {
		tip.style.left = (e.clientX + 12) + "px";
		tip.style.top  = (e.clientY + 12) + "px";
	});
});
</script>
</body>
</html>
	};
}

# ------------------------------------------------------------
# _coverage_totals
#
# Extract structural coverage totals from a Devel::Cover JSON
# report. Returns four scalar values in list context:
#
#   ($statement_total, $statement_hit,
#    $branch_total,    $branch_hit)
#
# This matches how the routine is used elsewhere in this file.
#
# NOTE:
# Devel::Cover stores totals under:
#
#   $cov->{summary}->{Total}
#
# while per-file data appears under:
#
#   $cov->{summary}->{filename}
#
# This routine extracts only the aggregated totals.
# ------------------------------------------------------------

sub _coverage_totals
{
	my $cov = $_[0];

	# Defensive checks to avoid warnings
	return (0,0,0,0) unless $cov;
	return (0,0,0,0) unless ref $cov eq 'HASH';
	return (0,0,0,0) unless $cov->{summary};

	my $total = $cov->{summary}->{Total} || {};

	# Extract statement coverage
	my $stmt_total = $total->{statement}{total}   || 0;
	my $stmt_hit   = $total->{statement}{covered} || 0;

	# Extract branch coverage
	my $branch_total = $total->{branch}{total}   || 0;
	my $branch_hit   = $total->{branch}{covered} || 0;

	return ($stmt_total, $stmt_hit, $branch_total, $branch_hit);
}

# ------------------------------------------------------------
# _coverage_for_file
#
# Attempts to find coverage data for a given source file.
# Devel::Cover JSON keys may store paths relative to project
# root, so we try multiple match strategies.
# ------------------------------------------------------------
sub _coverage_for_file {
    my ($cov, $file) = @_;

    return unless $cov && $cov->{summary};
    my $summary = $cov->{summary};

    # 1. exact match (what worked before)
    return $summary->{$file} if exists $summary->{$file};

    require File::Basename;

    my $base = File::Basename::basename($file);

    # 2. basename match (what worked before)
    for my $k (keys %$summary) {
        next if $k eq 'Total';
        if (File::Basename::basename($k) eq $base) {
            return $summary->{$k};
        }
    }

    # 3. try lib/ relative path
    my $rel = $file;
    $rel =~ s{.*?/lib/}{lib/};

    return $summary->{$rel} if exists $summary->{$rel};

    # 4. NEW: try blib/lib version
    my $blib = "blib/$rel";
    return $summary->{$blib} if exists $summary->{$blib};

    return;
}

# ------------------------------------------------------------
# _cyclomatic_complexity
#
# Compute a simple cyclomatic complexity metric using PPI.
#
# Formula:
#   complexity = 1 + number_of_decision_points
#
# This is an approximation but works well for dashboards.
# ------------------------------------------------------------

sub _cyclomatic_complexity {
	my $file = $_[0];

	return 0 unless -f $file;

	require PPI;

	my $doc = PPI::Document->new($file);
	return 0 unless $doc;

	my $complexity = 1;

	# --------------------------------------------------
	# Control-flow keywords
	# --------------------------------------------------
	my $words = $doc->find('PPI::Token::Word') || [];

	foreach my $w (@$words) {
		my $c = $w->content;

		if ($c =~ /^(if|elsif|unless|while|for|foreach|until|when)$/) {
			$complexity++;
		}
	}

	# --------------------------------------------------
	# Logical operators (extra branches)
	# --------------------------------------------------
	my $ops = $doc->find('PPI::Token::Operator') || [];

	foreach my $op (@$ops) {
		my $c = $op->content;

		if ($c eq '&&' || $c eq '||' || $c eq '?') {
			$complexity++;
		}
	}

	return $complexity;
}

# ------------------------------------------------------------
# _lcsaj_coverage_for_file($file, $lcsaj_dir, $hits, $html)
#
# Look up LCSAJ path coverage for a single source file.
#
# Arguments:
#   $file      - path to the source file (relative or absolute)
#   $lcsaj_dir - root directory where .lcsaj.json files were written
#   $hits      - hashref of { normalised_path => { line => count } }
#                as produced by Devel::App::Test::Generator::LCSAJ::Runtime
#   $html      - arrayref to push HTML comments into (for diagnostics)
#
# Returns:
#   ($covered, $total)  - both defined if the .lcsaj.json was found
#   (undef, undef)      - if no .lcsaj.json could be located
#
# Path resolution strategy
# ------------------------
# The .lcsaj.json file path is derived by stripping the source tree
# prefix from $file to get a repo-relative name, then appending
# ".lcsaj.json" under $lcsaj_dir.  We try several prefix-strip
# strategies to cope with:
#
#   1. Standard layout:   lib/Foo/Bar.pm
#   2. Build tree:        blib/lib/Foo/Bar.pm  (same strip target)
#   3. Non-standard:      src/Foo/Bar.pm, or Bar.pm at repo root
#      -> falls back to basename only
#
# The $hits lookup also tries multiple key forms because Runtime.pm
# writes normalised lib-relative keys (e.g. "lib/Foo/Bar.pm") while
# callers may pass an absolute path or a blib-prefixed path.
# ------------------------------------------------------------

sub _lcsaj_coverage_for_file {
	my ($file, $lcsaj_dir, $hits, $html) = @_;

	# push @{$html}, "<!-- _lcsaj_coverage_for_file: dir=$lcsaj_dir file=$file -->";

	return (undef, undef) unless $lcsaj_dir && $hits && defined $file;

	# ----------------------------------------------------------
	# Resolve to an absolute path for reliable prefix stripping.
	# Keep the original argument too — we need it for $hits lookup.
	# ----------------------------------------------------------
	my $original = $file;
	my $abs      = abs_path($file) // $file;
	my $base     = basename($abs);

	# ----------------------------------------------------------
	# Build candidate relative paths to try, most-specific first:
	#   1. lib-relative  e.g.  Foo/Bar.pm          (strip .../lib/)
	#   2. basename only e.g.  Bar.pm              (last resort)
	# We deliberately do NOT include the leading "lib/" segment in
	# the .lcsaj.json path because the LCSAJ analyser is expected to
	# write files mirroring only the package-namespace portion of the
	# path (i.e. what comes *after* lib/).
	# ----------------------------------------------------------
	my @rel_candidates;

    if ($abs =~ m{(?:^|/)(?:blib/)?lib/(.+)$}) {
        push @rel_candidates, $1;               # e.g. Foo/Bar.pm
    }
    push @rel_candidates, $base                 # e.g. Bar.pm
        unless @rel_candidates && $rel_candidates[0] eq $base;

    # ----------------------------------------------------------
    # Search for the .lcsaj.json file using each candidate.
    # ----------------------------------------------------------
    my $lcsaj_file;

    for my $rel (@rel_candidates) {
	my $base = basename($rel);
	my $candidate = File::Spec->catfile(
		$lcsaj_dir,
		"$rel.lcsaj",
		"$base.lcsaj.json"
	);
	# push @{$html}, "<!-- _lcsaj_coverage_for_file: trying $candidate -->";

	if (-f $candidate) {
		$lcsaj_file = $candidate;
		# push @{$html}, "<!-- _lcsaj_coverage_for_file: found $candidate -->";
		last;
	}
    }

    return (undef, undef) unless defined $lcsaj_file;

    # ----------------------------------------------------------
    # Load the LCSAJ path definitions.
    # ----------------------------------------------------------
    open my $fh, '<', $lcsaj_file
        or do {
            # push @{$html}, "<!-- _lcsaj_coverage_for_file: cannot open $lcsaj_file: $! -->";
            return (undef, undef);
        };
    my $paths = decode_json(do { local $/; <$fh> });
    close $fh;

    my $total = scalar @{ $paths // [] };
    return (0, 0) unless $total;

    # ----------------------------------------------------------
    # Resolve which hit-map entry belongs to this file.
    # Runtime.pm writes keys as _normalize(abs_path(file)), which
    # produces "lib/Foo/Bar.pm".  Try several key forms so we match
    # regardless of what the caller passed in.
    # ----------------------------------------------------------
    my $norm_abs = $abs;
    $norm_abs =~ s{^.*/blib/lib/}{lib/};
    $norm_abs =~ s{^.*/lib/}{lib/};

    my $norm_orig = $original;
    $norm_orig =~ s{^.*/blib/lib/}{lib/};
    $norm_orig =~ s{^.*/lib/}{lib/};

    my $file_hits =
           $hits->{$norm_abs}           # "lib/Foo/Bar.pm"  (most likely)
        // $hits->{$norm_orig}          # same, from original arg
        // $hits->{$abs}               # absolute path (unusual)
        // $hits->{$original}          # raw arg as-is
        // {};

    # push @{$html}, "<!-- _lcsaj_coverage_for_file: hit key=$norm_abs hits=" . scalar(keys %$file_hits) . " -->";

    # ----------------------------------------------------------
    # Count how many LCSAJ paths had at least one line executed.
    # A path is considered covered if any line in [start..end]
    # appears in the hit map.
    # ----------------------------------------------------------
    my $covered = 0;

    for my $p (@{ $paths }) {
        next unless ref $p eq 'HASH';

        my $start = $p->{start};
        my $end   = $p->{end};
        next unless defined $start && defined $end;

        for my $line ($start .. $end) {
            if ($file_hits->{$line}) {
                $covered++;
                last;
            }
        }
    }

	return ($covered, $total);
}

# --------------------------------------------------
# _own_file_coverage_pct
#
# Compute average coverage percentage across only the
# project's own files in a Devel::Cover summary hashref,
# excluding Devel::Cover's pre-aggregated Total key and
# any absolute paths (installed CPAN modules) which
# would otherwise inflate the reported figure.
#
# Arguments:
#   $summary - hashref of Devel::Cover summary data
#
# Returns:
#   Average total coverage percentage, or undef if no
#   qualifying files found
# --------------------------------------------------
sub _own_file_coverage_pct {
	my ($summary) = @_;

	return undef unless $summary;

	my ($sum, $count) = (0, 0);
	for my $f (keys %$summary) {
		next if $f eq 'Total';
		next if $f =~ /^\//;	# skip absolute paths
		next unless $f =~ /^(?:lib|blib|bin)\//;	# only own project files
		$sum += $summary->{$f}{total}{percentage} // 0;
		$count++;
	}

	return $count ? $sum / $count : undef;
}
