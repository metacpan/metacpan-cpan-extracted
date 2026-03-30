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
    package MockDTApp2;
    sub new {
        bless {
            _bindings  => {},
            _eval      => [],
            _dispatch  => [],
            _eval_dies => 0,
        }, shift;
    }
    sub bind { $_[0]->{_bindings}{$_[1]} = $_[2]; return $_[0] }
    sub eval { push @{$_[0]->{_eval}}, $_[1]; return $_[0] }
    sub dispatch_eval {
        die "eval crash" if $_[0]->{_eval_dies};
        push @{$_[0]->{_dispatch}}, $_[1];
        return $_[0];
    }
}

# === js_code class method returns devtools JS ===
{
    my $js = Chandra::DevTools->js_code;
    ok(defined $js, 'js_code returns value');
    ok(length($js) > 100, 'js_code is substantial');
    like($js, qr/__chandraDevTools/, 'contains devtools object');
    like($js, qr/toggle/, 'contains toggle');
    like($js, qr/F12/, 'contains F12 shortcut');
    like($js, qr/Console/, 'contains Console tab');
    like($js, qr/Bindings/, 'contains Bindings tab');
    like($js, qr/Elements/, 'contains Elements tab');
}

# === js_code is idempotent ===
{
    my $a = Chandra::DevTools->js_code;
    my $b = Chandra::DevTools->js_code;
    is($a, $b, 'js_code returns same value');
}

# === error forwarding when dispatch_eval crashes ===
{
    my $mock = MockDTApp2->new;
    $mock->{_eval_dies} = 1;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    # Error forwarding should not crash even if dispatch_eval dies
    eval { Chandra::Error->capture("test error") };
    is($@, '', 'error forwarding catches dispatch_eval crash');

    Chandra::Error->clear_handlers;
}

# === log when dispatch_eval crashes ===
{
    my $mock = MockDTApp2->new;
    $mock->{_eval_dies} = 1;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    eval { $dt->log("test message") };
    is($@, '', 'log catches dispatch_eval crash');

    Chandra::Error->clear_handlers;
}

# === warn when dispatch_eval crashes ===
{
    my $mock = MockDTApp2->new;
    $mock->{_eval_dies} = 1;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    eval { $dt->warn("test warning") };
    is($@, '', 'warn catches dispatch_eval crash');

    Chandra::Error->clear_handlers;
}

# === is_enabled initial state ===
{
    my $dt = Chandra::DevTools->new;
    ok(!$dt->is_enabled, 'initially disabled');
}

# === enable sets enabled state ===
{
    my $mock = MockDTApp2->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;
    ok($dt->is_enabled, 'enabled after enable()');
    Chandra::Error->clear_handlers;
}

# === enable with explicit app parameter ===
{
    my $mock = MockDTApp2->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new;
    $dt->enable($mock);
    ok($dt->is_enabled, 'enabled with explicit app');
    ok(exists $mock->{_bindings}{'__devtools_list_bindings'}, 'bindings registered on explicit app');
    Chandra::Error->clear_handlers;
}

# === disable when already disabled ===
{
    my $dt = Chandra::DevTools->new;
    my $ret = $dt->disable;
    isa_ok($ret, 'Chandra::DevTools', 'disable when already disabled returns self');
    ok(!$dt->is_enabled, 'still disabled');
}

# === error not forwarded after disable ===
{
    my $mock = MockDTApp2->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;
    $dt->disable;

    # Clear any dispatches from disable itself
    @{$mock->{_dispatch}} = ();

    Chandra::Error->capture("should not forward");
    my @error_js = grep { /addError/ } @{$mock->{_dispatch}};
    is(scalar @error_js, 0, 'errors not forwarded after disable');

    Chandra::Error->clear_handlers;
}

# === __devtools_reload without on_reload callback ===
{
    my $mock = MockDTApp2->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    my $reload_cb = $mock->{_bindings}{'__devtools_reload'};
    my $result = $reload_cb->();
    is_deeply($result, { ok => 1 }, 'reload without callback still returns ok');

    Chandra::Error->clear_handlers;
}

# === chaining toggle, show, hide ===
{
    my $mock = MockDTApp2->new;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $ret = $dt->toggle->show->hide;
    isa_ok($ret, 'Chandra::DevTools', 'toggle/show/hide chaining works');
}

# === chaining enable/disable/inject ===
{
    my $mock = MockDTApp2->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    my $ret = $dt->enable->disable;
    isa_ok($ret, 'Chandra::DevTools', 'enable/disable chaining works');
    Chandra::Error->clear_handlers;
}

# === __devtools_list_bindings filters all internal names ===
{
    my $mock = MockDTApp2->new;
    Chandra::Error->clear_handlers;
    my $bind = Chandra::Bind->new;

    # Clean out other bindings from previous tests
    for my $name ($bind->list) {
        $bind->unbind($name) unless $name =~ /^__devtools_/;
    }

    $bind->bind('public_func', sub { });
    $bind->bind('__internal_func', sub { });

    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;

    my $list_cb = $mock->{_bindings}{'__devtools_list_bindings'};
    my $list = $list_cb->();
    ok(grep({ $_ eq 'public_func' } @$list), 'public function listed');
    # __internal_func should still appear since filter only removes __devtools_ prefix
    ok(grep({ $_ eq '__internal_func' } @$list), 'non-devtools internal still listed');
    ok(!grep({ /^__devtools_/ } @$list), 'devtools functions filtered');

    $bind->unbind('public_func');
    $bind->unbind('__internal_func');
    Chandra::Error->clear_handlers;
}

# === warn returns self ===
{
    my $mock = MockDTApp2->new;
    Chandra::Error->clear_handlers;
    my $dt = Chandra::DevTools->new(app => $mock);
    $dt->enable;
    my $ret = $dt->warn("test");
    isa_ok($ret, 'Chandra::DevTools', 'warn returns self');
    Chandra::Error->clear_handlers;
}

# === log/warn return undef when disabled ===
{
    my $dt = Chandra::DevTools->new;
    my $log_ret = $dt->log("noop");
    my $warn_ret = $dt->warn("noop");
    ok(!defined $log_ret, 'log returns undef when disabled');
    ok(!defined $warn_ret, 'warn returns undef when disabled');
}

done_testing;
