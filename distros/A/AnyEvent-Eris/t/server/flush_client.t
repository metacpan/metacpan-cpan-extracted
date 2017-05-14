use t::lib::Eris::Test tests => 3;

my $buffer_said_hi;
my $buffer_msg      = 'Buffer says hi!';
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
            } elsif ( $line eq $buffer_msg ) {
                $buffer_said_hi++;
                $cv->send('OK');
            }
        },
    );
};

my $timer; $timer = AE::timer 0.2, 0, sub {
    undef $timer;
    push @{ $server->{'buffers'}{$SID} }, $buffer_msg;
};

is( $server->run($cv), 'OK', 'Server closed' );
ok( $buffer_said_hi, 'Buffer was flushed (flush_client)' );
is_deeply( $server->{'buffers'}{$SID}, [], 'Buffers were emptied' );
