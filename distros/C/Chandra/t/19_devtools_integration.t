#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::DevTools');
use_ok('Chandra::Error');
use_ok('Chandra::Bind');

# --- Reusable mock app ---
{
    package MockDTApp;
    sub new {
        bless {
            _bindings => {},
            _eval => [],
            _dispatch => [],
        }, shift;
    }
    sub bind {
        my ($self, $name, $sub) = @_;
        $self->{_bindings}{$name} = $sub;
        return $self;
    }
    sub eval { push @{$_[0]->{_eval}}, $_[1]; return $_[0] }
    sub dispatch_eval { push @{$_[0]->{_dispatch}}, $_[1]; return $_[0] }
}

# === toggle dispatches JS ===
{
    my $mock = MockDTApp->new;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $ret = $dt->toggle;
    isa_ok($ret, 'Chandra::DevTools', 'toggle returns self');
    my $found = grep { /toggle/ } @{$mock->{_eval}};
    ok($found, 'toggle evals JS with toggle');
}

# === show dispatches JS ===
{
    my $mock = MockDTApp->new;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $ret = $dt->show;
    isa_ok($ret, 'Chandra::DevTools', 'show returns self');
    my $found = grep { /show/ } @{$mock->{_eval}};
    ok($found, 'show evals JS with show');
}

# === hide dispatches JS ===
{
    my $mock = MockDTApp->new;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $ret = $dt->hide;
    isa_ok($ret, 'Chandra::DevTools', 'hide returns self');
    my $found = grep { /hide/ } @{$mock->{_eval}};
    ok($found, 'hide evals JS with hide');
}

# === disable hides panel ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;
    $dt->disable;
    ok(!$dt->is_enabled, 'disabled');
    my $found = grep { /hide/ } @{$mock->{_eval}};
    ok($found, 'disable hides panel via JS');
    Chandra::Error->clear_handlers;
}

# === toggle/show/hide no-op without app ===
{
    my $dt = Chandra::DevTools->new;
    eval { $dt->toggle; $dt->show; $dt->hide };
    is($@, '', 'toggle/show/hide without app do not crash');
}

# === log escapes special characters ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    $dt->log("it's a\ntest\\with\\backslashes");
    my @dispatched = @{$mock->{_dispatch}};
    my $log_js = (grep { /addLog/ } @dispatched)[-1];
    ok($log_js, 'log dispatched');
    like($log_js, qr/\\'/, 'single quote escaped in log');
    like($log_js, qr/\\\\/, 'backslash escaped in log');
    unlike($log_js, qr/(?<!\\)\n/, 'newline escaped in log');

    Chandra::Error->clear_handlers;
}

# === warn escapes special characters ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    $dt->warn("warning's\nhere\\now");
    my @dispatched = @{$mock->{_dispatch}};
    my $warn_js = (grep { /addLog.*warn/ } @dispatched)[-1];
    ok($warn_js, 'warn dispatched');
    like($warn_js, qr/\\'/, 'single quote escaped in warn');

    Chandra::Error->clear_handlers;
}

# === log returns self when enabled ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    my $ret = $dt->log("test");
    isa_ok($ret, 'Chandra::DevTools', 'log returns self');

    Chandra::Error->clear_handlers;
}

# === log/warn no-op when disabled ===
{
    my $mock = MockDTApp->new;
    my $dt = Chandra::DevTools->new(app => $mock);
    # Not enabled
    $dt->log("should not appear");
    $dt->warn("should not appear");
    is(scalar @{$mock->{_dispatch}}, 0, 'log/warn skip when disabled');
}

# === inject calls eval with JS ===
{
    my $mock = MockDTApp->new;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $ret = $dt->inject;
    isa_ok($ret, 'Chandra::DevTools', 'inject returns self');
    my $found = grep { /__chandraDevTools/ } @{$mock->{_eval}};
    ok($found, 'inject evals devtools JS');
}

# === inject with explicit app ===
{
    my $mock = MockDTApp->new;
    my $dt = Chandra::DevTools->new;
    $dt->inject($mock);
    my $found = grep { /__chandraDevTools/ } @{$mock->{_eval}};
    ok($found, 'inject with explicit app works');
}

# === inject without app is safe ===
{
    my $dt = Chandra::DevTools->new;
    eval { $dt->inject };
    is($@, '', 'inject without app does not crash');
}

# === on_reload returns self ===
{
    my $dt = Chandra::DevTools->new;
    my $ret = $dt->on_reload(sub { 'reload' });
    isa_ok($ret, 'Chandra::DevTools', 'on_reload returns self');
}

# === __devtools_reload binding invokes on_reload callback ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $reload_called = 0;
    $dt->on_reload(sub { $reload_called++ });
    $dt->enable;

    # Invoke the reload binding
    my $reload_cb = $mock->{_bindings}{'__devtools_reload'};
    ok($reload_cb, '__devtools_reload binding exists');
    my $result = $reload_cb->();
    is($reload_called, 1, 'reload callback invoked');
    is_deeply($result, { ok => 1 }, 'reload returns ok');

    Chandra::Error->clear_handlers;
}

# === __devtools_list_bindings returns filtered list ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    # Register some user bindings first
    my $bind = Chandra::Bind->new;
    $bind->bind('user_func1', sub { });
    $bind->bind('user_func2', sub { });

    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    my $list_cb = $mock->{_bindings}{'__devtools_list_bindings'};
    ok($list_cb, '__devtools_list_bindings binding exists');
    my $list = $list_cb->();
    ok(ref $list eq 'ARRAY', 'returns arrayref');
    ok(grep({ $_ eq 'user_func1' } @$list), 'user_func1 in list');
    ok(grep({ $_ eq 'user_func2' } @$list), 'user_func2 in list');
    ok(!grep({ /^__devtools_/ } @$list), 'devtools bindings filtered out');

    Chandra::Error->clear_handlers;
}

# === Error forwarding includes stack trace info ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    # Capture an error with context
    Chandra::Error->capture("something broke", context => 'mymodule');

    my @dispatched = @{$mock->{_dispatch}};
    my $error_js = (grep { /addError/ } @dispatched)[-1];
    ok($error_js, 'error forwarded');
    like($error_js, qr/something broke/, 'error message present');
    like($error_js, qr/mymodule/, 'context present');

    Chandra::Error->clear_handlers;
}

# === Multiple errors forwarded in order ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    Chandra::Error->capture("error one");
    Chandra::Error->capture("error two");
    Chandra::Error->capture("error three");

    my @error_js = grep { /addError/ } @{$mock->{_dispatch}};
    is(scalar @error_js, 3, 'three errors forwarded');
    like($error_js[0], qr/error one/, 'first error');
    like($error_js[1], qr/error two/, 'second error');
    like($error_js[2], qr/error three/, 'third error');

    Chandra::Error->clear_handlers;
}

# === Error forwarding escapes special characters ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    Chandra::Error->capture("error with 'quotes' and\nnewlines\\backslash");

    my @error_js = grep { /addError/ } @{$mock->{_dispatch}};
    my $js = $error_js[-1];
    ok($js, 'error forwarded');
    like($js, qr/\\'/, 'quotes escaped in error');
    unlike($js, qr/(?<!\\)\n/, 'newlines escaped in error');

    Chandra::Error->clear_handlers;
}

# === enable returns self ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $ret = $dt->enable;
    isa_ok($ret, 'Chandra::DevTools', 'enable returns self');
    Chandra::Error->clear_handlers;
}

# === disable returns self ===
{
    my $dt = Chandra::DevTools->new;
    my $ret = $dt->disable;
    isa_ok($ret, 'Chandra::DevTools', 'disable returns self');
}

# === re-enable after disable ===
{
    my $mock = MockDTApp->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;
    $dt->disable;
    ok(!$dt->is_enabled, 'disabled');
    $dt->enable;
    ok($dt->is_enabled, 're-enabled');
    Chandra::Error->clear_handlers;
}

done_testing;
