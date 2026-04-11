package App::aep;

# ABSTRACT: Allows you to run a command within a container and control its start up

# Core
use warnings;
use strict;
use utf8;
use v5.28;

# Core - Modules
use Socket qw(AF_INET PF_UNIX SOCK_STREAM);
use IO::Socket::INET;

# Core - Experimental (stable)
use experimental 'signatures';

# Debug
use Data::Dumper;

# External
use POE qw(
    Session::PlainCall
    Wheel::SocketFactory
    Wheel::ReadWrite
    Wheel::Run
    Filter::Stackable
    Filter::Line
    Filter::JSONMaybeXS
);
use Try::Tiny;

# Ensure unbuffered output for container environments
STDOUT->autoflush(1);
STDERR->autoflush(1);

# Version of this software
our $VERSION = '0.013';

# create a new blessed object, we will carry any passed arguments forward.
sub new ( $class, @args )
{
    my $self = bless { '_passed_args' => $args[ 0 ]->{ '_passed_args' }, }, $class;
    return $self;
}

# POE::Kernel's _start, in this case it also tells the kernel to capture signals
sub _start ( $self, @args )
{
    poe->kernel->sig( INT  => 'sig_int' );
    poe->kernel->sig( TERM => 'sig_term' );
    poe->kernel->sig( CHLD => 'sig_chld' );
    poe->kernel->sig( USR  => 'sig_usr' );

    # Store the main session ID so sub-sessions can post events back to us
    poe->heap->{ '_' }->{ 'main_session' } = poe->session->ID;

    my $debug = poe->heap->{ '_' }->{ 'debug' };
    $debug->( 'STDERR', __LINE__, 'Signals(INT,TERM,CHLD,USR) trapped.' );

    # What command are we meant to be running?
    my $opt = poe->heap->{ '_' }->{ 'opt' };

    # Initialize lock server order tracking
    if ( $opt->lock_server )
    {
        my $order_str = $opt->lock_server_order || '';
        my @raw_steps = grep { $_ ne '' } split( /,/, $order_str );

        # Each step may contain || for parallel groups: "redis1||redis2" becomes ['redis1', 'redis2']
        my @order;
        for my $step_str ( @raw_steps )
        {
            my @ids = split( /\|\|/, $step_str );
            push @order, \@ids;
        }

        poe->heap->{ 'lock' }->{ 'order' }          = \@order;
        poe->heap->{ 'lock' }->{ 'order_idx' }      = 0;
        poe->heap->{ 'lock' }->{ 'order_orig' }     = [ map { [ @{ $_ } ] } @order ];
        poe->heap->{ 'lock' }->{ 'waiting' }        = {};
        poe->heap->{ 'lock' }->{ 'unknown_queue' }  = [];
        poe->heap->{ 'lock' }->{ 'step_completed' } = 0;
    }

    # Initialize command state
    poe->heap->{ 'command' }                    = {};
    poe->heap->{ 'command' }->{ 'restart_count' } = 0;
    poe->heap->{ 'command' }->{ 'running' }     = 0;
    poe->heap->{ 'command' }->{ 'trigger_ok' }  = 0;

    if ( $opt->docker_health_check || $opt->lock_client )
    {
        poe->heap->{ 'services' }->{ 'afunixcli' } = POE::Session::PlainCall->create(
            'object_states' => [
                App::aep->new() => {
                    '_start'                        => 'afunixcli_client_start',
                    'afunixcli_server_connected'    => 'afunixcli_server_connected',
                    'afunixcli_client_error'        => 'afunixcli_client_error',
                    'afunixcli_server_input'        => 'afunixcli_server_input',
                    'afunixcli_server_error'        => 'afunixcli_server_error',
                    'afunixcli_client_send'         => 'afunixcli_client_send',
                    'afunixcli_client_reconnect'    => 'afunixcli_client_reconnect',
                },
            ],
            'heap' => poe->heap,
        );
    }
    elsif ( $opt->lock_server )
    {
        poe->heap->{ 'services' }->{ 'afunixsrv' } = POE::Session::PlainCall->create(
            'object_states' => [
                App::aep->new() => {
                    '_start'                     => 'afunixsrv_server_start',
                    'afunixsrv_client_connected' => 'afunixsrv_client_connected',
                    'afunixsrv_server_error'     => 'afunixsrv_server_error',
                    'afunixsrv_client_input'     => 'afunixsrv_client_input',
                    'afunixsrv_client_error'     => 'afunixsrv_client_error',
                    'afunixsrv_server_send'      => 'afunixsrv_server_send'
                },
            ],
            'heap' => poe->heap,
        );
    }

    poe->kernel->yield( 'scheduler' );

    return;
}

# As server
sub afunixsrv_server_start
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    my $socket_path = poe->heap->{ '_' }->{ 'config' }->{ 'AEP_SOCKETPATH' };
    poe->heap->{ 'afunixsrv' }->{ 'socket_path' } = $socket_path;

    if ( -e $socket_path )
    {
        unlink $socket_path;
    }

    # Unix domain socket listener
    poe->heap->{ 'afunixsrv' }->{ 'server' } = POE::Wheel::SocketFactory->new(
        'SocketDomain' => PF_UNIX,
        'BindAddress'  => $socket_path,
        'SuccessEvent' => 'afunixsrv_client_connected',
        'FailureEvent' => 'afunixsrv_server_error',
    );

    # TCP socket listener
    my $tcp_host = $opt->lock_server_host || '0.0.0.0';
    my $tcp_port = $opt->lock_server_port || 60000;

    poe->heap->{ 'afunixsrv' }->{ 'tcp_server' } = POE::Wheel::SocketFactory->new(
        'SocketDomain' => AF_INET,
        'BindAddress'  => $tcp_host,
        'BindPort'     => $tcp_port,
        'Reuse'        => 'yes',
        'SuccessEvent' => 'afunixsrv_client_connected',
        'FailureEvent' => 'afunixsrv_server_error',
    );

    $debug->( 'STDERR', __LINE__, "Lock server listening on unix:$socket_path and tcp:$tcp_host:$tcp_port" );

    return;
}

# As client
sub afunixcli_client_start
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    my $transport = $opt->lock_transport || 'auto';

    my $socket_path = poe->heap->{ '_' }->{ 'config' }->{ 'AEP_SOCKETPATH' };
    poe->heap->{ 'afunixcli' }->{ 'socket_path' } = $socket_path;

    if ( $transport eq 'tcp' || $transport eq 'auto' )
    {
        # Try TCP first (or only TCP if transport is 'tcp')
        my $tcp_host = $opt->lock_client_host || 'aep-master';
        my $tcp_port = $opt->lock_client_port || 60000;

        $debug->( 'STDERR', __LINE__, "Lock client connecting via TCP to $tcp_host:$tcp_port (transport=$transport)." );

        poe->heap->{ 'afunixcli' }->{ 'transport_attempted' } = 'tcp';

        poe->heap->{ 'afunixcli' }->{ 'client' } = POE::Wheel::SocketFactory->new(
            'SocketDomain'  => AF_INET,
            'RemoteAddress' => $tcp_host,
            'RemotePort'    => $tcp_port,
            'SuccessEvent'  => 'afunixcli_server_connected',
            'FailureEvent'  => 'afunixcli_client_error',
        );
    }
    else
    {
        # Unix socket only
        if ( !-e $socket_path )
        {
            $debug->( 'STDERR', __LINE__, "Control socket '$socket_path' does not exist, refusing to continue." );
            die;
        }

        $debug->( 'STDERR', __LINE__, "Lock client connecting via Unix socket $socket_path." );

        poe->heap->{ 'afunixcli' }->{ 'transport_attempted' } = 'unix';

        poe->heap->{ 'afunixcli' }->{ 'client' } = POE::Wheel::SocketFactory->new(
            'SocketDomain'  => PF_UNIX,
            'RemoteAddress' => $socket_path,
            'SuccessEvent'  => 'afunixcli_server_connected',
            'FailureEvent'  => 'afunixcli_client_error',
        );
    }

    return;
}

# As server
sub afunixsrv_server_error ( $self, $syscall, $errno, $error, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    if ( !$errno )
    {
        $error = "Normal disconnection.";
    }

    $debug->( 'STDERR', __LINE__, "Server AA socket encountered $syscall error $errno: $error", 'error' );

    delete poe->heap->{ 'services' }->{ 'afunixsrv' };
    return;
}

# As client
sub afunixcli_client_error ( $self, $syscall, $errno, $error, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    if ( !$errno )
    {
        $error = "Normal disconnection.";
    }

    $debug->( 'STDERR', __LINE__, "Client socket encountered $syscall error $errno: $error", 'error' );

    # If running a docker health check and connection failed, exit unhealthy
    if ( $opt->docker_health_check )
    {
        $debug->( 'STDERR', __LINE__, "Health check connection failed, exiting unhealthy.", 'error' );
        poe->heap->{ '_' }->{ 'set_exit' }->( '1', 'health-check-failed' );
        poe->kernel->stop();
        return;
    }

    # Auto transport fallback: if TCP was attempted and failed, try Unix socket
    my $transport = $opt->lock_transport || 'auto';
    my $attempted = poe->heap->{ 'afunixcli' }->{ 'transport_attempted' } || '';

    if ( $transport eq 'auto' && $attempted eq 'tcp' )
    {
        my $socket_path = poe->heap->{ 'afunixcli' }->{ 'socket_path' };

        if ( $socket_path && -e $socket_path )
        {
            $debug->( 'STDERR', __LINE__, "TCP connection failed, falling back to Unix socket $socket_path." );

            poe->heap->{ 'afunixcli' }->{ 'transport_attempted' } = 'unix';

            poe->heap->{ 'afunixcli' }->{ 'client' } = POE::Wheel::SocketFactory->new(
                'SocketDomain'  => PF_UNIX,
                'RemoteAddress' => $socket_path,
                'SuccessEvent'  => 'afunixcli_server_connected',
                'FailureEvent'  => 'afunixcli_client_error',
            );
            return;
        }
        else
        {
            $debug->( 'STDERR', __LINE__, "TCP failed and Unix socket '$socket_path' does not exist." );
        }
    }

    delete poe->heap->{ 'services' }->{ 'afunixcli' };

    # Check if retries are disabled
    if ( $opt->lock_client_noretry )
    {
        $debug->( 'STDERR', __LINE__, "lock-client-noretry is set, exiting.", 'error' );
        poe->heap->{ '_' }->{ 'set_exit' }->( '1', 'lock-client-noretry' );
        poe->kernel->stop();
        return;
    }

    # Increment retry counter
    poe->heap->{ 'afunixcli' }->{ 'retry_count' } ||= 0;
    poe->heap->{ 'afunixcli' }->{ 'retry_count' }++;

    my $max_retries = $opt->lock_client_retry || 0;
    my $retry_count = poe->heap->{ 'afunixcli' }->{ 'retry_count' };

    # 0 = infinite retries, otherwise check max
    if ( $max_retries > 0 && $retry_count > $max_retries )
    {
        $debug->( 'STDERR', __LINE__, "Max retries ($max_retries) exceeded, exiting.", 'error' );
        poe->heap->{ '_' }->{ 'set_exit' }->( '1', 'lock-client-retries-exhausted' );
        poe->kernel->stop();
        return;
    }

    my $delay = $opt->lock_client_retry_delay || 5;
    $debug->( 'STDERR', __LINE__,
        "Scheduling reconnect attempt $retry_count in ${delay}s (max: "
        . ( $max_retries == 0 ? 'infinite' : $max_retries ) . ")." );
    poe->kernel->delay( 'afunixcli_client_reconnect' => $delay );

    return;
}

# As client - reconnect after a failed connection
sub afunixcli_client_reconnect
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    $debug->( 'STDERR', __LINE__, "Attempting lock client reconnect." );

    my $transport = $opt->lock_transport || 'auto';

    if ( $transport eq 'tcp' || $transport eq 'auto' )
    {
        my $tcp_host = $opt->lock_client_host || 'aep-master';
        my $tcp_port = $opt->lock_client_port || 60000;

        $debug->( 'STDERR', __LINE__, "Reconnecting via TCP to $tcp_host:$tcp_port." );

        poe->heap->{ 'afunixcli' }->{ 'transport_attempted' } = 'tcp';

        poe->heap->{ 'afunixcli' }->{ 'client' } = POE::Wheel::SocketFactory->new(
            'SocketDomain'  => AF_INET,
            'RemoteAddress' => $tcp_host,
            'RemotePort'    => $tcp_port,
            'SuccessEvent'  => 'afunixcli_server_connected',
            'FailureEvent'  => 'afunixcli_client_error',
        );
    }
    else
    {
        my $socket_path = poe->heap->{ '_' }->{ 'config' }->{ 'AEP_SOCKETPATH' };
        poe->heap->{ 'afunixcli' }->{ 'socket_path' } = $socket_path;

        if ( !-e $socket_path )
        {
            $debug->( 'STDERR', __LINE__, "Control socket '$socket_path' does not exist, will retry." );
            my $delay = $opt->lock_client_retry_delay || 5;
            poe->kernel->delay( 'afunixcli_client_reconnect' => $delay );
            return;
        }

        $debug->( 'STDERR', __LINE__, "Reconnecting via Unix socket $socket_path." );

        poe->heap->{ 'afunixcli' }->{ 'transport_attempted' } = 'unix';

        poe->heap->{ 'afunixcli' }->{ 'client' } = POE::Wheel::SocketFactory->new(
            'SocketDomain'  => PF_UNIX,
            'RemoteAddress' => $socket_path,
            'SuccessEvent'  => 'afunixcli_server_connected',
            'FailureEvent'  => 'afunixcli_client_error',
        );
    }

    return;
}

# As server
sub afunixsrv_client_connected ( $self, $socket, @args )
{

    # Generate an ID we can use
    my $client_id = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'id' }++;

    # Store the socket within it so it cannot go out of scope
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $client_id }->{ 'socket' } = $socket;

    # Send a debug message for the event of a client connecting
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    $debug->( 'STDERR', __LINE__, "Client connected." );

    # Create a stackable filter so we can talk in json
    my $filter = POE::Filter::Stackable->new();
    $filter->push( POE::Filter::Line->new(), POE::Filter::JSONMaybeXS->new(), );

    # Create a rw_wheel to deal with the client
    my $rw_wheel = POE::Wheel::ReadWrite->new(
        'Handle'     => $socket,
        'Filter'     => $filter,
        'InputEvent' => 'afunixsrv_client_input',
        'ErrorEvent' => 'afunixsrv_client_error',
    );

    # Store the wheel next to the socket
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $client_id }->{ 'wheel' } = $rw_wheel;

    # Store the filter so it never falls out of scope
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $client_id }->{ 'filter' } = $filter;

    # Store tx/rx about the connection
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $client_id }->{ 'tx_count' } = 0;
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $client_id }->{ 'rx_count' } = 0;

    # Create a mapping from the wheelid to the client
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'cid2wid' }->{ $client_id } = $rw_wheel->ID;

    # And the other way
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'wid2cid' }->{ $rw_wheel->ID } = $client_id;

    # Also make a note under the obj, for cleaning up
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $client_id }->{ 'wid' } = $rw_wheel->ID;

    # Send a message to the connected client (direct put, not cross-session yield)
    my $msg = { 'event' => 'hello' };
    $rw_wheel->put( $msg );

    return;
}

# As client
sub afunixcli_server_connected ( $self, $socket, @args )
{
    # Store the socket within it so it cannot go out of scope
    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'obj' } = $socket;

    # Send a debug message for the event of a client connecting
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    $debug->( 'STDERR', __LINE__, "Server connected." );

    # Create a stackable filter so we can talk in json
    my $filter = POE::Filter::Stackable->new();
    $filter->push( POE::Filter::Line->new(), POE::Filter::JSONMaybeXS->new(), );

    # Create a rw_wheel to deal with the client
    my $rw_wheel = POE::Wheel::ReadWrite->new(
        'Handle'     => $socket,
        'Filter'     => $filter,
        'InputEvent' => 'afunixcli_server_input',
        'ErrorEvent' => 'afunixcli_server_error',
    );

    # Store the wheel next to the socket
    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'wheel' } = $rw_wheel;

    # Store the filter so it never falls out of scope
    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'filter' } = $filter;

    # Store tx/rx about the connection
    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'tx_count' } = 0;
    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'rx_count' } = 0;

    my $opt = poe->heap->{ '_' }->{ 'opt' };

    if ( $opt->docker_health_check )
    {
        # Health check mode: request status from server
        my $msg = { 'event' => 'health_check' };
        $rw_wheel->put( $msg );
    }
    else
    {
        # Send our lock-id to the server so it knows who we are
        my $msg = { 'event' => 'hello', 'lock_id' => $opt->lock_id };
        $rw_wheel->put( $msg );
    }

    return;
}

# As server
sub afunixsrv_server_send ( $self, $cid, $pkt )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'tx_count' }++;

    my $wheel = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'wheel' };

    # Format the packet, should be small
    my $packet = Dumper( $pkt );
    $packet =~ s#[\r\n]##g;
    $packet =~ s#\s+# #g;

    $debug->( 'STDERR', __LINE__, "Client($cid) TX: $packet", 'debug' );

    $wheel->put( $pkt );

    return;
}

# As client
sub afunixcli_client_send ( $self, $pkt )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'tx_count' }++;

    my $wheel = poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'wheel' };

    # Format the packet, should be small
    my $packet = Dumper( $pkt );
    $packet =~ s#[\r\n]##g;
    $packet =~ s#\s+# #g;

    $debug->( 'STDERR', __LINE__, "Server(-) TX: $packet", 'debug' );

    $wheel->put( $pkt );

    return;
}

# As server - handle input from a connected lock client
sub afunixsrv_client_input ( $self, $input, $wid )
{
    my $cid   = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'wid2cid' }->{ $wid };
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    # Increment the received packet count
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'rx_count' }++;

    # Shortcut to the wheel the client is connected to
    my $wheel = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'wheel' };

    # Format the packet, should be small
    my $packet = Dumper( $input );
    $packet =~ s#[\r\n]##g;
    $packet =~ s#\s+# #g;

    $debug->( 'STDERR', __LINE__, "Client($cid) RX: $packet", 'debug' );

    my $event = $input->{ 'event' } || '';

    # Client is saying hello with its lock-id
    if ( $event eq 'hello' && defined $input->{ 'lock_id' } )
    {
        my $lock_id = $input->{ 'lock_id' };
        $debug->( 'STDERR', __LINE__, "Client($cid) identified as lock-id: $lock_id" );

        # Store the lock-id for this client
        poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'lock_id' } = $lock_id;

        # Map lock_id to cid for quick lookup
        poe->heap->{ 'lock' }->{ 'id2cid' }->{ $lock_id } = $cid;

        # Check if this client is next in the order
        _lock_server_check_next();
    }
    # Client is reporting that its lock-trigger passed (command started successfully)
    elsif ( $event eq 'trigger_ok' )
    {
        my $lock_id = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'lock_id' } || 'unknown';
        $debug->( 'STDERR', __LINE__, "Client($cid) lock-id '$lock_id' reports trigger success." );

        # Increment step_completed counter for parallel groups
        poe->heap->{ 'lock' }->{ 'step_completed' }++;

        my $order = poe->heap->{ 'lock' }->{ 'order' };
        my $idx   = poe->heap->{ 'lock' }->{ 'order_idx' };

        if ( $idx < scalar( @{ $order } ) )
        {
            my $step = $order->[ $idx ];
            my @ids  = ref $step eq 'ARRAY' ? @{ $step } : ( $step );
            my $step_size = scalar @ids;

            $debug->( 'STDERR', __LINE__,
                "Step $idx: " . poe->heap->{ 'lock' }->{ 'step_completed' } . "/$step_size completed." );

            # Only advance when all IDs in the current parallel step have reported trigger_ok
            if ( poe->heap->{ 'lock' }->{ 'step_completed' } >= $step_size )
            {
                poe->heap->{ 'lock' }->{ 'step_completed' } = 0;
                poe->heap->{ 'lock' }->{ 'order_idx' }++;
                _lock_server_check_next();
            }
        }
    }
    # Client is requesting a health check
    elsif ( $event eq 'health_check' )
    {
        my $order       = poe->heap->{ 'lock' }->{ 'order' } || [];
        my $idx         = poe->heap->{ 'lock' }->{ 'order_idx' } || 0;
        my $total_steps = scalar @{ $order };

        # Build lists of cleared and waiting IDs
        my @cleared;
        my @waiting;
        for my $i ( 0 .. $#{ $order } )
        {
            my $step = $order->[ $i ];
            my @ids  = ref $step eq 'ARRAY' ? @{ $step } : ( $step );
            if ( $i < $idx )
            {
                push @cleared, @ids;
            }
            else
            {
                push @waiting, @ids;
            }
        }

        my $status = {
            'event'             => 'health_status',
            'status'            => 'ok',
            'clients_connected' => scalar( keys %{ poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' } || {} } ),
            'order_progress'    => "$idx/$total_steps",
            'cleared'           => \@cleared,
            'waiting'           => \@waiting,
        };
        $wheel->put( $status );
    }

    return;
}

# Check if the next client in the lock order is connected and ready
sub _lock_server_check_next
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };
    my $order = poe->heap->{ 'lock' }->{ 'order' };
    my $idx   = poe->heap->{ 'lock' }->{ 'order_idx' };

    # Check if we have exhausted the order list
    if ( $idx >= scalar( @{ $order } ) )
    {
        $debug->( 'STDERR', __LINE__, "Lock order list exhausted." );
        _lock_server_handle_exhaust();
        return;
    }

    my $step = $order->[ $idx ];
    my @ids  = ref $step eq 'ARRAY' ? @{ $step } : ( $step );
    my $step_label = join( '||', @ids );
    $debug->( 'STDERR', __LINE__, "Lock order: checking step $idx [$step_label]." );

    # For each ID in the current parallel step, send run if connected
    for my $next_id ( @ids )
    {
        my $cid = poe->heap->{ 'lock' }->{ 'id2cid' }->{ $next_id };
        if ( defined $cid )
        {
            # Only send run if we haven't already sent it
            if ( !poe->heap->{ 'lock' }->{ 'run_sent' }->{ $next_id } )
            {
                $debug->( 'STDERR', __LINE__, "Lock-id '$next_id' is connected (cid $cid), sending run." );
                my $msg = { 'event' => 'run' };
                my $wheel = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'wheel' };
                $wheel->put( $msg );
                poe->heap->{ 'lock' }->{ 'run_sent' }->{ $next_id } = 1;
            }
        }
        else
        {
            $debug->( 'STDERR', __LINE__, "Lock-id '$next_id' not yet connected, waiting." );
        }
    }

    # Also process any unknown clients based on lock-server-default
    _lock_server_process_unknown();

    return;
}

# Handle unknown lock-ids based on --lock-server-default
sub _lock_server_process_unknown
{
    my $debug       = poe->heap->{ '_' }->{ 'debug' };
    my $opt         = poe->heap->{ '_' }->{ 'opt' };
    my $default_act = $opt->lock_server_default || 'ignore';
    my $order       = poe->heap->{ 'lock' }->{ 'order' };

    # Build a set of known lock-ids from the order list (which is now array-of-arrays)
    my %known;
    for my $step ( @{ $order } )
    {
        my @ids = ref $step eq 'ARRAY' ? @{ $step } : ( $step );
        $known{ $_ } = 1 for @ids;
    }

    # Check all connected clients for unknown lock-ids
    my $clients = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' } || {};
    for my $cid ( keys %{ $clients } )
    {
        my $lid = $clients->{ $cid }->{ 'lock_id' };
        next unless defined $lid;
        next if $known{ $lid };
        next if $clients->{ $cid }->{ 'unknown_handled' };

        if ( $default_act eq 'run' )
        {
            $debug->( 'STDERR', __LINE__, "Unknown lock-id '$lid' (cid $cid): sending run (default=run)." );
            my $msg = { 'event' => 'run' };
            my $wheel = $clients->{ $cid }->{ 'wheel' };
            $wheel->put( $msg ) if $wheel;
            $clients->{ $cid }->{ 'unknown_handled' } = 1;
        }
        elsif ( $default_act eq 'runlast' )
        {
            # Queue it - will be processed after order list exhaustion
            push @{ poe->heap->{ 'lock' }->{ 'unknown_queue' } }, $cid
                unless grep { $_ == $cid } @{ poe->heap->{ 'lock' }->{ 'unknown_queue' } };
        }
        else
        {
            # ignore
            $debug->( 'STDERR', __LINE__, "Unknown lock-id '$lid' (cid $cid): ignoring (default=ignore)." );
            $clients->{ $cid }->{ 'unknown_handled' } = 1;
        }
    }

    return;
}

# Handle what happens when the lock order list is fully exhausted
sub _lock_server_handle_exhaust
{
    my $debug  = poe->heap->{ '_' }->{ 'debug' };
    my $opt    = poe->heap->{ '_' }->{ 'opt' };
    my $action = $opt->lock_server_exhaust_action || 'idle';

    # First, run any "runlast" queued unknowns
    my $queue = poe->heap->{ 'lock' }->{ 'unknown_queue' } || [];
    for my $cid ( @{ $queue } )
    {
        $debug->( 'STDERR', __LINE__, "Exhaust: sending run to queued unknown cid $cid." );
        my $msg   = { 'event' => 'run' };
        my $wheel = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'wheel' };
        $wheel->put( $msg ) if $wheel;
    }
    poe->heap->{ 'lock' }->{ 'unknown_queue' } = [];

    if ( $action eq 'exit' )
    {
        $debug->( 'STDERR', __LINE__, "Lock order exhausted: exiting." );
        poe->heap->{ '_' }->{ 'set_exit' }->( '0', 'lock-order-exhausted' );
        poe->kernel->stop();
    }
    elsif ( $action eq 'restart' )
    {
        $debug->( 'STDERR', __LINE__, "Lock order exhausted: restarting order list." );
        poe->heap->{ 'lock' }->{ 'order_idx' }      = 0;
        poe->heap->{ 'lock' }->{ 'order' }          = [ map { [ @{ $_ } ] } @{ poe->heap->{ 'lock' }->{ 'order_orig' } } ];
        poe->heap->{ 'lock' }->{ 'id2cid' }         = {};
        poe->heap->{ 'lock' }->{ 'step_completed' } = 0;
        poe->heap->{ 'lock' }->{ 'run_sent' }       = {};
    }
    elsif ( $action eq 'execute' )
    {
        $debug->( 'STDERR', __LINE__, "Lock order exhausted: starting own command." );
        poe->kernel->yield( 'command_start' );
    }
    else
    {
        # idle - do nothing, just keep the event loop alive
        $debug->( 'STDERR', __LINE__, "Lock order exhausted: idling." );
    }

    return;
}

# As client - handle input from the lock server
sub afunixcli_server_input ( $self, $input, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    # Increment the received packet count
    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'rx_count' }++;

    # Shortcut to the wheel the client is connected to
    my $wheel = poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'wheel' };

    # Format the packet, should be small
    my $packet = Dumper( $input );
    $packet =~ s#[\r\n]##g;
    $packet =~ s#\s+# #g;

    $debug->( 'STDERR', __LINE__, "Server(-) RX: $packet", 'debug' );

    my $event = $input->{ 'event' } || '';

    # Server says run - start our command (post to main session, not this socket session)
    if ( $event eq 'run' )
    {
        $debug->( 'STDERR', __LINE__, "Received 'run' from lock server, starting command." );
        poe->heap->{ 'command' }->{ 'lock_cleared' } = 1;
        # Cancel the timeout if one was set
        poe->kernel->post( poe->heap->{ '_' }->{ 'main_session' }, 'lock_client_timeout_cancel' );
        poe->kernel->post( poe->heap->{ '_' }->{ 'main_session' }, 'command_start' );
    }
    # Server sends health status
    elsif ( $event eq 'health_status' )
    {
        require JSON::MaybeXS;
        say STDOUT JSON::MaybeXS::encode_json( $input );
        poe->heap->{ '_' }->{ 'set_exit' }->( 0, 'health-check-ok' );
        poe->kernel->stop();
    }

    return;
}

# As server
sub afunixsrv_client_error ( $self, $syscall, $errno, $error, $wid )
{
    my $cid   = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'wid2cid' }->{ $wid };
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    if ( !$errno )
    {
        $error = "Normal disconnection for wheel: $wid, cid: $cid";
    }

    $debug->( 'STDERR', __LINE__, "Server session encountered $syscall error $errno: $error", 'error' );

    # Clean up the dead client's state
    if ( defined $cid )
    {
        my $lock_id = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'lock_id' };

        # Remove the lock id2cid mapping if it exists
        if ( defined $lock_id )
        {
            delete poe->heap->{ 'lock' }->{ 'id2cid' }->{ $lock_id };
        }

        # Remove wid2cid and cid2wid mappings
        delete poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'wid2cid' }->{ $wid };
        delete poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'cid2wid' }->{ $cid };

        # Delete the client's obj entry
        delete poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid };
    }

    return;
}

# As client
sub afunixcli_server_error ( $self, $syscall, $errno, $error, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    if ( !$errno )
    {
        $error = "Normal disconnection for wheel: $wid";
    }

    $debug->( 'STDERR', __LINE__, "Server session encountered $syscall error $errno: $error", 'error' );

    return;
}

# --- Command execution via POE::Wheel::Run ---

# Start the child command process
sub command_start
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    # Do not start if already running
    if ( poe->heap->{ 'command' }->{ 'running' } )
    {
        $debug->( 'STDERR', __LINE__, "Command already running, skipping start." );
        return;
    }

    my $cmd      = $opt->command || 'aep --help';
    my $cmd_args = $opt->command_args || '';

    # Build the program + args array for Wheel::Run
    my @args = grep { $_ ne '' } split( /,/, $cmd_args );

    $debug->( 'STDERR', __LINE__, "Starting command: $cmd " . join( ' ', @args ) );

    # Reset trigger state for this run
    poe->heap->{ 'command' }->{ 'trigger_ok' } = 0;

    my $wheel = POE::Wheel::Run->new(
        'Program'     => $cmd,
        'ProgramArgs' => \@args,
        'StdoutEvent' => 'command_stdout',
        'StderrEvent' => 'command_stderr',
        'CloseEvent'  => 'command_close',
        'ErrorEvent'  => 'command_error',
    );

    poe->heap->{ 'command' }->{ 'wheel' }   = $wheel;
    poe->heap->{ 'command' }->{ 'pid' }     = $wheel->PID;
    poe->heap->{ 'command' }->{ 'running' } = 1;

    $debug->( 'STDERR', __LINE__, "Command started with PID: " . $wheel->PID );

    # Tell the kernel to watch this child
    poe->kernel->sig_child( $wheel->PID, 'sig_chld' );

    # If we are a lock client with a time-based trigger, set the timer now
    if ( $opt->lock_client )
    {
        _lock_trigger_setup();
    }

    return;
}

# Handle stdout from the child process
sub command_stdout ( $self, $line, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    # Pass through to our own stdout
    say STDOUT $line;

    # Check lock trigger if we are a lock client
    if ( $opt->lock_client && !poe->heap->{ 'command' }->{ 'trigger_ok' } )
    {
        _lock_trigger_check( 'stdout', $line );
    }

    return;
}

# Handle stderr from the child process
sub command_stderr ( $self, $line, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    # Pass through to our own stderr
    say STDERR $line;

    # Check lock trigger if we are a lock client
    if ( $opt->lock_client && !poe->heap->{ 'command' }->{ 'trigger_ok' } )
    {
        _lock_trigger_check( 'stderr', $line );
    }

    return;
}

# Handle child process close (all filehandles closed)
sub command_close ( $self, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    $debug->( 'STDERR', __LINE__, "Command process closed (wheel $wid)." );

    poe->heap->{ 'command' }->{ 'running' } = 0;
    delete poe->heap->{ 'command' }->{ 'wheel' };

    # Do not restart if we are shutting down
    if ( poe->heap->{ 'command' }->{ 'shutting_down' } )
    {
        $debug->( 'STDERR', __LINE__, "Command exited during shutdown, not restarting." );
        return;
    }

    # Check restart logic
    my $max_restart = $opt->command_restart || 0;
    my $no_restart  = $opt->command_norestart || 0;

    if ( $no_restart )
    {
        # In lock-client mode, don't exit yet -- wait for the trigger to fire
        # and report back to the server before shutting down
        if ( $opt->lock_client && !poe->heap->{ 'command' }->{ 'trigger_ok' } )
        {
            $debug->( 'STDERR', __LINE__, "Command exited, waiting for lock trigger before shutdown." );
            return;
        }
        $debug->( 'STDERR', __LINE__, "Command exited, no-restart flag set." );
        poe->heap->{ '_' }->{ 'set_exit' }->( '0', 'command-exited-norestart' );
        return;
    }

    my $count = poe->heap->{ 'command' }->{ 'restart_count' };

    # -1 means infinite restarts, otherwise check the limit
    if ( $max_restart == -1 || $count < $max_restart )
    {
        poe->heap->{ 'command' }->{ 'restart_count' }++;
        my $delay_ms = $opt->command_restart_delay || 1000;
        my $delay_s  = $delay_ms / 1000;

        $debug->( 'STDERR', __LINE__,
            "Command exited, restarting in ${delay_ms}ms (attempt " . ( $count + 1 ) . ")." );
        poe->kernel->delay( 'command_start' => $delay_s );
    }
    else
    {
        $debug->( 'STDERR', __LINE__, "Command exited, max restarts ($max_restart) reached." );
        poe->heap->{ '_' }->{ 'set_exit' }->( '0', 'command-exited-max-restarts' );
    }

    return;
}

# Handle errors from the child process wheel
sub command_error ( $self, $syscall, $errno, $error, $wid, @extra )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    # errno 0 on read means EOF, which is normal
    if ( !$errno )
    {
        return;
    }

    $debug->( 'STDERR', __LINE__, "Command wheel error: $syscall errno=$errno: $error", 'error' );

    return;
}

# --- Lock trigger logic ---

# Parse the lock-trigger spec and set up the appropriate watcher
sub _lock_trigger_setup
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    my $trigger = $opt->lock_trigger || 'none:time:10000';
    my ( $handle, $filter, $spec ) = split( /:/, $trigger, 3 );

    poe->heap->{ 'command' }->{ 'trigger' } = {
        'handle' => $handle || 'none',
        'filter' => $filter || 'time',
        'spec'   => $spec   || '10000',
    };

    $debug->( 'STDERR', __LINE__, "Lock trigger configured: handle=$handle filter=$filter spec=$spec" );

    # If the trigger is time-based, set up a delay
    if ( $filter eq 'time' )
    {
        my $delay_ms = $spec || 10000;
        my $delay_s  = $delay_ms / 1000;
        $debug->( 'STDERR', __LINE__, "Time-based trigger: will fire in ${delay_ms}ms." );
        poe->kernel->delay( 'lock_trigger_fire' => $delay_s );
    }
    # If the trigger is connect-based, try a TCP connection
    elsif ( $filter eq 'connect' )
    {
        $debug->( 'STDERR', __LINE__, "Connect-based trigger: will try connecting to $spec." );
        poe->kernel->delay( 'lock_trigger_connect' => 1 );
    }
    # If the trigger is script-based, run the script
    elsif ( $filter eq 'script' )
    {
        $debug->( 'STDERR', __LINE__, "Script-based trigger: will run $spec." );
        poe->kernel->delay( 'lock_trigger_script' => 1 );
    }
    # text and regex triggers are checked inline via _lock_trigger_check

    return;
}

# Check a line of output against text/regex triggers
sub _lock_trigger_check ( $source, $line )
{
    my $debug   = poe->heap->{ '_' }->{ 'debug' };
    my $trigger = poe->heap->{ 'command' }->{ 'trigger' };

    return unless $trigger;

    my $handle = $trigger->{ 'handle' };
    my $filter = $trigger->{ 'filter' };
    my $spec   = $trigger->{ 'spec' };

    # Check if this source matches the handle
    return if ( $handle eq 'stdout' && $source ne 'stdout' );
    return if ( $handle eq 'stderr' && $source ne 'stderr' );
    # 'both' and 'none' match everything (none has no output filter)

    if ( $filter eq 'text' )
    {
        if ( index( $line, $spec ) != -1 )
        {
            $debug->( 'STDERR', __LINE__, "Text trigger matched: '$spec' found in $source output." );
            poe->kernel->yield( 'lock_trigger_fire' );
        }
    }
    elsif ( $filter eq 'regex' )
    {
        if ( $line =~ m{$spec} )
        {
            $debug->( 'STDERR', __LINE__, "Regex trigger matched: /$spec/ found in $source output." );
            poe->kernel->yield( 'lock_trigger_fire' );
        }
    }

    return;
}

# Fire the lock trigger - report success to the lock server
sub lock_trigger_fire
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    # Only fire once
    if ( poe->heap->{ 'command' }->{ 'trigger_ok' } )
    {
        return;
    }

    poe->heap->{ 'command' }->{ 'trigger_ok' } = 1;

    $debug->( 'STDERR', __LINE__, "Lock trigger fired, reporting success to server." );

    # Send trigger_ok directly via the wheel (not via yield, to avoid cross-session issues)
    if ( poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'wheel' } )
    {
        my $msg = { 'event' => 'trigger_ok', 'lock_id' => $opt->lock_id };
        poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'wheel' }->put( $msg );
        $debug->( 'STDERR', __LINE__, "Sent trigger_ok to server." );
    }

    # If the command has already exited, schedule shutdown after a brief delay
    # to allow the trigger_ok message to flush to the server
    if ( !poe->heap->{ 'command' }->{ 'running' } )
    {
        $debug->( 'STDERR', __LINE__, "Trigger fired and command already exited, shutting down shortly." );
        poe->heap->{ '_' }->{ 'set_exit' }->( '0', 'trigger-ok-command-exited' );
        poe->kernel->delay( 'scheduler' => 0.5 );
    }

    return;
}

# Attempt a TCP connect for the connect trigger type
sub lock_trigger_connect
{
    my $debug   = poe->heap->{ '_' }->{ 'debug' };
    my $trigger = poe->heap->{ 'command' }->{ 'trigger' };
    my $spec    = $trigger->{ 'spec' } || '';

    # Already triggered
    return if poe->heap->{ 'command' }->{ 'trigger_ok' };

    # Parse host:port from spec
    my ( $host, $port ) = split( /:/, $spec, 2 );
    if ( !$host || !$port )
    {
        $debug->( 'STDERR', __LINE__, "Connect trigger: invalid spec '$spec', expected host:port." );
        return;
    }

    $debug->( 'STDERR', __LINE__, "Connect trigger: trying $host:$port." );

    my $ok = try {
        my $sock = IO::Socket::INET->new(
            PeerAddr => $host,
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => 2,
        );
        if ( $sock )
        {
            close( $sock );
            return 1;
        }
        return 0;
    }
    catch {
        return 0;
    };

    if ( $ok )
    {
        $debug->( 'STDERR', __LINE__, "Connect trigger: connection to $host:$port succeeded." );
        poe->kernel->yield( 'lock_trigger_fire' );
    }
    else
    {
        # Retry after 1 second
        poe->kernel->delay( 'lock_trigger_connect' => 1 );
    }

    return;
}

# Run an external script for the script trigger type
sub lock_trigger_script
{
    my $debug   = poe->heap->{ '_' }->{ 'debug' };
    my $trigger = poe->heap->{ 'command' }->{ 'trigger' };
    my $spec    = $trigger->{ 'spec' } || '';

    # Already triggered
    return if poe->heap->{ 'command' }->{ 'trigger_ok' };

    $debug->( 'STDERR', __LINE__, "Script trigger: running '$spec'." );

    # WARNING: system() blocks the event loop. Using alarm() to cap execution time.
    my $exit_code;
    eval {
        local $SIG{ 'ALRM' } = sub { die "script_timeout\n" };
        alarm( 30 );
        $exit_code = system( $spec );
        alarm( 0 );
    };
    if ( $@ )
    {
        $debug->( 'STDERR', __LINE__, "Script trigger: '$spec' timed out after 30s." );
        $exit_code = -1;
    }

    if ( $exit_code == 0 )
    {
        $debug->( 'STDERR', __LINE__, "Script trigger: '$spec' exited 0 (success)." );
        poe->kernel->yield( 'lock_trigger_fire' );
    }
    else
    {
        $debug->( 'STDERR', __LINE__, "Script trigger: '$spec' exited non-zero, retrying." );
        poe->kernel->delay( 'lock_trigger_script' => 1 );
    }

    return;
}

# --- Lock client timeout ---

# Fire when the lock client timeout expires without receiving "run"
sub lock_client_timeout_fire
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    # If command already started (run received), ignore
    return if poe->heap->{ 'command' }->{ 'lock_cleared' };

    $debug->( 'STDERR', __LINE__,
        "WARNING: Lock client timeout reached (" . $opt->lock_client_timeout . "s), starting command without server permission.",
        'error' );
    poe->heap->{ 'command' }->{ 'lock_cleared' } = 1;
    poe->kernel->yield( 'command_start' );

    return;
}

# Cancel the lock client timeout (called when "run" is received)
sub lock_client_timeout_cancel
{
    poe->kernel->delay( 'lock_client_timeout_fire' );
    return;
}

# --- Signal handlers ---

sub sig_int
{

    # Set an appropriate exit
    poe->heap->{ '_' }->{ 'set_exit' }->( '1', 'sigint' );

    # Announce the event
    poe->heap->{ '_' }->{ 'debug' }->( 'STDERR', __LINE__, 'Signal: INT - starting controlled shutdown.' );

    # Tell the kernel to ignore the term we are handling it
    poe->kernel->sig_handled();

    # Send kill to the child process if running
    if ( poe->heap->{ 'command' }->{ 'wheel' } )
    {
        poe->heap->{ 'command' }->{ 'wheel' }->kill( 'INT' );
    }

    # Prevent restarts during shutdown
    poe->heap->{ 'command' }->{ 'shutting_down' } = 1;

    # Clean up the unix socket file if it exists
    my $socket_path = poe->heap->{'afunixsrv'}->{'socket_path'};
    unlink $socket_path if $socket_path && -e $socket_path;

    # Stop the event wheel
    poe->kernel->stop();

    return;
}

sub sig_term
{

    # Set an appropriate exit
    poe->heap->{ '_' }->{ 'set_exit' }->( '1', 'sigterm' );

    # Announce the event
    poe->heap->{ '_' }->{ 'debug' }->( 'STDERR', __LINE__, 'Signal: TERM - starting controlled shutdown.' );

    # Tell the kernel to ignore the term we are handling it
    poe->kernel->sig_handled();

    # Send kill to the child process if running
    if ( poe->heap->{ 'command' }->{ 'wheel' } )
    {
        poe->heap->{ 'command' }->{ 'wheel' }->kill( 'TERM' );
    }

    # Prevent restarts during shutdown
    poe->heap->{ 'command' }->{ 'shutting_down' } = 1;

    # Clean up the unix socket file if it exists
    my $socket_path = poe->heap->{'afunixsrv'}->{'socket_path'};
    unlink $socket_path if $socket_path && -e $socket_path;

    # Stop the event wheel
    poe->kernel->stop();

    return;
}

sub sig_chld
{

    # Announce the event
    poe->heap->{ '_' }->{ 'debug' }->( 'STDERR', __LINE__, 'Signal CHLD received.' );

    # Let POE handle the child reaping
    poe->kernel->sig_handled();

    return;
}

sub sig_usr
{

    # Announce the event
    poe->heap->{ '_' }->{ 'debug' }->( 'STDERR', __LINE__, 'Signal USR, ignoring' );

    return;
}

# --- Scheduler ---

# The scheduler decides what to do based on the operating mode
sub scheduler
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };
    my $opt   = poe->heap->{ '_' }->{ 'opt' };

    # If called after trigger_ok, this is a deferred shutdown
    if ( poe->heap->{ 'command' }->{ 'trigger_ok' } && !poe->heap->{ 'command' }->{ 'running' } )
    {
        $debug->( 'STDERR', __LINE__, "Scheduler: deferred shutdown after trigger." );
        poe->kernel->stop();
        return;
    }

    if ( $opt->lock_client )
    {
        # Lock client mode: wait for the server to tell us to run
        # The afunixcli_server_input handler will post command_start when it receives "run"
        $debug->( 'STDERR', __LINE__, "Scheduler: lock-client mode, waiting for server signal." );

        # Set a timeout if configured
        my $timeout = $opt->lock_client_timeout || 0;
        if ( $timeout > 0 )
        {
            $debug->( 'STDERR', __LINE__, "Scheduler: lock-client timeout set to ${timeout}s." );
            poe->kernel->delay( 'lock_client_timeout_fire' => $timeout );
        }
    }
    elsif ( $opt->lock_server )
    {
        # Lock server mode: listen for connections and process the order
        # The afunixsrv_client_input handler manages the ordering protocol
        $debug->( 'STDERR', __LINE__, "Scheduler: lock-server mode, listening for clients." );
    }
    else
    {
        # Standalone mode: start the command immediately
        $debug->( 'STDERR', __LINE__, "Scheduler: standalone mode, starting command." );
        poe->kernel->yield( 'command_start' );
    }

    return;
}

__END__

=head1 SYNOPSIS

    # Standalone: run a command with restart on failure
    shell$ aep --command /usr/bin/myapp --command-args "--foreground" --command-restart -1

    # Lock server: orchestrate startup order for docker-compose
    shell$ aep --lock-server --lock-server-order "db,redis,app" \
               --lock-server-exhaust-action exit

    # Lock server with parallel groups (redis1 and redis2 start simultaneously)
    shell$ aep --lock-server --lock-server-order "db,redis1||redis2,nginx"

    # Lock client via TCP (default for Docker networking)
    shell$ aep --lock-client --lock-id db --command /usr/bin/postgres \
               --lock-trigger "both:text:ready to accept connections" \
               --lock-transport tcp --lock-client-host aep-master

    # Lock client with timeout (start after 30s even without server)
    shell$ aep --lock-client --lock-id db --command /usr/bin/postgres \
               --lock-client-timeout 30

    # Docker health check (returns JSON status)
    shell$ aep --docker-health-check

    # Quiet mode (errors only)
    shell$ aep --quiet --lock-client --lock-id db --command /usr/bin/myapp

    # Verbose mode (includes packet dumps)
    shell$ aep --verbose --lock-server --lock-server-order "db,app"

=head1 DESCRIPTION

AEP (Advanced Entry Point) is a container entrypoint tool that runs commands
within Docker containers and provides a lock server/client mechanism for
orchestrating multi-container startup order.

In multi-container environments (docker-compose, Kubernetes pods), services
often start simultaneously but depend on each other. AEP solves this by
providing a lock server that controls the order in which services start,
waiting for each service to report readiness before allowing the next to begin.

AEP communicates between containers over both TCP and Unix domain sockets
using a JSON protocol. TCP transport is the default for Docker networking,
eliminating the need for shared volumes. It supports five trigger types for
detecting when a service is ready: time delay, text match, regex match, TCP
connect probe, and external script.

The lock-server-order option supports parallel groups using the C<||>
operator. For example, C<db,redis1||redis2,nginx> starts db first, then
redis1 and redis2 simultaneously, then nginx after both are ready.

=head1 ARGUMENTS

=head2 Config related

=head3 config-env

Default value: disabled

Only read configuration from environment variables.

=head3 config-file

Default value: disabled

Read configuration from a YAML file.

=head3 config-args

Default value: disabled

Only read configuration from command line arguments.

=head3 config-merge (default)

Default value: enabled

Merge together env, config file and args to generate the final configuration.

=head3 config-order (default)

Default value: 'env,file,args' (left to right)

The order to merge configuration sources. Later sources override earlier ones.

=head2 Environment related

=head3 env-prefix (default)

Default value: AEP_

When scanning the environment, aep will look for this prefix to identify
which environment variables it should use as configuration. For example,
setting C<AEP_SOCKETPATH=/var/run/aep.sock> overrides the default socket path.

=head2 Command related (what to run)

=head3 command (string)

What to actually run within the container. Default is C<aep --help>.

=head3 command-args (string)

The arguments to add to the command, comma separated. Default is nothing.

Example: C<--list,--as-service,--with-long "arg",--foreground>

=head3 command-norestart

If the command exits, do not attempt to restart it. Exit immediately.

=head3 command-restart (integer)

If the command exits, how many times to retry it. Default 0. Set to -1 for
infinite restarts.

=head3 command-restart-delay (integer)

The time in milliseconds to wait before retrying the command. Default 1000.

=head2 Lock commands (server)

These options control the lock server, which orchestrates the startup order
of multiple containers to prevent race conditions.

=head3 lock-server

Default value: disabled

Act as a lock server. Other aep instances (lock clients) will connect and
wait for permission to start their commands.

=head3 lock-server-host (string)

What host to bind to. Defaults to 0.0.0.0.

=head3 lock-server-port (integer)

What port to bind to. Defaults to 60000.

=head3 lock-server-default (string)

Default value: ignore

If a client connects with a lock-id not in the order list, what action to take.

=over 4

=item * ignore - Do not send a run signal. The client will wait indefinitely.

=item * run - Immediately tell the unknown client to start.

=item * runlast - Queue the client and run it after the order list is exhausted.

=back

=head3 lock-server-order (string)

The list of lock-ids and the order to allow them to run, comma separated.
Use C<||> within a step to run multiple clients in parallel.

Example: C<db,redis,nginx>

Example with parallel groups: C<db,redis1||redis2,nginx>

In the parallel example, C<db> starts first, then C<redis1> and C<redis2>
start simultaneously. Only after both report trigger success does C<nginx>
start.

Each entry must match a lock-id sent by a connecting client. The server
sends a C<run> signal to each client in order, waiting for each to report
success (via its lock-trigger) before advancing to the next.

=head3 lock-server-exhaust-action (string)

Default value: idle

What to do when all clients in the order list have reported success.

=over 4

=item * exit - Exit with code 0.

=item * idle - Do nothing, keep the server running.

=item * restart - Reset the order list and start the cycle again.

=item * execute - Start the server's own command (from --command).

=back

=head2 Lock commands (client)

=head3 lock-client

Default value: disabled

Become a lock client. This aep will connect to a lock server and wait for
permission to start its command.

=head3 lock-client-host (string)

What host to connect to. Defaults to C<aep-master> (assumes Docker DNS).

=head3 lock-client-port (integer)

What port to connect to. Defaults to 60000.

=head3 lock-client-noretry

If the connection to the lock server fails, exit immediately instead of
retrying. Overrides lock-client-retry.

=head3 lock-client-retry (integer)

Maximum number of connection retry attempts. Set to 0 for infinite retries.
Defaults to 3.

=head3 lock-client-retry-delay (integer)

How long to wait in seconds before retrying the connection. Defaults to 5.

=head3 lock-client-timeout (integer)

Maximum seconds to wait for the lock server to send the C<run> signal.
If the timeout expires without receiving permission, the command starts
anyway and a warning is logged. Set to 0 (default) to wait forever.

=head3 lock-transport (string)

Default value: auto

Which transport to use for connecting to the lock server.

=over 4

=item * auto - Try TCP first, fall back to Unix socket if TCP fails.

=item * tcp - Use TCP only. Connect to lock-client-host:lock-client-port.

=item * unix - Use Unix socket only.

=back

=head3 lock-trigger (string)

Default: none:time:10000

How to determine that the command started successfully. After the trigger
fires, the client reports success to the lock server, which then allows the
next client in the order to start.

The syntax is:

    handle:filter:specification

C<handle> can be C<stderr>, C<stdout>, C<both>, or C<none>.

Available filters:

=over 4

=item *

time - Wait this many milliseconds and then report success.

Example: C<none:time:2000>

=item *

regex - Wait until this regex matches output.

Example: C<both:regex:ok|success>

=item *

text - Wait until this exact text appears in output.

Example: C<both:text:success>

=item *

script - Run an external script and use its exit code (0 = success).
Runs with a 30-second timeout. Retries every second on failure.

Example: C<none:script:/opt/check_state>

=item *

connect - Try to connect to a TCP host:port. No data is sent or received.
Retries every second on failure.

Example: C<none:connect:127.0.0.1:6767>

=back

=head3 lock-id (string)

The identity this client reports to the lock server. Must match an entry in
the server's C<--lock-server-order> list (unless C<--lock-server-default> is
set to C<run> or C<runlast>).

=head2 Output control

=head3 quiet

Suppress informational output. Only errors and the final exit message are
shown.

=head3 verbose

Show detailed debug output including packet contents (the serialized JSON
sent and received).

=head2 Other

=head3 docker-health-check

Connect to the lock server and request a health status report. The server
responds with JSON containing the current order progress, connected clients,
and which services have been cleared or are still waiting.

Returns exit code 0 (healthy) with JSON on stdout, or exit code 1
(unhealthy) if the connection fails.

=head1 ENVIRONMENT

=over 4

=item AEP_SOCKETPATH

Path to the Unix domain socket for lock server/client communication.
Default: C</tmp/aep.sock>

=back

=head1 BUGS

For any feature requests or bug reports please visit:

L<https://github.com/PaulGWebster/p5-App-aep>

You may also find the author 'daemon' on IRC:

=over 4

=item * irc.libera.org #perl

=back

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023-2026 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
