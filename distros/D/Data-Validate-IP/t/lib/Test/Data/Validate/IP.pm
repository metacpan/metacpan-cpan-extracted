package    # hide from PAUSE
    Test::Data::Validate::IP;

use strict;
use warnings;

use Data::Validate::IP;
use Exporter qw( import );
use Test::More 0.88;

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = 'run_tests';
## use critic

my $object = Data::Validate::IP->new();

my %ipv4_types = (
    private    => [qw(10.0.0.1 172.16.0.1 192.168.0.1)],
    public     => [qw(1.2.3.4 123.123.44.55 216.17.184.1)],
    loopback   => [qw(127.0.0.1)],
    testnet    => [qw(192.0.2.9 198.51.100.33 203.0.113.44)],
    multicast  => [qw(224.0.0.1)],
    anycast    => [qw(192.88.99.45)],
    linklocal  => [qw(169.254.0.1)],
    unroutable => [
        qw(
            0.0.0.1
            100.64.1.2
            192.0.0.4
            198.18.0.55
            240.0.0.4
            255.255.255.254
            255.255.255.255
        )
    ],
);

my %ipv6_types = (
    private => [
        qw(
            fc00::
            fc01::1234
            fdef::
            fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        )
    ],
    public => [
        qw(
            ::abcd:1234
            1::
            2::
            1:1:1:1::
            2001:abcd::
            abcd::
        )
    ],
    loopback    => [qw(::1)],
    ipv4_mapped => [
        qw(
            ::ffff:0:0
            ::ffff:0:1234
            ::ffff:1.2.3.4
            ::ffff:ffff:ffff
        )
    ],
    discard => [
        qw(
            100::
            100::1234
            100:0000:0000:0000:ffff:ffff:ffff:ffff
        )
    ],
    multicast => [
        qw(
            ff00::
            ffff::
            ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        )
    ],
    linklocal => [
        qw(
            fe80::
            fe89::
            febf::
            febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        )
    ],
    special => [
        [ '2001::'     => [qw( teredo )] ],
        [ '2001::1234' => [qw( teredo )] ],
        qw(
            2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
        )
    ],
    teredo => [
        qw(
            2001::
            2001::1234
            2001:0:ffff:ffff:ffff:ffff:ffff:ffff
        )
    ],
    orchid => [
        qw(
            2001:10::
            2001:10::1234
            2001:001F:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
        )
    ],
    documentation => [
        qw(
            2001:db8::
            2001:db8::1234
            2001:0db8:ffff:ffff:ffff:ffff:ffff:ffff
        )
    ],
);

my %ip_types = map { $_ => [ @{ $ipv4_types{$_} }, @{ $ipv6_types{$_} } ] }
    qw( linklocal loopback multicast private public );

sub run_tests {
    _ipv4_basic_tests();
    _type_tests(\%ipv4_types, 4);
    _ipv4_innet_tests();

    _ipv6_basic_tests();
    _type_tests(\%ipv6_types, 6);

    # Tests for subs without a family
    _ip_basic_tests();
    _type_tests(\%ip_types);
}

sub _ipv4_basic_tests {
    my @valid_ipv4 = qw(
        0.0.0.0
        1.2.3.4
        216.17.184.1
        255.255.255.255
    );

    for my $ip (@valid_ipv4) {
        is(is_ipv4($ip),          $ip, "is_ipv4($ip) returns $ip");
        is($object->is_ipv4($ip), $ip, "->is_ipv4($ip) returns $ip");
    }

    my @invalid_ipv4 = (
        qw(
            2067:fa88::0
            www.neely.cx
            216.17.184.G
            216.17.184.1.
            216.17.184
            216.17.184.
            256.17.184.1
            216.017.184.1
            016.17.184.1
        ),
        "1.1.1.1\0 exploit goes here",
    );

    for my $ip (@invalid_ipv4) {
        is(is_ipv4($ip),          undef, "is_ipv4($ip) returns undef");
        is($object->is_ipv4($ip), undef, "->is_ipv4($ip) returns undef");

        for my $type (sort keys %ipv4_types) {
            my ($is_sub_name, $is_sub) = _sub_for_type($type, 4);

            is($is_sub->($ip), undef, "$is_sub_name($ip) returns undef");
            is(
                $object->$is_sub_name($ip), undef,
                "->$is_sub_name($ip) returns undef"
            );
        }
    }
}

sub _ipv4_innet_tests {
    my @tests = (
        [ '216.17.184.1', '216.17.184.0/24', 1 ],
        [ '127.0.0.1',    '216.17.184.0/24', 0 ],
        [ 'invalid',      '216.17.184.0/24', 0 ],
        [ '0.0.0.0',      'default',         1 ],
        [ '1.2.3.4',      'default',         1 ],
        [ '216.240.32.1', '216.240.32.1',    1 ],
    );

    # These are accepted for backwards compatibility with the time when we
    # used Net::Netmask.
    my @deprecated = (
        [ '216.240.32.1', '216.240.32/24',              1, 1 ],
        [ '216.240.32.1', '216.240/16',                 1, 1 ],
        [ '216.240.32.1', '216.240.32.0:255.255.255.0', 1, 1 ],
        [ '216.240.32.1', '216.240.32.0-255.255.255.0', 1, 1 ],
        [ '216.240.32.1', '216.240.32',                 1, 1 ],
        [ '216.240.32.1', '216.240',                    1, 1 ],
        [ '216.240.32.1', '216',                        1, 1 ],
        [ '216.240.32.1', '216.240.32.0#0.0.31.255',    1, 1 ],
    );

    my @warnings;
    for my $triplet (@tests, @deprecated) {
        my ($ip, $network, $is_member, $is_deprecated) = @{$triplet};

        my $expect = $is_member ? $ip : undef;

        my $expect_string = $expect || 'undef';

        local $SIG{__WARN__} = sub { push @warnings, @_ }
            if $is_deprecated;

        is(
            is_innet_ipv4($ip, $network), $expect,
            "is_innet_ipv4($ip, $network) returns $expect_string"
        );
    }

    is(
        scalar @warnings,
        1,
        'got one warning from is_innet_ipv4'
    );

    like(
        $warnings[0],
        qr/\QUse of non-CIDR notation for networks with is_innet_ipv4() is deprecated/,
        'got expected deprecation warning'
    );

    like(
        $warnings[0],
        qr/at line \d+ of Test::Data::Validate::IP in sub Test::Data::Validate::IP::_ipv4_innet_tests/,
        'deprecation warning identifies caller'
    );
}

sub _ipv6_basic_tests {
    my @valid = qw(
        2067:fa88::0
        2067:FA88::1
        2067:FA88::
        2001:4888:205:7126:e0:120::
        2607:fa88::8a2e:370:7334
        2001:0db8:0000:0000:0000:0000:1428:57ab
        2001:0db8:0000:0000:0000::1428:57ab
        2001:0db8:0:0:0:0:1428:57ab
        2001:0db8:0:0::1428:57ab
        2001:0db8::1428:57ab
        2001:db8::1428:57ab
        ::
        ::0
        ::1
        ::ffff:12.34.56.78
        0:0:0:0:0:ffff:12.34.56.78
    );

    for my $ip (@valid) {
        is(is_ipv6($ip),          $ip, "is_ipv6($ip) returns $ip");
        is($object->is_ipv6($ip), $ip, "->is_ipv6($ip) returns $ip");
    }

    my @invalid = (
        qw(
            0000:00:0000:0000:0000:0000:0000:00000
            2067:fa88
            2067:FA88
            2067:::
            2067:::1
            2067::1:
            216.17.184.1
            bbb.bbb.bbb
            :::
            g123::1234
            :abcd
        ),
        "::1\0 invalid",
    );

    for my $ip (@invalid) {
        is(is_ipv6($ip),          undef, "is_ipv6($ip) returns undef");
        is($object->is_ipv6($ip), undef, "->is_ipv6($ip) returns undef");

        for my $type (sort keys %ipv6_types) {
            my ($is_sub_name, $is_sub) = _sub_for_type($type, 6);

            is($is_sub->($ip), undef, "$is_sub_name($ip) returns undef");
            is(
                $object->$is_sub_name($ip), undef,
                "->$is_sub_name($ip) returns undef"
            );
        }
    }
}

sub _ip_basic_tests {
    my @valid = qw( 1.1.1.1 2067:fa88::0 ::1.1.1.1 );

    for my $ip (@valid) {
        is(is_ip($ip),          $ip, "is_ip($ip) returns $ip");
        is($object->is_ip($ip), $ip, "->is_ip($ip) returns $ip");

    }

    my @invalid = (
        qw(
            2067:fa88
            216.17.184
            :216.17.184
        ),
        "::1\0 invalid"
    );
    for my $ip (@invalid) {
        is(is_ip($ip),          undef, "is_ip($ip) returns undef");
        is($object->is_ip($ip), undef, "->is_ip($ip) returns undef");
    }
}

sub _type_tests {
    my $types     = shift;
    my $ip_number = shift;

    my @types = sort keys %{$types};

    for my $type (@types) {
        for my $test (@{ $types->{$type} }) {
            my ($ip, $is_also) = ref $test ? @{$test} : ($test, []);

            my ($is_sub_name, $is_sub) = _sub_for_type($type, $ip_number);

            is($is_sub->($ip), $ip, "$is_sub_name($ip) returns $ip");
            is(
                $object->$is_sub_name($ip), $ip,
                "->$is_sub_name($ip) returns $ip"
            );

            for my $other (sort grep { $_ ne $type } @types) {
                next if grep { $_ eq $other } @{$is_also};

                my ($other_sub_name, $other_sub)
                    = _sub_for_type($other, $ip_number);

                ## no critic (Subroutines::ProtectPrivateSubs)
                if (Data::Validate::IP::_network_is_subnet_of($type, $other))
                {
                    is(
                        $other_sub->($ip), $ip,
                        "$other_sub_name($ip) returns $ip"
                    );
                    is(
                        $object->$other_sub_name($ip), $ip,
                        "->$other_sub_name($ip) returns $ip"
                    );
                }
                else {
                    is(
                        $other_sub->($ip), undef,
                        "$other_sub_name($ip) returns undef"
                    );
                    is(
                        $object->$other_sub_name($ip), undef,
                        "->$other_sub_name($ip) returns undef"
                    );
                }
            }
        }
    }
}

sub _sub_for_type {
    my $type      = shift;
    my $ip_number = shift;

    my $sub_name = 'is_' . $type . '_ip';
    $sub_name .= 'v' . $ip_number if defined $ip_number;

    my $sub = do {
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        \&{$sub_name};
        }
        or die "No sub named $sub_name was imported";

    return ($sub_name, $sub);
}

1;
