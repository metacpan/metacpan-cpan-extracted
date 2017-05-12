use Test::More tests => 2;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $secret      = "Super Secret Squirrel";
my $known_value = '{SHA}lmrkJArUS4AvuHtllhJG2hOBlcE=';

# Bcrypt has to have a salt, so we pick a different algorithm
my $rfc2307 = passphrase($secret)->generate({ algorithm => 'SHA-1', salt => '' })->rfc2307;

ok(passphrase($secret)->matches($known_value),  "Match plaintext to it's pre-computed hash");
ok(passphrase($secret)->matches($rfc2307),      "Match plaintext to it's generated hash");
