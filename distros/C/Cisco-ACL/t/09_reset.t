#
# $Id$
#

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

my $package = 'Cisco::ACL';

use_ok($package);

my $acl;
lives_ok {
    $acl = $package->new;
} 'create an ACL object';
isa_ok($acl, $package);

$acl->permit(1);
$acl->dst_addr( '1.1.1.1' );
$acl->dst_port( '21937' );
$acl->established(1);
$acl->protocol('tcp');

$acl->reset;

my $expected = "deny tcp any any";
my $gotback = $acl->acls->[0];
is($gotback, $expected, 'established ACL matches');

#
# EOF
