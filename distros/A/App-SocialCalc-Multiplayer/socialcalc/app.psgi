#!/usr/bin/env perl
use strict;
use warnings;
use Plack::Request;
use Plack::Builder;
use Plack::App::File;
use Plack::App::Cascade;
use File::Basename;
BEGIN { chdir dirname(__FILE__) };
use lib dirname(__FILE__)."/third-party/lib";

my $html = do {
    local $/;
    open my $fh, '<', 'index.mt';
    <$fh>;
};

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);

    if ($req->path eq '/') {
        $res->content_type('text/html; charset=utf-8');
        $res->content($html);
    } else {
        $res->code(404);
    }

    $res->finalize;
};

use PocketIO;
my $path_to_socket_io = "./third-party/Socket.IO-node";

builder {
    mount '/socket.io/socket.io.js' => Plack::App::File->new(
        file => "$path_to_socket_io/support/socket.io-client/socket.io.js"
    );
    mount '/socket.io/lib' => Plack::App::File->new(
        root => "$path_to_socket_io/support/socket.io-client/lib"
    );
    mount '/socket.io' => PocketIO->new(
        handler => sub {
            my $self = shift;
            $self->on_message(sub {
                my $self = shift;
                my ($message) = @_;
                $self->send_broadcast($message); # {message => [$self->id, $message]});
            });
        }
    );
    mount '/' => 
        Plack::App::Cascade->new
                ( apps => [ $app,
                            Plack::App::File->new( root => '.' )->to_app,
                        ] );
};
