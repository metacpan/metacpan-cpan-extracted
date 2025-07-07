use strict;
use warnings;


use Test::More ;
use Crypt::OpenSSL::EC;
use Crypt::OpenSSL::Bignum;
use Crypt::OpenSSL::BaseFunc;
use Data::Dumper;
#use Smart::Comments;

my $group_name = "prime256v1";
my $type = 'sswu';
my $u_hex = 'ea083a886a38ef4d15d95bd6a4b4d65620d3c57e4ed00e09fd2d67d67afd0797';
my $u = Crypt::OpenSSL::Bignum->new_from_hex($u_hex);

my $params_ref = get_hash2curve_params($group_name, $type);

my $P  = map_to_curve($params_ref, $group_name, $type, $u, 0);

### $P

my $bn = point2hex($group_name, $P, 4);

### $bn

is($bn, '04993B46E30BA9CFC3DC2D3AE2CF9733CF03994E74383C4E1B4A92E8D6D466B321C4A642979162FBDE9E1C9A6180BD27A0594491E4C231F51006D0BF7992D07127', 'map to curve');


done_testing;

