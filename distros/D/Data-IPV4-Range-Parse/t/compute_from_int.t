# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-IPV4-Range-Parse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 41;
use strict;
use warnings;
use lib qw(../lib lib .);
use Data::IPV4::Range::Parse qw(:CONSTANTS :COMPUTE_FROM_INT :PARSE_IP);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(cidr_to_int(32)==ALL_BITS,"cidr_to_int(32)");
ok(cidr_to_int(31)==(ALL_BITS & (ALL_BITS<<1)),"cidr_to_int(31)");
ok(cidr_to_int(30)==(ALL_BITS & (ALL_BITS<<2)),"cidr_to_int(30)");
ok(cidr_to_int(29)==(ALL_BITS & (ALL_BITS<<3)),"cidr_to_int(29)");
ok(cidr_to_int(28)==(ALL_BITS & (ALL_BITS<<4)),"cidr_to_int(28)");
ok(cidr_to_int(27)==(ALL_BITS & (ALL_BITS<<5)),"cidr_to_int(27)");
ok(cidr_to_int(26)==(ALL_BITS & (ALL_BITS<<6)),"cidr_to_int(26)");
ok(cidr_to_int(25)==(ALL_BITS & (ALL_BITS<<7)),"cidr_to_int(25)");
ok(cidr_to_int(24)==(ALL_BITS & (ALL_BITS<<8)),"cidr_to_int(24)");
ok(cidr_to_int(23)==(ALL_BITS & (ALL_BITS<<9)),"cidr_to_int(23)");
ok(cidr_to_int(22)==(ALL_BITS & (ALL_BITS<<10)),"cidr_to_int(22)");
ok(cidr_to_int(21)==(ALL_BITS & (ALL_BITS<<11)),"cidr_to_int(21)");
ok(cidr_to_int(20)==(ALL_BITS & (ALL_BITS<<12)),"cidr_to_int(20)");
ok(cidr_to_int(19)==(ALL_BITS & (ALL_BITS<<13)),"cidr_to_int(19)");
ok(cidr_to_int(18)==(ALL_BITS & (ALL_BITS<<14)),"cidr_to_int(18)");
ok(cidr_to_int(17)==(ALL_BITS & (ALL_BITS<<15)),"cidr_to_int(17)");
ok(cidr_to_int(16)==(ALL_BITS & (ALL_BITS<<16)),"cidr_to_int(16)");
ok(cidr_to_int(15)==(ALL_BITS & (ALL_BITS<<17)),"cidr_to_int(15)");
ok(cidr_to_int(14)==(ALL_BITS & (ALL_BITS<<18)),"cidr_to_int(14)");
ok(cidr_to_int(13)==(ALL_BITS & (ALL_BITS<<19)),"cidr_to_int(13)");
ok(cidr_to_int(12)==(ALL_BITS & (ALL_BITS<<20)),"cidr_to_int(12)");
ok(cidr_to_int(11)==(ALL_BITS & (ALL_BITS<<21)),"cidr_to_int(11)");
ok(cidr_to_int(10)==(ALL_BITS & (ALL_BITS<<22)),"cidr_to_int(10)");
ok(cidr_to_int(9)==(ALL_BITS & (ALL_BITS<<23)),"cidr_to_int(9)");
ok(cidr_to_int(8)==(ALL_BITS & (ALL_BITS<<24)),"cidr_to_int(8)");
ok(cidr_to_int(7)==(ALL_BITS & (ALL_BITS<<25)),"cidr_to_int(7)");
ok(cidr_to_int(6)==(ALL_BITS & (ALL_BITS<<26)),"cidr_to_int(6)");
ok(cidr_to_int(5)==(ALL_BITS & (ALL_BITS<<27)),"cidr_to_int(5)");
ok(cidr_to_int(4)==(ALL_BITS & (ALL_BITS<<28)),"cidr_to_int(4)");
ok(cidr_to_int(3)==(ALL_BITS & (ALL_BITS<<29)),"cidr_to_int(3)");
ok(cidr_to_int(2)==(ALL_BITS & (ALL_BITS<<30)),"cidr_to_int(2)");
ok(cidr_to_int(1)==(ALL_BITS & (ALL_BITS<<31)),"cidr_to_int(1)");
ok(cidr_to_int(0)==0,"cidr_to_int(0)");
my $ip=ip_to_int('192.168.0.1');
my $base=ip_to_int('192.168.0.0');
my $mask=ip_to_int('255.255.255');
ok(base_int($ip,$mask)==$base,'base_int 1');
ok(Data::IPV4::Range::Parse->base_int($ip,$mask)==$base,'base_int 2');
ok(hostmask($mask)==255,'hostmask 1');
ok(Data::IPV4::Range::Parse->hostmask($mask)==255,'hostmask 1');
ok(size_from_mask($mask)==256,'size_from_mask 2');
ok(Data::IPV4::Range::Parse->size_from_mask($mask)==256,'size_from_mask 1');
ok(broadcast_int(ALL_BITS,ALL_BITS) == ALL_BITS ,'broadcast_int(ALL_BITS) 1');
ok(Data::IPV4::Range::Parse->broadcast_int(ALL_BITS,ALL_BITS) == ALL_BITS ,'broadcast_int(ALL_BITS) 2');

