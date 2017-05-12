use Test::More tests => 4;
use strict;
use warnings;
use Crypt::Keyczar::Signer;
use Crypt::Keyczar::Verifier;
use Crypt::Keyczar::Util;
use FindBin;


my $KEYSET = "$FindBin::Bin/data/compat-python-sign";
my $signer = Crypt::Keyczar::Signer->new($KEYSET);
ok($signer);
my $sign = $signer->sign("This is some test data");
ok(Crypt::Keyczar::Util::encode($sign) eq 'AEcYuxsWbrgABHY2L_vEk5OzHGrD8eZb7g');

my $verifier = Crypt::Keyczar::Verifier->new($KEYSET);
ok($verifier->verify("This is some test data", $sign));
ok(!$verifier->verify("Wrong string", $sign));

