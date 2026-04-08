#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
no warnings 'once';

use Chandra::Window;
use Chandra::Test::Display;

Chandra::Test::Display->skip_unless_display(module => 'Chandra::Window');

# --- Window creation on unsupported platform ---
# (Can't easily test without actually running on unsupported platform)
# This is platform-dependent, so we just test that it works on this platform
{
    my $win = Chandra::Window->new(title => 'Test');
    ok($win, 'Window creates on this platform');
    ok($win->wid >= 0, 'has valid wid');
    $win->close;
}

# --- Multiple windows created and destroyed ---
{
    my @windows;
    for (1..10) {
        push @windows, Chandra::Window->new;
    }
    is(scalar @windows, 10, 'created 10 windows');
    
    my $count = Chandra::Window->window_count;
    ok($count >= 10, 'at least 10 windows in registry');
    
    for my $win (@windows) {
        $win->close;
    }
    
    # All should be closed
    my $all_closed = 1;
    for my $win (@windows) {
        $all_closed = 0 unless $win->is_closed;
    }
    ok($all_closed, 'all 10 windows closed');
}

# --- HTML content with full HTML tag preserved ---
{
    my $win = Chandra::Window->new(
        content => '<html><body>Full HTML</body></html>'
    );
    ok($win->{content}, 'content stored');
    like($win->{content}, qr/<html>/, 'full HTML preserved in hash');
    $win->close;
}

# --- Chaining methods ---
{
    my $win = Chandra::Window->new;
    my $result = $win->set_title('Title')
                     ->set_size(800, 600)
                     ->set_position(100, 100)
                     ->set_content('<h1>Hi</h1>');
    is($result, $win, 'methods chain correctly');
    is($win->{title}, 'Title', 'chained title');
    is($win->{width}, 800, 'chained width');
    $win->close;
}

# --- Parent-child creation ---
{
    my $parent = Chandra::Window->new(id => 'parent');
    my $child = Chandra::Window->new(id => 'child', parent => $parent);
    
    my @children = $parent->children;
    is(scalar @children, 1, 'parent has 1 child');
    is($children[0], $child, 'correct child');
    is($child->parent, $parent, 'child knows parent');
    
    $child->close;
    $parent->close;
}

# --- Event handlers multiple ---
{
    my $win = Chandra::Window->new;
    
    my @calls;
    $win->on('event', sub { push @calls, 'h1' });
    $win->on('event', sub { push @calls, 'h2' });
    $win->on('event', sub { push @calls, 'h3' });
    
    $win->emit('event');
    is_deeply(\@calls, ['h1', 'h2', 'h3'], 'all handlers called in order');
    
    $win->close;
}

# --- Window not found returns undef ---
{
    my $not_found = Chandra::Window->window_by_id('nonexistent');
    ok(!defined $not_found, 'window_by_id returns undef for unknown id');
    
    $not_found = Chandra::Window->window_by_wid(999999);
    ok(!defined $not_found, 'window_by_wid returns undef for unknown wid');
}

# --- Empty event emission ---
{
    my $win = Chandra::Window->new;
    eval { $win->emit('no_handlers'); };
    ok(!$@, 'emit with no handlers does not die');
    $win->close;
}

# --- Multiple close calls are safe ---
{
    my $win = Chandra::Window->new;
    $win->close;
    eval { $win->close; };  # Second close
    ok(!$@, 'double close does not die');
}

# --- Window with URL in constructor ---
{
    my $win = Chandra::Window->new(url => 'https://test.com');
    is($win->{url}, 'https://test.com', 'URL stored from constructor');
    $win->close;
}

# --- Windows enumeration ---
{
    my $win1 = Chandra::Window->new;
    my $win2 = Chandra::Window->new;
    
    my @windows = Chandra::Window->windows;
    ok(scalar @windows >= 2, 'windows returns at least our 2');
    
    # Both should be findable
    my $found_win1 = 0;
    my $found_win2 = 0;
    for my $w (@windows) {
        $found_win1 = 1 if $w == $win1;
        $found_win2 = 1 if $w == $win2;
    }
    ok($found_win1 && $found_win2, 'both windows in list');
    
    $win1->close;
    $win2->close;
}

# --- window_by_wid ---
{
    my $win = Chandra::Window->new;
    my $wid = $win->wid;
    
    my $found = Chandra::Window->window_by_wid($wid);
    is($found, $win, 'window_by_wid finds window');
    
    $win->close;
}

# --- Modal with no parent ---
{
    my $win = Chandra::Window->new;
    $win->set_modal;  # No parent
    ok($win->is_modal, 'modal without parent');
    $win->end_modal;
    $win->close;
}

# --- get_size and get_position ---
{
    my $win = Chandra::Window->new(width => 123, height => 456, x => 10, y => 20);
    
    my @size = $win->get_size;
    is($size[0], 123, 'get_size width');
    is($size[1], 456, 'get_size height');
    
    my @pos = $win->get_position;
    is($pos[0], 10, 'get_position x');
    is($pos[1], 20, 'get_position y');
    
    $win->close;
}

done_testing();
