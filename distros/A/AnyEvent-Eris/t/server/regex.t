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

            my $regex = $server->{'regex'};
            if ( $line =~ /^EHLO/ ) {
                ($SID) = $line =~ /\(KERNEL:\s\d+:([a-fA-F0-9]+)\)/;

                is(
                    $server->clients->{$SID}{'regex'},
                    undef,
                    'Client not registered for regex',
                );

                $hdl->push_write("regex .+\n");
            } elsif ( $line =~ /^Receiving messages matching regex : / ) {
                is_deeply(
                    $server->clients->{$SID}{'regex'},
                    { qr{.+} => 1 },
                    'Client registered for regex',
                );

                $hdl->push_write("noregex\n");
            } elsif ( $line =~ /^No longer receiving regex-based matches/ ) {
                is_deeply(
                    $server->clients->{$SID}{'regex'},
                    undef,
                    'Client no longer registered for regex',
                );


                $cv->send('OK');
            } else {
                $cv->send("Unknown response: $line");
            }
        },
    );
};

is( $server->run($cv), 'OK', 'Server closed' );
