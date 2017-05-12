use 5.006;
use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use MongoDB 0.45;
use MongoDBx::Queue;

my $client = eval { MongoDB::MongoClient->new; };
plan skip_all => "No MongoDB on localhost" unless $client;

my $db_name = 'test_dancer_plugin_queue_mongodb';

# make sure we clean up from prior runs
my $db   = $client->get_database($db_name);
my $coll = $db->get_collection('queue');
$coll->drop;

{

    use Dancer;
    use Dancer::Plugin::Queue;

    set plugins => {
        Queue => {
            default => {
                class   => 'MongoDB',
                options => { db_name => $db_name },
            },
        }
    };

    get '/add' => sub {
        queue->add_msg( params->{msg} );
        my ( $msg, $body ) = queue->get_msg;
        queue->remove_msg($msg);
        return $body;
        return "Hello World";
    };

}

use Dancer::Test;

route_exists [ GET => '/add' ], 'GET /add handled';

response_content_like [ GET => '/add?msg=Hello%20World' ], qr/Hello World/i,
  "sent and received message";

done_testing;
