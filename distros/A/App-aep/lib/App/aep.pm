#!/usr/bin/env perl

package App::aep;

# ABSTRACT: Allows you to run a command within a container and control its start up

# Core
use warnings;
use strict;
use utf8;
use v5.28;

# Core - Modules
use Socket;
use Env qw(PATH HOME TERM);

# Core - Experimental (stable)
use experimental 'signatures';

# Debug
use Data::Dumper;
use Carp qw(cluck longmess shortmess);

# External
use POE qw(
    Session::PlainCall
    Wheel::SocketFactory
    Wheel::ReadWrite
    Filter::Stackable
    Filter::Line
    Filter::JSONMaybeXS
);
use Try::Tiny;

# Version of this software
our $VERSION = '0.010';

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

    #say STDERR Dumper poe->heap;

    my $debug = poe->heap->{ '_' }->{ 'debug' };
    $debug->( 'STDERR', __LINE__, 'Signals(INT,TERM,CHLF,USR) trapped.' );

    # What command are we meant to be running?
    my $opt = poe->heap->{ '_' }->{ 'opt' };

    if ( $opt->docker_health_check || $opt->lock_client )
    {
        poe->heap->{ 'services' }->{ 'afunixcli' } = POE::Session::PlainCall->create(
            'object_states' => [
                App::aep->new() => {
                    '_start'                     => 'afunixcli_client_start',
                    'afunixcli_server_connected' => 'afunixcli_server_connected',
                    'afunixcli_client_error'     => 'afunixcli_client_error',
                    'afunixcli_server_input'     => 'afunixcli_server_input',
                    'afunixcli_server_error'     => 'afunixcli_server_error',
                    'afunixcli_client_send'      => 'afunixcli_client_send',
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
    my $socket_path = poe->heap->{ '_' }->{ 'config' }->{ 'AEP_SOCKETPATH' };
    poe->heap->{ 'afunixsrv' }->{ 'socket_path' } = $socket_path;

    if ( -e $socket_path )
    {
        unlink $socket_path;
    }

    poe->heap->{ 'afunixsrv' }->{ 'server' } = POE::Wheel::SocketFactory->new(
        'SocketDomain' => PF_UNIX,
        'BindAddress'  => $socket_path,
        'SuccessEvent' => 'afunixsrv_client_connected',
        'FailureEvent' => 'afunixsrv_server_error',
    );

    return;
}

# As client
sub afunixcli_client_start
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    my $socket_path = poe->heap->{ '_' }->{ 'config' }->{ 'AEP_SOCKETPATH' };
    poe->heap->{ 'afunixcli' }->{ 'socket_path' } = $socket_path;

    if ( !-e $socket_path )
    {
        $debug->( 'STDERR', __LINE__, "Control socket '$socket_path' does not exist, refusing to continue." );
        die;
    }

    poe->heap->{ 'afunixsrv' }->{ 'server' } = POE::Wheel::SocketFactory->new(
        'SocketDomain'  => PF_UNIX,
        'RemoteAddress' => $socket_path,
        'SuccessEvent'  => 'afunixcli_server_connected',
        'FailureEvent'  => 'afunixcli_client_error',
    );

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

    $debug->( 'STDERR', __LINE__, "Server AA socket encountered $syscall error $errno: $error" );

    delete poe->heap->{ 'services' }->{ 'afunixsrv' };
    return;
}

# As client
sub afunixcli_client_error ( $self, $syscall, $errno, $error, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    if ( !$errno )
    {
        $error = "Normal disconnection.";
    }

    $debug->( 'STDERR', __LINE__, "Client socket encountered $syscall error $errno: $error" );

    delete poe->heap->{ 'services' }->{ 'afunixcli' };
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

    # Send a message to the connected client
    my $msg = { 'event' => 'hello' };
    poe->kernel->yield( 'afunixsrv_server_send', $client_id, $msg );

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

    # Send a message to the connected client
    my $msg = { 'event' => 'hello' };
    poe->kernel->yield( 'afunixcli_client_send', $msg );

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

    $debug->( 'STDERR', __LINE__, "Client($cid) TX: $packet" );

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

    $debug->( 'STDERR', __LINE__, "Server(-) TX: $packet" );

    $wheel->put( $pkt );

    return;
}

# As server
sub afunixsrv_client_input ( $self, $input, $wid )
{
    my $cid   = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'wid2cid' }->{ $wid };
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    # Increment the received packet count
    poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'rx_count' }++;

    # Shortcut to the wheel the client is connected to
    my $wheel = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'obj' }->{ $cid }->{ 'wheel' };

    # Format the packet, should be small
    my $packet = Dumper( $input );
    $packet =~ s#[\r\n]##g;
    $packet =~ s#\s+# #g;

    $debug->( 'STDERR', __LINE__, "Client($cid) RX: $packet" );

    return;
}

# As client
sub afunixcli_server_input ( $self, $input, $wid )
{
    my $debug = poe->heap->{ '_' }->{ 'debug' };

    # Increment the received packet count
    poe->heap->{ 'afunixcli' }->{ 'server' }->{ 'rx_count' }++;

    # Shortcut to the wheel the client is connected to
    my $wheel = poe->heap->{ 'afunixsrv' }->{ 'client' }->{ 'wheel' };

    # Format the packet, should be small
    my $packet = Dumper( $input );
    $packet =~ s#[\r\n]##g;
    $packet =~ s#\s+# #g;

    $debug->( 'STDERR', __LINE__, "Server(-) RX: $packet" );

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

    $debug->( 'STDERR', __LINE__, "Server session encountered $syscall error $errno: $error" );

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

    $debug->( 'STDERR', __LINE__, "Server session encountered $syscall error $errno: $error" );

    return;
}

sub sig_int
{

    # Set an appropriate exit
    poe->heap->{ '_' }->{ 'set_exit' }->( '1', 'sigint' );

    # Announce the event
    poe->heap->{ '_' }->{ 'debug' }->( 'STDERR', __LINE__, 'Signal: INT - starting controlled shutdown.' );

    # Tell the kernel to ignore the term we are handling it
    poe->kernel->sig_handled();

    # Send kill to the child
    # ... todo ...
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

    # Send kill to the child
    # ... todo ...
    # Stop the event wheel
    poe->kernel->stop();

    return;
}

sub sig_chld
{

    # Announce the event
    poe->heap->{ '_' }->{ 'debug' }->( 'STDERR', __LINE__, 'Signal CHLD, ignoring' );

    return;
}

sub sig_usr
{

    # Announce the event
    poe->heap->{ '_' }->{ 'debug' }->( 'STDERR', __LINE__, 'Signal USR, ignoring' );

    return;
}

sub scheduler
{
    if ( poe->heap->{ 'exit' }++ >= 2000 )
    {
        poe->heap->{ '_' }->{ 'set_exit' }->( '0', 'test' );

        #poe->kernel->yield('set_exit',0,'test');
    }
    else
    {
        poe->kernel->delay_add( 'scheduler' => 1 );
    }

    return;
}

# # Detect the CHLD signal as each of our children exits.
# sub sig_child {
#   my ($heap, $sig, $pid, $exit_val) = @_[HEAP, ARG0, ARG1, ARG2];
#   #my $details = delete $heap->{$pid};
#   warn "Got sig_child";

#   # warn "$$: Child $pid exited";
# }

__END__

=head1 SYNOPSIS

=for comment Brief examples of using the module.

    shell$ aep --help

=head1 DESCRIPTION

=for comment The module's description.

You are reading the wrong documentation; please refer to L<App::CorrectModule>.

=head1 ARGUMENTS

=head2 config related

=head3 config-env

Default value: disabled

Only read command line options from the enviroment

=head3 config-file

Default value: disabled

Only read command line options from the enviroment

=head3 config-args

Default value: disabled

Only listen to command line arguments

=head3 config-merge (default)

Default value: enabled 

Merge together env, config and args to generate a config 

=head3 config-order (default)

Default value: 'env,conf,args' (left to right)

The order to merge options together, 

=head2 environment related

=head3 env-prefix (default)

Default value: aep-

When scanning the enviroment aep will look for this prefix to know which 
environment variables it should pay attention to.

=head2 Command related (what to run)

=head3 command (string)

What to actually run within the container, default is print aes help.

=head3 command-args (string)

The arguments to add to the command comma seperated, default is nothing.

Example: --list,--as-service,--with-long "arg",--foreground

=head3 command-restart (integer)

If the command exits how many times to retry it, default 0 set to -1 for infinate

=head3 command-restart-delay (integer)

The time in milliseconds to wait before retrying the command, default 1000

=head2 Lock commands (server)

These are for if you have concerns of 'race' conditions.

=head3 lock-server

Default value: disabled

Act like a lock server, this means we will expect other aeps to connect to us,
we in turn will say when they should actually start, this is to counter-act
race issues when starting multi image containers such as docker-compose.

=head3 lock-server-host (string)

What host to bind to, defaults to 0.0.0.0

=head3 lock-server-port (integer)

What port to bind to, defaults to 60000

=head3 lock-server-default-run

Default value: disabled

If we get sent an ID we do not know what to do with, tell it to run.

=head3 lock-server-default-ignore

Default value: enabled

If we get sent an ID we do not know what to do with, ignore it.

=head3 lock-server-order (string)

The list of ids and the order to allow them to run, allows OR || operators, for
example: db,redis1||redis2,redis1||redis2,nginx

Beware the the lock-server-default-ignore config flag!

=head3 lock-server-exhaust-action (string)

Default value: idle

What to do if all clients have been started (list end), options are: 


=over 4 

=item * 

exit-  Exit 0

=item *

idle - Do nothing, just sit there doing nothing

=item *

restart - Reset the lock-server-order list and continue operating

=item * 

execute - Read in any passed commands and args and run them like a normal aep

=back

=head2 Lock commands (client)

=head3 lock-client

Default value: disabled

Become a lock client, this will mean your aep will connect to another aep to
learn when it should run its command.

=head3 lock-server-host (string)

What host to connect to, defaults to 'aep-master'

=head3 lock-server-port (integer)

What port to connect to, defaults to 60000

=head3 lock-trigger (string)

Default: none:time:10000

What to look for to know that our target command has executed correctly, if the 
target command dies or exits before this filter can complete, the success will 
never be reported, if you have also set restart options the lock-trigger will 
continue to try to validate the service.

The syntax for the filters is: 

    handle:filter:specification

handle can be stderr, stdout, both or none

So an example for a filter that will match 'now serving requests':

    both:text:now serving requests

Several standard filters are availible:

=over 4

=item * 

time - Wait this many milliseconds and then report success.

Example: none:time:2000

=item *

regex - Wait till this regex matches to report success.

Example: both:regex:ok|success

=item * 

text - Wait till this line of text is seen. 

Example: both:text:success

=item *

script - Run a script or binary somewhere else on the system and use its exit 
code to determine success or failure.

Example: none:script:/opt/check_state

=item * 

connect - Try to connect to a tcp port, no data is sent and any recieved is 
ignored. Will be treated as success if the connect its self succeeds.

Example: none:connect:127.0.0.1:6767

=back

=head3 lock-id (string)

What ID we should say we are

=head1 BUGS

For any feature requests or bug reports please visit:

* Github L<https://github.com/PaulGWebster/p5-App-aep>

You may also catch up to the author 'daemon' on IRC:

* irc.libera.org

* #perl

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 

1;
