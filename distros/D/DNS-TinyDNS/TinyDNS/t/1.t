# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use lib ".";
use Test::More tests => 32;
use DNS::TinyDNS;

my ($dnscache,%config,$cache,$server);

# Tests 4 dnscache
$dnscache = DNS::TinyDNS->new( type     => 'dnscache');
ok( $dnscache );

SKIP : {
        skip("I can't find a running version of dnscache", 19)
                   unless $dnscache->dir("/service/dnscachex");
        ok( $dnscache->dir );
        ok( $config{ip} = $dnscache->get_env('ip') );
        ok( $config{ipsend} = $dnscache->get_env('ipsend') );
        ok( $config{cachesize} = $dnscache->get_env('cachesize') );
        ok( $config{datalimit} = $dnscache->get_env('datalimit') );
        ok( $config{root} = $dnscache->get_env('root') );
        {
                my @a = $dnscache->get_env( qw{cachesize ip datalimit} );
                ok( 3 == @a );
        }
        ok( $dnscache->set_env( ip              => $config{ip}          ) );
        ok( $dnscache->set_env( root            => $config{root}        ) );
        ok( $dnscache->set_env( cachesize       => $config{cachesize}   ) );
        ok( $dnscache->set_env( datalimit       => $config{datalimit}   ) );
        ok( $dnscache->set_env( ipsend          => $config{ipsend}      ) );
        ok( $dnscache->set_env( ip              => $config{ip},
                                root            => $config{root},
                                cachesize       => $config{cachesize}   ) );
        ok( $dnscache->add_ip( '10.0.0.13' ) );
        ok( $dnscache->del_ip( '10.0.0.13' ) );
        ok( $dnscache->list_ips );
        ok( $dnscache->list_servers );
        ok( $dnscache->add_server( '10.0.0.13' ) );
        ok( $dnscache->del_server( '10.0.0.13' ) );
}
# End of dnscache tests

# Test for dnsserver
%config = ();
my $dnsserver = DNS::TinyDNS->new(type => 'dnsserver');
ok( $dnsserver );

SKIP : {
        skip("I can't find a running version of dnsserver", 11)
                   unless $dnsserver->dir("/service/tinydns");

        ok( $dnsserver->dir );
        ok( $config{ip}=$dnsserver->get_env('ip') );
        ok( $config{root}=$dnsserver->get_env('root') );
        {
                my @a = $dnsserver->get_env( qw{ip root} );
                ok( 2 == @a );
        }
        ok( $dnsserver->set_env( ip             => $config{ip}          ) );
        ok( $dnsserver->set_env( root           => $config{root}        ) );
        {
                my @zones;
                ok( @zones=$dnsserver->list_zones );
                ok( $dnsserver->list(   type    => 'mx',
                                        zone    => $zones[-1]   ) );
                ok( $dnsserver->get_zone( $zones[-1] ) );
        }
        ok( $dnsserver->add(    zone => '7a69ezine.org',
                                type => 'host',
                                ip   => '10.0.0.1',
                                host => 'rivendel',
                                ttl  => 84500,          ) );
        ok( $dnsserver->del(    zone => '7a69ezine.org',
                                type => 'host',
                                ip   => '10.0.0.1',
                                host => 'rivendel',
                                ttl  => 84500,          ) );
}

1;
