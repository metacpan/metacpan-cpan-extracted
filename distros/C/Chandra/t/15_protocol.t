#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once', 'redefine';

use_ok('Chandra::Protocol');

# --- Constructor ---
{
    my $proto = Chandra::Protocol->new;
    ok($proto, 'Protocol created');
    isa_ok($proto, 'Chandra::Protocol');
}

# --- register requires scheme ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    eval { $proto->register(undef, sub {}) };
    like($@, qr/requires a scheme/, 'register dies without scheme');
}

# --- register requires handler ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    eval { $proto->register('myapp', undef) };
    like($@, qr/requires a handler/, 'register dies without handler');
}

# --- register and list schemes ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('myapp', sub { });
    $proto->register('custom', sub { });

    my @schemes = sort $proto->schemes;
    is(scalar @schemes, 2, 'two schemes registered');
    is($schemes[0], 'custom', 'custom scheme');
    is($schemes[1], 'myapp', 'myapp scheme');
}

# --- is_registered ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('test', sub { });
    ok($proto->is_registered('test'), 'test is registered');
    ok(!$proto->is_registered('nope'), 'nope is not registered');
}

# --- scheme cleanup (strips :// and :) ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('foo://', sub { });
    ok($proto->is_registered('foo'), 'foo:// cleaned to foo');

    $proto->register('bar:', sub { });
    ok($proto->is_registered('bar'), 'bar: cleaned to bar');
}

# --- register binds function via app ---
{
    my @binds;
    my $mock = _mock_app_track(\@binds);
    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->register('myapp', sub { return 'handled' });

    ok(grep({ $_ eq '__protocol_myapp' } @binds), '__protocol_myapp bound');
}

# --- js_code returns JavaScript ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('app', sub { });

    my $js = $proto->js_code;
    ok(defined $js, 'js_code returns something');
    like($js, qr/window\.__chandraProtocol/, 'js_code defines __chandraProtocol');
    like($js, qr/'app'/, 'js_code contains registered scheme');
    like($js, qr/navigate/, 'js_code has navigate function');
    like($js, qr/addEventListener.*click/, 'js_code intercepts clicks');
}

# --- js_code is empty with no protocols ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    my $js = $proto->js_code;
    is($js, '', 'js_code is empty without protocols');
}

# --- inject sets _injected flag ---
{
    my @evaled;
    my $mock = _mock_app_eval(\@evaled);
    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->register('test', sub { });

    ok(!$proto->{_injected}, 'not injected initially');
    $proto->inject;
    ok($proto->{_injected}, 'injected after inject()');
    ok(scalar @evaled >= 1, 'eval called during inject');
}

# --- inject is idempotent ---
{
    my @evaled;
    my $mock = _mock_app_eval(\@evaled);
    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->register('x', sub { });

    $proto->inject;
    my $count = scalar @evaled;
    $proto->inject;
    is(scalar @evaled, $count, 'second inject does nothing');
}

# --- bound handler parses path and params ---
{
    my @handler_calls;
    my %binds;
    my $mock = _mock_app_capture(\%binds);
    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->register('nav', sub {
        push @handler_calls, [@_];
        return 'ok';
    });

    # Call the bound handler directly (simulating what JS would do)
    my $cb = $binds{'__protocol_nav'};
    ok($cb, 'handler was bound');

    my $result = $cb->('dashboard', '{"tab":"home"}');
    is(scalar @handler_calls, 1, 'handler called');
    is($handler_calls[0][0], 'dashboard', 'path passed');
    is_deeply($handler_calls[0][1], { tab => 'home' }, 'params parsed');
    is($result, 'ok', 'handler return value passed through');
}

# --- bound handler with empty params ---
{
    my @handler_calls;
    my %binds;
    my $mock = _mock_app_capture(\%binds);
    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->register('simple', sub { push @handler_calls, [@_]; return 1 });

    my $cb = $binds{'__protocol_simple'};
    $cb->('page', '');

    is($handler_calls[0][0], 'page', 'path with empty params');
    is_deeply($handler_calls[0][1], {}, 'empty params gives empty hash');
}

# --- multiple schemes in js_code ---
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('alpha', sub { });
    $proto->register('beta', sub { });

    my $js = $proto->js_code;
    like($js, qr/'alpha'/, 'alpha in js_code');
    like($js, qr/'beta'/, 'beta in js_code');
}

done_testing;

# --- Mock helpers ---

sub _mock_app {
    my $mock = bless {}, 'MockProtoApp';
    no strict 'refs';
    no warnings 'redefine';
    *MockProtoApp::bind = sub { return shift };
    *MockProtoApp::eval = sub { };
    use strict 'refs';
    return $mock;
}

sub _mock_app_track {
    my ($binds_ref) = @_;
    my $mock = bless {}, 'MockProtoAppT';
    no strict 'refs';
    no warnings 'redefine';
    *MockProtoAppT::bind = sub { push @$binds_ref, $_[1]; return $_[0] };
    *MockProtoAppT::eval = sub { };
    use strict 'refs';
    return $mock;
}

sub _mock_app_eval {
    my ($evaled_ref) = @_;
    my $mock = bless {}, 'MockProtoAppE';
    no strict 'refs';
    no warnings 'redefine';
    *MockProtoAppE::bind = sub { return $_[0] };
    *MockProtoAppE::eval = sub { push @$evaled_ref, $_[1]; return $_[0] };
    use strict 'refs';
    return $mock;
}

sub _mock_app_capture {
    my ($binds_ref) = @_;
    my $mock = bless {}, 'MockProtoAppC';
    no strict 'refs';
    no warnings 'redefine';
    *MockProtoAppC::bind = sub { $binds_ref->{$_[1]} = $_[2]; return $_[0] };
    *MockProtoAppC::eval = sub { };
    use strict 'refs';
    return $mock;
}
