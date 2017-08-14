use warnings;
use strict;

use Test::More tests => 9;

BEGIN { use_ok "Data::ID::Exim", qw(exim_mid exim_mid36); }

my $id = exim_mid;
isnt(exim_mid, $id);
like($id, qr/\A[0-9A-Za-z]{6}-[0-9A-Za-z]{6}-[0-9A-Za-z]{2}\z/);

$id = exim_mid(3);
isnt(exim_mid(3), $id);
like($id, qr/\A[0-9A-Za-z]{6}-[0-9A-Za-z]{6}-[0-9A-Za-z]{2}\z/);

$id = exim_mid36;
isnt(exim_mid36, $id);
like($id, qr/\A[0-9A-Z]{6}-[0-9A-Z]{6}-[0-9A-Z]{2}\z/);

$id = exim_mid36(3);
isnt(exim_mid36(3), $id);
like($id, qr/\A[0-9A-Z]{6}-[0-9A-Z]{6}-[0-9A-Z]{2}\z/);

1;
