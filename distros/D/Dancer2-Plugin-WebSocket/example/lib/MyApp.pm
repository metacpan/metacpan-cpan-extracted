package MyApp;

use Dancer2;

use Dancer2::Plugin::WebSocket;

websocket_on_open sub {
    my( $conn, $env ) = @_;
    warn "# opening $conn\n";
};


websocket_on_close sub {
    my( $conn ) = @_;
    warn "# closing $conn\n";
};

websocket_on_error sub {
    my ( $env ) = @_;
    warn "Something went bonker";
};

websocket_on_message sub {
    my( $conn, $message ) = @_;

    if ( $message->{hello} ) {
        $message->{hello} = 'browser!';
        $conn->send( $message );
    }

    if( my $browser = $message->{browser} ) {
        $conn->add_channels( $browser );
    }

    if ( my $channel = $message->{emit} ) {
        $conn->to($channel)->send({ emitting => $channel });
    }

    if ( my $channel = $message->{broadcast} ) {
        $conn->to($channel)->broadcast({ broadcasting => $channel });
    }
};

get '/' => sub {
    my $ws_url = websocket_url;
    return <<"END";
<html>
	<head>
		<script>
			var urlMySocket = "$ws_url";

            var mySocket = new WebSocket(urlMySocket);
            mySocket.sendJSON = function(message) { return this.send(JSON.stringify(message)) };

            mySocket.onmessage = function (evt) {
                console.log( "Got message ", evt.data );
//                mySocket.close();
            };

            mySocket.onopen = function(evt) {
                console.log("opening");
                let isChrome = /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor);
                mySocket.sendJSON({
                    browser: isChrome ? 'chrome' : 'firefox'
                })
                setTimeout( function() { mySocket.sendJSON({"hello": "Dancer"}); }, 2000 );
            };

			</script>
		</head>
	<body>
        <h1>WebSocket client</h1>
    </body>
</html>
END
};

get '/say_hi' => sub {
    $_->send([ "Hello!" ]) for websocket_connections;
};

1;
