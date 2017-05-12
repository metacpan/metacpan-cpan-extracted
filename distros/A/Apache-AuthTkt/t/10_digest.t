# Test digest_types

use File::Basename;
use Test::More tests => 21;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

my $dir = dirname($0);
my $secret = 'sekret';
my ($at, $ticket);

# Simple constructor
$at = Apache::AuthTkt->new(secret => $secret);
ok($at, 'secret constructor ok');
is($at->secret, $secret, 'secret() ok');
is($at->digest_type, 'MD5', 'default digest_type ok');

# Explicit digest_type to constructor
ok($at = Apache::AuthTkt->new(secret => $secret, digest_type => 'MD5'), 
  'explicit digest_type MD5 constructor ok');
is($at->digest_type, 'MD5', 'explicit digest_type MD5 ok');
$at = Apache::AuthTkt->new(secret => $secret, digest_type => 'SHA256');
ok($at, 'explicit digest_type SHA256 constructor ok');
is($at->digest_type, 'SHA256', 'explicit digest_type SHA256 ok');

# Invalid digest_type
ok(! defined eval { Apache::AuthTkt->new(secret => $secret, digest_type => 'foobar') },
  "die on invalid digest_type 'foobar'");

# MD5 ticket
ok($at = Apache::AuthTkt->new(secret => $secret, digest_type => 'MD5'), 
  'explicit digest_type MD5 constructor ok');
$ticket = $at->ticket(ts => 1235457789, base64 => 0);
is($ticket, '3f75c93bca98b3bb51f1fdc0ece8b01749a396fdguest!', 'MD5 ticket ok');
$ticket =~ s/guest!$//;
is(length($ticket), 32 + 8, 'length MD5 ticket == 32 + 8');

# Default ticket
ok($at = Apache::AuthTkt->new(secret => $secret),
  'default digest_type constructor ok');
$ticket = $at->ticket(ts => 1235457789, base64 => 0);
is($ticket, '3f75c93bca98b3bb51f1fdc0ece8b01749a396fdguest!', 'MD5 ticket ok');
$ticket =~ s/guest!$//;
is(length($ticket), 32 + 8, 'length default (MD5) ticket == 32 + 8');

# SHA256 ticket
ok($at = Apache::AuthTkt->new(secret => $secret, digest_type => 'SHA256'), 
  'explicit digest_type SHA256 constructor ok');
$ticket = $at->ticket(ts => 1235457789, base64 => 0);
is($ticket, '354e9021c33efd98fed2c5d39bfa29b48675f691f993c326eef25190c0d0677f49a396fdguest!', 
  'SHA256 ticket ok');
$ticket =~ s/guest!$//;
is(length($ticket), 64 + 8, 'length SHA256 ticket == 64 + 8');

# SHA512 ticket
ok($at = Apache::AuthTkt->new(secret => $secret, digest_type => 'SHA512'), 
  'explicit digest_type SHA512 constructor ok');
$ticket = $at->ticket(ts => 1235457789, base64 => 0);
is($ticket, '892e687e321b9991251951cbe273220fd3611041c32ea337d73ad3eb1ae65ad4fd46393e000a971fd38e01abc8717f92cca157017e4315abdcc9553bca56571649a396fdguest!', 
  'SHA512 ticket ok');
$ticket =~ s/guest!$//;
is(length($ticket), 128 + 8, 'length SHA512 ticket == 128 + 8');


# vim:ft=perl
