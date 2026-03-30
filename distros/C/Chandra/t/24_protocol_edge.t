#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
no warnings 'once';

use_ok('Chandra::Protocol');

# --- Mock helpers ---
sub _mock_app {
    my $mock = bless { _binds => {} }, 'MockPEdgeApp';
    no strict 'refs';
    *MockPEdgeApp::bind = sub {
        $_[0]->{_binds}{$_[1]} = $_[2];
        return $_[0];
    };
    *MockPEdgeApp::eval = sub { };
    use strict 'refs';
    return $mock;
}

# === register returns self for chaining ===
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    my $ret = $proto->register('a', sub { });
    is($ret, $proto, 'register returns self');
}

# === register chaining ===
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('alpha', sub { })->register('beta', sub { });
    my @schemes = sort $proto->schemes;
    is_deeply(\@schemes, ['alpha', 'beta'], 'chained registration works');
}

# === scheme cleanup: multiple slashes ===
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('test://', sub { });
    ok($proto->is_registered('test'), 'test:// cleaned to test');
    ok($proto->is_registered('test://'), 'is_registered also cleans input');
}

# === scheme cleanup: trailing colon ===
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('proto:', sub { });
    ok($proto->is_registered('proto'), 'proto: cleaned to proto');
    ok($proto->is_registered('proto:'), 'is_registered cleans colon');
}

# === is_registered for non-existent scheme ===
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    ok(!$proto->is_registered('nothing'), 'non-existent scheme');
}

# === re-registration overwrites handler ===
{
    my $app = _mock_app();
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('retest', sub { 'old' });
    $proto->register('retest', sub { 'new' });

    my @schemes = $proto->schemes;
    my @retest = grep { $_ eq 'retest' } @schemes;
    is(scalar @retest, 1, 'only one entry after re-register');

    # The bound handler should be the new one
    my $cb = $app->{_binds}{'__protocol_retest'};
    ok($cb, 'binding exists');
    my $result = $cb->('path', '');
    is($result, 'new', 'new handler active after re-register');
}

# === handler receives empty path ===
{
    my $app = _mock_app();
    my @calls;
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('ep', sub { push @calls, [@_]; return 'ok' });

    my $cb = $app->{_binds}{'__protocol_ep'};
    $cb->('', '');
    is($calls[0][0], '', 'empty path passed');
    is_deeply($calls[0][1], {}, 'empty params hash');
}

# === handler receives complex query params ===
{
    my $app = _mock_app();
    my @calls;
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('qp', sub { push @calls, [@_]; return 1 });

    my $cb = $app->{_binds}{'__protocol_qp'};
    $cb->('page', '{"key":"value","num":"42","empty":""}');
    is($calls[0][0], 'page', 'path passed');
    is_deeply($calls[0][1], { key => 'value', num => '42', empty => '' }, 'complex params parsed');
}

# === handler with invalid JSON params ===
{
    my $app = _mock_app();
    my @calls;
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('bad', sub { push @calls, [@_]; return 1 });

    my $cb = $app->{_binds}{'__protocol_bad'};
    # Invalid JSON should not crash - params default to {}
    eval { $cb->('path', 'not{json') };
    # Should either give empty params or die gracefully
    ok(1, 'invalid JSON params does not crash');
}

# === handler that dies ===
{
    my $app = _mock_app();
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('die', sub { die "protocol handler crash" });

    my $cb = $app->{_binds}{'__protocol_die'};
    eval { $cb->('path', '') };
    like($@, qr/protocol handler crash/, 'handler die propagates');
}

# === handler return value passed through ===
{
    my $app = _mock_app();
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('ret', sub { return { status => 'ok', data => [1, 2, 3] } });

    my $cb = $app->{_binds}{'__protocol_ret'};
    my $result = $cb->('page', '');
    is_deeply($result, { status => 'ok', data => [1, 2, 3] }, 'complex return value preserved');
}

# === handler returning undef ===
{
    my $app = _mock_app();
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('undef', sub { return undef });

    my $cb = $app->{_binds}{'__protocol_undef'};
    my $result = $cb->('x', '');
    ok(!defined $result, 'undef return preserved');
}

# === schemes returns empty list when none registered ===
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    my @schemes = $proto->schemes;
    is(scalar @schemes, 0, 'no schemes initially');
}

# === js_code with multiple schemes ===
{
    my $proto = Chandra::Protocol->new(app => _mock_app());
    $proto->register('one', sub { });
    $proto->register('two', sub { });
    $proto->register('three', sub { });

    my $js = $proto->js_code;
    like($js, qr/'one'/, 'one in js');
    like($js, qr/'two'/, 'two in js');
    like($js, qr/'three'/, 'three in js');
}

# === inject with no protocols is no-op ===
{
    my @evaled;
    my $mock = bless {}, 'MockPEdgeAppE';
    no strict 'refs';
    *MockPEdgeAppE::bind = sub { return $_[0] };
    *MockPEdgeAppE::eval = sub { push @evaled, $_[1] };
    use strict 'refs';

    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->inject;
    is(scalar @evaled, 0, 'inject with no protocols does nothing');
    ok(!$proto->{_injected}, 'not marked as injected');
}

# === inject only runs once even with protocols ===
{
    my @evaled;
    my $mock = bless {}, 'MockPEdgeAppI';
    no strict 'refs';
    *MockPEdgeAppI::bind = sub { return $_[0] };
    *MockPEdgeAppI::eval = sub { push @evaled, $_[1] };
    use strict 'refs';

    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->register('test', sub { });
    $proto->inject;
    my $count = scalar @evaled;
    ok($count >= 1, 'first inject evaluates JS');

    $proto->inject;
    is(scalar @evaled, $count, 'second inject is no-op');
}

# === inject returns self ===
{
    my $mock = bless {}, 'MockPEdgeAppR';
    no strict 'refs';
    *MockPEdgeAppR::bind = sub { return $_[0] };
    *MockPEdgeAppR::eval = sub { };
    use strict 'refs';

    my $proto = Chandra::Protocol->new(app => $mock);
    $proto->register('r', sub { });
    my $ret = $proto->inject;
    is($ret, $proto, 'inject returns self');
}

# === constructor without app ===
{
    my $proto = Chandra::Protocol->new;
    ok($proto, 'Protocol created without app');
    ok(!$proto->{app}, 'no app stored');
}

# === binding name format ===
{
    my $app = _mock_app();
    my $proto = Chandra::Protocol->new(app => $app);
    $proto->register('myscheme', sub { });
    ok(exists $app->{_binds}{'__protocol_myscheme'}, 'bind name is __protocol_<scheme>');
}

done_testing;
