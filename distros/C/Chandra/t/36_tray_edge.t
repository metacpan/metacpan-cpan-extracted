#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::Tray');

# --- Empty menu show ---
{
	my $mock_wv = bless {}, 'MockEdge1';
	no strict 'refs';
	*MockEdge1::_tray_create = sub { return 0 };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockEdgeApp1';
	no strict 'refs';
	*MockEdgeApp1::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app, icon => 'i.png');
	my $ret = $tray->show;
	is($ret, $tray, 'show with empty menu returns self');
	is($tray->is_active, 1, 'active with empty menu');
}

# --- Double show is no-op ---
{
	my $call_count = 0;
	my $mock_wv = bless {}, 'MockEdge2';
	no strict 'refs';
	*MockEdge2::_tray_create = sub { $call_count++; return 0 };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockEdgeApp2';
	no strict 'refs';
	*MockEdgeApp2::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	$tray->show;
	is($call_count, 1, '_tray_create called only once on double show');
}

# --- remove when not active is safe ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->remove;
	is($ret, $tray, 'remove on inactive tray returns self');
}

# --- Double remove is safe ---
{
	my $destroy_count = 0;
	my $mock_wv = bless {}, 'MockEdge3';
	no strict 'refs';
	*MockEdge3::_tray_create = sub { return 0 };
	*MockEdge3::_tray_destroy = sub { $destroy_count++ };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockEdgeApp3';
	no strict 'refs';
	*MockEdgeApp3::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	$tray->remove;
	$tray->remove;
	is($destroy_count, 1, '_tray_destroy called only once');
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

# --- Rapid updates when active ---
{
	my $update_count = 0;
	my $mock_wv = bless {}, 'MockEdge4';
	no strict 'refs';
	*MockEdge4::_tray_create = sub { return 0 };
	*MockEdge4::_tray_update = sub { $update_count++ };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockEdgeApp4';
	no strict 'refs';
	*MockEdgeApp4::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	$tray->set_tooltip("t$_") for 1..10;
	is($update_count, 10, '10 rapid updates sent');
}

# --- Failed create (non-zero return) ---
{
	my $mock_wv = bless {}, 'MockEdge5';
	no strict 'refs';
	*MockEdge5::_tray_create = sub { return -1 };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockEdgeApp5';
	no strict 'refs';
	*MockEdgeApp5::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	is($tray->is_active, 0, 'not active after failed create');
}

# --- show without webview returns self ---
{
	my $mock_app = bless { _started => 1 }, 'MockEdgeApp6';
	no strict 'refs';
	*MockEdgeApp6::webview = sub { return undef };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app);
	my $ret = $tray->show;
	is($ret, $tray, 'show without webview returns self');
	is($tray->is_active, 0, 'not active without webview');
}

# --- Deferred show before app started ---
{
	my $create_count = 0;
	my $mock_wv = bless {}, 'MockEdge6';
	no strict 'refs';
	*MockEdge6::_tray_create = sub { $create_count++; return 0 };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv }, 'MockEdgeApp7';
	no strict 'refs';
	*MockEdgeApp7::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	is($create_count, 0, '_tray_create not called before app started');
	is($tray->is_active, 0, 'not active before start');
	ok($tray->{_pending}, 'pending flag set');

	# Simulate app start
	$mock_app->{_started} = 1;
	$tray->show;
	is($create_count, 1, '_tray_create called after app started');
	is($tray->is_active, 1, 'active after deferred show');
}

done_testing();
