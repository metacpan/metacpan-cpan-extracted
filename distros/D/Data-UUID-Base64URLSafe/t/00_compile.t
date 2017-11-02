use strict;
use Test::More 0.98 tests => 8;

use lib './lib';
use Data::UUID qw(NameSpace_DNS);

use_ok 'Data::UUID::Base64URLSafe';                                     # 1

my $ug = new_ok('Data::UUID::Base64URLSafe');                           # 2
my $qr = qr/^(:?[\w\-]{22})$/;

 like my $uuid1 = $ug->create_b64_urlsafe(), $qr,                       # 3
"succeed to create a b64-urlsafe string";

 like my $uuid2 = $ug->create_b64_urlsafe(), $qr,                       # 4
"succeed to create another b64-urlsafe string";

isnt $uuid1, $uuid2, "UUIDs are different";                             # 5

my $uuid = '';
my $ns = Data::UUID::NameSpace_DNS;
my $str = 'test';

 like $uuid = $ug->create_from_name_b64_urlsafe( $ns, $str ), $qr,      # 6
"succeed to create b64-urlsafe string from name";

my $bin1 = $ug->from_b64_urlsafe($uuid);
my $bin2 = $ug->create_from_name( $ns, $str );

is $bin1, $bin2, "decoding works correctly";                            # 7
is $uuid, $ug->to_b64_urlsafe($bin2), "encoding works correctly";       # 8

done_testing();
