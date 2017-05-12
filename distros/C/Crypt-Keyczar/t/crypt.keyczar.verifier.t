use Test::More tests => 3;
use strict;
use warnings;
use FindBin;

sub BEGIN { use_ok('Crypt::Keyczar::Verifier') }
my $KEYSET = "$FindBin::Bin/data/signer";
my $signature = pack 'H*', '00f24be16ff04a5982c38dfe356e4f852800a936795d3331ca';

my $verifier = Crypt::Keyczar::Verifier->new($KEYSET);
ok($verifier, 'create verifier');
ok($verifier->verify('Hello World!', $signature), 'test verify');
