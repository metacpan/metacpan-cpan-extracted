#
# $Id$
#

use strict;
use warnings;

use Test::More tests => 5;
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

my $expected = "permit tcp any host 1.1.1.1 eq 21937 established";
my $gotback = $acl->acls->[0];
is($gotback, $expected, 'established ACL matches');

$acl->reset;

$acl->permit(1);
$acl->established(1);

$expected = "permit tcp any any established";
$gotback = $acl->acls->[0];
is($gotback, $expected, 'established ACL matches');

#
# EOF
