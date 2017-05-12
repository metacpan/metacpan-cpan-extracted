#!perl -T

use strict;
use warnings;

use Test::More 0.88;
use Test::Requires {
    'Test::Taint' => 0,
};

use Data::Validate::IP;

unless (taint_checking_ok('taint is enabled')) {
    done_testing();
    exit 0;
}

_test_good_data('is_ipv4', '1.2.3.4');
_test_bad_data('is_ipv4', '1.2.3.999');

_test_good_data(
    'is_innet_ipv4',
    [ '216.17.184.1', '216.17.184.0/24' ],
    '216.17.184.1'
);
_test_bad_data(
    'is_innet_ipv4',
    [ '127.0.0.1', '216.17.184.0/24' ],
);

_test_good_data('is_private_ipv4', '10.0.0.1');
_test_bad_data('is_private_ipv4', '1.2.3.4');

_test_good_data('is_public_ipv4', '1.2.3.4');
_test_bad_data('is_public_ipv4', '10.0.0.1');

_test_good_data('is_loopback_ipv4', '127.0.0.1');
_test_bad_data('is_loopback_ipv4', '10.0.0.1');

_test_good_data('is_testnet_ipv4', '192.0.2.9');
_test_bad_data('is_testnet_ipv4', '10.0.0.1');

_test_good_data('is_multicast_ipv4', '224.0.0.1');
_test_bad_data('is_multicast_ipv4', '10.0.0.1');

_test_good_data('is_linklocal_ipv4', '169.254.0.1');
_test_bad_data('is_linklocal_ipv4', '10.0.0.1');

_test_good_data('is_ipv6', '::');
_test_good_data('is_ipv6', 'fff0:1234::');
_test_bad_data('is_ipv6', 'fffff::');

_test_good_data('is_linklocal_ipv6', 'fe80:db8::4');
_test_bad_data('is_linklocal_ipv6', 'fffff::');

sub _test_good_data {
    my $meth   = shift;
    my $good   = shift;
    my $expect = shift || $good;

    my @args = _args($good);
    tainted_ok_deeply(\@args, 'all arguments are tainted');

    my $return = Data::Validate::IP->new()->$meth(@args);
    is($return, $expect, "$meth(@args) returns $expect with tainted value");
    untainted_ok(
        $return,
        "$meth() returns untained value when value is valid"
    );
}

sub _test_bad_data {
    my $meth = shift;
    my $bad  = shift;

    my @args = _args($bad);
    tainted_ok_deeply(\@args, 'all arguments are tainted');

    my $return = Data::Validate::IP->new()->$meth(@args);
    is($return, undef, "$meth(@args) returns undef with tainted value");
}

sub _args {
    my $args = shift;

    my @args = ref $args ? @{$args} : $args;
    taint(@args);

    return @args;
}

done_testing();
