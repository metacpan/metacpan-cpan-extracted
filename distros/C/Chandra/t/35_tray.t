#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::Tray');

# --- Constructor ---
{
	my $tray = Chandra::Tray->new;
	ok($tray, 'Tray created');
	isa_ok($tray, 'Chandra::Tray');
	is($tray->{icon}, '', 'default icon empty');
	is($tray->{tooltip}, '', 'default tooltip empty');
	is($tray->item_count, 0, 'no items initially');
	is($tray->is_active, 0, 'not active initially');
}

# --- Constructor with args ---
{
	my $mock = bless {}, 'MockTrayApp';
	my $tray = Chandra::Tray->new(
		app     => $mock,
		icon    => '/path/icon.png',
		tooltip => 'Test App',
	);
	is($tray->{app}, $mock, 'app stored');
	is($tray->{icon}, '/path/icon.png', 'icon stored');
	is($tray->{tooltip}, 'Test App', 'tooltip stored');
}

# --- Methods exist ---
{
	my $tray = Chandra::Tray->new;
	can_ok($tray, qw(
		add_item add_separator add_submenu
		set_icon set_tooltip update_item
		on_click show remove is_active
		items item_count
	));
}

# --- add_item ---
{
	my $tray = Chandra::Tray->new;
	my $called = 0;
	my $ret = $tray->add_item('Show' => sub { $called = 1 });
	is($ret, $tray, 'add_item returns self for chaining');
	is($tray->item_count, 1, '1 item added');

	my $items = $tray->items;
	is($items->[0]{label}, 'Show', 'item label');
	ok($items->[0]{id} > 0, 'item has id');

	$tray->add_item('Hide' => sub {});
	is($tray->item_count, 2, '2 items');
}

# --- add_separator ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('A' => sub {});
	my $ret = $tray->add_separator;
	is($ret, $tray, 'add_separator returns self');
	$tray->add_item('B' => sub {});
	is($tray->item_count, 3, '3 items including separator');

	my $items = $tray->items;
	ok($items->[1]{separator}, 'separator flag set');
}

# --- add_submenu ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->add_submenu('Settings' => [
		{ label => 'Theme', handler => sub {} },
		{ label => 'Language', handler => sub {} },
	]);
	is($ret, $tray, 'add_submenu returns self');
	is($tray->item_count, 1, 'submenu counts as one item');

	my $items = $tray->items;
	is($items->[0]{label}, 'Settings', 'submenu label');
	is(scalar @{$items->[0]{submenu}}, 2, '2 submenu items');
	is($items->[0]{submenu}[0]{label}, 'Theme', 'submenu item label');
}

# --- set_icon / set_tooltip ---
{
	my $tray = Chandra::Tray->new(icon => 'a.png', tooltip => 'A');
	my $ret = $tray->set_icon('b.png');
	is($ret, $tray, 'set_icon returns self');
	is($tray->{icon}, 'b.png', 'icon updated');

	$ret = $tray->set_tooltip('B');
	is($ret, $tray, 'set_tooltip returns self');
	is($tray->{tooltip}, 'B', 'tooltip updated');
}

# --- update_item by label ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('Show' => sub {});
	$tray->update_item('Show', label => 'Show Window');

	my $items = $tray->items;
	is($items->[0]{label}, 'Show Window', 'label updated by name');
}

# --- update_item by id ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('Quit' => sub {});
	my $id = $tray->items->[0]{id};
	$tray->update_item($id, disabled => 1);

	my $items = $tray->items;
	is($items->[0]{disabled}, 1, 'disabled flag set by id');
}

# --- on_click ---
{
	my $tray = Chandra::Tray->new;
	my $called = 0;
	$tray->on_click(sub { $called = 1 });
	is(ref $tray->{_on_click}, 'CODE', 'on_click handler stored');
}

# --- Chaining ---
{
	my $tray = Chandra::Tray->new;
	my $result = $tray
		->add_item('A' => sub {})
		->add_separator
		->add_item('B' => sub {})
		->set_icon('icon.png')
		->set_tooltip('Tip');
	is($result, $tray, 'chaining works');
	is($tray->item_count, 3, '3 items after chain');
}

# --- Callback dispatch ---
{
	my $tray = Chandra::Tray->new;
	my @called_ids;
	$tray->add_item('A' => sub { push @called_ids, 'A' });
	$tray->add_item('B' => sub { push @called_ids, 'B' });

	my $cb = $tray->_make_dispatch_callback;
	ok(ref $cb eq 'CODE', 'dispatch callback is a coderef');

	my $id_a = $tray->items->[0]{id};
	my $id_b = $tray->items->[1]{id};

	$cb->($id_a);
	is_deeply(\@called_ids, ['A'], 'first handler called');

	$cb->($id_b);
	is_deeply(\@called_ids, ['A', 'B'], 'second handler called');
}

# --- on_click dispatch ---
{
	my $tray = Chandra::Tray->new;
	my $click_called = 0;
	$tray->on_click(sub { $click_called = 1 });

	my $cb = $tray->_make_dispatch_callback;
	$cb->(-1);
	is($click_called, 1, 'on_click handler called with id -1');
}

# --- Menu JSON output ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('Show' => sub {});
	$tray->add_separator;
	$tray->add_item('Quit' => sub {});

	my $menu_json = $tray->_menu_json;
	ok(defined $menu_json, 'menu_json produced');

	require Cpanel::JSON::XS;
	my $decoded = Cpanel::JSON::XS::decode_json($menu_json);
	is(ref $decoded, 'ARRAY', 'decoded JSON is array');
	is(scalar @$decoded, 3, '3 entries');
	is($decoded->[0]{label}, 'Show', 'first item label');
	ok($decoded->[1]{separator}, 'separator present');
	is($decoded->[2]{label}, 'Quit', 'third item label');
}

# --- show without app returns self ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->show;
	is($ret, $tray, 'show without app returns self');
	is($tray->is_active, 0, 'not active without app');
}

# --- remove when not active ---
{
	my $tray = Chandra::Tray->new;
	my $ret = $tray->remove;
	is($ret, $tray, 'remove when not active returns self');
}

# --- show with mock XS ---
{
	my @create_calls;
	my $mock_wv = bless {}, 'MockTrayWV1';
	no strict 'refs';
	*MockTrayWV1::_tray_create = sub {
		shift;
		push @create_calls, [@_];
		return 0;
	};
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockTrayApp1';
	no strict 'refs';
	*MockTrayApp1::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(
		app     => $mock_app,
		icon    => 'icon.png',
		tooltip => 'Test',
	);
	$tray->add_item('Quit' => sub {});
	$tray->show;

	is(scalar @create_calls, 1, '_tray_create called once');
	is($create_calls[0][0], 'icon.png', 'icon passed');
	is($create_calls[0][1], 'Test', 'tooltip passed');
	ok(ref $create_calls[0][3] eq 'CODE', 'callback passed');
	is($tray->is_active, 1, 'tray is active after show');
}

# --- remove with mock XS ---
{
	my $destroy_called = 0;
	my $mock_wv = bless {}, 'MockTrayWV2';
	no strict 'refs';
	*MockTrayWV2::_tray_create = sub { return 0 };
	*MockTrayWV2::_tray_destroy = sub { $destroy_called = 1 };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockTrayApp2';
	no strict 'refs';
	*MockTrayApp2::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(app => $mock_app);
	$tray->show;
	$tray->remove;

	is($destroy_called, 1, '_tray_destroy called');
	is($tray->is_active, 0, 'not active after remove');
}

# --- _sync on update when active ---
{
	my @update_calls;
	my $mock_wv = bless {}, 'MockTrayWV3';
	no strict 'refs';
	*MockTrayWV3::_tray_create = sub { return 0 };
	*MockTrayWV3::_tray_update = sub { shift; push @update_calls, [@_] };
	use strict 'refs';

	my $mock_app = bless { _wv => $mock_wv, _started => 1 }, 'MockTrayApp3';
	no strict 'refs';
	*MockTrayApp3::webview = sub { shift->{_wv} };
	use strict 'refs';

	my $tray = Chandra::Tray->new(
		app     => $mock_app,
		icon    => 'a.png',
		tooltip => 'A',
	);
	$tray->show;
	$tray->add_item('New Item' => sub {});
	is(scalar @update_calls, 1, '_tray_update called on add_item when active');

	$tray->set_tooltip('B');
	is(scalar @update_calls, 2, '_tray_update called on set_tooltip when active');
}

# --- items returns a copy ---
{
	my $tray = Chandra::Tray->new;
	$tray->add_item('A' => sub {});
	my $items = $tray->items;
	push @$items, { fake => 1 };
	is($tray->item_count, 1, 'items returns a copy');
}

done_testing();
