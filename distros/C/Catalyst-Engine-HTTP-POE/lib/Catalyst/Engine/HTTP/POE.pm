package Catalyst::Engine::HTTP::POE;

use strict;
use warnings;
use base 'Catalyst::Engine::HTTP';
use Data::Dump qw(dump);
use HTTP::Body;
use HTTP::Date ();
use HTTP::Headers;
use HTTP::Response;
use HTTP::Status ();
use POE;
use POE::Filter::Line;
use POE::Filter::Stream;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;
use Socket;
use Time::HiRes;

use Catalyst::Engine::HTTP::Restarter::Watcher;

our $VERSION = '0.08';

# Enable for helpful debugging information
sub DEBUG () { $ENV{CATALYST_POE_DEBUG} || 0 }
sub BENCH () { $ENV{CATALYST_POE_BENCH} || 0 }

# Max processes (including parent)
sub MAX_PROC () { $ENV{CATALYST_POE_MAX_PROC} || 1 }

# Keep-alive connection timeout in seconds
sub KEEPALIVE_TIMEOUT () { 300 }

# Benchmark::Stopwatch for profiling
if ( BENCH ) {
    require Benchmark::Stopwatch;
}

sub run { 
    my ( $self, $class, @args ) = @_;
    
    $self->spawn( $class, @args );
    
    POE::Kernel->run;
}

sub spawn {
    my ( $self, $class, $port, $host, $options ) = @_;
    
    my $addr = $host ? inet_aton($host) : INADDR_ANY;
    if ( $addr eq INADDR_ANY ) {
        require Sys::Hostname;
        $host = lc Sys::Hostname::hostname();
    }
    else {
        $host = gethostbyaddr( $addr, AF_INET ) || inet_ntoa($addr);
    }
    
    $self->{alias}  = delete $options->{alias} || 'catalyst-poe';
    
    $self->{config} = {
        appclass   => $class,
        addr       => $addr,
        port       => $port,
        host       => $host,
        options    => $options,
        children   => {},
        is_a_child => 0,
    };
    
    POE::Session->create(
        object_states => [
            $self => [
                qw/_start
                   _stop
                   shutdown
                   child_shutdown
                   dump_state
                   status
                   
                   prefork
                   sig_chld
                   
                   check_restart
                   restart
                   
                   accept_new_client
                   accept_failed

                   client_flushed
                   client_error
                   
                   read_input
                   process_input
                   process

                   handle_prepare
                   prepare_done

                   handle_finalize
                   finalize_done
                   client_done
                   
                   keepalive_timeout
               /
           ],
       ],
   );
   
   return $self;
}

# start the server
sub _start {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    $kernel->alias_set( $self->{alias} );

    # take a copy of %ENV
    $self->{global_env} = \%ENV;
    
    $self->{listener} = POE::Wheel::SocketFactory->new(
         ( defined ( $self->{config}->{addr} ) 
            ? ( BindAddress => $self->{config}->{addr} ) 
            : () 
         ),
         ( defined ( $self->{config}->{port} ) 
            ? ( BindPort => $self->{config}->{port} ) 
            : ( BindPort => 3000 ) 
         ),
         SuccessEvent   => 'accept_new_client',
         FailureEvent   => 'accept_failed',
         SocketDomain   => AF_INET,
         SocketType     => SOCK_STREAM,
         SocketProtocol => 'tcp',
         Reuse          => 'on',
    );

    # dump our state if we get a SIGUSR1
    $kernel->sig( USR1 => 'dump_state' );

    # shutdown on INT and TERM
    $kernel->sig( INT  => 'shutdown' );
    $kernel->sig( TERM => 'shutdown' );
    
    # restart on HUP
    $kernel->sig( HUP => 'restart' );
    
    # Pre-fork if requested
    $self->{config}->{options}->{max_proc} ||= MAX_PROC;
    if ( $self->{config}->{options}->{max_proc} > 1 ) {
        $kernel->sig( CHLD => 'sig_chld' );
        $kernel->yield( 'prefork' );
    }
    
    # Init restarter
    if ( $self->{config}->{options}->{restart} ) {
        my $delay = $self->{config}->{options}->{restart_delay} || 1;
        $kernel->delay_set( 'check_restart', $delay );
    }
    
    my $url = 'http://' . $self->{config}->{host};
    $url .= ':' . $self->{config}->{port}
        unless $self->{config}->{port} == 80;
    
    $self->{url} = $url;

    print "You can connect to your server at $url\n";
}

sub _stop { }

sub shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    DEBUG && warn "Catalyst POE engine shutting down...\n";
    
    if ( my @children = keys %{ $self->{config}->{children} } ) {
        DEBUG && warn "Signaling all children to stop...\n";
        kill INT => @children;
    }
    
    delete $self->{listener};
    delete $self->{clients};
    
    $kernel->alias_remove( $self->{alias} );
    
    return 1;
}

sub child_shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    return 0;
}

sub dump_state {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    my $clients = scalar keys %{ $self->{clients} };
    warn "-- POE Engine State --\n";
    warn dump( $self );
    warn "Active clients: $clients\n";
}

sub status {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    # XXX: Include more status stuff here
    my $status = {
        url            => $self->{url},
        active_clients => scalar keys %{ $self->{clients} },
    };
    
    return $status;
}

sub prefork {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    return if $self->{config}->{is_a_child};
    
    my $max_proc = $self->{config}->{options}->{max_proc};
    
    DEBUG && warn 'Preforking ' . ( $max_proc - 1 ) . " children...\n";
    
    my $current_children = keys %{ $self->{config}->{children} };
    for ( $current_children + 2 .. $max_proc ) {
        
        my $pid = fork();
        
        unless ( defined $pid ) {
            DEBUG && warn "Server $$ fork failed: $!\n";
            $kernel->delay_set( prefork => 1 );
            return;
        }
        
        # Parent.  Add the child process to its list.
        if ( $pid ) {
            $self->{config}->{children}->{$pid} = 1;
            next;
        }
        
        # Child.  Clear the child process list.
        DEBUG && warn "Child $$ forked successfully.\n";
        $self->{config}->{is_a_child} = 1;
        $self->{config}->{children}   = {};
        
        $kernel->sig( INT => 'child_shutdown' );
        
        return;
    }
}

sub sig_chld {
    my ( $kernel, $self, $child_pid ) = @_[ KERNEL, OBJECT, ARG1 ];

    if ( delete $self->{config}->{children}->{$child_pid} ) {
        DEBUG && warn "Server $$ received SIGCHLD from $child_pid.\n";
        $kernel->yield( 'prefork' );
    }
    return 0;
}

sub check_restart {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    # Only check in the parent process
    return if $self->{config}->{is_a_child};
    
    my $options = $self->{config}->{options};
    
    # Init watcher object with no delay
    if ( !$self->{watcher} ) {        
        $self->{watcher} = Catalyst::Engine::HTTP::Restarter::Watcher->new(
            directory => ( 
                $options->{restart_directory} || 
                File::Spec->catdir( $FindBin::Bin, '..' )
            ),
            regex     => $options->{restart_regex},
            # current Cat versions will 'sleep 1' if this is 0
            delay     => 0.00000000001,
        );
    }
    
    my @changed_files = $self->{watcher}->watch();
    
    # Restart if any files have changed
    if (@changed_files) {
        my $files = join ', ', @changed_files;
        print STDERR qq/File(s) "$files" modified, restarting\n\n/;
        
        $kernel->yield( 'restart' );
    }
    else {
        # Schedule next check
        $kernel->delay_set( 'check_restart', $options->{restart_delay} );
    }
}

sub restart {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];
    
    $kernel->call( 'catalyst-poe', 'shutdown' );
    
    ### if the standalone server was invoked with perl -I .. we will loose
    ### those include dirs upon re-exec. So add them to PERL5LIB, so they
    ### are available again for the exec'ed process --kane
    use Config;
    $ENV{PERL5LIB} .= join $Config{path_sep}, @INC;
    
    my $options = $self->{config}->{options};
    exec $^X . ' "' . $0 . '" ' . join( ' ', @{ $options->{argv} } );
}

sub accept_new_client {
    my ( $kernel, $self, $socket, $peeraddr, $peerport ) 
        = @_[ KERNEL, OBJECT, ARG0 .. ARG2 ];
    
    my $stopwatch;
    if ( BENCH ) {
        $stopwatch = Benchmark::Stopwatch->new->start;
    }

    $peeraddr = inet_ntoa($peeraddr);
    
    my $wheel = POE::Wheel::ReadWrite->new(
        Handle       => $socket,
        Filter       => POE::Filter::Stream->new,
        FlushedEvent => 'client_flushed',
        ErrorEvent   => 'client_error',
        HighMark     => 128 * 1024,
        HighEvent    => sub {}, # useless, never gets called
        LowMark      => 8 * 1024,
        LowEvent     => sub {}, # also useless, we can use FlushedEvent
    );

    # get the local connection information
    my $local_sockaddr = getsockname($socket);
    my ( undef, $localiaddr ) = sockaddr_in($local_sockaddr);
    my $localaddr = inet_ntoa($localiaddr) || '127.0.0.1';
    my $localname = gethostbyaddr( $localiaddr, AF_INET ) || 'localhost';
    
    my $ID = $wheel->ID;
    
    $self->{clients}->{$ID} = {
        wheel     => $wheel,
        socket    => $socket,
        peeraddr  => $peeraddr,
        peerport  => $peerport,
        localaddr => $localaddr,
        localname => $localname,
        
        requests  => 0,
        inputbuf  => '',
        written   => 0,
        
        stopwatch => $stopwatch,
    };
    
    DEBUG && warn "[$ID] [$$] New connection (wheel $ID from $peeraddr:$peerport)\n";

    # Wait for some data to read
    $poe_kernel->select_read( $socket, 'read_input', $ID );
}

sub accept_failed {
    my ( $kernel, $self, $op, $errnum, $errstr ) = @_[ KERNEL, OBJECT, ARG0 .. ARG2 ];
    
    warn "Unable to start server: $op error $errnum: $errstr\n";
    
    $kernel->yield('shutdown');
}

sub client_error {
    my ( $kernel, $self, $op, $errnum, $errstr, $ID ) = @_[ KERNEL, OBJECT, ARG0 .. ARG3 ];
    
    DEBUG && warn "[$ID] [$$] Wheel generated $op error $errnum: $errstr\n";
    
    delete $self->{clients}->{$ID};
}

sub read_input {
    my ( $kernel, $self, $handle, $ID ) = @_[ KERNEL, OBJECT, ARG0, ARG2 ];
    
    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && $client->{stopwatch}->lap('read_input');
    
    # Clear the keepalive timeout timer if set
    if ( my $timer = delete $client->{_timeout_timer} ) {
        $kernel->alarm_remove( $timer );
    }
    
    # Read some data from the driver
    my $driver = $client->{wheel}->[ $client->{wheel}->DRIVER_BOTH ];
    my $buffer_ref = $driver->get( $handle );
        
    if ( !$buffer_ref ) {
        # Error, stop reading and shut down this client
        DEBUG && warn "[$ID] [$$] Error reading, disconnecting\n";
        $kernel->select_read( $handle );
        delete $self->{clients}->{$ID};
        return;
    }
        
    $client->{inputbuf} .= join '', @{$buffer_ref};
        
    DEBUG && warn "[$ID] [$$] read_input (" . length( $client->{inputbuf} ) . " bytes in buffer)\n";
    
    $kernel->yield( 'process_input', $ID );
}

sub process_input {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];
    
    my $client = $self->{clients}->{$ID} || return;
    
    # Have we started processing the body?
    if ( exists $client->{_read} ) {
        
        _process_chunk( $client );
                
        return;
    }
    
    # Have we already parsed headers
    return if $client->{_headers};
    
    # Have we read enough to include all headers?
    if ( $client->{inputbuf} =~ /(\x0D\x0A?\x0D\x0A?|\x0A\x0D?\x0A\x0D?)/s ) {
        $client->{_headers} = 1;

        # Copy the buffer for header parsing, and remove the header block
        # from the content buffer.
        my $buf = $client->{inputbuf};
        $client->{inputbuf} =~ s/.*?(\x0D\x0A?\x0D\x0A?|\x0A\x0D?\x0A\x0D?)//s;
        
        # Parse the request line.
        if ( $buf !~ s/^(\w+)[ \t]+(\S+)(?:[ \t]+(HTTP\/\d+\.\d+))?[^\012]*\012// ) {
            # Invalid request
            DEBUG && warn "[$ID] [$$] Bad request: $buf\n";

            my $status   = 400;
            my $message  = HTTP::Status::status_message($status);
            my $response = HTTP::Response->new( $status => $message );
            $response->content_type( 'text/plain' );
            $response->content( "$status $message" );
            # XXX: fix to use CRLF
            $client->{wheel}->put( $response->as_string );
            return;
        }
        
        my $method = $1;
        my $uri    = $2;
        my $proto  = $3 || 'HTTP/0.9';
        
        DEBUG && warn "[$ID] [$$] process_input: Parsing headers ($method $uri $proto)\n";
        
        # Initialize CGI environment
        my ( $path, $query_string ) = split /\?/, $uri, 2;
        my %env = (
            PATH_INFO       => $path         || '',
            QUERY_STRING    => $query_string || '',
            REMOTE_ADDR     => $client->{peeraddr},
            REMOTE_HOST     => $client->{peeraddr},
            REQUEST_METHOD  => $method || '',
            SERVER_NAME     => $client->{localname},
            SERVER_PORT     => $self->{config}->{port},
            SERVER_PROTOCOL => $proto,
            %{ $self->{global_env} },
        );
        
        # Parse headers
        my $headers = HTTP::Headers->new;
        my ($key, $val);
        HEADER:
        while ( $buf =~ s/^([^\012]*)\012// ) {
            $_ = $1;
            s/\015$//;
            if ( /^([\w\-~]+)\s*:\s*(.*)/ ) {
                $headers->push_header( $key, $val ) if $key;
                ($key, $val) = ($1, $2);
            }
            elsif ( /^\s+(.*)/ ) {
                $val .= " $1";
            }
            else {
                last HEADER;
            }
        }
        $headers->push_header( $key, $val ) if $key;
        
        DEBUG && warn "[$ID] [$$] " . dump($headers) . "\n";

        # Convert headers into ENV vars
        $headers->scan( sub {
            my ( $key, $val ) = @_;
            
            $key = uc $key;
            $key = 'COOKIE' if $key eq 'COOKIES';
            $key =~ tr/-/_/;
            $key = 'HTTP_' . $key
                unless $key =~ m/\A(?:CONTENT_(?:LENGTH|TYPE)|COOKIE)\z/;
                
            if ( exists $env{$key} ) {
                $env{$key} .= ", $val";
            }
            else {
                $env{$key} = $val;
            }
        } );
        
        $client->{env} = \%env;
        
        $kernel->yield( 'process', $ID );
    }
}

sub process {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $class = $self->{config}->{appclass};

    # This request may be executing within another request,
    # so we must localize all of NEXT so it doesn't get confused about what's
    # already been called
    local $NEXT::NEXT{ $class, 'prepare' };
    local $NEXT::NEXT{ $class, 'prepare_request' };
    local $NEXT::NEXT{ $class, 'prepare_connection' };
    local $NEXT::NEXT{ $class, 'prepare_query_parameters' };
    local $NEXT::NEXT{ $class, 'prepare_headers' };
    local $NEXT::NEXT{ $class, 'prepare_cookies' };
    local $NEXT::NEXT{ $class, 'prepare_path' };
    local $NEXT::NEXT{ $class, 'prepare_body' };

    local $NEXT::NEXT{ $class, 'finalize_uploads' };
    local $NEXT::NEXT{ $class, 'finalize_error' };
    local $NEXT::NEXT{ $class, 'finalize_headers' };
    local $NEXT::NEXT{ $class, 'finalize_body' };
    
    # pass flow control to Catalyst
    my $status = $class->handle_request( $ID );
}

# Prepare handles the entire prepare stage so we can yield to each step
sub prepare {
    my ( $self, $c, $ID ) = @_;

    DEBUG && warn "[$ID] [$$] - prepare\n";

    # store our ID in context
    $c->{_POE_ID} = $ID;
    
    my $client = $self->{clients}->{$ID} || return;
    $client->{context} = $c;

    $client->{_prepare_done} = 0;
    
    BENCH && $client->{stopwatch}->lap('prepare');
    
    $poe_kernel->yield( 'handle_prepare', 'prepare_request', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_connection', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_query_parameters', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_headers', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_cookies', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_path', $ID );
    
    # If parse_on_demand is set, prepare_body will be called later
    unless ( $c->config->{parse_on_demand} ) {
        $poe_kernel->yield( 'handle_prepare', 'prepare_body', $ID );
        
         # prepare_body calls prepare_done after reading all data
    }
    else {
        # Parse on demand will call prepare_body later, so we're done with 
        # the rest of the prepare cycle now
        $poe_kernel->yield( 'prepare_done', $ID );
    }

    # Wait until all prepare processing has completed, or we will return too
    # early
    # XXX: Is there a better way to handle this?
    while ( !$client->{_prepare_done} ) {
        $poe_kernel->run_one_timeslice();
    }

    return $c;
}

# handle_prepare localizes our per-client %ENV and calls $c->$method
# Allows plugins to do things during each step
sub handle_prepare {
    my ( $kernel, $self, $method, $ID ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    DEBUG && warn "[$ID] [$$] - $method\n";
    
    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && $client->{stopwatch}->lap(" - $method");
    
    {
        local (*ENV) = $client->{env};
        $client->{context}->$method();
    }
}

sub prepare_body {
    my ( $self, $c ) = @_;

    my $ID = $c->{_POE_ID};
    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && $client->{stopwatch}->lap('prepare_body');
    
    # Initialize the HTTP::Body object
    my $type   = $c->request->header('Content-Type');
    my $length = $c->request->header('Content-Length') 
        || length( $client->{inputbuf} ) 
        || 0;
    
    # Catalyst >= 5.7007 has support for bypassing HTTP::Body object
    if ( !$length && $Catalyst::VERSION ge '5.7007' ) {
        # Defined but will cause all body code to be skipped
        $c->request->{_body} = 0;
        
        $poe_kernel->yield( 'prepare_done', $ID );
        return;
    }

    unless ( $c->request->{_body} ) {
        $c->request->{_body} = HTTP::Body->new( $type, $length );
    }

    if ( !$length ) {
        # Nothing to parse, we're done
        $poe_kernel->yield( 'prepare_done', $ID );
        return;
    }
   
    DEBUG && warn "[$ID] [$$] Processing body data (total length: $length)\n";

    # Read some more data
    $client->{_prepare_body_done} = 0;
    $client->{_read}              = 0;
    $client->{_read_length}       = $length;
    
    # First process any data that is already in our input buffer
    if ( $client->{inputbuf} ) {
        _process_chunk( $client );
    }
    
    # If we have more body data to read, this will be processed in process_input

    # We need to wait until all body data is read before returning
    while ( !$client->{_prepare_body_done} ) {
        $poe_kernel->run_one_timeslice();
    }
    
    $poe_kernel->yield( 'prepare_done', $ID );
}

sub prepare_done {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];
    
    my $client = $self->{clients}->{$ID} || return;
    
    DEBUG && warn "[$ID] [$$] prepare_done\n";
#    DEBUG && warn dump( $self->{clients}->{$ID}->{context} );

    $client->{_prepare_done} = 1;
    
    BENCH && $client->{stopwatch}->lap('prepare_done');
}

# Finalize handles the entire finalize stage
sub finalize {
    my ( $self, $c ) = @_;

    my $ID = $c->{_POE_ID};
    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && $client->{stopwatch}->lap('finalize');

    $client->{_finalize_done} = 0;

    $poe_kernel->yield( 'handle_finalize', 'finalize_uploads', $ID );

    if ( $#{ $c->error } >= 0 ) {
        $poe_kernel->yield( 'handle_finalize', 'finalize_error', $ID );
    }

    $poe_kernel->yield( 'handle_finalize', 'finalize_headers', $ID );

    $poe_kernel->yield( 'handle_finalize', 'finalize_body', $ID );

    $poe_kernel->yield( 'finalize_done', $ID );

    while ( !$client->{_finalize_done} ) {
        $poe_kernel->run_one_timeslice();
    }
    
    return $c->response->status;
}

sub handle_finalize {
    my ( $kernel, $self, $method, $ID ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];
    
    DEBUG && warn "[$ID] [$$] - $method\n";

    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && $client->{stopwatch}->lap(" - $method");

    # Set the response body to null when we're doing a HEAD request.
    # Must be done here so finalize_headers can still set the proper
    # Content-Length value
    if ( $method eq 'finalize_body' ) {
        if ( $client->{context}->request->method eq 'HEAD' ) {
            $client->{context}->response->body('');
        }
    }

    $client->{context}->$method();
}

sub finalize_headers {
    my ( $self, $c ) = @_;

    my $client = $self->{clients}->{ $c->{_POE_ID} } || return;
    
    BENCH && $client->{stopwatch}->lap('finalize_headers');
    
    my $protocol = 'HTTP/1.0'; # We're not HTTP/1.1 (yet)
    my $status   = $c->response->status;
    my $message  = HTTP::Status::status_message($status);

    my @headers;
    push @headers, "$protocol $status $message";
    
    $c->response->headers->header( Date => HTTP::Date::time2str(time) );

    # Some notes: I found that to get keepalive mode to perform well under ab,
    # I had to send all data in a single put() call, so the second put in write() below is
    # what caused keepalive to be so slow.  Not sure if this is just a quirk with ab
    # or really a performance problem. :(
    
    # Should we keep the connection open?
    my $connection = $c->request->header('Connection');
    if ( $connection && $connection =~ /^keep-alive$/i ) {
        $c->response->headers->header( Connection => 'keep-alive' );
        $client->{_keepalive} = 1;
    }
    else {
        $c->response->headers->header( Connection => 'close' );
    }
    
    push @headers, $c->response->headers->as_string("\x0D\x0A");
    
    # Buffer the headers so they are sent with the first write() call
    # This reduces the number of TCP packets we are sending
    $client->{_header_buf} = join("\x0D\x0A", @headers, '');
}

sub finalize_done {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];
    
    DEBUG && warn "[$ID] [$$] finalize_done\n";

    my $client = $self->{clients}->{$ID} || return;
    
    # If we did not send our headers yet (we had no body), send them now
    if ( my $headers = delete $client->{_header_buf} ) {
        $client->{wheel}->put( $headers );
    }

    $client->{_finalize_done} = 1;
    
    BENCH && $client->{stopwatch}->lap('finalize_done');
}

sub write {
    my ( $self, $c, $buffer ) = @_;

    my $ID = $c->{_POE_ID};
    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && $client->{stopwatch}->lap('write');
    
    # keep track of the amount of data we've sent
    $client->{_written} += length $buffer;
    DEBUG && warn "[$ID] [$$] written: " . $client->{_written} . "\n";
    
    # Add headers to the first write() call
    if ( my $headers = delete $client->{_header_buf} ) {
        $client->{_highmark_reached} = $client->{wheel}->put( $headers . $buffer );
    }
    else {
        $client->{_highmark_reached} = $client->{wheel}->put( $buffer );
    }    

    # if the output buffer has reached the highmark, we have a
    # lot of outgoing data.  Don't return until it's been sent
    while ( $client && $client->{_highmark_reached} ) {
        $poe_kernel->run_one_timeslice();
    }

    # always return 1, we can't detect failures here
    return 1;
}

# client_flushed is called when all data is done being written to the browser
sub client_flushed {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && $client->{stopwatch}->lap('client_flushed');

    # Are we done writing?
    if ( $client->{context} ) {
        my $cl = $client->{context}->response->content_length;
        if ( $cl && $client->{_written} >= $cl ) {
            DEBUG && warn "[$ID] [$$] client_flushed, written full content-length\n";
            $kernel->yield( 'client_done', $ID );
            return;
        }
    }

    # if we get this event because of the highmark being reached
    # don't clean up but reset the highmark value to 0
    if ( $client->{_highmark_reached} ) {
        $client->{_highmark_reached} = 0;
        return;
    }

    # we may have not had a content-length...
    $kernel->yield( 'client_done', $ID );
}

sub client_done {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];
    
    my $client = $self->{clients}->{$ID} || return;
    
    BENCH && warn "[$ID] [$$] Stopwatch:\n" . $client->{stopwatch}->stop->summary;

    # clean up everything about this client unless we are using keepalive
    if ( $client->{_keepalive} ) {
        DEBUG && warn "[$ID] [$$] client_done, keepalive enabled, waiting for more requests\n";
        $client->{requests}++;
        
        # Clear important variables from the previous state
        delete $client->{_headers};
        delete $client->{_written};
        delete $client->{_read};
        
        if ( BENCH ) {
            $client->{stopwatch} = Benchmark::Stopwatch->new->start;
        }

        # timeout idle connection after some seconds
        $client->{_timeout_timer} = $kernel->delay_set( 'keepalive_timeout', KEEPALIVE_TIMEOUT, $ID );
    }
    else {
        DEBUG && warn "[$ID] [$$] client_done, closing connection\n";
        delete $self->{clients}->{$ID};
    }
}

sub keepalive_timeout {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];
    
    DEBUG && warn "[$ID] [$$] Timing out idle keepalive connection\n";
    
    delete $self->{clients}->{$ID};
}

# Process a chunk of body data
sub _process_chunk {
    my $client = shift;
    
    # Read no more than content-length
    my $cl = $client->{env}->{CONTENT_LENGTH} || length( $client->{inputbuf} ) || 0;

    my $buf  = substr $client->{inputbuf}, 0, $cl, '';
    my $read = length($buf);
    
    return unless $read;
        
    $client->{context}->prepare_body_chunk( $buf );

    $client->{_read} += $read;
    
    if ( DEBUG ) {
        my $ID   = $client->{wheel}->ID;
        my $togo = $client->{_read_length} - $client->{_read};
        warn "[$ID] [$$] prepare_body: Read $read bytes ($togo to go)\n";
    }
    
    # Is that all the body data?
    if ( $client->{_read} >= $client->{_read_length} ) {
        # Some browsers (like MSIE 5.01) send extra CRLFs after the content
        # so we need to strip it away
        $client->{inputbuf} =~ s/^\s+//;
        
        $client->{_prepare_body_done} = 1;
    }
}

1;
__END__

=head1 NAME

Catalyst::Engine::HTTP::POE - Single-threaded multi-tasking Catalyst engine (deprecated in favor of HTTP::Prefork)

=head1 SYNOPIS

    CATALYST_ENGINE='HTTP::POE' script/yourapp_server.pl
    
    # Prefork 5 children
    CATALYST_POE_MAX_PROC=6 CATALYST_ENGINE='HTTP::POE' script/yourapp_server.pl

=head1 DEPRECATED

This engine has been deprecated.  Please consider using L<Catalyst::Engine::HTTP::Prefork> instead.

=head1 DESCRIPTION

This engine allows Catalyst to process multiple requests in parallel within a
single process.  Much of the internal Catalyst flow now uses POE yield calls.
Application code will still block of course, but all I/O, header processing, and
POST body processing is handled asynchronously.

A good example of the engine's power is the L<Catalyst::Plugin::UploadProgress> demo
application, which can process a file upload as well as an Ajax polling request
at the same time in the same process.

This engine requires at least Catalyst 5.67.

=head1 RESTART SUPPORT

As of version 0.05, the -r flag is supported and the server will restart itself when any
application files are modified.

=head1 PREFORKING

As of version 0.05, the engine is able to prefork a set number of child processes to distribute
requests.  Set the CATALYST_POE_MAX_PROC environment variable to the total number of processes
you would like to run, including the parent process.  So, to prefork 5 children, set this value
to 6.  This value may also be set by modifying yourapp_server.pl and adding max_proc to the
options hash passed to YourApp->run().

=head1 DEBUGGING

To enable trace-level debugging, set the environment variable CATALYST_POE_DEBUG.

At any time you can get a dump of the internal state of the engine by sending a
USR1 signal to the running process.

=head1 EXPERIMENTAL STATUS

This engine should still be considered experimental and likely has bugs,
however as it's only intended for development, please use it and report bugs.

The engine has been tested with the UploadProgress demo, the Streaming example,
and one of my own moderately large applications.  It also fully passes the Catalyst
test suite.

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
