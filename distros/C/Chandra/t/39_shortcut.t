#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once', 'redefine';

use_ok('Chandra::Shortcut');

# --- Constructor ---
{
    my $sc = Chandra::Shortcut->new;
    ok($sc, 'Shortcut created');
    isa_ok($sc, 'Chandra::Shortcut');
}

# --- Constructor with app ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    ok($sc, 'Shortcut created with app');
    ok(exists $sc->{app}, 'app stored');
}

# --- _normalize_combo: basic modifiers ---
{
    is(Chandra::Shortcut->_normalize_combo('ctrl+s'),
       'ctrl+s', 'basic ctrl+s');

    is(Chandra::Shortcut->_normalize_combo('Ctrl+S'),
       'ctrl+s', 'case insensitive');

    is(Chandra::Shortcut->_normalize_combo('shift+ctrl+s'),
       'ctrl+shift+s', 'modifiers reordered to canonical');

    is(Chandra::Shortcut->_normalize_combo('alt+shift+ctrl+a'),
       'ctrl+shift+alt+a', 'three modifiers canonical order');

    is(Chandra::Shortcut->_normalize_combo('meta+shift+ctrl+alt+x'),
       'ctrl+shift+alt+meta+x', 'all four modifiers canonical order');
}

# --- _normalize_combo: mod mapping ---
{
    my $norm = Chandra::Shortcut->_normalize_combo('mod+s');
    if ($^O eq 'darwin') {
        is($norm, 'meta+s', 'mod maps to meta on macOS');
    } else {
        is($norm, 'ctrl+s', 'mod maps to ctrl on non-macOS');
    }

    my $norm2 = Chandra::Shortcut->_normalize_combo('mod+shift+z');
    if ($^O eq 'darwin') {
        is($norm2, 'shift+meta+z', 'mod+shift maps correctly on macOS');
    } else {
        is($norm2, 'ctrl+shift+z', 'mod+shift maps correctly on non-macOS');
    }
}

# --- _normalize_combo: key aliases ---
{
    like(Chandra::Shortcut->_normalize_combo('ctrl+up'),
        qr/ctrl\+arrowup/, 'up -> arrowup');

    like(Chandra::Shortcut->_normalize_combo('ctrl+down'),
        qr/ctrl\+arrowdown/, 'down -> arrowdown');

    like(Chandra::Shortcut->_normalize_combo('ctrl+left'),
        qr/ctrl\+arrowleft/, 'left -> arrowleft');

    like(Chandra::Shortcut->_normalize_combo('ctrl+right'),
        qr/ctrl\+arrowright/, 'right -> arrowright');

    is(Chandra::Shortcut->_normalize_combo('esc'),
       'escape', 'esc -> escape');

    is(Chandra::Shortcut->_normalize_combo('del'),
       'delete', 'del -> delete');

    is(Chandra::Shortcut->_normalize_combo('return'),
       'enter', 'return -> enter');
}

# --- _normalize_combo: modifier aliases ---
{
    like(Chandra::Shortcut->_normalize_combo('cmd+s'),
        qr/meta\+s/, 'cmd -> meta');

    like(Chandra::Shortcut->_normalize_combo('command+s'),
        qr/meta\+s/, 'command -> meta');

    like(Chandra::Shortcut->_normalize_combo('super+s'),
        qr/meta\+s/, 'super -> meta');

    like(Chandra::Shortcut->_normalize_combo('option+s'),
        qr/alt\+s/, 'option -> alt');

    like(Chandra::Shortcut->_normalize_combo('control+s'),
        qr/ctrl\+s/, 'control -> ctrl');
}

# --- _normalize_combo: single keys ---
{
    is(Chandra::Shortcut->_normalize_combo('f5'), 'f5', 'F5 key');
    is(Chandra::Shortcut->_normalize_combo('F5'), 'f5', 'F5 uppercase');
    is(Chandra::Shortcut->_normalize_combo('escape'), 'escape', 'escape key');
    is(Chandra::Shortcut->_normalize_combo('tab'), 'tab', 'tab key');
    is(Chandra::Shortcut->_normalize_combo('enter'), 'enter', 'enter key');
    is(Chandra::Shortcut->_normalize_combo('backspace'), 'backspace', 'backspace key');
    is(Chandra::Shortcut->_normalize_combo('delete'), 'delete', 'delete key');
}

# --- _normalize_combo: chord sequences ---
{
    is(Chandra::Shortcut->_normalize_combo('ctrl+k ctrl+c'),
       'ctrl+k ctrl+c', 'chord sequence');

    is(Chandra::Shortcut->_normalize_combo('Ctrl+K Ctrl+C'),
       'ctrl+k ctrl+c', 'chord sequence case insensitive');
}

# --- _normalize_combo: special keys ---
{
    is(Chandra::Shortcut->_normalize_combo('ctrl+plus'),
       'ctrl++', 'plus key alias');

    is(Chandra::Shortcut->_normalize_combo('ctrl+minus'),
       'ctrl+-', 'minus key alias');

    is(Chandra::Shortcut->_normalize_combo('ctrl+equal'),
       'ctrl+=', 'equal key alias');

    is(Chandra::Shortcut->_normalize_combo('ctrl+space'),
       'ctrl+ ', 'space key alias');
}

# --- bind and is_bound ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+s', sub { 'save' });
    ok($sc->is_bound('ctrl+s'), 'ctrl+s is bound');
    ok(!$sc->is_bound('ctrl+z'), 'ctrl+z is not bound');
}

# --- bind normalizes combo ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('Shift+Ctrl+S', sub { 'save_as' });
    ok($sc->is_bound('ctrl+shift+s'), 'bound with normalized combo');
    ok($sc->is_bound('Shift+Ctrl+S'), 'is_bound normalizes too');
}

# --- bind chaining ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    my $ret = $sc->bind('ctrl+s', sub { })
                 ->bind('ctrl+z', sub { });
    isa_ok($ret, 'Chandra::Shortcut', 'bind returns self for chaining');
}

# --- bind requires handler coderef ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    eval { $sc->bind('ctrl+s', 'not a coderef') };
    like($@, qr/requires a handler coderef/, 'bind dies without coderef');
}

# --- bind requires combo ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    eval { $sc->bind(undef, sub { }) };
    like($@, qr/requires a combo string/, 'bind dies without combo');
}

# --- unbind ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+s', sub { });
    ok($sc->is_bound('ctrl+s'), 'bound initially');
    $sc->unbind('ctrl+s');
    ok(!$sc->is_bound('ctrl+s'), 'unbound after unbind');
}

# --- unbind normalizes ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+shift+s', sub { });
    $sc->unbind('Shift+Ctrl+S');
    ok(!$sc->is_bound('ctrl+shift+s'), 'unbind normalizes combo');
}

# --- list ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+s', sub { });
    $sc->bind('ctrl+z', sub { });

    my @bindings = $sc->list;
    is(scalar @bindings, 2, 'list returns 2 bindings');

    my %combos = map { $_->{combo} => $_ } @bindings;
    ok(exists $combos{'ctrl+s'}, 'ctrl+s in list');
    ok(exists $combos{'ctrl+z'}, 'ctrl+z in list');
    is($combos{'ctrl+s'}{enabled}, 1, 'enabled by default');
    is($combos{'ctrl+s'}{prevent_default}, 0, 'prevent_default off by default');
}

# --- list empty ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    my @bindings = $sc->list;
    is(scalar @bindings, 0, 'list empty when no bindings');
}

# --- disable / enable individual ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+s', sub { });

    $sc->disable('ctrl+s');
    my @bindings = $sc->list;
    my ($entry) = grep { $_->{combo} eq 'ctrl+s' } @bindings;
    is($entry->{enabled}, 0, 'disabled after disable()');

    $sc->enable('ctrl+s');
    @bindings = $sc->list;
    ($entry) = grep { $_->{combo} eq 'ctrl+s' } @bindings;
    is($entry->{enabled}, 1, 'enabled after enable()');
}

# --- disable/enable chaining ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+s', sub { });
    my $ret = $sc->disable('ctrl+s')->enable('ctrl+s');
    isa_ok($ret, 'Chandra::Shortcut', 'disable/enable return self');
}

# --- disable_all / enable_all ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    is($sc->{_disabled_all}, 0, 'not globally disabled');

    $sc->disable_all;
    is($sc->{_disabled_all}, 1, 'globally disabled');

    $sc->enable_all;
    is($sc->{_disabled_all}, 0, 'globally enabled');
}

# --- disable_all/enable_all chaining ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    my $ret = $sc->disable_all->enable_all;
    isa_ok($ret, 'Chandra::Shortcut', 'disable_all/enable_all return self');
}

# --- prevent_default option ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+p', sub { }, prevent_default => 1);

    my @bindings = $sc->list;
    my ($entry) = grep { $_->{combo} eq 'ctrl+p' } @bindings;
    is($entry->{prevent_default}, 1, 'prevent_default set');
}

# --- bind registers __chandra_shortcut via app ---
{
    my @binds;
    my $mock = _mock_app_track(\@binds);
    my $sc = Chandra::Shortcut->new(app => $mock);
    $sc->bind('ctrl+s', sub { });

    ok(grep({ $_ eq '__chandra_shortcut' } @binds),
        '__chandra_shortcut bound via app');
}

# --- __chandra_shortcut only bound once ---
{
    my @binds;
    my $mock = _mock_app_track(\@binds);
    my $sc = Chandra::Shortcut->new(app => $mock);
    $sc->bind('ctrl+s', sub { });
    $sc->bind('ctrl+z', sub { });

    my $count = grep { $_ eq '__chandra_shortcut' } @binds;
    is($count, 1, '__chandra_shortcut bound only once');
}

# --- js_code returns JavaScript ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+s', sub { });

    my $js = $sc->js_code;
    ok(defined $js, 'js_code returns something');
    like($js, qr/window\.__chandraShortcut/, 'defines __chandraShortcut');
    like($js, qr/'ctrl\+s'/, 'contains registered combo');
    like($js, qr/keydown/, 'has keydown listener');
    like($js, qr/normKey/, 'has normKey function');
    like($js, qr/chordPrefix/, 'has chord support');
    like($js, qr/__chandra_shortcut/, 'invokes __chandra_shortcut');
}

# --- js_code empty when no bindings ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    is($sc->js_code, '', 'js_code empty without bindings');
}

# --- inject sets _injected flag ---
{
    my @evaled;
    my $mock = _mock_app_eval(\@evaled);
    my $sc = Chandra::Shortcut->new(app => $mock);
    $sc->bind('ctrl+s', sub { });

    ok(!$sc->{_injected}, 'not injected initially');
    $sc->inject;
    ok($sc->{_injected}, 'injected after inject()');
    ok(scalar @evaled >= 1, 'eval called during inject');
}

# --- inject is idempotent ---
{
    my @evaled;
    my $mock = _mock_app_eval(\@evaled);
    my $sc = Chandra::Shortcut->new(app => $mock);
    $sc->bind('ctrl+s', sub { });

    $sc->inject;
    my $count = scalar @evaled;
    $sc->inject;
    is(scalar @evaled, $count, 'second inject does nothing');
}

# --- chord bindings appear in js_code ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('ctrl+k ctrl+c', sub { });

    my $js = $sc->js_code;
    like($js, qr/'ctrl\+k ctrl\+c'/, 'chord combo in js_code');
}

# --- function keys ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    $sc->bind('f5', sub { });
    $sc->bind('ctrl+f12', sub { });

    ok($sc->is_bound('f5'), 'f5 bound');
    ok($sc->is_bound('ctrl+f12'), 'ctrl+f12 bound');
}

# --- duplicate binding overwrites ---
{
    my $sc = Chandra::Shortcut->new(app => _mock_app());
    my $first = 0;
    my $second = 0;
    $sc->bind('ctrl+s', sub { $first = 1 });
    $sc->bind('ctrl+s', sub { $second = 1 });

    my @bindings = $sc->list;
    is(scalar @bindings, 1, 'only one binding after overwrite');
}

done_testing;

# --- Mock helpers ---

sub _mock_app {
    my $mock = bless {}, 'MockShortcutApp';
    no strict 'refs';
    no warnings 'redefine';
    *MockShortcutApp::bind = sub { return shift };
    *MockShortcutApp::eval = sub { };
    use strict 'refs';
    return $mock;
}

sub _mock_app_track {
    my ($binds_ref) = @_;
    my $mock = bless {}, 'MockShortcutAppT';
    no strict 'refs';
    no warnings 'redefine';
    *MockShortcutAppT::bind = sub { push @$binds_ref, $_[1]; return $_[0] };
    *MockShortcutAppT::eval = sub { };
    use strict 'refs';
    return $mock;
}

sub _mock_app_eval {
    my ($evaled_ref) = @_;
    my $mock = bless {}, 'MockShortcutAppE';
    no strict 'refs';
    no warnings 'redefine';
    *MockShortcutAppE::bind = sub { return $_[0] };
    *MockShortcutAppE::eval = sub { push @$evaled_ref, $_[1]; return $_[0] };
    use strict 'refs';
    return $mock;
}
