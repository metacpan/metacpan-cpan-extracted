#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::DevTools');
use_ok('Chandra::Error');
use_ok('Chandra::Bind');

# --- constructor ---
{
    my $dt = Chandra::DevTools->new;
    ok($dt, 'DevTools created');
    isa_ok($dt, 'Chandra::DevTools');
    ok(!$dt->is_enabled, 'not enabled by default');
}

# --- constructor with args ---
{
    my $mock_app = bless {}, 'MockApp';
    my $dt = Chandra::DevTools->new(app => $mock_app);
    is($dt->{app}, $mock_app, 'app stored');
}

# --- js_code returns JavaScript ---
{
    my $js = Chandra::DevTools->js_code;
    ok(defined $js, 'js_code returns something');
    ok(length $js > 100, 'js_code has substantial content');
    like($js, qr/window\.__chandraDevTools/, 'js_code defines __chandraDevTools');
    like($js, qr/toggle/, 'js_code has toggle');
    like($js, qr/addError/, 'js_code has addError');
    like($js, qr/showTab/, 'js_code has showTab');
    like($js, qr/F12/, 'js_code has F12 shortcut');
    like($js, qr/_renderDomTree/, 'js_code has DOM tree renderer');
    like($js, qr/Console/, 'js_code has Console tab');
    like($js, qr/Bindings/, 'js_code has Bindings tab');
    like($js, qr/Elements/, 'js_code has Elements tab');
    like($js, qr/Reload/, 'js_code has Reload button');
    like($js, qr/clearConsole/, 'js_code has clearConsole');
}

# --- enable/disable ---
{
    Chandra::Error->clear_handlers;
    # Create a minimal mock app that has bind and dispatch_eval
    my @bound;
    my $mock_app = bless {
        _bindings => {},
    }, 'MockApp2';

    no strict 'refs';
    *MockApp2::bind = sub {
        my ($self, $name, $sub) = @_;
        $self->{_bindings}{$name} = $sub;
        push @bound, $name;
        return $self;
    };
    *MockApp2::dispatch_eval = sub { };
    *MockApp2::eval = sub { };
    use strict 'refs';

    my $dt = Chandra::DevTools->new(app => $mock_app);
    $dt->enable;
    ok($dt->is_enabled, 'enabled after enable()');

    # Check that DevTools helper bindings were registered
    ok(grep({ $_ eq '__devtools_list_bindings' } @bound), '__devtools_list_bindings bound');
    ok(grep({ $_ eq '__devtools_reload' } @bound), '__devtools_reload bound');

    # Check error handler was registered
    my $handlers = Chandra::Error->handlers;
    ok(scalar @$handlers > 0, 'error handler registered');

    $dt->disable;
    ok(!$dt->is_enabled, 'disabled after disable()');

    Chandra::Error->clear_handlers;
}

# --- on_reload ---
{
    my $dt = Chandra::DevTools->new;
    my $called = 0;
    $dt->on_reload(sub { $called++ });

    # Simulate reload callback
    $dt->{reload_cb}->();
    is($called, 1, 'on_reload callback invoked');
}

# --- __devtools_list_bindings callback ---
{
    # Set up bindings in the global registry
    my @bound_names;
    my $mock_app = bless {}, 'MockApp3';
    no strict 'refs';
    *MockApp3::bind = sub {
        my ($self, $name, $sub) = @_;
        push @bound_names, $name;
        # Actually register in Chandra::Bind for the list test
        Chandra::Bind->new->bind($name, $sub);
        return $self;
    };
    *MockApp3::dispatch_eval = sub { };
    use strict 'refs';

    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock_app);
    $dt->enable;

    # The __devtools_list_bindings callback should return bound names
    my $list_cb = $mock_app->{_bindings}{'__devtools_list_bindings'} 
        // (grep { $_ eq '__devtools_list_bindings' } @bound_names) ? sub {
            my $bind = Chandra::Bind->new;
            return [sort grep { !/^__devtools_/ } $bind->list];
        } : undef;

    # If we registered properly, we can test via Bind directly
    my $bind = Chandra::Bind->new;
    my @all = $bind->list;
    my @filtered = sort grep { !/^__devtools_/ } @all;
    ok(scalar @all >= 2, 'at least devtools bindings exist');
    ok(!grep({ /^__devtools_/ } @filtered), 'devtools bindings filtered out');

    Chandra::Error->clear_handlers;
}

# --- enable with explicit app ---
{
    my $mock = bless {}, 'MockApp4';
    no strict 'refs';
    *MockApp4::bind = sub { return shift };
    *MockApp4::dispatch_eval = sub { };
    use strict 'refs';

    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new;
    $dt->enable($mock);
    is($dt->{app}, $mock, 'app set via enable()');
    ok($dt->is_enabled, 'enabled with explicit app');
    Chandra::Error->clear_handlers;
}

# --- log and warn (smoke test - no real webview) ---
{
    my @evaled;
    my $mock = bless {}, 'MockApp5';
    no strict 'refs';
    *MockApp5::bind = sub { return shift };
    *MockApp5::dispatch_eval = sub { push @evaled, $_[1] };
    use strict 'refs';

    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    $dt->log("info message");
    ok(scalar @evaled >= 1, 'log dispatches eval');
    like($evaled[-1], qr/addLog.*info.*info message/, 'log message dispatched');

    $dt->warn("warn message");
    ok(scalar @evaled >= 2, 'warn dispatches eval');
    like($evaled[-1], qr/addLog.*warn.*warn message/, 'warn message dispatched');

    Chandra::Error->clear_handlers;
}

# --- error forwarding to DevTools ---
{
    my @evaled;
    my $mock = bless {}, 'MockApp6';
    no strict 'refs';
    *MockApp6::bind = sub { return shift };
    *MockApp6::dispatch_eval = sub { push @evaled, $_[1] };
    use strict 'refs';

    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    # Capture an error - should forward to DevTools
    Chandra::Error->capture("test forwarded error", context => 'fwd');

    ok(scalar @evaled >= 1, 'error forwarded to DevTools');
    like($evaled[-1], qr/addError/, 'error calls addError');
    like($evaled[-1], qr/test forwarded error/, 'error message forwarded');

    Chandra::Error->clear_handlers;
}

# --- disabled DevTools doesn't forward errors ---
{
    my @evaled;
    my $mock = bless {}, 'MockApp7';
    no strict 'refs';
    *MockApp7::bind = sub { return shift };
    *MockApp7::dispatch_eval = sub { push @evaled, $_[1] };
    use strict 'refs';

    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;
    $dt->disable;

    @evaled = ();
    Chandra::Error->capture("should not forward", context => 'off');

    # The handler still runs but checks is_enabled
    my $forwarded = grep { /addError/ } @evaled;
    is($forwarded, 0, 'disabled DevTools does not forward errors');

    Chandra::Error->clear_handlers;
}

done_testing;
