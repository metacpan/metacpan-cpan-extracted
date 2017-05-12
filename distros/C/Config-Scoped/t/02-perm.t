# vim: cindent ft=perl

# change 'tests => 1' to 'tests => last_test_to_print';
use warnings;
use strict;

use Test::More tests => 4;
use File::Spec;

BEGIN { use_ok('Config::Scoped') }
my $unsafe_cfg = File::Spec->catfile( 't', 'files', 'fvalid.cfg' );
chmod 0664, $unsafe_cfg;
my ($p, $cfg);
isa_ok($p = Config::Scoped->new(file => $unsafe_cfg), 'Config::Scoped');

eval { $cfg = $p->parse; };
isa_ok($@, 'Config::Scoped::Error::Validate::Permissions');
like($@, qr/is unsafe/i, "$@");
