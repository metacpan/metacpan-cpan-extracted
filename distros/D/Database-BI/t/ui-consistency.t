use strict;
use warnings;

# The dashboard and the pages it opens behave as one piece of software:
#
#   * every chart, pivot, stats and insights form carries the whole view --
#     joins and their type, combined files, filters, time range, cross-row
#     columns and de-duplication -- through one macro;
#   * a chart of a de-duplicated view counts the rows the table shows;
#   * a chart page says what it is drawn from when that is not the whole file;
#   * the toolbar panels are listed once, and every panel is in that list;
#   * a view can be joined and combined at once, whichever was done first;
#   * the main navigation reaches canvases, the catalog and the file browser
#     from every page.
#
#   prove -l t/ui-consistency.t

use Test::More;
use Test::Mojo;
use Mojo::DOM;
use Mojo::File;
use Mojo::Util qw(url_escape);
use File::Temp ();

my $data_dir  = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;
my $model_dir = Mojo::File->new(File::Temp::tempdir(CLEANUP => 1))->to_string;

# Row 2 repeats row 1 exactly, so d=1 has something to remove.
Mojo::File->new($data_dir)->child('sales.csv')->spew(
	"id,region,amount\n1,North,10\n1,North,10\n2,South,5\n");
Mojo::File->new($data_dir)->child('more.csv')->spew(
	"id,region,amount\n3,East,7\n");
Mojo::File->new($data_dir)->child('managers.csv')->spew(
	"region,manager\nNorth,Ann\nSouth,Bob\nEast,Cy\n");

my $t = Test::Mojo->new('Database::BI', {
	data_dir  => $data_dir,
	model_dir => $model_dir,
});

my $more = "path:$data_dir/more.csv";

# The forms a dashboard panel submits to draw the current view somewhere else.
my @view_forms = map { "$_-form" }
	qw(graph pie heatmap bar stacked scatter combo treemap histogram wordcloud
	   map pivot stats insights);

subtest 'every view form carries the combined files, filters, range and de-dup' => sub {
	my $url = '/combine?l=table:sales&c=' . url_escape($more)
		. '&f=' . url_escape('region:ne:West') . '&d=1'
		. '&range=last_year&rcol=region';
	my $dom = Mojo::DOM->new($t->get_ok($url)->status_is(200)->tx->res->body);

	for my $id (@view_forms) {
		my $form = $dom->at("form#$id");
		ok($form, "$id is on the page") or next;
		my %has = map { ($_->{name} // '') => $_->{value} } $form->find('input[type=hidden]')->each;
		is($has{l}, 'table:sales', "$id carries l=");
		is($has{c}, $more, "$id carries c=");
		is($has{f}, 'region:ne:West', "$id carries f=");
		is($has{d}, '1', "$id carries d=1");
		is($has{range}, 'last_year', "$id carries range=");
	}
};

subtest 'a joined view carries its join type to every view form' => sub {
	my $url = '/join?l=table:sales&j=' . url_escape("$more|id|id") . '&jtype=inner';
	my $dom = Mojo::DOM->new($t->get_ok($url)->status_is(200)->tx->res->body);
	for my $id (@view_forms) {
		my $in = $dom->at("form#$id input[name=jtype]");
		ok($in && $in->{value} eq 'inner', "$id carries jtype=inner");
	}
};

subtest 'charts, stats and exports honour d=1 like the table does' => sub {
	my $csv = $t->get_ok('/export?l=table:sales&d=1')->status_is(200)->tx->res->body;
	my @lines = grep { length } split /\r?\n/, $csv;
	is(scalar(@lines), 3, 'the export holds a header and two distinct rows');

	# The pie's data array: {"value":N,"label":"North"} in either key order.
	my $north = sub {
		my ($body) = @_;
		my ($json) = $body =~ /const data = (\[.*?\]);/s or return;
		my ($obj)  = grep { /"label":"North"/ } $json =~ /(\{[^}]*\})/g or return;
		my ($v)    = $obj =~ /"value":([\d.]+)/;
		return $v;
	};
	my $plain = $t->get_ok('/pie?l=table:sales&cat=region&val=amount')->status_is(200)->tx->res->body;
	my $dedup = $t->get_ok('/pie?l=table:sales&cat=region&val=amount&d=1')->status_is(200)->tx->res->body;
	is($north->($plain), 20, 'without d=1 North sums both copies');
	is($north->($dedup), 10, 'with d=1 North sums one copy');

	# The SQL push path has to give the same answer as the Perl fold.
	local $ENV{BI_FORCE_PERL_AGG} = 1;
	$dedup = $t->get_ok('/pie?l=table:sales&cat=region&val=amount&d=1')->status_is(200)->tx->res->body;
	is($north->($dedup), 10, 'and so does the Perl fold');
};

subtest 'a chart page names what it is drawn from' => sub {
	my $url = '/bar?l=table:sales&cat=region&val=amount&f=' . url_escape('region:eq:North') . '&d=1';
	my $dom = Mojo::DOM->new($t->get_ok($url)->status_is(200)->tx->res->body);
	my $ctx = $dom->at('#view-context');
	ok($ctx, 'a filtered chart has a Drawn from strip') or return;
	like($ctx->all_text, qr/region:eq:North/, 'it names the filter');
	like($ctx->all_text, qr/duplicates removed/, 'and the de-duplication');

	$dom = Mojo::DOM->new($t->get_ok('/bar?l=table:sales&cat=region&val=amount')->tx->res->body);
	ok(!$dom->at('#view-context'), 'an unfiltered chart has none');
};

subtest 'the toolbar panels are listed once, and the list is complete' => sub {
	my $body = $t->get_ok('/view/sales')->status_is(200)->tx->res->body;
	unlike($body, qr/\botherPanels\b/, 'no panel keeps its own list of the others');
	my ($list) = $body =~ /var BI_PANELS = \[([^\]]*)\]/;
	ok($list, 'BI_PANELS is defined') or return;
	my %listed = map { $_ => 1 } $list =~ /'([^']+)'/g;
	my $dom = Mojo::DOM->new($body);
	my @panels = $dom->find('div.graph-panel[id], div[id$="-panel"].join-panel, div.combine-panel[id], div.export-panel[id], div.save-analysis-panel[id]')
		->map(attr => 'id')->each;
	ok(scalar(@panels) >= 20, 'the page has its panels');
	ok($listed{$_}, "$_ is in BI_PANELS") for @panels;
};

subtest 'every chart, analysis and model button in the toolbar looks the same' => sub {
	my $dom = Mojo::DOM->new($t->get_ok('/view/sales')->status_is(200)->tx->res->body);

	# These are styled on purpose as actions of their own (colour-coded or
	# toggles); every other toolbar button opens a chart, an analysis or a
	# model panel and shares one look.
	my %own_style = map { $_ => 1 } qw(
		btn-copy-link btn-export-open btn-refresh btn-delete-sel btn-dedup
		btn-add-db btn-combine dash-f-apply dash-range-apply chip-remove-range
	);
	my @buttons = grep { ($_->{id} // '') =~ /\Abtn-/ && !$own_style{$_->{id}} }
		$dom->find('div.toolbar button[id]')->each;
	ok(scalar(@buttons) >= 20, 'the toolbar has its buttons');
	for my $b (@buttons) {
		like($b->{class} // '', qr/(?:^|\s)btn-tool(?:\s|$)/, "$b->{id} has the btn-tool class");
	}
	ok($dom->at('#btn-wordcloud.btn-tool'), 'Word cloud is one of them');
	ok($dom->at('#btn-cross-row.btn-tool'), 'and so is Cross-row');

	my $tt = Mojo::File->new('templates/web/en/dashboard.html.tt')->slurp;
	like($tt, qr/<button class="btn-tool btn-ask"/, 'Ask, shown only with an AI key, too');
};

# Measured in Firefox when this was written: with align-items: baseline and no
# common height, the Map button's emoji made it 29px and Merge, Combine, Hide
# duplicates and Totals were 28.6px beside 28px neighbours.  No browser runs
# in the suite, so the rules that line the boxes up are checked as written.
subtest 'controls on a toolbar row share one height and are centred' => sub {
	my $layout = Mojo::File->new('templates/web/en/layouts/default.html.tt')->slurp;
	my ($toolbar) = $layout =~ /^\s*\.toolbar \{([^}]*)\}/m;
	like($toolbar // '', qr/align-items:\s*center/, 'the toolbar centres its row');
	like($layout, qr/\.toolbar > button,\s*\.toolbar > \.lbl-totals \{[^}]*height:\s*1\.75rem/,
		'every toolbar button and the Totals toggle have one height');

	my $tt = Mojo::File->new('templates/web/en/dashboard.html.tt')->slurp;
	like($tt, qr/\.dash-add-filter > select,\s*\.dash-add-filter > input,\s*\.dash-add-filter > button \{[^}]*height:\s*1\.75rem/,
		'and the filter bar uses the same height');
};

# Measured in Firefox: Limit to top, ranked by and Time bucket were 21px
# browser-default controls beside 28px Row, Column and Measure fields, because
# the pivot's field rule did not name the options row.
subtest 'the pivot options row is styled like its dimension fields' => sub {
	my $tt = Mojo::File->new('templates/web/en/dashboard.html.tt')->slurp;
	my ($rule) = $tt =~ /^(  \.pivot-dim-row select,.*?)\{/ms;
	ok($rule, 'the pivot field rule is there') or return;
	like($rule, qr/\.pivot-options-row select/, 'it covers the options row selects');
	like($rule, qr/\.pivot-options-row input\[type="text"\]/, 'its text inputs');
	like($rule, qr/\.pivot-options-row input\[type="number"\]/, 'and its number inputs');
};

# Measured in Firefox: the canvas's Time range bar was 21px browser-default
# controls, the parameter bar 25.4px and Print / Delete canvas 29px beside
# 28px toolbar buttons; card-header buttons were 17.6, 18.6 and 19.2px.
subtest 'canvas bars and card headers share one control height each' => sub {
	my $tt = Mojo::File->new('templates/web/en/canvas.html.tt')->slurp;
	like($tt, qr/\.param-bar input,\s*\.param-bar select,\s*\.param-bar button,\s*\.canvas-toolbar > button,\s*\.canvas-toolbar > \.bm-wrap > button,\s*\.canvas-toolbar \.btn-add-visual \{[^}]*height:\s*1\.75rem/,
		'the toolbar, Time range and parameter bars use the table toolbar height');
	like($tt, qr/\.param-bar select \{/, 'the Time range menus are styled');
	like($tt, qr/\.param-bar \.btn-add-visual \{/, 'and so is its Apply button');
	like($tt, qr/\.visual-edit-btn,\s*\.visual-cs-btn,\s*\.visual-size-select,\s*\.visual-dl-btn \{[^}]*height:\s*1\.25rem/,
		'card-header controls share one height');
};

# Measured in Firefox: the table page's filter bar and pivot fields showed the
# browser's grey (no rule set a background) while panels and the canvas were
# white, with three different border greys.  One rule in the layout now gives
# every field its colours, and components read them from two variables.
subtest 'every dropdown and text field shares one colour' => sub {
	my $layout = Mojo::File->new('templates/web/en/layouts/default.html.tt')->slurp;
	like($layout, qr/--field-bg:\s*#fff;/, 'the field background is defined once');
	like($layout, qr/--field-border:\s*#c0c8e0;/, 'and the field border');

	my ($base) = $layout =~ /^\s*(:where\(select, textarea, input[^\n]*)\{/m;
	ok($base, 'the base field rule is in the layout, on one line') or return;
	unlike($base, qr/\)\s+:not/, 'its :not() chain has no space, so it is not a descendant selector');

	# No component names a field colour of its own any more (the Export panel's
	# green accent border is the one deliberate exception).
	for my $file (qw(layouts/default dashboard canvas)) {
		my $tt = Mojo::File->new("templates/web/en/$file.html.tt")->slurp;
		while ($tt =~ /([^{}]*)\{([^{}]*)\}/g) {
			my ($sel, $body) = ($1, $2);
			next unless $sel =~ /\b(?:select|input|textarea)\b|-select\b|-input\b/;
			next if $sel =~ /export-|btn|button|::before|db-card/;
			ok($body !~ /background(?:-color)?:\s*#(?:fff|222)\b|var\(--(?:card|header)-bg/,
				"$file: no hard-coded field background in '" . ($sel =~ s/\s+/ /gr =~ s/^ //r) . "'")
				if $body =~ /background/;
		}
	}
};

subtest 'the main navigation reaches canvases, the catalog and the browser' => sub {
	for my $page ('/', '/view/sales', '/bar?l=table:sales&cat=region&val=amount', '/catalog') {
		my $dom = Mojo::DOM->new($t->get_ok($page)->status_is(200)->tx->res->body);
		for my $href ('/#bi-canvases', '/catalog', '/browse') {
			ok($dom->at(qq{nav.site-nav a[href="$href"]}), "$page links to $href");
		}
	}
};

subtest 'a view joins and combines at once, whichever came first' => sub {
	my $j = 'table:managers|region|region';
	for my $route (qw(join combine)) {
		my $url = "/$route?l=table:sales&j=" . url_escape($j) . '&c=' . url_escape($more);
		my $dom = Mojo::DOM->new($t->get_ok($url)->status_is(200)->tx->res->body);
		my @head = map { $_->all_text } $dom->find('#data-table thead th, table thead th')->each;
		ok((grep { $_ eq 'manager' } @head), "/$route shows the joined column");
		my @rows = $dom->find('table tbody tr')->each;
		ok((grep { $_->all_text =~ /East/ } @rows), "/$route shows the combined rows");
		for my $id (qw(join-form combine-form bar-form)) {
			my %has = map { ($_->{name} // '') => $_->{value} } $dom->find("form#$id input[type=hidden]")->each;
			is($has{j}, $j, "/$route: $id carries j=");
			is($has{c}, $more, "/$route: $id carries c=");
		}
	}
};

done_testing();
