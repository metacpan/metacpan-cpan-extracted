package MyApp;

use Dancer2;

use Dancer2::Plugin::WebSocket;

websocket_on_open sub {
    my( $conn, $env ) = @_;
};


websocket_on_close sub {
    my( $conn ) = @_;
};

websocket_on_error sub {
    my ( $env ) = @_;
};

websocket_on_message sub {
    my( $conn, $message ) = @_;
    $message->{hello} = 'browser!';
    warn "Got one!";
    $conn->send( $message );
};

get '/' => sub {
    my $ws_url = websocket_url;
    return <<"END";
<html>
	<head>
		<script>
			var urlMySocket = "$ws_url";

            var mySocket = new WebSocket(urlMySocket);

            mySocket.onmessage = function (evt) {
                console.log( "Got message " + evt.data );
                mySocket.close();
            };

            mySocket.onopen = function(evt) {
                console.log("opening");
                setTimeout( function() { mySocket.send('{"hello": "Dancer"}'); }, 2000 );
            };

			</script>
		</head>
	<body>
        <h1>WebSocket client</h1>
    </body>
</html>
END
};

true;
