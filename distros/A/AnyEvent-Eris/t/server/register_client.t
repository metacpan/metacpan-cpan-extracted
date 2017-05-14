use t::lib::Eris::Test tests => 6;

my ( $server, $cv ) = new_server;
my ( $addr, $port ) = @{$server}{qw<ListenAddress ListenPort>};
my $c = tcp_connect $addr, $port, sub {
    my ($fh) = @_
        or BAIL_OUT("Connect failed: $!");

    my $hdl; $hdl = AnyEvent::Handle->new(
        fh       => $fh,
        on_error => sub { AE::log error => $_[2]; $_[0]->destroy },
        on_eof   => sub { $hdl->destroy; AE::log info => 'Done.' },
        on_read  => sub {
            my $hdl = shift;

            chomp( my $line = $hdl->rbuf );

            my $KID = $$;
            $line =~ /^EHLO Streamer \(KERNEL: $KID:(.+)\)$/;
            my $SID = $1 || '(undef)';

            ok( $KID && $SID, "Got a nice hello (KID: $KID, SID: $SID)" );
            $cv->send('OK');
        },
    );
};

is( $server->run($cv), 'OK', 'Server closed' );

my %clients = %{ $server->{'clients'} || {} };
is( scalar keys %clients, 1, 'One client registered' );

my $key = $clients{ (keys %clients)[0] };

can_ok( $server, 'clients' );
is(
    scalar keys %{ $server->clients },
    1,
    'Also one client registered through attribute',
);

is(
    $clients{$key},
    $server->clients->{$key},
    'Same attribute',
);
