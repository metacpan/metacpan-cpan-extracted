use Test::More tests => 1;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $secret = "Super Secret Squirrel";

my $rfc2307 = passphrase($secret)->generate;


eval { passphrase($secret)->matches($rfc2307) };
unlike $@, qr/Operation "eq": no method found/i, 'Auto stringifies passphrase object';

