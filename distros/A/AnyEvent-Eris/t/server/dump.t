use t::lib::Eris::Test tests => 2;

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
                $hdl->push_write("dump streams\n");
            } else {
                is(
                    $line,
                    "subscription -> \nmatch -> \ndebug -> \n" .
                    "full -> $SID\n" .
                    "regex -> ",
                    'Correct dump output'
                );

                $cv->send('OK');
            }
        },
    );
};

is( $server->run($cv), 'OK', 'Server closed' );
