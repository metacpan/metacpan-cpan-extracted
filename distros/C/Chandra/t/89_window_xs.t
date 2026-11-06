#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Chandra::Test::Display;

Chandra::Test::Display->skip_unless_display(module => 'Chandra::Window');

use Chandra::Window;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

# --- constructor shapes ---
{
    eval { Chandra::Window->new('odd') };
    like($@, qr/requires key => value pairs/, 'odd arguments croak');
    my $w = Chandra::Window->new(title => 'Named', id => 'named-1', content => '<p>x</p>');
    is($w->id, 'named-1', 'a given id is kept');
    my $full = Chandra::Window->new(title => 'Full', content => '<html><body>y</body></html>');
    ok($full, 'content that is already a document is not wrapped');
    $full->set_content('<html><body>z</body></html>');
    $full->set_content('<p>wrapped</p>');
    is($full->{content}, '<p>wrapped</p>', 'set_content keeps the content');
    $w->close;
    $full->close;
}

# --- modal and parent tracking ---
{
    my $parent = Chandra::Window->new(title => 'Parent');
    my $child = Chandra::Window->new(title => 'Child', parent => $parent, modal => 1);
    is($child->parent, $parent, 'the child knows its parent');
    is_deeply([ $parent->children ], [ $child ], 'and the parent lists the child');
    my $second = Chandra::Window->new(title => 'Second', parent => $parent);
    is(scalar(my @kids = $parent->children), 2, 'a second child joins the list');
    my $odd = { wid => 'not a number' };
    my $orphan = Chandra::Window->new(title => 'Orphan', parent => $odd, modal => 1);
    ok($orphan, 'a parent without a numeric wid is tracked but not modal');
    is(scalar @{ $odd->{_children} }, 1, 'and still gets the child');
    my $broken = { _children => 'not an array' };
    my $kid = Chandra::Window->new(title => 'Kid', parent => $broken);
    is(ref $broken->{_children}, 'ARRAY', 'a parent whose children slot is not an array gets a fresh one');
    is($child->set_modal($parent), $child, 'set_modal with a parent');
    is($child->set_modal, $child, 'set_modal again is a no-op');
    is($child->end_modal, $child, 'end_modal');
    is($child->end_modal, $child, 'end_modal again is a no-op');
    is($second->set_modal($odd), $second, 'set_modal with a parent lacking a numeric wid');
    $second->end_modal;
    $_->close for $kid, $orphan, $second, $child, $parent;
}

# --- every method refuses something that is not a window hash ---
{
    my $not = bless \(my $s = 1), 'Chandra::Window';
    my %arity = (map({ $_ => 0 } qw(wid id show hide focus minimize maximize close is_visible is_modal is_closed get_size get_position end_modal parent children set_modal)),
                 map({ $_ => 1 } qw(set_content navigate eval set_title on_close on_resize on_focus on_blur _add_child emit)),
                 map({ $_ => 2 } qw(set_size set_position on)));
    for my $m (sort keys %arity) {
        my @args = ('a', 'b')[0 .. $arity{$m} - 1];
        eval { Chandra::Window->can($m)->($not, @args) };
        like($@, qr/Not a Chandra::Window object/, "$m refuses a non-hash");
    }
    undef $not;
    pass('and destroying it is harmless');
}

# --- a window whose native side is gone ---
{
    my $w = Chandra::Window->new(title => 'Gone');
    $w->close;
    $w->{wid} = -1;
    is($w->set_content('<p>'), $w, 'set_content without a native window returns self');
    is($w->navigate('about:blank'), $w, 'navigate');
    $w->eval('1');
    $w->set_title('t');
    $w->set_size(1, 1);
    $w->set_position(1, 1);
    $w->show;
    $w->hide;
    $w->focus;
    $w->minimize;
    $w->maximize;
    is($w->set_modal, $w, 'set_modal without a native window returns self');
    $w->{modal} = 1;
    is($w->end_modal, $w, 'end_modal without a native window clears the flag');
    is($w->{modal}, 0, 'cleared');
    is($w->close, $w, 'close again returns self');
    $w->{width} = 'wide';
    $w->{x} = 'left';
    my ($cw, $ch) = $w->get_size;
    my ($cx, $cy) = $w->get_position;
    ok(defined $cw && defined $cx, 'sizes and positions that are not numbers fall back');
}

# --- events ---
{
    my $w = Chandra::Window->new(title => 'Events');
    delete $w->{_events};
    $w->emit('nothing');
    my @got;
    is($w->on('ping', sub { push @got, @_ }), $w, 'on with no event table makes one');
    $w->on('ping', sub { push @got, 'second' });
    push @{ $w->{_events}{ping} }, undef;
    $w->emit('ping', 1, 2);
    is_deeply(\@got, [1, 2, 'second'], 'emit runs every handler with the arguments and skips an undef one');
    $w->emit('unknown');
    $w->close;
}

# --- the class registry ---
{
    my $a = Chandra::Window->new(title => 'A', id => 'reg-a');
    my $b = Chandra::Window->new(title => 'B', id => 'reg-b');
    ok(scalar(grep { $_ == $a } Chandra::Window->windows), 'windows lists a live window');
    is(Chandra::Window->window_by_id('reg-b'), $b, 'window_by_id finds it');
    delete $b->{id};
    ok(!defined Chandra::Window->window_by_id('reg-b'), 'a window without an id is not found');
    ok(!defined Chandra::Window->window_by_id('reg-none'), 'nor an unknown id');
    is(Chandra::Window->window_by_wid($a->wid), $a, 'window_by_wid');
    ok(!defined Chandra::Window->window_by_wid(99999), 'an unknown wid is undef');
    $a->close;
    $b->close;
}

# --- children ---
{
    my $w = Chandra::Window->new(title => 'Kids');
    is_deeply([ $w->children ], [], 'no children');
    my $kid = Chandra::Window->new(title => 'Kid');
    is($w->_add_child($kid), $w, '_add_child makes the list');
    $w->_add_child($kid);
    push @{ $w->{_children} }, undef;
    is(scalar(my @c = $w->children), 2, 'children skips an undef entry');
    $kid->close;
    $w->close;
}

# --- a window dropped without close is destroyed, modal or not ---
{
    {
        my $w = Chandra::Window->new(title => 'Dropped');
        my $m = Chandra::Window->new(title => 'Dropped modal');
        $m->set_modal;
    }
    pass('windows left to go out of scope are destroyed');
}

# --- the low-level functions ---
{
    my $wid = Chandra::Window::_window_create('Low', 120, 80, -1, -1, 1, 0);
    ok($wid >= 0, 'a native window is created');
    ok(Chandra::Window::_window_exists($wid), 'and exists');
    Chandra::Window::_window_set_html($wid, '<p>low</p>');
    Chandra::Window::_window_eval_js($wid, '1+1');
    Chandra::Window::_window_set_title($wid, 'Lower');
    Chandra::Window::_window_set_size($wid, 130, 90);
    Chandra::Window::_window_set_position($wid, 10, 10);
    Chandra::Window::_window_show($wid);
    Chandra::Window::_window_hide($wid);
    Chandra::Window::_window_focus($wid);
    Chandra::Window::_window_minimize($wid);
    Chandra::Window::_window_maximize($wid);
    Chandra::Window::_window_navigate($wid, 'about:blank');
    Chandra::Window::_window_set_modal($wid, 0);
    ok(Chandra::Window::_window_is_modal($wid), 'modal after set_modal');
    Chandra::Window::_window_end_modal($wid);
    ok(!Chandra::Window::_window_is_modal($wid), 'not modal after end_modal');
    Chandra::Window::_window_destroy($wid);
    ok(!Chandra::Window::_window_exists($wid), 'and gone after destroy');
}

done_testing;
