use strict;
use warnings;

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Hash2Curve;

my $group_name = "prime256v1";
my $type = 'sswu';
my $z = sn2z($group_name, $type);
my $z_hex = $z->to_hex;
is($z_hex, '-0A', 'find_z');


done_testing;
