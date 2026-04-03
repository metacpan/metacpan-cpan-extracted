#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once', 'redefine';

use_ok('Chandra::Shortcut');

# --- Invalid combo strings ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    eval { $sc->bind(undef, sub { }) };
    like($@, qr/requires a combo/, 'undef combo dies');
}

{
    eval { Chandra::Shortcut->_normalize_combo(undef) };
    like($@, qr/requires a combo/, 'normalize undef dies');
}

# --- Empty combo string ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    my $norm = Chandra::Shortcut->_normalize_combo('');
    is($norm, '', 'empty combo normalizes to empty');
}

# --- Duplicate bindings (overwrite) ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    my $called_first = 0;
    my $called_second = 0;
    $sc->bind('ctrl+s', sub { $called_first++ });
    $sc->bind('ctrl+s', sub { $called_second++ });

    my @list = $sc->list;
    is(scalar @list, 1, 'duplicate binding overwrites, not duplicates');
}

# --- Unbind non-existent combo does not crash ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    eval { $sc->unbind('ctrl+nonexistent') };
    ok(!$@, 'unbind non-existent does not die');
}

# --- Disable non-existent combo does not crash ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    eval { $sc->disable('ctrl+nonexistent') };
    ok(!$@, 'disable non-existent does not die');
}

# --- Enable non-existent combo does not crash ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    eval { $sc->enable('ctrl+nonexistent') };
    ok(!$@, 'enable non-existent does not die');
}

# --- is_bound returns false for unbound combo ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    ok(!$sc->is_bound('ctrl+never'), 'unbound combo returns false');
}

# --- Case sensitivity in combo lookup ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('CTRL+SHIFT+A', sub { });
    ok($sc->is_bound('ctrl+shift+a'), 'lookup normalizes case');
    ok($sc->is_bound('CTRL+SHIFT+A'), 'original case also works');
    ok($sc->is_bound('Ctrl+Shift+A'), 'mixed case also works');
}

# --- Disable and enable toggle correctly ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+d', sub { });

    # Disable twice
    $sc->disable('ctrl+d');
    $sc->disable('ctrl+d');
    my @list = $sc->list;
    my ($e) = grep { $_->{combo} eq 'ctrl+d' } @list;
    is($e->{enabled}, 0, 'double disable still disabled');

    # Enable once
    $sc->enable('ctrl+d');
    @list = $sc->list;
    ($e) = grep { $_->{combo} eq 'ctrl+d' } @list;
    is($e->{enabled}, 1, 'enable after double disable works');
}

# --- disable_all does not affect individual enabled flags ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+a', sub { });
    $sc->disable_all;

    my @list = $sc->list;
    my ($e) = grep { $_->{combo} eq 'ctrl+a' } @list;
    is($e->{enabled}, 1, 'individual enabled unaffected by disable_all');
    is($sc->{_disabled_all}, 1, 'global disable flag set');

    $sc->enable_all;
    is($sc->{_disabled_all}, 0, 'global disable flag cleared');
}

# --- Empty shortcut_map ---
{
    my $app = _mock_chandra_app();
    eval { $app->shortcut_map({}) };
    ok(!$@, 'empty shortcut_map does not die');
}

# --- shortcut_map requires hashref ---
{
    my $app = _mock_chandra_app();
    eval { $app->shortcut_map('not a hashref') };
    like($@, qr/requires a hashref/, 'shortcut_map dies with non-hashref');
}

# --- Special keys through full chain ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    for my $key (qw(f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12)) {
        $sc->bind($key, sub { });
        ok($sc->is_bound($key), "$key bound");
    }
    my @all = $sc->list;
    is(scalar @all, 12, 'all 12 function keys bound');
}

# --- Very long chord sequences ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+k ctrl+c', sub { 'comment' });
    ok($sc->is_bound('ctrl+k ctrl+c'), 'two-part chord bound');

    my $js = $sc->js_code;
    like($js, qr/ctrl\+k ctrl\+c/, 'chord appears in JS');
}

# --- inject with no app does not crash ---
{
    my $sc = Chandra::Shortcut->new;
    $sc->{bindings} = { 'ctrl+s' => { handler => sub{}, enabled => 1, prevent_default => 0 } };
    eval { $sc->inject };
    ok(!$@, 'inject without app does not crash');
}

# --- inject with no bindings is no-op ---
{
    my @evaled;
    my $mock = _mock_app_eval(\@evaled);
    my $sc = Chandra::Shortcut->new(app => $mock);
    $sc->inject;
    is(scalar @evaled, 0, 'inject with no bindings does not eval');
    ok(!$sc->{_injected}, '_injected not set when no bindings');
}

# --- Multiple combos with prevent_default ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+s', sub { }, prevent_default => 1);
    $sc->bind('ctrl+p', sub { }, prevent_default => 1);
    $sc->bind('ctrl+z', sub { });

    my $js = $sc->js_code;
    like($js, qr/'ctrl\+s':\{pd:1\}/, 'ctrl+s has pd:1');
    like($js, qr/'ctrl\+p':\{pd:1\}/, 'ctrl+p has pd:1');
    like($js, qr/'ctrl\+z':\{pd:0\}/, 'ctrl+z has pd:0');
}

# --- Bind then unbind then rebind ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+r', sub { 'first' });
    ok($sc->is_bound('ctrl+r'), 'bound first time');

    $sc->unbind('ctrl+r');
    ok(!$sc->is_bound('ctrl+r'), 'unbound');

    $sc->bind('ctrl+r', sub { 'second' });
    ok($sc->is_bound('ctrl+r'), 'rebound');
}

# --- Arrow key normalization round-trip ---
{
    for my $pair (['up', 'arrowup'], ['down', 'arrowdown'],
                  ['left', 'arrowleft'], ['right', 'arrowright']) {
        my ($alias, $canonical) = @$pair;
        my $sc = Chandra::Shortcut->new(app => _mock_app());
        $sc->bind("ctrl+$alias", sub { });
        ok($sc->is_bound("ctrl+$alias"), "ctrl+$alias bound by alias");
        ok($sc->is_bound("ctrl+$canonical"), "ctrl+$canonical found by canonical");
    }
}

# --- App shortcuts() lazy creation ---
{
    my $app = Chandra::App->new(title => 'Test');
    my $sc = $app->shortcuts;
    ok($sc, 'shortcuts() returns object');
    isa_ok($sc, 'Chandra::Shortcut');

    # Same instance returned
    my $sc2 = $app->shortcuts;
    is($sc, $sc2, 'shortcuts() returns same instance');
}

# --- App shortcut() convenience ---
{
    my $app = Chandra::App->new(title => 'Test');
    my $ret = $app->shortcut('ctrl+s', sub { });
    isa_ok($ret, 'Chandra::App', 'shortcut() returns app for chaining');
    ok($app->shortcuts->is_bound('ctrl+s'), 'shortcut registered');
}

# --- App shortcut_map() ---
{
    my $app = Chandra::App->new(title => 'Test');
    my $ret = $app->shortcut_map({
        'ctrl+s' => sub { 'save' },
        'ctrl+z' => sub { 'undo' },
    });
    isa_ok($ret, 'Chandra::App', 'shortcut_map returns app');
    ok($app->shortcuts->is_bound('ctrl+s'), 'ctrl+s from map');
    ok($app->shortcuts->is_bound('ctrl+z'), 'ctrl+z from map');
}

done_testing;

# --- Mock helpers ---

sub _mock_app {
    my $mock = bless {}, 'MockShortcutEdgeApp';
    no strict 'refs';
    no warnings 'redefine';
    *MockShortcutEdgeApp::bind = sub { return shift };
    *MockShortcutEdgeApp::eval = sub { };
    use strict 'refs';
    return $mock;
}

sub _mock_app_eval {
    my ($evaled_ref) = @_;
    my $mock = bless {}, 'MockShortcutEdgeApp2';
    no strict 'refs';
    no warnings 'redefine';
    *MockShortcutEdgeApp2::bind = sub { return $_[0] };
    *MockShortcutEdgeApp2::eval = sub { push @$evaled_ref, $_[1]; return $_[0] };
    use strict 'refs';
    return $mock;
}

sub _mock_chandra_app {
    require Chandra::App;
    return Chandra::App->new(title => 'Test');
}
