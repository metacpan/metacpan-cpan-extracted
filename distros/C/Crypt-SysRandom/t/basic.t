#! perl

use strict;
use warnings;

use Test::More;

use Crypt::SysRandom ':all';

my $first = random_bytes(16);

is length $first, 16, '$first is 16 bytes';
isnt $first, scalar("\0" x 16), "\$first isn't empty";

my $second = random_bytes(16);

isnt $first, $second, "\$first isn't second";

my $uuid = random_uuid();
like($uuid, qr/^\w{8}-\w{4}-4\w{3}-[89ab]\w{3}-\w{12}$/, 'random_uuid looks correct');

my $hex = random_hex(16);
like($hex, qr/^[0-9a-f]{32}$/, 'random_hex looks ok');

my $base64 = random_base64(16);
like($base64, qr/^[A-Za-z0-9+\/]{22}==$/, 'random_base64 looks ok');

my $base64url = random_base64url(16);
like($base64url, qr/^[A-Za-z0-9_-]{22}$/, 'random_base64url looks ok');

done_testing;
