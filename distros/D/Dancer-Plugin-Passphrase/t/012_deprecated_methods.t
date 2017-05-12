use Test::More tests => 7;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $secret = "Super Secret Squirrel";
my $object = passphrase($secret)->generate();

# Suppress all warnings while we are testing things that are supposed to warn
local $SIG{__WARN__} = sub { };

# Check that deprecated methods match their non-deprecated counterparts
is ($object->as_rfc2307(), $object->rfc2307(),  "rfc2307 & as_rfc2307 output is identical");
is ($object->raw_salt(),   $object->salt_raw(), "salt_raw & raw_salt output is identical");
is ($object->raw_hash(),   $object->hash_raw(), "hash_raw & raw_hash output is identical");


# Make warnings die, so we can catch them without additional modules
local $SIG{__WARN__} = sub { die $_[0] };

# We've checked they work, now check they warn
eval { passphrase($secret)->generate_hash() };
like $@, qr/generate_hash method is deprecated/i, 'Warns generate_hash is deprecated';

eval { passphrase($secret)->generate()->as_rfc2307 };
like $@, qr/as_rfc2307 method is deprecated/i, 'Warns as_rfc2307 is deprecated';

eval { passphrase($secret)->generate()->raw_salt };
like $@, qr/raw_salt method is deprecated/i, 'Warns raw_salt is deprecated';

eval { passphrase($secret)->generate()->raw_hash };
like $@, qr/raw_hash method is deprecated/i, 'Warns raw_hash is deprecated';
