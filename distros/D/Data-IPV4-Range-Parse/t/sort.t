# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-IPV4-Range-Parse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use lib qw(../lib lib .);
use Data::IPV4::Range::Parse qw(:SORT);

my @ips=qw(11 9 8 6);
my $sorted=join ',',sort sort_quad @ips;

ok($sorted eq '6,8,9,11','sort_quad 1');

my @ranges=qw(10/11 10/25 8-16);

$sorted=join ',',sort sort_notations @ranges;
ok($sorted eq '8-16,10/25,10/11','sort_notations 1');
