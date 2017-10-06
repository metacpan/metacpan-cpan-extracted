#!/usr/bin/perl

use strict;
use warnings;
use Test::Simple tests => 48;

use Cisco::SNMP;
ok(1, "Loading Module"); # If we made it this far, we're ok.

my $ANSWER;
{
    local $/;
    $ANSWER = eval <DATA>;
}

my $ret;

res( 0, '1.1.1.1' );
res( 1, '1.1.1.1:1024' );
res( 2, 'localhost' );
res( 3, 'localhost:1024' );
res( 4, 'fe80::1' );
res( 5, 'fe80::1:1024' );
res( 6, '[fe80::1]' );
res( 7, '[fe80::1]:1024' );

sub res {
    my ( $test, $host ) = @_;
    my $ret = Cisco::SNMP::_resolv( $host );
    for ( sort (keys ( %{$ret} ) ) ) {
        ok($ret->{$_} eq $ANSWER->[$test]->{$_}, "$test: $_");
    }
}

ok(Cisco::SNMP->DEFAULT_FAMILY()   == 2,  '->default_family() return');
ok(Cisco::SNMP->DEFAULT_FAMILY(2)  == 2,  '->default_family(2) return');
ok(Cisco::SNMP->DEFAULT_FAMILY(4)  == 2,  '->default_family(4) return');
ok(Cisco::SNMP->DEFAULT_FAMILY(6)  == 2,  '->default_family(6) return');
ok(Cisco::SNMP->DEFAULT_FAMILY(23) == 23, '->default_family(23) return');
ok(Cisco::SNMP->DEFAULT_FAMILY()   == 23, '->default_family() return');

ok(Cisco::SNMP::DEFAULT_FAMILY()   == 23, '::default_family() return');
ok(Cisco::SNMP::DEFAULT_FAMILY(2)  == 23, '::default_family(2) return');
ok(Cisco::SNMP::DEFAULT_FAMILY(4)  == 2, '::default_family(4) return');
ok(Cisco::SNMP::DEFAULT_FAMILY(6)  == 2,  '::default_family(6) return');
ok(Cisco::SNMP::DEFAULT_FAMILY(23) == 23,  '::default_family(23) return');
ok(Cisco::SNMP::DEFAULT_FAMILY()   == 23, '::default_family() return');

__DATA__
[
    {
        'addr' => '1.1.1.1',
        'family' => 2,
        'host' => '1.1.1.1',
        'name' => '1.1.1.1'
    },
    {
        'addr' => '1.1.1.1',
        'family' => 2,
        'host' => '1.1.1.1',
        'name' => '1.1.1.1:1024',
        'port' => 1024
    },
    {
        'addr' => '127.0.0.1',
        'family' => 2,
        'host' => 'localhost',
        'name' => 'localhost',
    },
    {
        'addr' => '127.0.0.1',
        'family' => 2,
        'host' => 'localhost',
        'name' => 'localhost:1024',
        'port' => 1024,
    },
    {
        'addr' => 'fe80::1',
        'family' => 23,
        'host' => 'fe80::1',
        'name' => 'fe80::1'
    },
    {
        'addr' => 'fe80::1:1024',
        'family' => 23,
        'host' => 'fe80::1:1024',
        'name' => 'fe80::1:1024',
    },
    {
        'addr' => 'fe80::1',
        'family' => 23,
        'host' => 'fe80::1',
        'name' => '[fe80::1]',
    },
    {
        'addr' => 'fe80::1',
        'family' => 23,
        'host' => 'fe80::1',
        'name' => '[fe80::1]:1024',
        'port' => 1024,
    },
]
