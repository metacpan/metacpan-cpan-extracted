use strict;
use warnings;
use Test::More tests => 4;
use Test::SharedFork;
use AnyEvent::Plackup;
use LWP::Simple qw($ua);

my $server = plackup(host => '127.0.0.1');

if (my $pid = fork()) {
    my $req = $server->recv;
    is $req->parameters->{foo}, 'bar';
    is $req->uri->path, '/test';
    $req->respond([ 200, [], [ 'AnyEvent::Plackup' ] ]);
    waitpid $pid, 0;
} else {
    my $res = $ua->get("$server/test?foo=bar");
    is $res->code, 200;
    is $res->content, 'AnyEvent::Plackup';
}

done_testing;
