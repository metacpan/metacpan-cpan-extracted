#!/usr/bin/perl

# The pivot table's column headers, driven from the keyboard, in a real browser.
#
# t/model.t proves the template carries the handlers, the instructions and the
# live region.  That is a test of the page's source.  This test presses real
# keys and follows them through: a header is focused by the browser, Enter sorts
# the rows, Space sorts by another column, Shift+Right moves a column, and the
# announcement and the rows are read back from what the browser actually did.
#
# The keys go through the browser's own input stack (WebDriver key actions),
# not through KeyboardEvents made up in the page, so a handler wired to the
# wrong element - or to an element that never receives focus - fails here.
#
# A header is not a button: the browser will not put it in the tab order or
# activate it by itself.  That makes this the only place the tabindex, the
# keydown handler and the focus ring can be shown to work together rather than
# merely to exist.
#
# The second part checks the limit as well as the feature: with a two-row
# header (a column dimension), moving a measure column would leave its group
# label over the wrong measures, so Shift+Left/Right does nothing there.  The
# same keys are pressed, and the table is asserted to be unchanged.
#
# The fixture (t/lib/BI/Test/Browser.pm) starts the app, Firefox and Marionette;
# the whole suite runs as
#   prove -l t/browser-*.t
# and skips when there is no Firefox, or when BI_SKIP_BROWSER_TESTS is set.

use strict;
use warnings;

use Test::Most;
use FindBin qw($Bin);
use lib "$Bin/lib";
use JSON::MaybeXS qw(decode_json);

use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

my $browser = BI::Test::Browser->new;

# One row dimension and one measure: a single header row, so a column can be
# moved.  data/sales.csv has four regions, which sort to a known order.
my $PIVOT = '/pivot?l=table%3Asales&rows=region&m=%3Acount%3Arows';

# The leaf headers - the ones that map onto the data columns - and what each of
# them says about itself.
sub headers {
	my $json = $browser->js(<<'JS');
/* The leaf headers are the cells of the last header row - the ones that map
 * onto data columns - so the group labels above them are not counted. */
var ths = Array.from(document.querySelectorAll('.pivot-table thead tr:last-of-type th'));
return JSON.stringify(ths.map(function (th) {
	return {
		text : th.textContent.trim(),
		tab  : th.getAttribute('tabindex'),
		sort : th.getAttribute('aria-sort'),
		desc : th.getAttribute('aria-describedby'),
		keys : th.title.indexOf('Enter to sort') >= 0,
	};
}));
JS
	return defined $json ? decode_json($json) : [];
}

# The body of the table, as rows of cells, in the order it is drawn.
sub rows {
	my $json = $browser->js(<<'JS');
return JSON.stringify(Array.from(document.querySelectorAll('.pivot-table tbody tr')).map(function (tr) {
	return Array.from(tr.cells).map(function (td) { return td.textContent.trim(); });
}));
JS
	return defined $json ? decode_json($json) : [];
}

sub live {
	my $text = $browser->js("return document.getElementById('pivot-live').textContent;");
	return defined $text ? $text : '';
}

# ---------------------------------------------------------------------------
# The header is a control, and the browser can reach it.
# ---------------------------------------------------------------------------

$browser->navigate($PIVOT);
ok $browser->wait_for(sub { @{ headers() } >= 2 ? 1 : undef }, timeout => 10),
	'the pivot table rendered with its leaf headers';

my $before = headers();
is scalar @$before, 2, 'one row dimension and one measure give two leaf headers';
is $before->[0]{tab}, '0', 'the first header is in the tab order';
is $before->[1]{tab}, '0', 'and so is the second';
is $before->[0]{desc}, 'pivot-head-help', 'the header points at the instructions';
is $before->[1]{desc}, 'pivot-head-help', 'both of them do';
is $before->[0]{sort}, 'none', 'and neither column is sorted yet';
is $before->[0]{keys}, 1, 'the title says the keys do what the pointer does';

$browser->focus('.pivot-table thead th');
is $browser->js("return document.activeElement.getAttribute('aria-describedby');"),
	'pivot-head-help', 'focus can be put on the header, which is what makes it a control';

# ---------------------------------------------------------------------------
# Enter sorts by the focused column, and says so.
# ---------------------------------------------------------------------------

$browser->press('Enter');

my $asc = $browser->wait_for(sub {
	my $h = headers();
	return undef unless $h->[0]{sort} eq 'ascending';
	my $r = rows();
	return @$r >= 2 ? $r : undef;
}, timeout => 5);

ok $asc, 'Enter on the header sorted by it, ascending';
is_deeply [ map { $_->[0] } @$asc ], [qw(East North South West)],
	'and the rows are in the order that column puts them in';
is headers()->[1]{sort}, 'none', 'the column that was not pressed is no longer sorted';
is $browser->wait_for(sub { live() =~ /^Sorted by .+ ascending$/ ? 1 : undef }, timeout => 5),
	1, 'and the sort was announced';
like live(), qr/^Sorted by .+ ascending$/, 'naming the column and the direction';

$browser->press('Enter');

my $desc = $browser->wait_for(sub {
	my $h = headers();
	return undef unless $h->[0]{sort} eq 'descending';
	my $r = rows();
	return @$r >= 2 ? $r : undef;
}, timeout => 5);

ok $desc, 'Enter again reverses it';
is_deeply [ map { $_->[0] } @$desc ], [qw(West South North East)],
	'and the rows are in the other order';
is $browser->wait_for(sub { live() =~ /descending$/ ? 1 : undef }, timeout => 5),
	1, 'the reversal is announced too';

# Space is the other key a button answers, and it sorts by the column it is
# pressed on rather than the one that was sorted before.
$browser->focus('.pivot-table thead th:nth-child(2)');
$browser->press('Space');

my $byCount = $browser->wait_for(sub {
	my $h = headers();
	return undef unless $h->[1]{sort} eq 'ascending';
	return $h;
}, timeout => 5);

ok $byCount, 'Space on the second header sorts by that column';
is $byCount->[0]{sort}, 'none', 'and the first column stops being the sorted one';
is $browser->wait_for(sub { live() =~ /^Sorted by .+, ascending$/ ? 1 : undef }, timeout => 5),
	1, 'which is announced as well';

# ---------------------------------------------------------------------------
# Shift+Right moves the focused column, and says where it went.
# ---------------------------------------------------------------------------

$browser->focus('.pivot-table thead th:nth-child(1)');
my $firstText  = headers()->[0]{text};
my $secondText = headers()->[1]{text};

$browser->press('ArrowRight', shift => 1);

my $moved = $browser->wait_for(sub {
	my $h = headers();
	return undef unless $h->[1]{text} eq $firstText;
	return $h;
}, timeout => 5);

ok $moved, 'Shift+Right moved the focused column one place right';
is $moved->[0]{text}, $secondText, 'the column it passed is now first';
is $moved->[0]{tab}, '0', 'the moved column is still a control';
is $moved->[1]{tab}, '0', 'and so is the one it passed';

is decode_json($browser->active())->{text}, $firstText,
	'focus stayed on the column that moved, so the next press moves it again';
is $browser->wait_for(sub { live() =~ /^Moved .+ to column 2 of 2$/ ? 1 : undef }, timeout => 5),
	1, 'and the move was announced with where the column went';

# The cells moved with the header: with the measure column first, the number
# is the first cell of every row, and the region is the last.
my $rowsNow = rows();
is scalar @{ $rowsNow->[0] }, 2, 'the rows still have one cell per header';
like $rowsNow->[0][0], qr/^\d+$/, 'the measure is in the first cell now';
ok !ref $rowsNow->[0][1] && length $rowsNow->[0][1], 'and the region in the second';

# ... and Shift+Left puts it back.
$browser->press('ArrowLeft', shift => 1);
my $back = $browser->wait_for(sub {
	my $h = headers();
	return undef unless $h->[0]{text} eq $firstText;
	return $h;
}, timeout => 5);
ok $back, 'Shift+Left moves it back';
is $back->[1]{text}, $secondText, 'to the place it came from';
is $browser->wait_for(sub { live() =~ /^Moved .+ to column 1 of 2$/ ? 1 : undef }, timeout => 5),
	1, 'announced as a move to column 1';

# ---------------------------------------------------------------------------
# A two-row header is not reordered: the keys are the same, and do nothing.
# ---------------------------------------------------------------------------

$browser->navigate('/pivot?l=table%3Asales&rows=region&cols=product'
	. '&m=%3Acount%3Arows&m=amount%3Asum%3Arevenue');
ok $browser->wait_for(sub {
	$browser->js("return document.querySelectorAll('.pivot-table thead tr:nth-child(2) th').length >= 2 ? 1 : undef;")
}, timeout => 10), 'the pivot rendered with a two-row header';

my $leafJs = <<'JS';
var ths = Array.from(document.querySelectorAll('.pivot-table thead tr:nth-child(2) th'));
return JSON.stringify(ths.map(function (th) {
	return { text : th.textContent.trim(), tab : th.getAttribute('tabindex'), sort : th.getAttribute('aria-sort') };
}));
JS
my $twoBefore = decode_json($browser->js($leafJs));
is scalar @$twoBefore, 6, 'three product values by two measures are the leaf headers';
is $twoBefore->[0]{tab}, '0', 'and they are still controls';

$browser->focus('.pivot-table thead tr:nth-child(2) th');
is $browser->js("return document.activeElement.textContent.trim();"), $twoBefore->[0]{text},
	'focus is on the first measure';

$browser->press('ArrowRight', shift => 1);
$browser->press('Enter');

my $twoAfter = decode_json($browser->js($leafJs));
is_deeply [ map { $_->{text} } @$twoAfter ], [ map { $_->{text} } @$twoBefore ],
	'Shift+Right left the measures where they are: a drag is not offered here';
is $twoAfter->[0]{sort}, 'ascending', 'but Enter still sorts, which is offered';
is $browser->wait_for(sub { length live() ? 1 : undef }, timeout => 5),
	1, 'and the sort is announced';

# What this run established, for the job summary: the tab order, the key
# handlers and the limit on moving a measure column beside a group label.
$browser->proved(
	'GET /pivot: a header takes focus from the browser, Enter and Space sort the'
	. ' rows, Shift+Arrow moves a measure column with its announcement, and a'
	. ' two-row header refuses the move while Enter still sorts'
);

done_testing;
