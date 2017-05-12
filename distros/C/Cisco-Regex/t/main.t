#!/usr/local/bin/perl

# Cisco::Regex main.t
# Copyright (c) 2014 Jeremy Kister.
# Released under Perl's Artistic License.

use strict;
use Test::Simple tests => 17;

use Cisco::Regex;

my $version = Cisco::Regex::Version();
ok( $version =~ /^\d+\.\d+$/, "version check okay" );

my $r = Cisco::Regex->new();
ok( $r->{class} eq 'Cisco::Regex', "testing Cisco::Regex v$version on platform: $^O" );

my %acl = ( std => { good => [ 'access-list 15 permit 10.0.0.0 0.255.255.255',
                               'access-list 15 permit host   192.168.1.1',
                             ],
                     bad  => [ 'access-list 15 permit 10.0.0.0 0.255.255.255 any',
                               'access-list 15 permit tcp any 10.1.0.0 0.0.255.255 range 32768 33792',
                               'access-list 15',
                               'aksdfasjs34',
                             ],
                   },
            ext => { good => [ 'access-list 115 permit udp 10.0.0.0 0.255.255.255 eq 5060 any log',
                               'access-list 115 permit tcp 10.0.0.0 0.0.255.255 eq 15 10.1.0.0 0.0.255.255 eq domain',
                               'access-list 115 permit tcp any 10.1.0.0 0.0.255.255 range 32768 33792',
                               'access-list 115 deny ip any any log DEFAULT',
                             ],
                     bad  => [ 'access-list 115 permit 10.0.0.0 0.255.255.255 any',
                               'access-list 115 permit any 10.1.0.0 0.0.255.255 range 32768 33792',
                               'access-list 115 permit 10.0.0.0 0.255.255.255',
                               'access-list 115',
                               'alajsdf34',
                             ],
                   },
         );

for my $type (keys %acl){
    my $method = $type eq 'std' ? 'standard' : 'extended';
    for my $line (@{ $acl{$type}{good} }){
        my $isok = $r->$method($line);
        ok( $isok == 1, "syntax ($method/good)." );
    }
    for my $line (@{ $acl{$type}{bad} }){
        my $isok = $r->$method($line);
        ok( $isok != 1, "syntax ($method/bad)." );
    }
}
