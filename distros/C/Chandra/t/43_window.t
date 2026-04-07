#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

BEGIN {
    plan skip_all => 'CHANDRA_SKIP_WINDOW set' if $ENV{CHANDRA_SKIP_WINDOW};
    if ($^O ne 'darwin' && $^O ne 'MSWin32'
        && !$ENV{DISPLAY} && !$ENV{WAYLAND_DISPLAY}) {
        plan skip_all => 'No display server available';
    }
}

use Chandra;
use Chandra::Window;

{
    my $win = eval { Chandra::Window->new };
    unless ($win) {
        plan skip_all => 'multi-window not supported on this platform';
    } else {
        $win->close;
    }
}

# --- Constructor ---
{
    my $win = Chandra::Window->new(
        title   => 'Test Window',
        width   => 400,
        height  => 300,
    );
    ok($win, 'Window created');
    isa_ok($win, 'Chandra::Window');
    is($win->{title}, 'Test Window', 'title stored');
    is($win->{width}, 400, 'width stored');
    is($win->{height}, 300, 'height stored');
    ok($win->{id}, 'has auto-generated id');
    ok($win->wid >= 0, 'wid is valid');
    $win->close;
}

# --- Constructor with all options ---
{
    my $win = Chandra::Window->new(
        id        => 'settings',
        title     => 'Settings',
        width     => 500,
        height    => 400,
        x         => 100,
        y         => 100,
        resizable => 0,
        frameless => 1,
        modal     => 1,
        content   => '<h1>Settings</h1>',
    );
    is($win->id, 'settings', 'custom id');
    is($win->{x}, 100, 'x position');
    is($win->{y}, 100, 'y position');
    is($win->{resizable}, 0, 'not resizable');
    is($win->{frameless}, 1, 'frameless');
    is($win->is_modal, 1, 'modal');
    is($win->{content}, '<h1>Settings</h1>', 'content stored');
    $win->close;
}

# --- Methods exist ---
{
    my $win = Chandra::Window->new;
    can_ok($win, qw(
        wid id
        set_content navigate eval
        set_title set_size set_position
        show hide focus minimize maximize close
        is_visible is_modal get_size get_position
        set_modal end_modal
        on_close on_resize on_focus on_blur
        on emit
        parent children
    ));
    $win->close;
}

# --- set_content ---
{
    my $win = Chandra::Window->new;
    my $ret = $win->set_content('<h1>Hello</h1>');
    is($ret, $win, 'set_content returns self');
    is($win->{content}, '<h1>Hello</h1>', 'HTML stored in hash');
    $win->close;
}

# --- navigate ---
{
    my $win = Chandra::Window->new;
    my $ret = $win->navigate('https://example.com');
    is($ret, $win, 'navigate returns self');
    is($win->{url}, 'https://example.com', 'URL stored');
    $win->close;
}

# --- eval ---
{
    my $win = Chandra::Window->new;
    my $ret = $win->eval('alert("test")');
    is($ret, $win, 'eval returns self');
    $win->close;
}

# --- set_title ---
{
    my $win = Chandra::Window->new;
    my $ret = $win->set_title('New Title');
    is($ret, $win, 'set_title returns self');
    is($win->{title}, 'New Title', 'title updated');
    $win->close;
}

# --- set_size ---
{
    my $win = Chandra::Window->new;
    my $ret = $win->set_size(800, 600);
    is($ret, $win, 'set_size returns self');
    is($win->{width}, 800, 'width updated');
    is($win->{height}, 600, 'height updated');
    $win->close;
}

# --- set_position ---
{
    my $win = Chandra::Window->new;
    my $ret = $win->set_position(200, 150);
    is($ret, $win, 'set_position returns self');
    is($win->{x}, 200, 'x updated');
    is($win->{y}, 150, 'y updated');
    $win->close;
}

# --- State methods ---
{
    my $win = Chandra::Window->new;
    
    # hide/show
    my $ret = $win->hide;
    is($ret, $win, 'hide returns self');
    is($win->{visible}, 0, 'visible set to false');
    
    $ret = $win->show;
    is($ret, $win, 'show returns self');
    is($win->{visible}, 1, 'visible set to true');
    
    # focus
    $ret = $win->focus;
    is($ret, $win, 'focus returns self');
    
    # minimize
    $ret = $win->minimize;
    is($ret, $win, 'minimize returns self');
    
    # maximize
    $ret = $win->maximize;
    is($ret, $win, 'maximize returns self');
    
    $win->close;
}

# --- Getters ---
{
    my $win = Chandra::Window->new(width => 800, height => 600, x => 100, y => 200);
    
    my @size = $win->get_size;
    is($size[0], 800, 'get_size width');
    is($size[1], 600, 'get_size height');
    
    my @pos = $win->get_position;
    is($pos[0], 100, 'get_position x');
    is($pos[1], 200, 'get_position y');
    
    ok($win->is_visible, 'is_visible true initially');
    ok(!$win->is_closed, 'is_closed false initially');
    
    $win->close;
    ok($win->is_closed, 'is_closed true after close');
}

# --- Lifecycle hooks ---
{
    my $close_called = 0;
    
    my $win = Chandra::Window->new;
    
    $win->on_close(sub { $close_called = 1; return 1; });
    $win->on_resize(sub { });
    $win->on_focus(sub { });
    $win->on_blur(sub { });
    
    ok($win->{_on_close}, 'on_close callback stored');
    ok($win->{_on_resize}, 'on_resize callback stored');
    ok($win->{_on_focus}, 'on_focus callback stored');
    ok($win->{_on_blur}, 'on_blur callback stored');
    
    # close triggers on_close
    $win->close;
    ok($close_called, 'on_close callback called');
}

# --- Event system ---
{
    my $win = Chandra::Window->new;
    
    my @received;
    $win->on('test', sub { push @received, [@_]; });
    $win->on('test', sub { push @received, ['second', @_]; });
    
    $win->emit('test', 'arg1', 'arg2');
    
    is(scalar @received, 2, 'both handlers called');
    is_deeply($received[0], ['arg1', 'arg2'], 'first handler got args');
    is_deeply($received[1], ['second', 'arg1', 'arg2'], 'second handler got args');
    
    $win->close;
}

# --- Window registry ---
{
    my $count_before = Chandra::Window->window_count;
    
    my $win1 = Chandra::Window->new(id => 'win1');
    my $win2 = Chandra::Window->new(id => 'win2');
    
    is(Chandra::Window->window_count, $count_before + 2, 'window_count increased');
    
    my @windows = Chandra::Window->windows;
    ok(scalar(@windows) >= 2, 'windows() returns list');
    
    my $found = Chandra::Window->window_by_id('win1');
    ok($found, 'window_by_id finds window');
    is($found, $win1, 'window_by_id returns correct window');
    
    my $found2 = Chandra::Window->window_by_wid($win2->wid);
    ok($found2, 'window_by_wid finds window');
    is($found2, $win2, 'window_by_wid returns correct window');
    
    $win1->close;
    $win2->close;
    
    is(Chandra::Window->window_count, $count_before, 'window_count back to original');
}

# --- Modal window control ---
{
    my $parent = Chandra::Window->new;
    my $child = Chandra::Window->new;
    
    # set_modal with parent
    $child->set_modal($parent);
    ok($child->is_modal, 'is_modal true after set_modal');
    is($child->{parent}, $parent, 'parent stored');
    
    $child->end_modal;
    ok(!$child->is_modal, 'is_modal false after end_modal');
    
    $parent->close;
    $child->close;
}

# --- Parent-child tracking ---
{
    my $parent = Chandra::Window->new;
    my $child = Chandra::Window->new(parent => $parent);
    
    is($child->parent, $parent, 'child has parent ref');
    
    my @children = $parent->children;
    ok(scalar(@children) >= 1, 'parent has children');
    
    $parent->close;
    $child->close;
}

# --- Window close with on_close returning false ---
{
    my $win = Chandra::Window->new;
    my $close_prevented = 0;
    
    $win->on_close(sub { 
        $close_prevented = 1;
        return 0;  # Prevent close
    });
    
    $win->close;  # Should be prevented
    ok($close_prevented, 'on_close called');
    ok(!$win->is_closed, 'close prevented when callback returns 0');
    
    # Now allow close
    $win->on_close(sub { return 1; });
    $win->close;
    ok($win->is_closed, 'close succeeded when callback returns 1');
}

done_testing();
