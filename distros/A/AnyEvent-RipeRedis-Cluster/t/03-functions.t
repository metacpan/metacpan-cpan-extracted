use 5.008000;
use strict;
use warnings;

use Test::More tests => 2;
use AnyEvent::RipeRedis::Cluster qw( crc16 hash_slot );

my $crc16 = crc16('123456789');
is( $crc16, 0x31c3, 'crc16' );

my $slot = hash_slot('{foo}bar');
is( $slot, 12182, 'hash_slot' );
