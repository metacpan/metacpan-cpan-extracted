package MyApp;

use Dancer2;

use Dancer2::Plugin::WebSocket;
use Dancer2::Plugin::Auth::Extensible;

=begin comment
# use this block if you want to check login by IP address and user-agent.

my $login_conn;

hook before => sub {
    $login_conn->{'ip'} = request->{'env'}->{'REMOTE_ADDR'} eq '127.0.0.1' ? request->{'env'}->{'HTTP_X_REAL_IP'} : request->{'env'}->{'REMOTE_ADDR'};
    $login_conn->{'user-agent'} = request->{'env'}->{'HTTP_USER_AGENT'};
    $login_conn->{'login'} = logged_in_user ? 1 : 0;
};

websocket_on_login sub {
    my( $conn, $env ) = @_;

    my $ip = $env->{'REMOTE_ADDR'} eq '127.0.0.1' ? $env->{'HTTP_X_REAL_IP'} : $env->{'REMOTE_ADDR'};
    if (($login_conn->{'login'}) and ($login_conn->{'ip'} eq $ip) and ($login_conn->{'user-agent'} eq $env->{'HTTP_USER_AGENT'})) {
        return 1;
    } else {
        warn "require login";
        return 0;
    }
};

#=end comment

=cut

#=begin comment
# use this block if you want to check login by cookie or by token.

my $login_conn;
my $cookie_name = 'example.session';

hook before => sub {
    if (defined cookies->{$cookie_name}) {
        $login_conn->{'cookie_id'} = cookies->{$cookie_name}->value;
    }
    $login_conn->{'login'} = logged_in_user ? 1 : 0;
};

websocket_on_login sub {
    my( $conn, $env ) = @_;

    my $token = '/CqPoYBz1lmhjNHnzM9AzOYH9RvhpG2Xcg1vqfN8yKCY';
    my ($cookie_id) = ($env->{'HTTP_COOKIE'} =~ /$cookie_name=(.*);?/g);
    if (($token eq $env->{'PATH_INFO'}) or (($login_conn->{'login'}) and ($login_conn->{'cookie_id'} eq $cookie_id))) {
        return 1;
    } else {
        warn "require login";
        return 0;
    }
};

#=end comment

#=cut

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
    my $is_logged = $login_conn->{'login'};
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
                if ("$is_logged" == true) {
                    console.log("opening");
                    let isChrome = /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor);
                    mySocket.sendJSON({
                        browser: isChrome ? 'chrome' : 'firefox'
                    })
                    setTimeout( function() { mySocket.sendJSON({"hello": "Dancer"}); }, 2000 );
                } else {
                    console.log( "require login");
                }
            };

			</script>
		</head>
	<body>
        <h1>WebSocket client</h1>
    </body>
</html>
END
};

get '/say_hi' => require_login sub {
    $_->send([ "Hello!" ]) for websocket_connections;
};

1;
