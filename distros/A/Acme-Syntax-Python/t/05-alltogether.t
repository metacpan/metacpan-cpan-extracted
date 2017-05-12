use lib './lib';
use Acme::Syntax::Python;
import Test::More tests => 5;

class Client:
    def __init__($client_id):
        $self->{_client_id} = $client_id;
    def set_client_id($self, $client_id):
        $self->{_client_id} = $client_id;
    def client_id($self):
        return $self->{_client_id};

my $client = Client->new(1);
ok($client->client_id == 1, "Client ID is 1");
check($client);
$client->set_client_id(2);
ok($client->client_id == 2, "Client ID is 2");
check($client);
$client->set_client_id(3);
check($client);

def check($client):
    if ($client->client_id == 1):
        ok(1, "Client id was 1 in if check");
    elif ($client->client_id == 2):
        ok(1, "Client id was 2 in if check");
    else:
        ok(1, "Client id was not 1 or 2");

