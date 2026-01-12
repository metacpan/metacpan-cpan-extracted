#!/usr/bin/env perl
use 5.020;
use strict;
use warnings;
use Test::More;

# Test the main Acme::Claude::Shell module

use_ok('Acme::Claude::Shell', qw(shell run));

# Test exports
subtest 'Exports' => sub {
    plan tests => 2;

    can_ok('main', 'shell');
    can_ok('main', 'run');
};

# Test VERSION
subtest 'Version' => sub {
    plan tests => 2;

    ok($Acme::Claude::Shell::VERSION, 'VERSION is defined');
    like($Acme::Claude::Shell::VERSION, qr/^\d+\.\d+$/, 'VERSION format is correct');
};

# Test _detect_color (internal function)
subtest 'Color detection' => sub {
    plan tests => 1;

    # This is tricky to test without a TTY, but we can at least verify
    # the function exists and returns a boolean
    my $result = Acme::Claude::Shell::_detect_color();
    ok(defined($result) && ($result == 0 || $result == 1), '_detect_color returns boolean');
};

done_testing();
