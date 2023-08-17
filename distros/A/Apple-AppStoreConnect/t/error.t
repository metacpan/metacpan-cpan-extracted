use Test2::Tools::Exception qw/dies lives/;
use Test2::V0;

use HTTP::Response;
use LWP::UserAgent;
use Apple::AppStoreConnect;

my (%opt, $asc);

subtest 'Wrong input' => sub {
    like(
        dies { Apple::AppStoreConnect->new(%opt) },
        qr/issuer .* required./,
        "No issuer ID"
    );
    $opt{issuer} = 1;

    like(
        dies { Apple::AppStoreConnect->new(%opt) },
        qr/key_id .* required./,
        "No key_id"
    );
    $opt{key_id} = 1;

    like(
        dies { Apple::AppStoreConnect->new(%opt) },
        qr/key or key_file required./,
        "No key/key_file"
    );

    $opt{key_file} = 'DoesNotExist';
    like(
        dies { Apple::AppStoreConnect->new(%opt) },
        qr/Can't open file/,
        "Not valid file"
    );
    $opt{key} = 1;

    ok(lives {$asc = Apple::AppStoreConnect->new(%opt)}, "Does not die");

    like(dies { $asc->get() }, qr/url required/, "Missing url");
};

my $mock = Test2::Mock->new(
    class => 'LWP::UserAgent',
    track => 1,
    override => [
        get => sub { return HTTP::Response->new(401, 'ERROR', undef, '{}') },
    ],
);

subtest 'Error response' => sub {
    $opt{key} = '-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgYirTZSx+5O8Y6tlG
cka6W6btJiocdrdolfcukSoTEk+hRANCAAQkvPNu7Pa1GcsWU4v7ptNfqCJVq8Cx
zo0MUVPQgwJ3aJtNM1QMOQUayCrRwfklg+D/rFSUwEUqtZh7fJDiFqz3
-----END PRIVATE KEY-----';
    ok(lives {$asc = Apple::AppStoreConnect->new(%opt)}, "New object");
    ok(lives {$asc->jwt}, "JWT created correctly");
    like(dies { $asc->get(url => 'test') }, qr/401 ERROR/, "LWP Error response");  
};

done_testing;
