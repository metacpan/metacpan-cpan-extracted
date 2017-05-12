#!perl
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin";
use FakeRealm;

use_ok( 'Catalyst::Authentication::Credential::YubiKey' );

my $realm = FakeRealm->new;
my $config = {};
my $app = {};

throws_ok {
    Catalyst::Authentication::Credential::YubiKey->new(
        $config, $app, $realm
    );
} 'Catalyst::Exception', 'Catches missing parameters';

like($@, qr/missing api_id and api_key/);

$config->{api_id} = '1234';
$config->{api_key} = 'd34db33f';

lives_ok {
    Catalyst::Authentication::Credential::YubiKey->new(
        $config, $app, $realm
    );
} "Creates object successfully with valid parameters";

$config{id_for_store} = 'yubico_id';
my $cred;
lives_ok {
    $cred = Catalyst::Authentication::Credential::YubiKey->new(
        $config, $app, $realm
    );
} "Creates object successfully with optional parameters";

ok($cred->isa('Catalyst::Authentication::Credential::YubiKey'));

# Unsure how to check the authenticate() method properly; perhaps a lot of mock
# objects are required?

done_testing();
