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

            if ( $line =~ /^EHLO/ ) {
                ($SID) = $line =~ /\(KERNEL:\s\d+:([a-fA-F0-9]+)\)/;

                is(
                    $server->clients->{$SID}{'full'},
                    undef,
                    'Client not registered for fullfeed',
                );

                $hdl->push_write("fullfeed\n");
            } elsif ( $line =~ /^Full feed enabled/ ) {
                is(
                    $server->clients->{$SID}{'full'},
                    1,
                    'Client registered for fullfeed',
                );

                $hdl->push_write("nofullfeed\n");
            } elsif ( $line =~ /^Full feed disabled/ ) {
                is(
                    $server->clients->{$SID}{'full'},
                    undef,
                    'Client not registered for fullfeed anymore',
                );

                $cv->send('OK');
            } else {
                $cv->send("Unknown response: $line");
            }
        },
    );
};

is( $server->run($cv), 'OK', 'Server closed' );
