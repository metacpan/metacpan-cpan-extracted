#!/usr/bin/perl

use strict;
use warnings;
use DNS::TinyDNS;

my $domain = "iomolo.com";
my $ip = "10.0.0.4";
my $host = "anarion";
my $dnsserver = DNS::TinyDNS->new(      type => 'dnsserver',
                                        dir  => '/service/tinydns' );

if ($ARGV[0] eq "add")
{
        add_dns();
}

if($ARGV[0] eq "del")
{
        del_dns();
}

$dnsserver->restart;

sub add_dns
{
        $dnsserver->add(zone => $domain,
                        type => 'mx',
                        ip   => $ip,
                        host => "$host.$domain",
                        pref => 10,
                        ttl  => 84500,
                        );

        $dnsserver->add(zone => $domain,
                        type => 'ns',
                        ip   => $ip,
                        host => $host,
                        ttl  => 84500,
                        );

        $dnsserver->add(zone => $domain,
                        type => 'host',
                        ip   => $ip,
                        host => $host,
                        ttl  => 84500,
                        );

        $dnsserver->add(zone => $domain,
                        type => 'alias',
                        cname=> 'www.iomolo.com',
                        host => $host,
                        ttl  => 84500,
                        );

        $dnsserver->add(zone => $domain,
                        type => 'reverse',
                        host => $host,
                        ip   => $ip,
                        );
}

sub del_dns
{
        $dnsserver->del(zone => $domain,
                        type => 'mx',
                        ip   => $ip,
                        host => "$host.$domain",
                        pref => 10,
                        );

        $dnsserver->del(zone => $domain,
                        type => 'ns',
                        ip   => $ip,
                        host => $host,
                        );

        $dnsserver->del(zone => $domain,
                        type => 'host',
                        host => $host,
                        ip   => $ip,
                        );

        $dnsserver->del(zone => $domain,
                        type => 'alias',
                        host => $host,
                        cname=> 'www.iomolo.com',
                        );

        $dnsserver->del(zone => $domain,
                        type => 'reverse',
                        host => $host,
                        ip   => $ip,
                        );
}
