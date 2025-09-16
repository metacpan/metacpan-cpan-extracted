#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(:all);

use JSON::MaybeXS;
use File::Glob ':glob';
use File::Slurp;
use File::stat;
use POSIX qw(strftime);
use Readonly;

Readonly my $cover_db => 'cover_db/cover.json';
Readonly my $output => 'cover_html/index.html';
Readonly my $max_points => 10;	# Only display the last 10 commits in the coverage trend graph

# Read and decode coverage data
my $json_text = read_file($cover_db);
my $data = decode_json($json_text);

my $coverage_pct = 0;
my $badge_color = 'red';

if(my $total_info = $data->{summary}{Total}) {
	$coverage_pct = int($total_info->{total}{percentage} // 0);
	$badge_color = $coverage_pct > 80 ? 'brightgreen' : $coverage_pct > 50 ? 'yellow' : 'red';
}

Readonly my $coverage_badge_url => "https://img.shields.io/badge/coverage-${coverage_pct}%25-${badge_color}";

# Start HTML
my @html;	# build in array, join later
push @html, <<"HTML";
<!DOCTYPE html>
<html>
	<head>
	<title>Database::Abstraction Coverage Report</title>
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
		// Show cursor points on the headers to show that they are clickable
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
	</style>
</head>
<body>
<div class="badges">
	<a href="https://github.com/nigelhorne/Database-Abstraction">
		<img src="https://img.shields.io/github/stars/nigelhorne/Database-Abstraction?style=social" alt="GitHub stars">
	</a>
	<img src="$coverage_badge_url" alt="Coverage badge">
</div>
<h1>Database::Abstraction</h1><h2>Coverage Report</h2>
<table data-sort-col="0" data-sort-order="asc">
<!-- Make the column headers clickable -->
<thead>
<tr>
	<th class="sortable" onclick="sortTable(0)"><span class="label">File</span> <span class="arrow active">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(1)"><span class="label">Stmt</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(2)"><span class="label">Branch</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(3)"><span class="label">Cond</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(4)"><span class="label">Sub</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(5)"><span class="label">Total</span> <span class="arrow">&#x25B2;</span></th>
	<th class="sortable" onclick="sortTable(6)"><span class="label">&Delta;</span> <span class="arrow">&#x25B2;</span></th>
</tr>
</thead>

<tbody>
HTML

# Load previous snapshot for delta comparison
my @history = sort { $a cmp $b } bsd_glob("coverage_history/*.json");
my $prev_data;

if (@history >= 1) {
	my $prev_file = $history[-1];	# Most recent before current
	eval {
		$prev_data = decode_json(read_file($prev_file));
	};
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

my $commit_sha = `git rev-parse HEAD`;
chomp $commit_sha;
my $github_base = "https://github.com/nigelhorne/Database-Abstraction/blob/$commit_sha/";

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
	$low_coverage_count++ if $total < 70;

	my $badge_class = $total >= 90 ? 'badge-good'
					: $total >= 70 ? 'badge-warn'
					: 'badge-bad';

	my $tooltip = $total >= 90 ? 'Excellent coverage'
				 : $total >= 70 ? 'Moderate coverage'
				 : 'Needs improvement';

	my $row_class = $total >= 90 ? 'high'
			: $total >= 70 ? 'med'
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

	# Create the sparkline
	# There's probably some duplication of code here
	my @file_history;
	my @history_files = sort <coverage_history/*.json>;

	my %history;
	for my $file (@history_files) {
		my $json = eval { decode_json(read_file($file)) };
		next unless $json;
		$history{$file} = $json;
	}
	for my $hist_file (sort @history_files) {
		my $json = eval { decode_json(read_file($hist_file)) };
		next unless $json && $json->{summary}{$file};
		my $pct = $json->{summary}{$file}{total}{percentage} // 0;
		push @file_history, sprintf('%.1f', $pct);
	}
	my $points_attr = join(',', @file_history);

	push @html, sprintf(
		qq{<tr class="%s"><td><a href="%s" title="View coverage line by line" target="_blank">%s</a> %s<canvas class="sparkline" width="80" height="20" data-points="$points_attr"></canvas></td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%s</td>%s</tr>\n},
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
	qq{<tr class="summary-row nosort"><td colspan="2"><strong>Summary</strong></td><td colspan="2">%d files</td><td colspan="3">Avg: %d%%, Low: %d</td></tr>\n},
	$total_files, $avg_coverage, $low_coverage_count
);

# Add totals row
if (my $total_info = $data->{summary}{Total}) {
	my $total_pct = $total_info->{total}{percentage} // 0;
	my $class = $total_pct > 80 ? 'high' : $total_pct > 50 ? 'med' : 'low';

	push @html, sprintf(
		qq{<tr class="%s nosort"><td><strong>Total</strong></td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td><td colspan="2"><strong>%.1f</strong></td></tr>\n},
		$class,
		$total_info->{statement}{percentage} // 0,
		$total_info->{branch}{percentage} // 0,
		$total_info->{condition}{percentage} // 0,
		$total_info->{subroutine}{percentage} // 0,
		$total_pct
	);
}

my $timestamp = 'Unknown';
if (my $stat = stat($cover_db)) {
	$timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime($stat->mtime));
}

Readonly my $commit_url => "https://github.com/nigelhorne/Database-Abstraction/commit/$commit_sha";
my $short_sha = substr($commit_sha, 0, 7);

push @html, '</tbody></table>';

# Parse historical snapshots
my @history_files = bsd_glob("coverage_history/*.json");
my @trend_points;

foreach my $file (sort @history_files) {
	my $json = eval { decode_json(read_file($file)) };
	next unless $json && $json->{summary}{Total};

	my $pct = $json->{summary}{Total}{total}{percentage} // 0;
	my ($date) = $file =~ /(\d{4}-\d{2}-\d{2})/;
	push @trend_points, { date => $date, coverage => sprintf('%.1f', $pct) };
}

# Inject chart if we have data
my %commit_times;
open(my $log, '-|', 'git log --all --pretty=format:"%H %h %ci"') or die "Can't run git log: $!";
while (<$log>) {
	chomp;
	my ($full_sha, $short_sha, $datetime) = split ' ', $_, 3;
	$commit_times{$short_sha} = $datetime;
}
close $log;

my %commit_messages;
open($log, '-|', 'git log --pretty=format:"%h %s"') or die "Can't run git log: $!";
while (<$log>) {
	chomp;
	my ($short_sha, $message) = /^(\w+)\s+(.*)$/;
	if($message =~ /^Merge branch /) {
		delete $commit_times{$short_sha};
	} else {
		$commit_messages{$short_sha} = $message;
	}
}
close $log;

# Collect data points from non-merge commits
my @data_points_with_time;
my $processed_count = 0;

foreach my $file (reverse sort @history_files) {
	last if $processed_count >= $max_points;

	my $json = eval { decode_json(read_file($file)) };
	next unless $json && $json->{summary}{Total};

	my ($sha) = $file =~ /-(\w{7})\.json$/;
	next unless $commit_messages{$sha};	# Skip merge commits

	my $timestamp = $commit_times{$sha} // strftime('%Y-%m-%dT%H:%M:%S', localtime((stat($file))->mtime));
	$timestamp =~ s/ /T/;
	$timestamp =~ s/\s+([+-]\d{2}):?(\d{2})$/$1:$2/;	# Fix space before timezone
	$timestamp =~ s/ //g;	# Remove any remaining spaces

	my $pct = $json->{summary}{Total}{total}{percentage} // 0;
	my $color = 'gray';	# Will be set properly after sorting
	my $url = "https://github.com/nigelhorne/Database-Abstraction/commit/$sha";
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

	push @data_points, qq{{ x: "$point->{timestamp}", y: $point->{pct}, delta: $delta, url: "$point->{url}", label: "$point->{timestamp}", pointBackgroundColor: "$color", comment: "$point->{comment}" }};
}

my $js_data = join(",\n", @data_points);

if(scalar(@data_points)) {
	push @html, <<'HTML';
<p>
	<h2>Coverage Trend</h2>
	<label>
		<input type="checkbox" id="toggleTrend" checked>
		Show regression trend
	</label>
</p>
HTML
}

push @html, <<"HTML";
<canvas id="coverageTrend" width="600" height="300"></canvas>
<!-- Zoom controls for the trend chart -->
<div id="zoomControls" style="margin-top:8px;">
	<button id="resetZoomBtn" type="button">Reset Zoom</button>
	<span style="margin-left:8px;color:#666;font-size:0.9em;">Use mouse wheel or pinch to zoom; drag to pan</span>
</div>
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

function sortTable(n) {
	const table = document.querySelector("table");
	if (!table || !table.tBodies || !table.tBodies[0]) return;

	// All rows in tbody
	const allBodyRows = Array.from(table.tBodies[0].rows);

	// Separate normal (sortable) rows and fixed (nosort) rows.
	const normalRows = allBodyRows.filter(r => !r.classList.contains("nosort"));
	const fixedRows = allBodyRows.filter(r => r.classList.contains("nosort"));

	// Decide numeric vs text column (column 0 = File => text)
	const isNumeric = n > 0;

	// Determine ascending/descending toggle logic
	const prevCol = table.getAttribute("data-sort-col");
	const prevOrder = table.getAttribute("data-sort-order") || "desc";
	const asc = (prevCol != n) ? true : (prevOrder === "desc");

	normalRows.sort((a, b) => {
		let x = (a.cells[n] && a.cells[n].innerText) ? a.cells[n].innerText.trim() : "";
		let y = (b.cells[n] && b.cells[n].innerText) ? b.cells[n].innerText.trim() : "";

		if (isNumeric) {
			// Remove non-number characters (arrows, percent signs, bullets, etc.)
			x = parseFloat(x.replace(/[^0-9.\-+eE]/g, '')) || 0;
			y = parseFloat(y.replace(/[^0-9.\-+eE]/g, '')) || 0;
		} else {
			// Text compare (case-insensitive)
			x = x.toLowerCase();
			y = y.toLowerCase();
		}

		if (x < y) return asc ? -1 : 1;
		if (x > y) return asc ? 1 : -1;
		return 0;
	});

	// Reattach rows: sorted normalRows first, then fixedRows (keeps summary/total last)
	normalRows.forEach(r => table.tBodies[0].appendChild(r));
	fixedRows.forEach(r => table.tBodies[0].appendChild(r));

	// Update header arrows
	const headers = table.tHead.rows[0].cells;
	for (let i = 0; i < headers.length; i++) {
		const arrow = headers[i].querySelector(".arrow");
		if (!arrow) continue;
		if (i === n) {
			// active column: bold arrow, direction ▲ or ▼
			arrow.textContent = asc ? "▲" : "▼";
			arrow.classList.add("active");
		} else {
			// inactive column: always ▲, dimmed
			arrow.textContent = "▲";
			arrow.classList.remove("active");
		}
	}

	// Remember state (so clicking same column toggles)
	table.setAttribute("data-sort-col", n);
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

</script>
HTML

push @html, <<"HTML";
<footer>
	<p>Project: <a href="https://github.com/nigelhorne/Database-Abstraction">Database-Abstraction</a></p>
	<p><em>Last updated: $timestamp - <a href="$commit_url">commit <code>$short_sha</code></a></em></p>
</footer>
</body>
</html>
HTML

# Write to index.html
write_file($output, join("\n", @html));
