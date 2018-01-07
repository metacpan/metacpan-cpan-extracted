#!/usr/bin/env perl

use strictures 2;
use Crypt::PK::ECC;
use MIME::Base64 qw(encode_base64url);
use Test::Exception;
use Test::More;

use_ok 'Authen::U2F::Tester::Keypair' or exit 1;
use_ok 'Authen::U2F::Tester::Keystore::Wrapped' or exit 1;

my $keyfile = 't/ssl/key.pem';

my $pk = Crypt::PK::ECC->new($keyfile);
isa_ok $pk, 'Crypt::PK::ECC';

my $keystore = Authen::U2F::Tester::Keystore::Wrapped->new(key => $pk);
isa_ok $keystore, 'Authen::U2F::Tester::Keystore::Wrapped';

can_ok $keystore, qw(exists get put);

my $keypair = Authen::U2F::Tester::Keypair->new;
isa_ok $keypair, 'Authen::U2F::Tester::Keypair';

my $handle = $keystore->put($keypair->private_key);

ok defined $handle;

$handle = encode_base64url($handle);

# valid handle exists
ok $keystore->exists($handle);

# invalid handle does not exist
ok !$keystore->exists('aaa');

$pk = $keystore->get($handle);
isa_ok $pk, 'Crypt::PK::ECC';

# compare the private key to the original keypair private key
my $ks_keypair = Authen::U2F::Tester::Keypair->new(keypair => $pk);

is $ks_keypair->private_key, $keypair->private_key;

dies_ok { $keystore->remove($handle) };

done_testing;
