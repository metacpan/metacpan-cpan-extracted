use strict;
use warnings;
use AnyEvent::Plackup;

my $server = plackup;

print "Server started at $server/\n";

while (my $req = $server->recv) {
    $req->respond(sub {
        my $respond = shift;
        my $writer = $respond->([ 200, [ 'Content-Type' => 'text/plain' ] ]);
        my $w; $w = AE::timer 1, 1, sub {
            $writer->write(localtime . "\n");
            scalar $w;
        };
    });
}
