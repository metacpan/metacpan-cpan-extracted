
use strict;
use warnings;

use Test2::V0;

use Authen::SASL qw(Perl);
use Authen::SCRAM::Client;


my $scram = Authen::SCRAM::Client->new(
    password => 'abc123',
    username => 'john',
    );

my ($stored_key, $client_key, $server_key) =
    $scram->computed_keys( '0123456789abcdefghijklm', 4096 );

my $sasl_client = Authen::SASL->new(
    mechanism => 'SCRAM-SHA-1',
    callback  => {
        pass => 'abc123',
        user => 'john',
    }
);

my $client = $sasl_client->client_new( 'service', 'host', 'security' );

my $sasl_server = Authen::SASL->new(
    mechanism => 'SCRAM-SHA-1',
    callback => {
        getsecret => sub {
            my $user = shift;
            ok $user eq 'john';
            return ('0123456789abcdefghijklm',
                    $stored_key,
                    $server_key,
                    4096);
        },
    }
);
my $server = $sasl_server->server_new( 'service', 'host', {} );

$client->client_step(
    $server->server_step(
        $client->client_step(
            $server->server_start(
                $client->client_start()
            )
        )
    )
);
ok( $client->is_success, 'Client authenticated successfully' );
ok( $server->is_success, 'Server authenticated successfully' );



done_testing;
