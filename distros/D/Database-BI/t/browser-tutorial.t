#!/usr/bin/env perl

# The tutorial is a side trip, not a place you can lose your work.
#
# The shared layout gives every page a Tutorial link and, where there is one,
# a Help: <chapter> link.  Both carry target="_blank", and F1 follows the Help
# link (or the Tutorial link on a page without a chapter).  This test presses
# the real F1 key through Firefox and watches the browser's window list, so a
# link that still replaced the current view - or a key handler that never ran -
# fails here rather than passing on a source-level check.
#
#   AUTHOR_TESTING=1 prove -l t/browser-tutorial.t
#
# It skips without AUTHOR_TESTING or without Firefox, like the other
# t/browser-*.t files.

use strict;
use warnings;

use Test::Most;
use lib 't/lib';
use BI::Test::Browser ();

BI::Test::Browser->plan_browser_tests(required_files => ['data/sales.csv']);

# WebDriver's key value for F1.  The named keys are in the Unicode private use
# area, and Marionette rejects the string 'F1' as not a single code point.
my $F1 = "\x{E031}";

my $browser = BI::Test::Browser->new;

sub handles {
	my ($browser) = @_;
	return $browser->{client}->cmd('WebDriver:GetWindowHandles');
}

# Poll the window list until a handle that was not there before appears.
sub new_handle {
	my ($browser, $before) = @_;
	my %seen = map { $_ => 1 } @$before;

	return $browser->wait_for(sub {
		my ($handle) = grep { !$seen{$_} } @{ handles($browser) };
		return $handle;
	}, timeout => 5);
}

# Switch to the tab just opened, read its URL, close it, and come back.  The
# original tab is named explicitly: closing a tab does not promise which one
# Firefox makes current.
sub visit_new_tab {
	my ($browser, $before) = @_;

	my $handle = new_handle($browser, $before);
	ok $handle, 'a new tab opened';
	return unless $handle;

	$browser->{client}->cmd('WebDriver:SwitchToWindow' => { handle => $handle });

	my $url = $browser->wait_for(sub {
		my $seen = $browser->js('return location.href;');
		return $seen if defined $seen && $seen =~ m{/tutorial(?:\#|\z)};
		return undef;
	}, timeout => 5);

	$browser->{client}->cmd('WebDriver:CloseWindow' => {});
	$browser->{client}->cmd('WebDriver:SwitchToWindow' => { handle => $before->[0] });

	return $url;
}

# ---------------------------------------------------------------------------
# F1 on a page with a chapter: the pie chart's own chapter, not the top.
# ---------------------------------------------------------------------------
$browser->navigate('/pie?l=table:sales&cat=region&val=amount');
ok $browser->wait_for(sub { $browser->js("return !!document.getElementById('site-nav-help');") }),
	'the pie chart page loaded with its Help link';

my $before = handles($browser);
$browser->press($F1);
my $url = visit_new_tab($browser, $before);

is $url, $browser->uri('/tutorial#pie-chart'),
	'F1 opened the pie chart chapter in a new tab';

# ---------------------------------------------------------------------------
# F1 on a page without a chapter: the tutorial's top is the fallback.
# ---------------------------------------------------------------------------
$browser->navigate('/tutorial');
ok $browser->wait_for(sub { $browser->js("return !!document.getElementById('site-nav-tutorial');") }),
	'the tutorial page loaded without a Help link of its own';

$before = handles($browser);
$browser->press($F1);
$url = visit_new_tab($browser, $before);

is $url, $browser->uri('/tutorial'),
	'F1 opened the tutorial top when the page has no chapter';

# ---------------------------------------------------------------------------
# The header link itself: the pointer and F1 must agree about the new tab.
# ---------------------------------------------------------------------------
$browser->navigate('/browse');
ok $browser->wait_for(sub { $browser->js("return !!document.getElementById('site-nav-tutorial');") }),
	'a page loaded with the header Tutorial link';

$before = handles($browser);
$browser->click('#site-nav-tutorial');
$url = visit_new_tab($browser, $before);

is $url, $browser->uri('/tutorial'),
	'the header Tutorial link opened in a new tab';

done_testing();
