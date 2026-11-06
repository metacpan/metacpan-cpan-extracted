#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::Tray;
use Cpanel::JSON::XS ();

# A mock app with _started set and no _webview: the tray treats it as started
# but finds no native side, so every path short of the native calls runs.
package MockTrayApp;
sub new { bless { _started => 1 }, shift }

package main;

my $json = Cpanel::JSON::XS->new->canonical;

# --- new: an unknown key is ignored, tooltip and icon are kept ---
{
    my $tray = Chandra::Tray->new(icon => 'i.png', tooltip => 'tip', colour => 'red');
    is($tray->{icon}, 'i.png', 'icon kept');
    is($tray->{tooltip}, 'tip', 'tooltip kept');
    ok(!exists $tray->{colour}, 'an unknown key is not stored');
    ok(!defined $tray->{app}, 'no app means an undef app slot');
}

# --- add_item with a handler that is not code ---
{
    my $tray = Chandra::Tray->new;
    $tray->add_item('Plain', 'not code');
    is($tray->item_count, 1, 'the item is added');
    is_deeply($tray->{_handlers}, {}, 'and nothing is bound for a handler that is not code');
}

# --- every mutator syncs when the tray is active, and the sync finds no native side ---
{
    my $app  = MockTrayApp->new;
    my $tray = Chandra::Tray->new(app => $app);
    $tray->{_active} = 1;
    is($tray->add_item('A', sub { 1 }), $tray, 'add_item while active');
    is($tray->add_separator, $tray, 'add_separator while active');
    is($tray->add_submenu('Sub', [ { label => 'x' } ]), $tray, 'add_submenu while active');
    is($tray->set_icon('new.png'), $tray, 'set_icon while active');
    is($tray->set_tooltip('new tip'), $tray, 'set_tooltip while active');
    is($tray->update_item('A', label => 'B'), $tray, 'update_item while active');
    is($tray->show, $tray, 'show while active is a no-op');
    is($tray->is_active, 1, 'still marked active');
    is($tray->remove, $tray, 'remove while active with no native side');
    is($tray->is_active, 0, 'and now inactive');
}

# --- _sync on its own: inactive, no app, a mock app ---
{
    my $tray = Chandra::Tray->new;
    $tray->_sync;
    ok(1, 'sync when inactive returns');
    $tray->{_active} = 1;
    $tray->_sync;
    ok(1, 'sync with no app returns');
    $tray->{app} = MockTrayApp->new;
    $tray->_sync;
    ok(1, 'sync with a mock app returns');
}

# --- remove while active with no app at all ---
{
    my $tray = Chandra::Tray->new;
    $tray->{_active} = 1;
    $tray->remove;
    is($tray->is_active, 0, 'remove without an app just clears the flag');
}

# --- add_submenu: entries that are not references and handlers that are not code ---
{
    my $tray = Chandra::Tray->new;
    $tray->add_submenu('More', [ 'plain', { label => 'one', handler => 'nope' }, { handler => sub { 1 } } ]);
    my $items = $tray->items;
    is(scalar @$items, 1, 'one submenu entry');
    my @sub = @{ $items->[0]{submenu} };
    is(scalar @sub, 2, 'the plain element is skipped');
    is($sub[0]{label}, 'one', 'the first label is kept');
    is($sub[1]{label}, '', 'a missing label is empty');
    is_deeply([ sort keys %{ $tray->{_handlers} } ], [ $sub[1]{id} ], 'only the code handler is kept');
    is($tray->add_submenu('Bad', 'not an array'), $tray, 'a submenu that is not an array is ignored');
    is($tray->item_count, 1, 'and adds nothing');
}

# --- update_item: numeric and label searches, every key ---
{
    my $tray = Chandra::Tray->new;
    $tray->add_item('First');
    $tray->add_item(undef);
    $tray->update_item('', label => 'x');
    is($tray->items->[0]{label}, 'First', 'an empty search matches nothing');
    $tray->update_item(99, label => 'x');
    is($tray->items->[0]{label}, 'First', 'an unknown id matches nothing');
    $tray->update_item('Nope', label => 'x');
    is($tray->items->[0]{label}, 'First', 'an unknown label matches nothing, and an undef label is skipped');
    $tray->update_item(1, label => 'One', disabled => 1, checked => 1, handler => sub { 'h' }, handler => 'not code', other => 1);
    my $one = $tray->items->[0];
    is($one->{label}, 'One', 'label updated by id');
    is($one->{disabled}, 1, 'disabled set');
    is($one->{checked}, 1, 'checked set');
    is(ref $tray->{_handlers}{1}, 'CODE', 'the code handler is bound, the string one is not');
    $tray->update_item('One', disabled => 0, checked => 0);
    is($tray->items->[0]{disabled}, 0, 'disabled cleared by label');
    push @{ $tray->{_items} }, 'not a ref', { label => 'no id' };
    $tray->update_item('no id', handler => sub { 1 });
    ok(!exists $tray->{_handlers}{''}, 'an item without an id takes no handler');
    $tray->update_item(1, 'label');
    is($tray->items->[0]{label}, 'One', 'a key without a value changes nothing');
}

# --- items with a hole ---
{
    my $tray = Chandra::Tray->new;
    $tray->add_item('A');
    $#{ $tray->{_items} } = 2;
    is(scalar @{ $tray->items }, 1, 'items skips the holes');
}

# --- show with an app that is not a reference ---
{
    my $tray = Chandra::Tray->new(app => 'string');
    is($tray->show, $tray, 'show with a string app returns self');
    is($tray->is_active, 0, 'and does not activate');
}

# --- _menu_json: separators, submenus, flags, oddities ---
{
    my $tray = Chandra::Tray->new;
    $tray->add_item('Open', sub { 1 });
    $tray->add_separator;
    $tray->add_submenu('More', [ { label => 'a' }, { label => 'b' } ]);
    $tray->update_item('Open', disabled => 1, checked => 1);
    push @{ $tray->{_items} }, 'not a ref';
    push @{ $tray->items->[2]{submenu} }, 'not a ref';
    $tray->{_items}[2]{submenu}[0]{label} = undef;
    delete $tray->{_items}[2]{submenu}[1]{id};
    push @{ $tray->{_items} }, { label => undef };
    my $got = $json->decode($tray->_menu_json);
    is_deeply($got, [
        { id => 1, label => 'Open', disabled => 1, checked => 1 },
        { separator => 1 },
        { id => 0, label => 'More' },
        { id => 2, label => '  ' },
        { id => 0, label => '  b' },
        { id => 0, label => '' },
    ], 'the flattened menu with every shape');
}

# --- _make_dispatch_callback ---
{
    my $tray = Chandra::Tray->new;
    my @ran;
    $tray->add_item('A', sub { push @ran, 'A' });
    my $cb = $tray->_make_dispatch_callback;
    is(ref $cb, 'CODE', 'a code reference');
    $cb->(1);
    $cb->(2);
    $cb->(-1);
    is_deeply(\@ran, ['A'], 'the handler for id 1 ran, an unknown id and the click without on_click did nothing');
    $tray->on_click(sub { push @ran, 'click' });
    $tray->_make_dispatch_callback->(-1);
    is_deeply(\@ran, ['A', 'click'], 'with on_click set the click runs it');
}

done_testing;
