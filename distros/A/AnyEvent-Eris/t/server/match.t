use t::lib::Eris::Test tests => 7;

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
                $hdl->push_write("match hello, world\n");

                is(
                    scalar keys %{ $server->{'words'} },
                    0,
                    'No registered words',
                );

                is(
                    $server->clients->{$SID}{'match'},
                    undef,
                    'Client not registered for matches',
                );
            } elsif ( $line =~ /^Receiving messages matching : / ) {
                is_deeply(
                    $server->clients->{$SID}{'match'},
                    { hello => 1, world => 1 },
                    'Client registered for two word matches',
                );

                is_deeply(
                    $server->{'words'},
                    { hello => 1, world => 1 },
                    'Two words registered',
                );

                $hdl->push_write("nomatch hello, world\n");
            } elsif ( $line =~ /^No longer receiving messages matching : / ) {
                is_deeply(
                    $server->clients->{$SID}{'match'},
                    {},
                    'Client not registered for matched words anymore',
                );

                is_deeply(
                    $server->{'words'},
                    {},
                    'No more words registered',
                );

                $cv->send('OK');
            } else {
                $cv->send("Unknown response: $line");
            }
        },
    );
};

is( $server->run($cv), 'OK', 'Server closed' );
