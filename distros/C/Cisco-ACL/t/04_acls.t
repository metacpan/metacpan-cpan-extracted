#
# $Id: 04_acls.t 86 2004-06-18 20:18:01Z james $
#

use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;

my $package = 'Cisco::ACL';

use_ok($package);

my $acl;
lives_ok {
    $acl = $package->new;
} 'create an ACL object';
isa_ok($acl, $package);

# these expected results of these tests are taken directly from the output
# of Chris De Young's original ACL Maker CGI.  Each tuple consists of 7
# elements: a 1 or 0 for permit/deny, the source address, the source port,
# the dest address, the dest port, the protocol, and the expected output.
my @tests;
{

    no warnings 'qw'; # lets us put commas in our words

    @tests = (

        [ 1, [ '10.1.1.1' ], [ 'any' ], [ '10.1.2.1' ], [ 'any' ], 'tcp',
          [
            'permit tcp host 10.1.1.1 host 10.1.2.1',
          ],
        ],

        [ 1, [ '10.10.10.10/8', '45.45.45.45' ], [ 34 ], [ '192.168.1.1/27' ], [ 'any' ], 'udp',
          [
            'permit udp 10.0.0.0 0.255.255.255 eq 34 192.168.1.0 0.0.0.31',
            'permit udp host 45.45.45.45 eq 34 192.168.1.0 0.0.0.31',
          ],
        ],
        [ 0, [ '10.94.98.0/24', '10.94.99.0/24' ], [ 'any' ], [ '10.160.1.125' ], [ 21937 ] , 'tcp',
          [
            'deny tcp 10.94.98.0 0.0.0.255 host 10.160.1.125 eq 21937',
            'deny tcp 10.94.99.0 0.0.0.255 host 10.160.1.125 eq 21937',
          ],
        ],

        [ 0, [ '24.223.251.222' ], [ 'any' ], [ 'any' ], [ 'any' ], 'ip',
          [
            'deny ip host 24.223.251.222 any',
          ],
        ],

        [ 0, [ 'any' ], [ 'any' ], [ '24.223.251.222' ], [ 'any' ], 'ip',
          [
            'deny ip any host 24.223.251.222',
          ],
        ],

        [ 1, [ '192.168.1.1/25', '10.1.1.1/26' ], [ 'any' ], [ 'any' ], [ 22, 25 ], 'tcp',
          [
            'permit tcp 192.168.1.0 0.0.0.127 any eq 22',
            'permit tcp 192.168.1.0 0.0.0.127 any eq 25',
            'permit tcp 10.1.1.0 0.0.0.63 any eq 22',
            'permit tcp 10.1.1.0 0.0.0.63 any eq 25',
          ],
        ],
        [ 1, [ '192.168.1.1/23' ], [ 'any' ], [ 'any' ], [ '8080-8088' ], 'udp',
          [
            'permit udp 192.168.0.0 0.0.1.255 any range 8080 8088',
          ]
        ],
        [ 0, [ '192.168.1.1/20' ], [ '25-20' ], [ 'any' ], [ '8088-8000' ], 'tcp',
          [
            'deny tcp 192.168.0.0 0.0.15.255 range 20 25 any range 8000 8088',
          ]
        ],
    );

}

for( @tests ) {
    my($permit, $src_addr, $src_port, $dst_addr, $dst_port,
       $proto, $expected) = @{ $_ };
    my $name = $permit ? "permit" : "deny";
    $name .= " $proto from " . join(',', @{ $src_addr }) . " port " .
               join(',', @{ $src_port }) . " to " .
               join(',', @{ $dst_addr }) . " port " .
               join(',', @{ $dst_port });
    
    $acl->permit($permit);
    $acl->src_addr($src_addr);
    $acl->src_port($src_port);
    $acl->dst_addr($dst_addr);
    $acl->dst_port($dst_port);
    $acl->protocol($proto);
    my $gotback = $acl->acls;
    is_deeply($gotback, $expected, "$name");
    $gotback = Cisco::ACL->new(
        permit   => $permit,
        src_addr => $src_addr,
        src_port => $src_port,
        dst_addr => $dst_addr,
        dst_port => $dst_port,
        protocol => $proto,
    )->acls;
    is_deeply($gotback, $expected, "$name");
}

#
# EOF
