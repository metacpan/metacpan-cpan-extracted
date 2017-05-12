use strict;
use warnings;
use Test::More tests => 2;

use Acme::Replica;

my $scalar = 'test';
my $replica = replica_of( $scalar );
is($replica, pack('H2', '1c') . 'test');

$replica = replica_of( \$scalar );
is($replica, pack('H2', '1c') . 'test');

