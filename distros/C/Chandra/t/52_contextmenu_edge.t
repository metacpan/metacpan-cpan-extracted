#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::ContextMenu;

# ---- Empty menu ----
{
    my $cm = Chandra::ContextMenu->new;
    my $js = $cm->js_code;
    like($js, qr/items=\[\]/, 'empty items in JS');
}

# ---- Deeply nested submenus ----
{
    my $deep = { label => 'L5', action => sub {} };
    for my $i (reverse 1..4) {
        $deep = { label => "L$i", submenu => [$deep] };
    }
    my $cm = Chandra::ContextMenu->new(items => [$deep]);
    $cm->attach('#x');
    my $js = $cm->js_code;
    like($js, qr/sub:/, 'nested submenus in JS');
    ok(length($js) > 100, 'JS code generated for deep nesting');
}

# ---- Very long label ----
{
    my $long = 'A' x 500;
    my $cm = Chandra::ContextMenu->new(
        items => [{ label => $long, action => sub {} }],
    );
    my $it = $cm->items->[0];
    is(length($it->{label}), 500, 'long label stored');
    $cm->attach('#x');
    my $js = $cm->js_code;
    like($js, qr/A{100}/, 'long label in JS');
}

# ---- Attach to nonexistent selector (no crash) ----
{
    my $cm = Chandra::ContextMenu->new;
    eval { $cm->attach('#does-not-exist') };
    ok(!$@, 'attach nonexistent selector no error');
    my @att = $cm->attachments;
    is(scalar @att, 1, 'selector stored even if nonexistent');
}

# ---- Duplicate labels ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [
            { label => 'Dup', action => sub { 'first' } },
            { label => 'Dup', action => sub { 'second' } },
        ],
    );
    is(scalar @{$cm->items}, 2, 'duplicate labels allowed');
    # set_item only modifies first match
    $cm->set_item('Dup', disabled => 1);
    ok($cm->items->[0]{disabled}, 'first dup modified');
    ok(!$cm->items->[1]{disabled}, 'second dup not modified');
}

# ---- Unicode labels ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [
            { label => "\x{2603} Snowman", action => sub {} },
            { label => "Caf\x{e9}", action => sub {} },
        ],
    );
    like($cm->items->[0]{label}, qr/Snowman/, 'unicode label stored');
    $cm->attach('#x');
    my $js = $cm->js_code;
    like($js, qr/Snowman/, 'unicode in JS output');
}

# ---- Many items ----
{
    my @items = map { { label => "Item $_", action => sub {} } } 1..100;
    my $cm = Chandra::ContextMenu->new(items => \@items);
    is(scalar @{$cm->items}, 100, '100 items stored');
    $cm->attach('#x');
    my $js = $cm->js_code;
    like($js, qr/Item 100/, 'all items in JS');
}

# ---- Remove nonexistent item (no crash) ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [{ label => 'A', action => sub {} }],
    );
    eval { $cm->remove_item('NOPE') };
    ok(!$@, 'remove nonexistent no crash');
    is(scalar @{$cm->items}, 1, 'items unchanged');
}

# ---- set_item nonexistent (no crash) ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [{ label => 'A', action => sub {} }],
    );
    eval { $cm->set_item('NOPE', disabled => 1) };
    ok(!$@, 'set_item nonexistent no crash');
}

# ---- Add then remove ----
{
    my $cm = Chandra::ContextMenu->new;
    $cm->add_item({ label => 'X', action => sub {} });
    $cm->add_item({ label => 'Y', action => sub {} });
    $cm->add_item({ label => 'Z', action => sub {} });
    is(scalar @{$cm->items}, 3, '3 items');

    $cm->remove_item('Y');
    is(scalar @{$cm->items}, 2, '2 items after remove middle');
    is($cm->items->[0]{label}, 'X', 'X remains');
    is($cm->items->[1]{label}, 'Z', 'Z remains');
}

# ---- Separator-only menu ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [
            { separator => 1 },
            { separator => 1 },
        ],
    );
    $cm->attach('#x');
    my $js = $cm->js_code;
    like($js, qr/sep:1/, 'separator-only menu JS ok');
}

# ---- Dispatch malformed JSON ----
{
    my $cm = Chandra::ContextMenu->new;
    eval { $cm->_dispatch('') };
    ok(!$@, 'empty string dispatch no crash');
    eval { $cm->_dispatch('{}') };
    ok(!$@, 'empty object dispatch no crash');
    eval { $cm->_dispatch('{"type":"unknown"}') };
    ok(!$@, 'unknown type dispatch no crash');
}

# ---- Dispatch action with nonexistent ID ----
{
    my $cm = Chandra::ContextMenu->new;
    eval { $cm->_dispatch('{"type":"action","id":9999}') };
    ok(!$@, 'nonexistent action ID no crash');
}

# ---- Multiple attach/detach cycles ----
{
    my $cm = Chandra::ContextMenu->new;
    for my $i (1..10) {
        $cm->attach("#sel-$i");
    }
    my @att = $cm->attachments;
    is(scalar @att, 10, '10 attachments');
    for my $i (1..5) {
        $cm->detach("#sel-$i");
    }
    @att = $cm->attachments;
    is(scalar @att, 5, '5 remaining');
}

# ---- Items without action (display-only) ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [
            { label => 'Info', disabled => 1 },
        ],
    );
    $cm->attach('#x');
    my $js = $cm->js_code;
    like($js, qr/dis:1/, 'disabled no-action item in JS');
}

# ---- Action error handling ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [
            { label => 'Boom', action => sub { die "boom" } },
        ],
    );
    $cm->attach('#x');
    my $id = $cm->items->[0]{_id};
    my $warned = '';
    local $SIG{__WARN__} = sub { $warned = $_[0] };
    eval { $cm->_dispatch('{"type":"action","id":' . $id . '}') };
    like($warned, qr/boom/, 'action error warned');
}

# ---- Global with dynamic callback ----
{
    my $cm = Chandra::ContextMenu->new;
    my $cb_called = 0;
    $cm->attach_global(sub { $cb_called++; return [{ label => 'Dyn' }] });
    # Can't fully test without app, just verify no crash
    ok(1, 'attach_global with dynamic callback ok');
    $cm->detach_global;
    ok(1, 'detach_global after dynamic ok');
}

# ---- js_code with all features ----
{
    my $cm = Chandra::ContextMenu->new(
        items => [
            { label => 'Edit', icon => "\x{270f}", shortcut => 'Ctrl+E',
              action => sub {} },
            { separator => 1 },
            { label => 'Toggle', checkable => 1, checked => 0,
              action => sub {} },
            { label => 'More', submenu => [
                { label => 'Sub1', action => sub {} },
            ]},
            { label => 'Disabled', disabled => 1, action => sub {} },
        ],
    );
    $cm->attach_global;
    my $js = $cm->js_code;
    like($js, qr/ico:'/, 'icon in JS');
    like($js, qr/sc:'Ctrl\+E'/, 'shortcut in JS');
    like($js, qr/chk:1/, 'checkable in JS');
    like($js, qr/sub:\[/, 'submenu in JS');
    like($js, qr/dis:1/, 'disabled in JS');
    like($js, qr/isGlobal=1/, 'global flag in JS');
}

done_testing;
