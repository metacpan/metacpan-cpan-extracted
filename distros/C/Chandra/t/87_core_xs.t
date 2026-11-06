#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra;
use Chandra::App;

my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

# --- the dispatcher before any bind exists ---
{
    Chandra::_xs_dispatch('{"type":"call","id":1,"method":"nothing"}');
    pass('a dispatch before any bind is set up does nothing');
}

# --- the invoke callback with no Perl callback ---
{
    my $w = Chandra->new(title => 'plain');
    $w->_xs_test_invoke('{"type":"call","id":1}');
    pass('an invoke with no callback does nothing');
    $w->_xs_test_tray_menu(1);
    pass('a tray menu click with no tray callback does nothing');
}

# --- the callback given to new, replaced and removed ---
{
    my @got;
    my $w = Chandra->new(callback => sub { push @got, $_[0] });
    $w->_xs_test_invoke('{"type":"call","id":2}');
    is_deeply(\@got, ['{"type":"call","id":2}'], 'the callback from new gets the raw argument');
    $w->_set_callback(sub { push @got, "second:$_[0]" });
    $w->_xs_test_invoke('x');
    is($got[-1], 'second:x', 'a replaced callback gets the next one');
    $w->_set_callback('not a reference');
    $w->_xs_test_invoke('y');
    is(scalar @got, 2, 'a callback that is not a reference removes it');
    $w->_set_callback(undef);
    $w->_set_callback(sub { push @got, "third:$_[0]" });
    $w->_xs_test_invoke('z');
    is($got[-1], 'third:z', 'and one set again after that works');
}

# --- the page load signal: the first is the initial render, the next a reload ---
{
    my $w = Chandra->new;
    my $load = '{"type":"pageload"}';
    $w->_xs_test_invoke($load);
    pass('the first page load is skipped');
    $w->_xs_test_invoke($load);
    pass('a second one with no refresh target does nothing');
    $w->_xs_test_invoke($load);

    my (@refreshed, @reloaded);
    {
        package RefreshTarget;
        sub refresh { push @refreshed, $_[0] }
    }
    my $target = bless { _on_reload => sub { push @reloaded, $_[0] } }, 'RefreshTarget';
    $Chandra::App::_refresh_target = $target;
    $w->_xs_test_invoke($load);
    is(scalar @refreshed, 1, 'a reload refreshes the target');
    is(scalar @reloaded, 1, 'and runs its on_reload');
    $w->_xs_test_invoke($load);
    $target->{_on_reload} = 'not code';
    $w->_xs_test_invoke($load);
    is(scalar @refreshed, 2, 'a target without on_reload code is refreshed alone');
    {
        package RefreshDies;
        sub refresh { die "refresh died\n" }
    }
    $Chandra::App::_refresh_target = bless { _on_reload => sub { die "reload died\n" } }, 'RefreshDies';
    $w->_xs_test_invoke($load);
    $w->_xs_test_invoke($load);
    ok(!$@, 'a refresh and an on_reload that die are swallowed');
    $Chandra::App::_refresh_target = undef;
}

# --- the bind set up on a window ---
{
    my $w = Chandra->new;
    $w->_xs_init_bind;
    isa_ok($Chandra::_xs_bind, 'Chandra::Bind', 'init_bind makes the bind');
    my $bind = $Chandra::_xs_bind;
    $w->_xs_init_bind;
    is($Chandra::_xs_bind, $bind, 'a second init on the same window keeps it');
    my $other = Chandra->new;
    $other->_xs_init_bind;
    isnt($Chandra::_xs_bind, $bind, 'another window gets a new bind');
    ok($Chandra::_xs_bind->{app} == $other, 'bound to the new window');

    Chandra::Bind->register_handler('double', sub { $_[0] * 2 });
    Chandra::_xs_dispatch('{"type":"call","id":1,"method":"double","args":[21]}');
    Chandra::_xs_dispatch('{"type":"call","id":2,"method":"nothing"}');
    Chandra::_xs_dispatch('"raw"');
    Chandra::_xs_dispatch('not json');
    pass('a call, an unknown method, a raw message and bad JSON all dispatch without a webview');
    ok(scalar(grep { /Failed to parse JSON/ } @warned), 'the bad JSON warned');
    $Chandra::_xs_bind->{app} = undef;
    Chandra::_xs_dispatch('{"type":"call","id":3,"method":"double","args":[1]}');
    pass('a dispatch with no app in the bind does nothing more');
}

done_testing;
