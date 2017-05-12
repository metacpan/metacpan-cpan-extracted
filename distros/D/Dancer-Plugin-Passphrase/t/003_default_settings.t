use Test::More tests => 3;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $secret = "Super Secret Squirrel";

my $rfc2307 = passphrase($secret)->generate->rfc2307;

like($rfc2307, qr/^{CRYPT}\$2a\$04\$/,      'RFC compliant hash generated');
ok(passphrase($secret)->matches($rfc2307),  'Match plaintext to hash');
ok(!passphrase('WRONG')->matches($rfc2307), 'Incorrect passwords should be rejected');
