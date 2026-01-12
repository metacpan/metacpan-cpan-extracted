#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;

# Test the Session module structure and attributes

use_ok('Acme::Claude::Shell::Session');

# Test that Session can be instantiated with required attributes
subtest 'Session instantiation' => sub {
    plan tests => 7;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $session = Acme::Claude::Shell::Session->new(
        loop        => $loop,
        dry_run     => 0,
        safe_mode   => 1,
        working_dir => '/tmp',
        colorful    => 0,
    );

    ok($session, 'Session created');
    isa_ok($session, 'Acme::Claude::Shell::Session');
    is($session->dry_run, 0, 'dry_run attribute');
    is($session->safe_mode, 1, 'safe_mode attribute');
    is($session->working_dir, '/tmp', 'working_dir attribute');
    is($session->colorful, 0, 'colorful attribute');
    is(ref($session->_history), 'ARRAY', '_history is arrayref');
};

# Test optional model attribute
subtest 'Session with model' => sub {
    plan tests => 2;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $session = Acme::Claude::Shell::Session->new(
        loop  => $loop,
        model => 'claude-sonnet-4-5',
    );

    ok($session->has_model, 'has_model returns true');
    is($session->model, 'claude-sonnet-4-5', 'model attribute');
};

# Test default values
subtest 'Session defaults' => sub {
    plan tests => 4;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $session = Acme::Claude::Shell::Session->new(
        loop => $loop,
    );

    is($session->dry_run, 0, 'dry_run defaults to 0');
    is($session->safe_mode, 1, 'safe_mode defaults to 1');
    is($session->working_dir, '.', 'working_dir defaults to .');
    is($session->colorful, 1, 'colorful defaults to 1');
};

# Test _history management
subtest 'Session history' => sub {
    plan tests => 3;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $session = Acme::Claude::Shell::Session->new(
        loop => $loop,
    );

    is(scalar(@{$session->_history}), 0, 'History starts empty');

    push @{$session->_history}, { command => 'ls', status => 'success' };
    is(scalar(@{$session->_history}), 1, 'Can add to history');

    push @{$session->_history}, { command => 'pwd', status => 'success' };
    is(scalar(@{$session->_history}), 2, 'Can add multiple entries');
};

# Test _spinner attribute
subtest 'Session spinner' => sub {
    plan tests => 3;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $session = Acme::Claude::Shell::Session->new(
        loop => $loop,
    );

    ok(!$session->_spinner, 'Spinner starts undefined');

    $session->_spinner('fake-spinner');
    is($session->_spinner, 'fake-spinner', 'Can set spinner');

    $session->_spinner(undef);
    ok(!$session->_spinner, 'Can clear spinner');
};

done_testing();
