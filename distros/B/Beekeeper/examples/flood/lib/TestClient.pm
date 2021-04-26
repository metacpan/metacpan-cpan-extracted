package TestClient;

use strict;
use warnings;

use Beekeeper::Client;


sub echo {
    my ($self, params) = @_;

    my $client = Beekeeper::Client->instance;

    my $resp = $client->do_job(
        method => 'myapp.test.echo',
        params => { string => $str },
    );

    return $resp->result;
}

1;
