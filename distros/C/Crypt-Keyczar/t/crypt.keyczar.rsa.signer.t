use Test::More tests => 11;
use strict;
use warnings;
use FindBin;

use Crypt::Keyczar::Util;


sub BEGIN {
    use_ok('Crypt::Keyczar::RsaPrivateKey');
    use_ok('Crypt::Keyczar::Verifier');
    use_ok('Crypt::Keyczar::Signer');
}
my $KEYSET = "$FindBin::Bin/data/rsa-sign";
my $KEYSET_PUB = "$FindBin::Bin/data/rsa-sign-pub";

my $sig1 = Crypt::Keyczar::Util::decode(get_file("$KEYSET/1.out"));
my $v = Crypt::Keyczar::Verifier->new($KEYSET);
ok($v->verify('This is some test data', $sig1), 'verify key#1');

my $sig2 = Crypt::Keyczar::Util::decode(get_file("$KEYSET/2.out"));
ok($v->verify('This is some test data', $sig2), 'verify key#2');




my $signer = Crypt::Keyczar::Signer->new($KEYSET);
ok($signer, 'create signer');
my $sig3 = $signer->sign('This is test data');
ok($sig3, 'sign pubkey');

my $v_pub = Crypt::Keyczar::Signer->new($KEYSET_PUB);
ok($v_pub->verify('This is test data', $sig3), 'verify public key');


ok(my $sig4 = $signer->sign("Hello World!", time() + 5 * 60), 'sign with expiration');
ok($v_pub->verify("Hello World!", $sig4), 'verify with expiration');
$sig4 = $signer->sign("Hello World!", time() - 5 * 60);
ok(!$v_pub->verify("Hello World!", $sig4), 'expired signature');



sub get_file {
    my $path = shift;
    open my $fh, '<', $path or die $!;
    local $/ = undef;
    my $data = <$fh>;
    close $fh;
    return $data;
}
