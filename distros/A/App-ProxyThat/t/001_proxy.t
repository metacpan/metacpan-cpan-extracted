#! /usr/bin/env perl
use warnings;
use strict;

use Plack::Runner;
use App::ProxyThat;
use HTTP::Tiny;

use Test::More tests => 1;

my $CONTENT    = "Hello world!\n";
my $APP_PORT   = 5004;
my $PROXY_PORT = 5006;

my $f1 = fork;
if ($f1) {
    sleep 1;
    my $response = HTTP::Tiny->new->get("http://localhost:$PROXY_PORT");
    is $response->{content}, $CONTENT;
    sleep 2;
    kill TERM => $f1;

} else {
    die "Can't fork!\n" unless defined $f1;

    my $f2 = fork;
    if ($f2) {
        local $SIG{ALRM} = sub { kill TERM => $f2 };
        alarm 2;
        local @ARGV = ( "http://localhost:$APP_PORT", '--port' => $PROXY_PORT );
        App::ProxyThat->new->run;

    } else {
        die "Can't fork!\n" unless defined $f2;

        my $runner = Plack::Runner->new;
        $runner->parse_options( '--port'   => $APP_PORT,
                                '--server' => 'Starman' );
        $runner->run(sub { [200, [], [$CONTENT]] });
        exit;
    }
    exit;
}
