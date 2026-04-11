package App::Test::Generator::Report::HTML;

use strict;
use warnings;
use autodie qw(:all);

use App::Test::Generator::LCSAJ;
use Cwd qw(abs_path);
use File::Basename qw(dirname basename);
use File::Path qw(make_path);
use File::Spec;
use JSON::MaybeXS;
use HTML::Entities;

our $VERSION = '0.31';

=head1 VERSION

Version 0.31

=head1 METHODS

=head2 generate

$json_file => mutation JSON
$output_dir => report directory
$cover_json => optional Devel::Cover JSON

=head3 Coverage Integration

If a L<Devel::Cover> JSON file is supplied to C<generate()>,
structural coverage metrics are displayed in the dashboard.

The LCSAJ metric shown is an approximation derived from statement and branch coverage.
It is not a full control flow graph computation.

=cut

sub generate {
	my ($class, $json_file, $output_dir, $cover_json, $lcsaj_dir, $lcsaj_hits_file) = @_;

	make_path($output_dir);

	open my $fh, '<', $json_file or die "Cannot open $json_file: $!";

	my $data = decode_json(do { local $/; <$fh> });

	close $fh;

	# --------------------------------------------------
	# Optional structural coverage loading
	# --------------------------------------------------
	my $coverage_data;

	if ($cover_json && -f $cover_json) {
		open my $cfh, '<', $cover_json;
		$coverage_data = decode_json(do { local $/; <$cfh> });
		close $cfh;
	}

	my $lcsaj_hits;

	if ($lcsaj_hits_file && -f $lcsaj_hits_file) {
		open my $lfh, '<', $lcsaj_hits_file;
		$lcsaj_hits = decode_json(do { local $/; <$lfh> });
		close $lfh;
	}

	my $files = _group_by_file($data);

	_write_index($output_dir, $data, $files, $coverage_data, $lcsaj_dir, $lcsaj_hits);

	# Pre-sort files worst-first so navigation order matches index order
	my @sorted_files = sort { _file_score($files->{$a}) <=> _file_score($files->{$b}) || $a cmp $b } keys %$files;

	for my $i (0 .. $#sorted_files) {
		my $file = $sorted_files[$i];

		# Only assign previous if this is NOT the first file
		my $prev = $i > 0 ? $sorted_files[$i - 1] : undef;

		# Only assign next if this is NOT the last file
		my $next = $i < $#sorted_files ? $sorted_files[$i + 1] : undef;

		_write_file_report($output_dir, $file, $files->{$file}, $prev, $next, $coverage_data, $lcsaj_dir, $lcsaj_hits);
	}
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
# Write index page
# --------------------------------------------------

sub _write_index {
	my ($dir, $data, $files, $coverage_data, $lcsaj_dir, $lcsaj_hits) = @_;

	open my $out, '>', File::Spec->catfile($dir, 'index.html') or die $!;

	print $out _header('Mutation Report');

	print $out "<h1>Mutation Report</h1>\n";

	print $out "<h2>Mutation Summary</h2>\n";
	print $out "<div class='summary'>\n";
	print $out "Score: $data->{score}%<br>\n";
	print $out "Total: $data->{total}<br>\n";
	print $out 'Killed: ', scalar(@{$data->{killed} || []}), "<br>\n";
	print $out 'Survived: ', scalar(@{$data->{survived} || []}), "<br>\n";
	print $out "</div>\n";

	print $out "<h2>Files</h2>\n";
	print $out "<table border='1' cellpadding='5'>\n";

	if($lcsaj_dir) {
		print $out "<tr><th>File</th><th>Total</th><th>Killed</th><th>Survivors</th><th>Score%</th><th>Complexity</th><th>LCSAJ</th></tr>\n";
	} else {
		print $out "<tr><th>File</th><th>Total</th><th>Killed</th><th>Survivors</th><th>Score%</th><th>Complexity</th></tr>\n";
	}

	for my $file (
		sort { _file_score($files->{$a}) <=> _file_score($files->{$b}) || $a cmp $b } keys %$files
	) {
		my $killed = scalar @{ $files->{$file}{killed} || [] };
		my $survived = scalar @{ $files->{$file}{survived} || [] };
		my $total = $killed + $survived;

		my $score = $total ? sprintf('%.2f', ($killed / $total) * 100) : 0;

		# --------------------------------------------------
		# Calculate cyclomatic complexity for the file
		# --------------------------------------------------
		my $complexity = _cyclomatic_complexity($file);

		# Approximate LSCAJ score
		my ($lcsaj_cov, $lcsaj_total) = _lcsaj_coverage_for_file($file, $lcsaj_dir, $lcsaj_hits);

		my $lcsaj_pct;
		if($lcsaj_dir) {
			$lcsaj_pct = $lcsaj_total ? sprintf('%.1f', ($lcsaj_cov / $lcsaj_total) * 100) : '-';
		} else {
			$lcsaj_pct = '';
		}

		print $out qq{
<tr>
<td><a href="$file.html">$file</a></td>
<td>$total</td>
<td>$killed</td>
<td>$survived</td>
<td>$score%</td>
<td>$complexity</td>
<td>$lcsaj_pct</td>
</tr>
};
	}

	print $out "</table>\n";

	# --------------------------------------------------
	# Structural Coverage Summary (if provided)
	# --------------------------------------------------
	if ($coverage_data) {
		my ($stmt_total, $stmt_hit, $branch_total, $branch_hit) = _coverage_totals($coverage_data);

		my $stmt_pct = $stmt_total ? sprintf('%.2f', ($stmt_hit / $stmt_total) * 100) : 0;

		my $branch_pct = $branch_total ? sprintf('%.2f', ($branch_hit / $branch_total) * 100) : 0;

		print $out "<h2>Structural Coverage (Approximate)</h2>\n";
		print $out "<div class='summary'>\n";
		print $out "Statement Coverage: $stmt_pct% ($stmt_hit / $stmt_total)<br>\n";
		print $out "Branch Coverage: $branch_pct% ($branch_hit / $branch_total)<br>\n";
		print $out "<em>Approximate LCSAJ derived from branch and statement coverage.</em>\n";
		print $out "</div>\n";

		# --------------------------------------------------
		# Executive summary
		# Statement coverage shows how much code runs.
		# Mutation score shows how well tests detect faults.
		# --------------------------------------------------
		print $out "<h2>Executive Summary</h2>\n";
		print $out "<div class='summary'>";
		print $out "Tests execute $stmt_pct% of the code, but detect only $data->{score}% of injected faults.";
		print $out "</div>\n";
	}

	print $out _footer();

	close $out;
}

# --------------------------------------------------
# Write per-file report with heatmap
# --------------------------------------------------
sub _write_file_report {
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

	print $out _header("File: $file");

	print $out "<h1>$file</h1>\n";

	# Navigation bar
	print $out qq{<div class="nav">};

	if ($prev) {
		my $link = _relative_link($file, $prev);
		print $out qq{<a href="$link">⬅ Previous</a> };
	}

	print $out qq{<a href="},
		File::Spec->abs2rel('index.html', File::Basename::dirname("$file.html")),
		qq{">Index</a>};

	$relative_path = File::Spec->catfile($dir, $file . '.lcsaj');
	App::Test::Generator::LCSAJ->generate($file, $relative_path);

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
			print $out "<div class='summary'>\n";
			print $out "<strong>Structural Coverage (Approximate)</strong><p>\n";
			print $out "Statement: $stmt_pct%<br>\n";
			print $out "Branch: $branch_pct%<br>\n";
			print $out "Approximate LCSAJ segments: $approx_lcsaj\n";
			print $out "</p></div>\n";
			print $out qq{
				<div class="legend">
					<h3>LCSAJ Legend</h3>

					<p>
					<span class="lcsaj-dot">●</span>
					Marks the start of an executed <b>LCSAJ (Linear Code Sequence And Jump)</b>.
					</p>

					<p>
					Multiple dots on a line indicate that multiple control-flow paths begin at that line.
					</p>

					<p>
					Hovering over a dot shows:
					</p>

					<pre>
					start → end → jump
					</pre>

					<ul>
					<li><b>start</b> – first line of the executed linear sequence</li>
					<li><b>end</b> – last line before control flow changes</li>
					<li><b>jump</b> – line execution jumps to next</li>
					</ul>

					<p>
					These markers help visualize which execution paths were exercised during testing.
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

	if ($lcsaj_hits) {
		my ($cov, $total) = _lcsaj_coverage_for_file($file, $lcsaj_dir, $lcsaj_hits);

		if ($total) {
			my $pct = sprintf('%.1f', ($cov / $total) * 100);

			print $out "<div class='summary'>";
			print $out "<strong>LCSAJ Coverage</strong><br>";
			print $out "$pct% ($cov / $total paths)";
			print $out '</div>';
		}
	}

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
		# warn "  file      = $file\n";
		# warn "  base      = $base\n";
		# warn "  lcsaj_dir = $lcsaj_dir\n";
		# warn "  lookup    = $lcsaj_file\n";
		# warn "  exists    = " . (-f $lcsaj_file ? "YES" : "NO") . "\n";

		if (-f $lcsaj_file) {
			open my $fh, '<', $lcsaj_file;
			my $paths = decode_json(do { local $/; <$fh> });
			close $fh;

			for my $p (@{ $paths || [] }) {
				next unless ref $p eq 'HASH';

				my $start = $p->{start};
				my $end = $p->{end};
				my $jump  = $p->{jump} // $p->{target};

				next unless defined $start && defined $end;

				push @{ $lcsaj_by_line{$start} }, {
					start => $start,
					end => $end,
					jump  => $jump,
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
				my $start = $p->{start};
				my $end = $p->{end};
				my $jump = $p->{jump} // 0;

				$lcsaj_marker .= qq{ <span class="lcsaj-dot" title="LCSAJ: $start → $end → $jump">●</span> };
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
			my $total = scalar @line_mutants;
			my $killed = scalar @{ $killed_by_line{$line_no} || [] };

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

	print $out _footer();

	close $out;
}

sub _file_score {
	my $file_data = $_[0];

	my $killed = scalar @{ $file_data->{killed} || [] };
	my $survived = scalar @{ $file_data->{survived} || [] };
	my $total = $killed + $survived;

	return $total ? ($killed / $total) * 100 : 0;
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

	return "Return value mutation survived. Add tests asserting exact return values." if $type =~ /RETURN/;

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

# --------------------------------------------------
# HTML Helpers
# --------------------------------------------------

sub _header {
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

pre {
    overflow-x: auto;
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

.lcsaj-dot:hover::after {
    content: attr(data-lcsaj);
    position: absolute;
    background: #333;
    color: white;
    padding: 4px 6px;
    border-radius: 4px;
    font-size: 11px;
}

</style>
</head>
<body>
<button class="toggle" onclick="toggleTheme()">🌙 Toggle Theme</button>
};
}

sub _footer {
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
	my $stmt_total = $total->{statement}{total} || 0;
	my $stmt_hit = $total->{statement}{covered} || 0;

	# Extract branch coverage
	my $branch_total = $total->{branch}{total} || 0;
	my $branch_hit = $total->{branch}{covered} || 0;

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
# Compute a simple *file based* cyclomatic complexity metric using PPI.
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

sub _lcsaj_coverage_for_file {
	my ($file, $lcsaj_dir, $hits) = @_;

	return unless $lcsaj_dir && $hits;

	my $path = $file;
	$file = abs_path($file) if defined $file;

	my $base = basename($file);

	my $rel = $file;
	$rel =~ s{.*?/lib/}{};

	my $lcsaj_file = File::Spec->catfile(
		$lcsaj_dir,
		"$rel.lcsaj",
		"$base.lcsaj.json"
	);

	return unless -f $lcsaj_file;

	open my $fh, '<', $lcsaj_file;
	my $paths = decode_json(do { local $/; <$fh> });
	close $fh;

	my $file_hits = $hits->{$path} || $hits->{$file} || {};

	my $covered = 0;
	my $total = scalar @$paths;

	for my $p (@$paths) {
		my $start = $p->{start};
		my $end = $p->{end};

		next unless defined $start && defined $end;

		my $hit = 0;

		for my $l ($start .. $end) {
			if ($file_hits->{$l}) {
				$hit = 1;
				last;
			}
		}

		$covered++ if $hit;
	}

	return ($covered, $total);
}

1;
