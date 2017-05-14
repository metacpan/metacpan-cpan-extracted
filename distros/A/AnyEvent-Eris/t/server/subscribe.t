use t::lib::Eris::Test tests => 6;

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
                    $server->clients->{$SID}{'subscription'},
                    undef,
                    'Client not subscribed',
                );

                $hdl->push_write(
                    "subscribe prog1,prog2, prog3, prog4,prog5\n"
                );
            } elsif ( $line =~ /^Subscribed/ ) {
                is(
                    $line,
                    'Subscribed to : prog1,prog2,prog3,prog4,prog5',
                    'Subscribed to all the right programs',
                );

                is_deeply(
                    $server->clients->{$SID}{'subscription'},
                    {
                        prog1 => 1, prog2 => 1, prog3 => 1,
                        prog4 => 1, prog5 => 1,
                    },
                    'Client not subscribed',
                );

                $hdl->push_write(
                    "unsubscribe prog1,prog2, prog3, prog4,prog5\n"
                );
            } else {
                $cv->send('OK');
            }
        },
    );
};

is( $server->run($cv), 'OK', 'Server closed' );

is(
    $server->clients->{$SID}{'subscription'},
    undef,
    'Subscribers cleared',
);

is_deeply( $server->{'programs'},    {}, 'Programs cleared'    );
