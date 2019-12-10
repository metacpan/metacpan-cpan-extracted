package App::aep;

# Internal perl
use 5.028;
use feature 'say';

# Internal perl modules
use warnings;
use strict;
use Data::Dumper;

# External modules 
use POE qw(Wheel::Run Filter::Reference);

# Version of this software
our $VERSION = '0.008';

=head1 NAME

App::aep - Advanced Entry Point (for docker and other containers)

=cut

sub new 
{
    my ($class,$callback) = @_;

    if (
        (!$callback) ||
        (ref $callback ne 'CODE')
    )
    {
        print STDERR "new() must be called with a reference to a function\n";
        print STDERR "An example of this would be ->new(\&my_handler)\n";
        exit 1;
    }

    my $session = POE::Session->create
    (
        inline_states => {
            _start      => \&start_tasks,
            sig_child   => \&sig_child,
        }
    );

    my $self = bless {
        callback => $callback
    }, $class;

    foreach my $signal (keys %SIG) { 
        $SIG{$signal} = sub { &{$self->{callback}}($signal) };
    }

    return $self;
}

sub start_tasks {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
}

# Detect the CHLD signal as each of our children exits.
sub sig_child {
  my ($heap, $sig, $pid, $exit_val) = @_[HEAP, ARG0, ARG1, ARG2];
  #my $details = delete $heap->{$pid};
  warn "Got sig_child";

  # warn "$$: Child $pid exited";
}


=head1 SYNOPSIS

=for comment Brief examples of using the module.

    From within your dockerfile, simply use cpan or cpanm to add App::aep

    It should then be possible to use 'aep' as the entrypoint in the dockerfile

    Please see the EXAMPLES section for a small dockerfile to create a working 
    example

=head1 DESCRIPTION

=for comment The module's description.

This app is a dynamic entry point for use in container systems such as docker, 
unlike most perl modules, this has been created to correctly react to signals
so it will respond correctly.

Signals passed to this entrypoint will also be passed down to the child.

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

* irc.freenode.net

* #perl

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 

$poe_kernel->run();

1;