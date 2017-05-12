# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-IPV4-Range-Parse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test::More tests => 16;
use lib qw(../lib lib .);
use Data::IPV4::Range::Parse qw(:PARSE_IP :PARSE_RANGE);

my $cidr_notation='0.0.0.1/24';
my $ip_mask='0.0.0.1/255.255.255';
my $range='0.0.0.0 - 0.0.0.255';
my $base=0;
my $broadcast=255;
my $hostmask=255;
my $start=0;
my $end=255;
my $cidr=24;
my $bogus_cidr='0/';

my ($int_start,$int_end);
ok((($int_start,$int_end)=parse_ipv4_range($range)),
  'should have 2 values test a');

ok((($int_start,$int_end)=Data::IPV4::Range::Parse->parse_ipv4_range($range)),
  'should have 2 values test b');

ok((($int_start,$int_end)=parse_ipv4_cidr($cidr_notation)),
  'should have 2 values test 1'
);

ok(
  (
   ($int_start,$int_end)=
     Data::IPV4::Range::Parse->parse_ipv4_cidr( $cidr_notation)
  ),
  'should have 2 values test 2'
);

ok((($int_start,$int_end)=parse_ipv4_ip('0.0.0.0')),
  'should have 2 values test 3'
);
ok((($int_start,$int_end)=Data::IPV4::Range::Parse->parse_ipv4_ip('0.0.0.0')),
  'should have 2 values test 3'
);
ok((($int_start,$int_end)=Data::IPV4::Range::Parse->parse_ipv4_range($range)),
  'should not be able to parse $bogus_cidr'
);

ok($int_start==$base,'$int_start should be $base');
ok($int_end==$broadcast,'$int_end should be $broadcast');

ok($int_start==0,'auto parse range int_start==0');
ok($int_end==255,'auto parse range int_end==255');
ok($int_start==0,'auto parse range int_start==0');
ok($int_end==255,'auto parse range int_end==255');
ok((($int_start,$int_end)=auto_parse_ipv4_range($cidr_notation)),'auto parse the cidr');
ok( (($int_start,$int_end)=auto_parse_ipv4_range($range)),'auto parse the range');
ok( (($int_start,$int_end)=auto_parse_ipv4_range('0')),'auto parse the range');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

