#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::DragDrop;

# ---- Empty files array ----
{
    my $dd = Chandra::DragDrop->new;
    my $called = 0;
    $dd->on_file_drop(sub { $called++ });
    $dd->_dispatch('{"type":"file_drop","files":[],"target":{"id":"","class":"","tag":"BODY"}}');
    is($called, 0, 'empty files array does not trigger handler');
}

# ---- Many files ----
{
    my $dd = Chandra::DragDrop->new;
    my @got;
    $dd->on_file_drop(sub { @got = @{$_[0]} });
    my @files = map { "/tmp/file_$_.txt" } 1..50;
    my $json = '{"type":"file_drop","files":['
        . join(',', map { qq{"$_"} } @files)
        . '],"target":{"id":"","class":"","tag":"BODY"}}';
    $dd->_dispatch($json);
    is(scalar @got, 50, '50 files handled');
}

# ---- Unicode file paths ----
{
    my $dd = Chandra::DragDrop->new;
    my @got;
    $dd->on_file_drop(sub { @got = @{$_[0]} });
    $dd->_dispatch('{"type":"file_drop","files":["/tmp/caf\u00e9.txt","/tmp/\u2603.png"],"target":{"id":"","class":"","tag":"BODY"}}');
    is(scalar @got, 2, 'unicode paths parsed');
    like($got[0], qr/caf/, 'unicode path content');
}

# ---- Empty text drop ----
{
    my $dd = Chandra::DragDrop->new;
    my $got_text;
    $dd->on_text_drop(sub { $got_text = $_[0] });
    $dd->_dispatch('{"type":"text_drop","text":"","target":{"id":"","class":"","tag":"BODY"}}');
    is($got_text, '', 'empty text drop delivered');
}

# ---- Drop outside any zone ----
{
    my $dd = Chandra::DragDrop->new;
    my $zone_called = 0;
    my $global_called = 0;
    $dd->add_drop_zone('#special', sub { $zone_called++ });
    $dd->on_file_drop(sub { $global_called++ });
    $dd->_dispatch('{"type":"file_drop","files":["a.txt"],"target":{"id":"other","class":"","tag":"DIV"}}');
    is($zone_called, 0, 'zone handler not called for non-matching target');
    is($global_called, 1, 'global handler called');
}

# ---- Rapid sequential drops ----
{
    my $dd = Chandra::DragDrop->new;
    my $count = 0;
    $dd->on_file_drop(sub { $count++ });
    for (1..10) {
        $dd->_dispatch('{"type":"file_drop","files":["f.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
    }
    is($count, 10, 'all rapid drops processed');
}

# ---- Handler error does not crash ----
{
    my $dd = Chandra::DragDrop->new;
    $dd->on_file_drop(sub { die "boom" });
    my $ok = eval {
        $dd->_dispatch('{"type":"file_drop","files":["a.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
        1;
    };
    ok($ok, 'handler error does not propagate');
}

# ---- No handler for type ----
{
    my $dd = Chandra::DragDrop->new;
    # No handlers registered
    my $ok = eval {
        $dd->_dispatch('{"type":"file_drop","files":["a.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
        $dd->_dispatch('{"type":"text_drop","text":"hello","target":{"id":"","class":"","tag":"BODY"}}');
        $dd->_dispatch('{"type":"drag_enter","target":{"id":"","class":"","tag":"BODY"}}');
        $dd->_dispatch('{"type":"drag_leave","target":{"id":"","class":"","tag":"BODY"}}');
        $dd->_dispatch('{"type":"internal_drop","data":null,"source":null,"target":null}');
        1;
    };
    ok($ok, 'dispatch with no handlers does not crash');
}

# ---- Remove non-existent zone ----
{
    my $dd = Chandra::DragDrop->new;
    my $ok = eval { $dd->remove_drop_zone('#nonexistent'); 1 };
    ok($ok, 'removing non-existent zone is safe');
}

# ---- Remove non-existent draggable ----
{
    my $dd = Chandra::DragDrop->new;
    my $ok = eval { $dd->remove_draggable('.nonexistent'); 1 };
    ok($ok, 'removing non-existent draggable is safe');
}

# ---- Multiple drop zones, most specific wins by sending zone ----
{
    my $dd = Chandra::DragDrop->new;
    my ($outer_called, $inner_called) = (0, 0);
    $dd->add_drop_zone('#outer', sub { $outer_called++ });
    $dd->add_drop_zone('#inner', sub { $inner_called++ });
    # JS sends the deepest matching zone
    $dd->_dispatch('{"type":"file_drop","files":["a.txt"],"target":{"id":"inner","class":"","tag":"DIV"},"zone":"#inner"}');
    is($inner_called, 1, 'inner zone called');
    is($outer_called, 0, 'outer zone not called');
}

# ---- Overwrite handler ----
{
    my $dd = Chandra::DragDrop->new;
    my ($first, $second) = (0, 0);
    $dd->on_file_drop(sub { $first++ });
    $dd->on_file_drop(sub { $second++ });
    $dd->_dispatch('{"type":"file_drop","files":["a.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
    is($first, 0, 'first handler replaced');
    is($second, 1, 'second handler active');
}

# ---- Dispatch with missing target ----
{
    my $dd = Chandra::DragDrop->new;
    my $called = 0;
    $dd->on_file_drop(sub { $called++ });
    $dd->_dispatch('{"type":"file_drop","files":["a.txt"]}');
    is($called, 1, 'missing target still dispatches');
}

# ---- make_draggable with static data ----
{
    my $dd = Chandra::DragDrop->new;
    $dd->make_draggable('.item', data => {id => 42, type => 'task'});
    my $js = $dd->js_code;
    like($js, qr/\.item/, 'draggable selector in JS');
    like($js, qr/42/, 'static data in JS');
}

# ---- Toggle enable/disable between dispatches ----
{
    my $dd = Chandra::DragDrop->new;
    my $count = 0;
    $dd->on_file_drop(sub { $count++ });
    $dd->_dispatch('{"type":"file_drop","files":["a.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
    is($count, 1, 'first dispatch');
    $dd->disable;
    $dd->_dispatch('{"type":"file_drop","files":["b.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
    is($count, 1, 'skipped while disabled');
    $dd->enable;
    $dd->_dispatch('{"type":"file_drop","files":["c.txt"],"target":{"id":"","class":"","tag":"BODY"}}');
    is($count, 2, 'resumed after re-enable');
}

done_testing;
