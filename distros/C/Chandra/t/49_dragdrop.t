#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::DragDrop;

# ---- API exists ----
{
    can_ok('Chandra::DragDrop', qw(
        new
        on_file_drop on_text_drop
        on_drag_enter on_drag_leave on_internal_drop
        add_drop_zone remove_drop_zone drop_zones
        make_draggable remove_draggable
        enable disable is_enabled
        inject js_code
        _dispatch
    ));
}

# ---- Constructor ----
{
    my $dd = Chandra::DragDrop->new;
    isa_ok($dd, 'Chandra::DragDrop');
    ok($dd->is_enabled, 'enabled by default');
}

# ---- Enable / disable ----
{
    my $dd = Chandra::DragDrop->new;
    ok($dd->is_enabled, 'initially enabled');
    $dd->disable;
    ok(!$dd->is_enabled, 'disabled');
    $dd->enable;
    ok($dd->is_enabled, 're-enabled');
}

# ---- Chaining ----
{
    my $dd = Chandra::DragDrop->new;
    my $cb = sub {};
    is($dd->on_file_drop($cb),  $dd, 'on_file_drop chains');
    is($dd->on_text_drop($cb),  $dd, 'on_text_drop chains');
    is($dd->on_drag_enter($cb), $dd, 'on_drag_enter chains');
    is($dd->on_drag_leave($cb), $dd, 'on_drag_leave chains');
    is($dd->on_internal_drop($cb), $dd, 'on_internal_drop chains');
    is($dd->enable, $dd, 'enable chains');
    is($dd->disable, $dd, 'disable chains');
}

# ---- Drop zones ----
{
    my $dd = Chandra::DragDrop->new;
    my @zones = $dd->drop_zones;
    is(scalar @zones, 0, 'no zones initially');

    $dd->add_drop_zone('#zone-1', sub {});
    $dd->add_drop_zone('.upload', sub {});
    @zones = sort $dd->drop_zones;
    is(scalar @zones, 2, 'two zones');
    is($zones[0], '#zone-1', 'zone 1');
    is($zones[1], '.upload', 'zone 2');

    $dd->remove_drop_zone('#zone-1');
    @zones = $dd->drop_zones;
    is(scalar @zones, 1, 'one zone after remove');
    is($zones[0], '.upload', 'remaining zone');
}

# ---- Draggables ----
{
    my $dd = Chandra::DragDrop->new;
    is($dd->make_draggable('.card', data => {id => 1}), $dd, 'make_draggable chains');
    is($dd->remove_draggable('.card'), $dd, 'remove_draggable chains');
}

# ---- Handler validation ----
{
    my $dd = Chandra::DragDrop->new;
    eval { $dd->on_file_drop('not a coderef') };
    like($@, qr/requires a coderef/, 'on_file_drop rejects non-coderef');

    eval { $dd->on_text_drop(42) };
    like($@, qr/requires a coderef/, 'on_text_drop rejects non-coderef');

    eval { $dd->on_drag_enter([]) };
    like($@, qr/requires a coderef/, 'on_drag_enter rejects non-coderef');

    eval { $dd->on_drag_leave({}) };
    like($@, qr/requires a coderef/, 'on_drag_leave rejects non-coderef');

    eval { $dd->on_internal_drop('nope') };
    like($@, qr/requires a coderef/, 'on_internal_drop rejects non-coderef');

    eval { $dd->add_drop_zone('#z', 'nope') };
    like($@, qr/requires a coderef/, 'add_drop_zone rejects non-coderef');
}

# ---- js_code ----
{
    my $dd = Chandra::DragDrop->new;
    $dd->on_file_drop(sub {});
    my $js = $dd->js_code;
    ok(length($js) > 100, 'js_code returns JS');
    like($js, qr/__chandraDragDrop/, 'guard variable present');
    like($js, qr/dragover/, 'dragover listener present');
    like($js, qr/drop/, 'drop listener present');
    like($js, qr/__chandra_dragdrop/, 'invoke call present');
}

# ---- js_code includes drop zones ----
{
    my $dd = Chandra::DragDrop->new;
    $dd->add_drop_zone('#upload', sub {});
    my $js = $dd->js_code;
    like($js, qr/#upload/, 'zone selector in JS');
}

# ---- js_code includes draggables ----
{
    my $dd = Chandra::DragDrop->new;
    $dd->make_draggable('.card', data_from => 'data-id');
    my $js = $dd->js_code;
    like($js, qr/\.card/, 'draggable selector in JS');
    like($js, qr/data-id/, 'data_from attribute in JS');
}

# ---- _dispatch with disabled ----
{
    my $dd = Chandra::DragDrop->new;
    my $called = 0;
    $dd->on_file_drop(sub { $called++ });
    $dd->disable;
    $dd->_dispatch('{"type":"file_drop","files":["test.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
    is($called, 0, '_dispatch skipped when disabled');
}

# ---- _dispatch file_drop ----
{
    my $dd = Chandra::DragDrop->new;
    my @got_files;
    my $got_target;
    $dd->on_file_drop(sub {
        my ($files, $target) = @_;
        @got_files = @$files;
        $got_target = $target;
    });
    $dd->_dispatch('{"type":"file_drop","files":["/tmp/a.txt","/tmp/b.png"],"target":{"id":"drop","class":"area","tag":"DIV"}}');
    is_deeply(\@got_files, ['/tmp/a.txt', '/tmp/b.png'], 'file_drop files');
    is($got_target->{id}, 'drop', 'file_drop target id');
    is($got_target->{tag}, 'DIV', 'file_drop target tag');
}

# ---- _dispatch text_drop ----
{
    my $dd = Chandra::DragDrop->new;
    my ($got_text, $got_target);
    $dd->on_text_drop(sub {
        ($got_text, $got_target) = @_;
    });
    $dd->_dispatch('{"type":"text_drop","text":"hello world","target":{"id":"","class":"","tag":"P"}}');
    is($got_text, 'hello world', 'text_drop text');
    is($got_target->{tag}, 'P', 'text_drop target tag');
}

# ---- _dispatch zone-specific ----
{
    my $dd = Chandra::DragDrop->new;
    my @zone_files;
    my @global_files;
    $dd->add_drop_zone('#upload', sub { @zone_files = @{$_[0]} });
    $dd->on_file_drop(sub { @global_files = @{$_[0]} });
    $dd->_dispatch('{"type":"file_drop","files":["x.txt"],"target":{"id":"upload","class":"","tag":"DIV"},"zone":"#upload"}');
    is_deeply(\@zone_files, ['x.txt'], 'zone handler called');
    is_deeply(\@global_files, ['x.txt'], 'global handler also called');
}

# ---- _dispatch internal_drop ----
{
    my $dd = Chandra::DragDrop->new;
    my ($got_data, $got_source, $got_target);
    $dd->on_internal_drop(sub {
        ($got_data, $got_source, $got_target) = @_;
    });
    $dd->_dispatch('{"type":"internal_drop","data":{"id":1},"source":{"id":"item-1","class":"","tag":"LI"},"target":{"id":"col-2","class":"","tag":"UL"}}');
    is($got_data->{id}, 1, 'internal_drop data');
    is($got_source->{id}, 'item-1', 'internal_drop source');
    is($got_target->{id}, 'col-2', 'internal_drop target');
}

# ---- _dispatch drag_enter ----
{
    my $dd = Chandra::DragDrop->new;
    my $enter_called = 0;
    $dd->on_drag_enter(sub { $enter_called++; return undef });
    $dd->_dispatch('{"type":"drag_enter","target":{"id":"zone","class":"","tag":"DIV"}}');
    is($enter_called, 1, 'drag_enter called');
}

# ---- _dispatch drag_leave ----
{
    my $dd = Chandra::DragDrop->new;
    my $leave_called = 0;
    $dd->on_drag_leave(sub { $leave_called++ });
    $dd->_dispatch('{"type":"drag_leave","target":{"id":"zone","class":"","tag":"DIV"}}');
    is($leave_called, 1, 'drag_leave called');
}

# ---- _dispatch invalid JSON ----
{
    my $dd = Chandra::DragDrop->new;
    my $called = 0;
    $dd->on_file_drop(sub { $called++ });
    $dd->_dispatch('not json');
    is($called, 0, 'invalid JSON ignored');
}

# ---- _dispatch unknown type ----
{
    my $dd = Chandra::DragDrop->new;
    my $called = 0;
    $dd->on_file_drop(sub { $called++ });
    $dd->_dispatch('{"type":"unknown"}');
    is($called, 0, 'unknown type ignored');
}

done_testing;
