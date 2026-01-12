#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;

# Test the Query module structure and attributes

use_ok('Acme::Claude::Shell::Query');

# Test that Query can be instantiated with required attributes
subtest 'Query instantiation' => sub {
    plan tests => 7;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $query = Acme::Claude::Shell::Query->new(
        loop        => $loop,
        dry_run     => 0,
        safe_mode   => 1,
        working_dir => '/tmp',
        colorful    => 0,
    );

    ok($query, 'Query created');
    isa_ok($query, 'Acme::Claude::Shell::Query');
    is($query->dry_run, 0, 'dry_run attribute');
    is($query->safe_mode, 1, 'safe_mode attribute');
    is($query->working_dir, '/tmp', 'working_dir attribute');
    is($query->colorful, 0, 'colorful attribute');
    ok(!$query->_spinner, '_spinner starts undefined');
};

# Test optional model attribute
subtest 'Query with model' => sub {
    plan tests => 2;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $query = Acme::Claude::Shell::Query->new(
        loop  => $loop,
        model => 'claude-opus-4-5',
    );

    ok($query->has_model, 'has_model returns true');
    is($query->model, 'claude-opus-4-5', 'model attribute');
};

# Test default values
subtest 'Query defaults' => sub {
    plan tests => 4;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $query = Acme::Claude::Shell::Query->new(
        loop => $loop,
    );

    is($query->dry_run, 0, 'dry_run defaults to 0');
    is($query->safe_mode, 1, 'safe_mode defaults to 1');
    is($query->working_dir, '.', 'working_dir defaults to .');
    is($query->colorful, 1, 'colorful defaults to 1');
};

# Test _spinner attribute
subtest 'Query spinner' => sub {
    plan tests => 3;

    require IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    my $query = Acme::Claude::Shell::Query->new(
        loop => $loop,
    );

    ok(!$query->_spinner, 'Spinner starts undefined');

    $query->_spinner('fake-spinner');
    is($query->_spinner, 'fake-spinner', 'Can set spinner');

    $query->_spinner(undef);
    ok(!$query->_spinner, 'Can clear spinner');
};

done_testing();
