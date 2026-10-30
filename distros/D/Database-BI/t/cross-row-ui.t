#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use Test::Mojo;
use Mojo::Util qw(url_escape);

# The panel, the chips and the round trip through the page: the cross-row pass
# itself is covered by t/cross-row.t and t/canvas-cross-row.t.  What is checked
# here is that a reader can reach it without editing the URL, that the panel
# submits the view it was opened on, and that every panel which leaves the page
# carries the columns with it.

my $t = Test::Mojo->new('Database::BI');

my $sales_path = $t->app->home->child('data/sales.csv')->to_string;
plan skip_all => 'data/sales.csv not found' unless -f $sales_path;

sub view_url {
	my (%q) = @_;
	my @pairs;
	for my $name (sort keys %q) {
		push @pairs, map { $name . '=' . url_escape($_) } @{ ref $q{$name} ? $q{$name} : [ $q{$name} ] };
	}
	return '/view/sales?' . join('&', @pairs);
}

# The one form on the page that composes a new cross-row column.
sub panel_form {
	my ($body) = @_;
	return $body =~ /(<form id="cross-row-form".*?<\/form>)/s ? $1 : '';
}

sub named_form {
	my ($body, $id) = @_;
	return $body =~ /(<form id="\Q$id\E".*?<\/form>)/s ? $1 : '';
}

sub hidden_pairs {
	my ($form) = @_;
	my @out;
	while ($form =~ /<input type="hidden" name="([^"]+)" value="([^"]*)">/g) {
		push @out, [ $1, $2 ];
	}
	return @out;
}

subtest 'the table view offers a cross-row picker even with no columns yet' => sub {
	$t->get_ok(view_url(l => 'table:sales'))->status_is(200);
	my $body = $t->tx->res->body;

	like $body, qr{id="btn-cross-row"},       'the toolbar has a cross-row button';
	like $body, qr{id="cross-row-panel"},     'and the panel it opens is on the page';
	like $body, qr{id="cross-row-col-sel"},   'the panel has a column picker';
	like $body, qr{id="cross-row-fn-sel"},    'a function picker';
	like $body, qr{id="cross-row-order-sel"}, 'an order picker';
	like $body, qr{id="cross-row-dir-sel"},   'a direction picker';
	like $body, qr{id="cross-row-by-sel"},    'and a partition picker';
	like $body, qr{id="cross-row-alias-inp"}, 'plus the name of the new column';

	my $panel = panel_form($body);
	ok length $panel, 'the form is found';

	# Every function the pass knows is offered, with the two facts the script
	# needs: whether it takes a window and whether it must be ordered.
	my @fns = $panel =~ /<option value="([a-z_]+)" data-arg="[01]" data-order="[01]">/g;
	is scalar @fns, 11, 'all eleven functions are offered';
	my %seen = map { $_ => 1 } @fns;
	ok $seen{running_total}, 'including a running total';
	ok $seen{window_avg},    'a moving average';
	ok $seen{rank},          'a rank';
	ok $seen{pct_of_total},  'a percent of total';

	like $panel, qr{<option value="window_avg" data-arg="1" data-order="1">},
		'the moving average is marked as taking a window and needing an order';
	like $panel, qr{<option value="rank" data-arg="0" data-order="0">},
		'and the rank as taking neither';

	my ($cols) = $panel =~ /(<select id="cross-row-col-sel".*?<\/select>)/s;
	my @options = $cols =~ /<option value="([^"]*)"/g;
	is shift @options, '', 'the column picker starts on a placeholder';
	ok scalar(grep { $_ eq 'amount' } @options),
		'and offers the number columns of the view';

	like $panel, qr{id="cross-row-window-field" hidden},
		'the window field starts hidden, because no function needs one';
	like $panel, qr{id="btn-do-cross-row" class="btn-primary" disabled},
		'and nothing can be added until the picks are complete';

	unlike $body, qr{class="filter-chip filter-chip-cs"},
		'a view with no cross-row column has no chip for one';
	my $bar = named_form($body, 'bar-form');
	unlike $bar, qr{name="cs"}, 'and the chart panel sends no cs=';
};

subtest 'a column already in the view is a chip and travels with the panels' => sub {
	my $spec = 'amount:running_total:rt';
	$t->get_ok(view_url(
		l     => 'table:sales',
		f     => 'region:eq:North',
		cs    => $spec,
		order => 'id:asc',
		by    => 'region',
	))->status_is(200);
	my $body = $t->tx->res->body;

	like $body, qr{class="filter-chip filter-chip-cs" data-cs="amount:running_total:rt"},
		'the column is shown as a chip of its own';
	like $body, qr{class="chip-remove chip-remove-cs"},
		'with a button to remove it';
	like $body, qr{<th[^>]*>rt</th>}, 'and the table has the column it produces';

	my $panel = panel_form($body);
	my %hidden = map { @$_ } hidden_pairs($panel);
	is $hidden{cs}, $spec, 'the panel keeps the column already computed';
	is $hidden{l},  'table:sales', 'so adding a second one does not lose the view';
	is $hidden{f},  'region:eq:North', 'nor the filters it was opened on';
	ok !exists $hidden{by},    'and the panel writes by= from its own picker';
	ok !exists $hidden{order}, 'as it does order=';

	like $body, qr{id="cross-row-order-sel" data-current="id:asc"},
		'the order picker starts where the view is';
	like $body, qr{id="cross-row-by-sel" name="by" data-current="region"},
		'and so does the partition picker';
	like $panel, qr{<option value="rt">rt</option>},
		'a produced column can be read in again';

	# Selecting the column count does not throw the chip away: the panel is a
	# GET form on this page, and the hidden inputs above are what make the
	# submission the same view plus one column.
	like $panel, qr{<input type="hidden" name="cs" value="amount:running_total:rt">},
		'the existing column is submitted with the new one';

	# Every panel that leaves the page carries it, so a chart is drawn from the
	# same rows rather than reporting a column that does not exist there.
	for my $id (qw(graph-form pie-form heatmap-form bar-form stacked-form
		scatter-form combo-form treemap-form histogram-form wordcloud-form
		map-form pivot-form)) {
		my $form = named_form($body, $id);
		like $form, qr{name="cs" value="amount:running_total:rt"},
			"$id carries the column";
		like $form, qr{name="order" value="id:asc"}, "$id carries the read order";
		like $form, qr{name="by" value="region"},    "$id carries the partition";
	}
};

subtest 'the panel submits the view, the old column and the new one' => sub {
	# The URL the form above produces when a reader picks a second column.
	$t->get_ok(view_url(
		l     => 'table:sales',
		f     => 'region:eq:North',
		cs    => [ 'amount:running_total:rt', 'amount:rank:amount_rank' ],
		order => 'id:asc',
	))->status_is(200);
	my $body = $t->tx->res->body;

	like $body, qr{<th[^>]*>rt</th>},          'the first column is still there';
	like $body, qr{<th[^>]*>amount_rank</th>}, 'the second one was added';
	is scalar(() = $body =~ /class="chip-remove chip-remove-cs"/g), 2,
		'and both are chips';

	my $panel = panel_form($body);
	is scalar(() = $panel =~ /<input type="hidden" name="cs"/g), 2,
		'so reopening the panel would add a third, not replace the two';
};

subtest 'a partitioned view is drawn and its picker shows the partition' => sub {
	$t->get_ok(view_url(
		l     => 'table:sales',
		cs    => 'amount:running_total:rt',
		order => 'id:asc',
		by    => 'region',
	))->status_is(200);

	like $t->tx->res->body, qr{id="cross-row-by-sel" name="by" data-current="region"},
		'the partition picker shows the partition in use';

	# North row 1 (1250) then South row 2 (875.50) starts again at 875.50,
	# and North's own second row continues from 1250.  That restart is what
	# the picker is for, so it is checked through the same view as a file.
	$t->get_ok('/export?l=' . url_escape('table:sales')
		. '&cs=' . url_escape('amount:running_total:rt')
		. '&order=' . url_escape('id:asc')
		. '&by=region')->status_is(200);
	my $csv = $t->tx->res->body;
	like $csv, qr{^\d+,Widget A,North,Alice Smith,1250\.00,2025-01-15,1250\r$}m,
		'North starts its own total';
	like $csv, qr{^\d+,Widget B,South,Bob Jones,875\.50,2025-01-16,875\.5\r$}m,
		'and South restarts rather than continuing North';
	like $csv, qr{^\d+,Gadget Pro,North,Alice Smith,1875\.00,2025-01-19,3125\r$}m,
		'while North\'s next row carries on from its own first';
};

subtest 'the export request carries the column' => sub {
	$t->get_ok('/export?l=' . url_escape('table:sales')
		. '&cs=' . url_escape('amount:running_total:rt')
		. '&order=' . url_escape('id:asc'))->status_is(200);
	my $csv  = $t->tx->res->body;
	my ($head) = split /\r\n/, $csv;
	like $head, qr/\brt\b/, 'the header has the produced column';
	like $csv, qr/,1250\r?\n/, 'and the rows hold its values';
};

subtest 'a cross-row spec that cannot be honoured is refused by the page' => sub {
	$t->get_ok(view_url(l => 'table:sales', cs => 'nosuch:running_total:rt'))
		->status_is(400);
	like $t->tx->res->body, qr/nosuch/, 'the refusal names the column';

	$t->get_ok(view_url(l => 'table:sales', cs => 'amount:nosuch:rt'))
		->status_is(400);
	like $t->tx->res->body, qr/nosuch/, 'and the function';

	# A stream function without an order is refused rather than run in file
	# order, which would be a number nobody asked for.
	$t->get_ok(view_url(l => 'table:sales', cs => 'amount:running_total:rt'))
		->status_is(400);
	like $t->tx->res->body, qr/order/, 'and a missing order is named too';
};

done_testing;
