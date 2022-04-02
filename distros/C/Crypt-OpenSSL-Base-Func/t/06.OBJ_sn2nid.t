use strict;
use warnings;

use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::Base::Func;

my $group_name = "prime256v1";
my $nid = OBJ_sn2nid($group_name);
is($nid, 415, "$group_name nid: $nid");
print "nid: $nid\n";
my $group = Crypt::OpenSSL::EC::EC_GROUP::new_by_curve_name($nid);
my $ctx   = Crypt::OpenSSL::Bignum::CTX->new();
my $p = Crypt::OpenSSL::Bignum->zero;
my $a = Crypt::OpenSSL::Bignum->zero;
my $b = Crypt::OpenSSL::Bignum->zero;
#$group->get_order( $order, $ctx );
#$group->get_curve($p, $a, $b, $ctx);
EC_GROUP_get_curve($group, $p, $a, $b, $ctx);
my $p_hex = $p->to_hex;
print "p: $p_hex\n";
my $a_hex = $a->to_hex;
print "a: $a_hex\n";
my $b_hex = $b->to_hex;
print "b: $b_hex\n";


done_testing;
