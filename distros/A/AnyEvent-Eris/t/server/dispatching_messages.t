use t::lib::Eris::Test tests => 4;

my ( $registered_fullfeed, $msg_arrived );
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

            if ( $line =~ /^EHLO/ ) {
                ($SID) = $line =~ /\(KERNEL:\s\d+:([a-fA-F0-9]+)\)/;
                $hdl->push_write("fullfeed\n");
            } elsif ( $line =~ /^Full feed enabled/ ) {
                is(
                    $server->clients->{$SID}{'full'},
                    1,
                    'Full feed registered for client',
                );
                $registered_fullfeed++;
            } else {
                $msg_arrived++;
                $cv->send('OK');
            }
        },
    );
};

my $timer; $timer = AE::timer 0.05, 0, sub {
    undef $timer;
    $server->dispatch_message('Hello world');
};

is( $server->run($cv), 'OK', 'Server closed' );
is( $registered_fullfeed, 1, 'Fullfeed registered' );
is( $msg_arrived, 1, 'Message arrived (msg dispatching)' );
