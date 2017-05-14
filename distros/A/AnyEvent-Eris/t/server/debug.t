use t::lib::Eris::Test tests => 4;

my ( $server, $cv ) = new_server;
my ( $addr, $port ) = @{$server}{qw<ListenAddress ListenPort>};
my $SID = '';
my $c = tcp_connect $addr, $port, sub {
    my ($fh) = @_
        or BAIL_OUT("Connect failed: $!");

    my $hdl; $hdl = AnyEvent::Handle->new(
        fh       => $fh,
        on_error => sub { AE::log error => $_[2]; $_[0]->destroy },
        on_eof   => sub { $hdl->destroy; AE::log info => 'Done.' },
        on_read  => sub {
            my ($hdl) = @_;
            chomp( my $line = delete $hdl->{'rbuf'} );

            if ( $line =~ /^EHLO Streamer \(KERNEL: \d+:(.+)\)/ ) {
                $SID = $1;
                $hdl->push_write("debug\n");

                is(
                    $server->clients->{$SID}{'debug'},
                    undef,
                    'No debugging for client yet',
                );
            } elsif ( $line =~ /^Debugging enabled/ ) {
                is(
                    $server->clients->{$SID}{'debug'},
                    1,
                    'Client has debugging enabled',
                );

                $hdl->push_write("nodebug\n");
            } elsif ( $line =~ /^Debugging disabled/ ) {
                is(
                    $server->clients->{$SID}{'debug'},
                    undef,
                    'Client does not have debugging enabled',
                );

                $cv->send('OK');
            } else {
                $cv->send("Unknown response: $line");
            }
        },
    );
};

is( $server->run($cv), 'OK', 'Server closed' );
