#!/usr/bin/env perl
use strict;
use warnings;
use Mojolicious::Lite;
use Mojo::IOLoop;
use Async::Selector;
use constant {
    UPDATE_RATE => 1,
    RESOURCE_LENGTH => 1024,
};

sub randomData {
    return pack("C*", map { int(rand(0x7E - 0x21)) + 0x21 } 1..RESOURCE_LENGTH);
}

my $selector;

{
    ################## Resource part: Setup resource and selector
    $selector = Async::Selector->new();
    my $resource = randomData;
    my $sequence = 1;

    $selector->register(res => sub {
        my ($given_sequence) = @_;
        return ($sequence > $given_sequence)
            ? {resource => $resource, sequence => $sequence} : undef;
    });

    ## Update the resource periodically
    Mojo::IOLoop->recurring(1/UPDATE_RATE, sub {
        $resource = randomData;
        $sequence++;
        $selector->trigger('res');
    });
}

{
    ################## HTTP part: Setup HTTP frontend
    get '/' => sub {
        my $self = shift;
        $self->render('index');
    };

    get '/comet' => sub {
        my $self = shift;
        my $client_sequence = $self->param('seq');
        my $watcher = $selector->watch(res => $client_sequence, sub {
            my ($w, %resources) = @_;
            my ($resource, $sequence)
                = ($resources{res}{resource}, $resources{res}{sequence});
            $self->render_data("$sequence $resource");
            $w->cancel();
        });
        $self->on(finish => sub {
            $watcher->cancel();
        });
    };

    websocket '/websocket' => sub {
        my $self = shift;
        Mojo::IOLoop->stream($self->tx->connection)->timeout(0);
        my $watcher = $selector->watch(res => 0, sub {
            my ($w, %resources) = @_;
            my ($resource, $sequence)
                = ($resources{res}{resource}, $resources{res}{sequence});
            $self->send("$sequence $resource");
        });
        $self->on(finish => sub {
            $watcher->cancel();
        });
    };

    app->start;
}


__DATA__
@@ index.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Async::Selector test</title>
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
    <script><!--
$(function() {
    var RECONNECT_BACKOFF = 2000;
    // Setup Comet (long-polling)
    var my_sequence = 0;
    var sendCometRequest = function() {
        $.get("<%= url_for('comet') %>?seq=" + my_sequence)
            .done(function(data) {
                data = data.split(" ");
                my_sequence = data[0];
                $('#comet_sequence').text(data[0]);
                $('#comet_resource').text(data[1]);
                sendCometRequest();
            })
            .fail(function() {
                setTimeout(sendCometRequest, RECONNECT_BACKOFF);
            });
    };
    sendCometRequest();

    // Setup WebSocket
    var connectWebsocket = function() {
        var ws = new WebSocket("<%= url_for('websocket')->to_abs %>");
        ws.onmessage = function(event) {
            var data = event.data.split(" ");
            $('#websocket_sequence').text(data[0]);
            $('#websocket_resource').text(data[1]);
        };
        ws.onclose = function() {
            setTimeout(connectWebsocket, RECONNECT_BACKOFF);
        };
    };
    connectWebsocket();
});
//--></script>
  </head>
  <body>
    <div>
      <h1>Comet (long-polling)</h1>
      <p>Sequence number: <span id="comet_sequence"></span></p>
      <textarea id="comet_resource" rows="10" cols="100" readonly="true"></textarea>
    </div>
    <div>
      <h1>WebSocket</h1>
      <p>Sequence number: <span id="websocket_sequence"></span></p>
      <textarea id="websocket_resource" rows="10" cols="100" readonly="true"></textarea>
    </div>
  </body>
</html>
