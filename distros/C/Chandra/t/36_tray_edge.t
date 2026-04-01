#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra');
use_ok('Chandra::Tray');

# --- Empty menu show (no _webview → guard path) ---
{
	my $mock_app = bless { _started => 1 }, 'MockEdgeApp1';

	my $tray = Chandra::Tray->new(app => $mock_app, icon => 'i.png');
	my $ret = $tray->show;
	is($ret, $tray, 'show with empty menu returns self');
	is($tray->is_active, 0, 'not active without _webview');
}

# --- Double show is no-op ---
{
	my $mock_app = bless { _started => 1 }, 'MockEdgeApp2';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	$tray->show;
	is($tray->is_active, 0, 'double show still not active without _webview');
}

# --- remove when not active is safe ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->remove;
	is($ret, $tray, 'remove on inactive tray returns self');
}

# --- Double remove is safe ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->remove;
	$ret = $tray->remove;
	is($ret, $tray, 'double remove on inactive tray returns self');
	is($tray->is_active, 0, 'still not active after double remove');
}

# --- Double remove without webview ---
{
	my $mock_app = bless { _started => 1 }, 'MockEdgeApp3';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	$tray->remove;
	$tray->remove;
	is($tray->is_active, 0, 'double remove safe without webview');
}

# --- update_item on nonexistent label ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('A' => sub {});
	my $ret = $tray->update_item('B', label => 'C');
	is($ret, $tray, 'update_item with unknown label returns self');
	is($tray->items->[0]{label}, 'A', 'original item unchanged');
}

# --- Unicode labels ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item("\x{2603} Snowman" => sub {});
	my $items = $tray->items;
	is($items->[0]{label}, "\x{2603} Snowman", 'unicode label preserved');
}

# --- add_submenu with empty array ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->add_submenu('Empty', []);
	is($ret, $tray, 'empty submenu returns self');
	is($tray->item_count, 1, 'empty submenu added');
	is(scalar @{$tray->items->[0]{submenu}}, 0, 'submenu is empty array');
}

# --- add_submenu with non-array ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->add_submenu('Bad', 'not_array');
	is($tray->item_count, 0, 'non-array submenu not added');
}

# --- Dispatch unknown item id ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('A' => sub { die 'should not run' });
	my $cb = $tray->_make_dispatch_callback;
	# Call with an ID that doesn't exist
	eval { $cb->(9999) };
	ok(!$@, 'dispatching unknown item id does not die');
}

# --- set_icon with undef ---
{
	my $tray = Chandra::Tray->new(icon => 'a.png');
	$tray->set_icon(undef);
	is($tray->{icon}, '', 'set_icon(undef) sets empty string');
}

# --- set_tooltip with undef ---
{
	my $tray = Chandra::Tray->new(tooltip => 'A');
	$tray->set_tooltip(undef);
	is($tray->{tooltip}, '', 'set_tooltip(undef) sets empty string');
}

# --- Checked item ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('Toggle' => sub {});
	$tray->update_item('Toggle', checked => 1);
	is($tray->items->[0]{checked}, 1, 'checked flag set');

	$tray->update_item('Toggle', checked => 0);
	is($tray->items->[0]{checked}, 0, 'checked flag cleared');
}

# --- Disabled and checked in JSON ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('D' => sub {});
	$tray->update_item('D', disabled => 1, checked => 1);

	require Cpanel::JSON::XS;
	my $decoded = Cpanel::JSON::XS::decode_json($tray->_menu_json);
	is($decoded->[0]{disabled}, 1, 'disabled in JSON');
	is($decoded->[0]{checked}, 1, 'checked in JSON');
}

# --- Many items ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item("Item $_" => sub {}) for 1..50;
	is($tray->item_count, 50, '50 items added');
}

# --- Rapid tooltip changes ---
{
	my $tray = Chandra::Tray->new(icon => 'i.png', tooltip => 'Start');
	$tray->set_tooltip("t$_") for 1..10;
	is($tray->{tooltip}, 't10', 'tooltip updated after 10 rapid changes');
	is($tray->item_count, 0, 'no items affected by tooltip changes');
}

# --- show without _webview returns self ---
{
	my $mock_app = bless { _started => 1 }, 'MockEdgeApp5';

	my $tray = Chandra::Tray->new(app => $mock_app);
	my $ret = $tray->show;
	is($ret, $tray, 'show without _webview returns self');
	is($tray->is_active, 0, 'not active without _webview');
}

# --- Deferred show before app started ---
{
	my $mock_app = bless {}, 'MockEdgeApp7';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	is($tray->is_active, 0, 'not active before start');
	ok($tray->{_pending}, 'pending flag set');

	# Simulate app start (still no _webview, but tests the pending logic)
	$mock_app->{_started} = 1;
	$tray->show;
	is($tray->is_active, 0, 'not active without _webview even after start');
	ok(!$tray->{_pending} || $tray->{_pending} == 0, 'pending cleared after show attempt');
}

done_testing();
