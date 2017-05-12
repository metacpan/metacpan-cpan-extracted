use Test::More tests => 26;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $secret = "Super Secret Squirrel";

for (qw(MD5 SHA-1 SHA-224 SHA-256 SHA-384 SHA-512 Bcrypt)) {
    my $rfc2307 = passphrase($secret)->generate({ algorithm => $_ })->rfc2307;

    ok(passphrase($secret)->matches($rfc2307),  "With Salt - Match plaintext to hash => $_");
    ok(!passphrase('WRONG')->matches($rfc2307), "With Salt - Incorrect passwords should be rejected => $_");
}


for (qw(MD5 SHA-1 SHA-224 SHA-256 SHA-384 SHA-512)) {
    my $rfc2307 = passphrase($secret)->generate({ algorithm => $_, salt => '' })->rfc2307;

    ok(passphrase($secret)->matches($rfc2307),  "No Salt - Match plaintext to hash => $_");
    ok(!passphrase('WRONG')->matches($rfc2307), "No Salt - Incorrect passwords should be rejected => $_");
}
