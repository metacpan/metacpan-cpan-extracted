#!/usr/bin/env perl

# Generates the HTML for use as a testing dashboard on GitHub
# The location will be https://nigelhorne.github.io/$config{github_repo}/coverage/
# The script is automatically run by each 'git push' by the script .github/workflows/dashboard.yml

use strict;
use warnings;
use autodie qw(:all);

use File::Glob ':glob';
use File::Slurp;
use File::stat;
use IPC::Run3;
use JSON::MaybeXS;
use POSIX qw(strftime);
use Readonly;
use HTTP::Tiny;
use Time::HiRes qw(sleep);
use URI::Escape qw(uri_escape);
use version;

Readonly my %config => (
	github_user => 'nigelhorne',
	github_repo => 'CGI-Lingua',
	package_name => 'CGI::Lingua',
	low_threshold => 70,
	med_threshold => 90,
	max_points => 10,	# Only display the last 10 commits in the coverage trend graph
	cover_db => 'cover_db/cover.json',
	output => 'cover_html/index.html',
	max_retry => 3
);

# -------------------------------
# Dependency correlation analysis
# -------------------------------
my $MAX_REPORTS_PER_GRADE = 20;	# safety rail
my $ENABLE_DEP_ANALYSIS = 1;

# Read and decode coverage data
my $data = eval { decode_json(read_file($config{cover_db})) };

my $coverage_pct = 0;
my $badge_color = 'red';

if(my $total_info = $data->{summary}{Total}) {
	$coverage_pct = int($total_info->{total}{percentage} // 0);
	$badge_color = $coverage_pct > $config{med_threshold} ? 'brightgreen' : $coverage_pct > $config{low_threshold} ? 'yellow' : 'red';
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
		.new-failure {
			background: #c00;
			color: #fff;
			font-weight: bold;
			padding: 2px 6px;
			border-radius: 4px;
			font-size: 0.85em;
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
if ($prev_data) {
	for my $file (keys %{$data->{summary}}) {
		next if $file eq 'Total';
		my $curr = $data->{summary}{$file}{total}{percentage} // 0;
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

for my $file (sort keys %{$data->{summary}}) {
	next if $file eq 'Total';

	my $info = $data->{summary}{$file};
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

	my $delta_html = '';
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
if (my $total_info = $data->{summary}{Total}) {
	my $total_pct = $total_info->{total}{percentage} // 0;
	my $class = $total_pct > 80 ? 'high' : $total_pct > 50 ? 'med' : 'low';

	push @html, sprintf(
		qq{<tr class="%s nosort"><td><strong>Total</strong></td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td colspan="2"><strong>%.1f</strong></td></tr>},
		$class,
		$total_info->{statement}{percentage} // 0,
		$total_info->{branch}{percentage} // 0,
		$total_info->{condition}{percentage} // 0,
		$total_info->{subroutine}{percentage} // 0,
		$total_pct
	);
}

Readonly my $commit_url => "https://github.com/$config{github_user}/$config{github_repo}/commit/$commit_sha";
my $short_sha = substr($commit_sha, 0, 7);

push @html, '</tbody></table>';

# Parse historical snapshots
my @trend_points;

foreach my $file (sort @history_files) {
	my $json = $historical_cache{$file};
	next unless $json->{summary}{Total};

	my $pct = $json->{summary}{Total}{total}{percentage} // 0;
	my ($date) = $file =~ /(\d{4}-\d{2}-\d{2})/;
	if(defined($date)) {
		push @trend_points, { date => $date, coverage => sprintf('%.1f', $pct) };
	}
}

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
	next unless $json->{summary}{Total};

	my ($sha) = $file =~ /-(\w{7})\.json$/;
	next unless $commit_messages{$sha};	# Skip merge commits

	my $timestamp = $commit_times{$sha} // strftime('%Y-%m-%dT%H:%M:%S', localtime((stat($file))->mtime));

	# Git log returns format like: "2024-01-15 14:30:45 -0500" or "2024-01-15 14:30:45 +0000"
	# We need ISO 8601 format: "2024-01-15T14:30:45-05:00"

	# Replace space between date and time with 'T'
	$timestamp =~ s/^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})/$1T$2/;

	# Fix timezone format: convert "-0500" to "-05:00" or " -05:00" to "-05:00"
	$timestamp =~ s/\s*([+-])(\d{2}):?(\d{2})$/$1$2:$3/;

	# Remove any remaining spaces (safety cleanup)
	$timestamp =~ s/\s+//g;

	my $pct = $json->{summary}{Total}{total}{percentage} // 0;
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

my $js_data = join(",\n", @data_points);

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
HTML
}

push @html, <<"HTML";
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

const dataPoints = [ $js_data ];
HTML

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

# -------------------------------
# Add CPAN Testers failing reports table
# -------------------------------
my $dist_name = $config{github_repo};	# e.g., CGI-Lingua
my $cpan_api = "https://api.cpantesters.org/v3/summary/"
		. uri_escape($dist_name);

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

	@versions = sort { version->parse($b) <=> version->parse($a) } @versions;

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
	);
	@pass_reports = fetch_reports_by_grades(
		$dist_name,
		$version,
		'pass',
	);

	if(scalar(@fail_reports)) {

		my @prev_fail_reports;
		if ($prev_version) {
			@prev_fail_reports = fetch_reports_by_grades(
				$dist_name,
				$prev_version,
				'fail',
				'unknown',
			);
		}

		push @html, <<"HTML";
<script>
document.addEventListener("DOMContentLoaded", function () {
	const toggleFail = document.getElementById('toggleFail');
	const toggleUnknown = document.getElementById('toggleUnknown');
	const toggleNew = document.getElementById('toggleNew');

	function update() {
		if (toggleFail) {
			document.querySelectorAll('tr.cpan-fail')
				.forEach(r => r.style.display = toggleFail.checked ? '' : 'none');
		}
		if (toggleUnknown) {
			document.querySelectorAll('tr.cpan-unknown')
				.forEach(r => r.style.display = toggleUnknown.checked ? '' : 'none');
		}
		if (toggleNew) {
			document.querySelectorAll('tr').forEach(row => {
				const cell = row.querySelector('.new-failure');
				if (!cell) return;
				row.style.display = toggleNew.checked ? '' : 'none';
			});
		}
	}

	[toggleFail, toggleUnknown, toggleNew].forEach(cb => {
		if (cb) cb.addEventListener('change', update);
	});

	update();
});
document.addEventListener("DOMContentLoaded", () => {
	const th = document.querySelector("table.sortable-table th");
	if (th) sortTable(th, 0);
});
</script>

<h2>CPAN Testers Failures for $dist_name $version</h2>
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
	<th class="sortable" onclick="sortTable(this, 4)">
		<span class="label">New</span> <span class="arrow">&#x25B2;</span>
	</th>
	<th>Report</th>
</tr>
</thead>
<tbody>
HTML

		my %best;

		for my $r (@fail_reports) {
			my $os = $r->{osname} // 'unknown';
			my $perl = $r->{perl} // 'unknown';
			my $grade = lc($r->{grade} // 'unknown');

			my $key = join '|', $os, $perl, $grade;

			if(!exists $best{$key} || (!$best{$key}{guid} && $r->{guid})) {
				$best{$key} = $r;
			}
		}

		my @deduped = values %best;

		my %prev_fail_set;

		for my $r (@prev_fail_reports) {
			my $key = join '|', $r->{osname} // '', $r->{perl} // '', $r->{arch} // '';

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

			my $is_new = !$prev_fail_set{ join '|', $r->{osname} // '', $r->{perl} // '', $r->{arch} // '' };
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

		if ($ENABLE_DEP_ANALYSIS) {
			my %dep_stats;

			# Split GUIDs by grade
			my @fail_guids = map { $_->{guid} } grep { ($_->{grade} // '') eq 'FAIL' } @fail_reports;
			my @unknown_guids = map { $_->{guid} } grep { ($_->{grade} // '') eq 'UNKNOWN' } @fail_reports;

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
		}
	} else {
		# @fail_reports is empty
		push @html, "<p>No CPAN Testers failures reported for $dist_name $version.</p>";
	}
} elsif($res->{status} == 404) {	# 404 means no fail reports
	# push @html, "<A HREF=\"$cpan_api\">$cpan_api</A>";
	push @html, "<p>No CPAN Testers failures reported for $dist_name $version.</p>";
} else {
	push @html, "<a href=\"$cpan_api\">$cpan_api</a>: $res->{status} $res->{reason}";
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
write_file($config{output}, join("\n", @html));

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
			my $key = join '|',
				$r->{osname} // '',
				$r->{perl} // '',
				$r->{arch} // '';

			next if $seen{$key}++;
			push @reports, $r;
		}
	}

	return @reports;
}

sub fetch_report_html {
	my ($guid) = @_;
	return unless $guid;

	my $url = "https://www.cpantesters.org/cpan/report/$guid";
	v("    fetching report HTML $guid");

	my $res = $http->get($url);
	return unless $res->{success};

	return $res->{content};
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

sub extract_installed_modules {
	my ($html) = @_;
	my %mods;

	return \%mods unless $html;

	while ($html =~ /^\s*([A-Z]\w*(?:::\w+)*)\s+v?([\d._]+)/mg) {
		my ($module, $version) = ($1, $2);

		# skip obvious noise
		next if $module =~ /^(Perl|OS|Reporter|Tester)$/;

		$mods{$module} = $version;
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
		if ($fail >= 3 && $ratio >= 0.7) {
			push @suspects, {
				module => $mod,
				fail => $fail,
				pass => $pass,
				ratio => sprintf("%.2f", $ratio),
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

		my @fail = sort { version->parse($a) <=> version->parse($b) } @{ $d->{fail} };
		my @pass = sort { version->parse($a) <=> version->parse($b) } @{ $d->{pass} };

		my $fail_min = version->parse($fail[0]);
		my $pass_max = version->parse($pass[-1]);

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

		if (version->parse($fail_median) > version->parse($pass_median)) {
			push @suspects, {
				module => $mod,
				type => 'soft',
				message => sprintf(
					'FAIL median %s > PASS median %s',
					$fail_median,
					$pass_median,
				),
			};
		}
	}

	return @suspects;
}
