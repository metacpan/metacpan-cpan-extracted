use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Avatica::Client;
use Mock 'mock_method';

my $client_err = Avatica::Client->new(url => 'http://127.0.0.1:12345');

my $connection_id = '12345';
my ($no_err, $res) = $client_err->open_connection($connection_id);
is $no_err, 0, 'wrong url: check error';
like $res->{message}, qr/Connection refused/i, 'wrong url: check error message';

my $url = $ENV{TEST_ONLINE} || 'http://127.0.0.1:12345';

# mock HTTP::Tiny if offline test
mock_client() unless $ENV{TEST_ONLINE};

my $client = Avatica::Client->new(url => $url);

($no_err, $res) = $client->create_statement('unknown connection id');
is $no_err, 0, 'wrong connection id: check error';

$connection_id = int(rand(1000)) . $$;
($no_err, $res) = $client->open_connection($connection_id);
is $no_err, 1, 'open connection';

($no_err, $res) = $client->prepare_and_execute($connection_id, 1000 + int(rand(100000)), 'UPSERT INTO X(id) VALUES (1)');
is $no_err, 0, 'wrong statement id: check error';
is $res->{message}, 'missing statement id', 'wrong statement id: check message';

($no_err, $res) = $client->close_connection($connection_id);
is $no_err, 1, 'close connection';

done_testing;

sub mock_client {
    my $mock_index = 0;
    mock_method 'HTTP::Tiny::post', sub {
        ++$mock_index;

        my $results = +{
            1 => +{
                success => 0,
                status => 500,
                content => do {
                    my $error = Avatica::Client::Protocol::ErrorResponse->new;
                    $error->set_error_message('some error');
                    my $msg = Avatica::Client::Protocol::ErrorResponse->encode($error);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$ErrorResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            2 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::OpenConnectionResponse->new;
                    my $msg = Avatica::Client::Protocol::OpenConnectionResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$OpenConnectionResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            3 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::ExecuteResponse->new;
                    $res->set_missing_statement(1);
                    my $msg = Avatica::Client::Protocol::ExecuteResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$ExecuteResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            },
            4 => +{
                success => 1,
                status => 200,
                content => do {
                    my $res = Avatica::Client::Protocol::CloseConnectionResponse->new;
                    my $msg = Avatica::Client::Protocol::CloseConnectionResponse->encode($res);
                    my $wrapped = Avatica::Client::Protocol::WireMessage->new;
                    $wrapped->set_name('org.apache.calcite.avatica.proto.Response$CloseConnectionResponse');
                    $wrapped->set_wrapped_message($msg);
                    Avatica::Client::Protocol::WireMessage->encode($wrapped);
                }
            }
        };
        return $results->{$mock_index};
    };
}
