package App::MultiModule::Task;
$App::MultiModule::Task::VERSION = '1.143160';
use strict;use warnings;
use IPC::Transit;
use parent 'App::MultiModule::Core';

=head1 METHODS

=head2 emit($message)

A task uses this to send a message to the Router.

The idea is to never address messages directly to tasks; each task
should only 'blindly' emit messages, and leave the decisions about
delivery and transformations to the Router.

You can over-ride this method in a task; just be sure to call the
emit method in the Task class in order to send messages.

This method sets the following fields on the message, automatically:

=over 4

=item source

This field contains the name of the task that called emit

=item previous_source

This field contains the previous value of the source field

=back

Example:

 $self->emit({something => 'important'});

=cut
sub emit {
    my $self = shift;
    my $message = shift;
    $message->{previous_source} = $message->{source}
        if $message->{source};
    {   my @info = caller(0);
        $message->{source} = $info[0];
        $message->{source} =~ s/.*:://;
    }
    $self->debug('Task: emit: sending to router', message => $message)
        if $self->{debug} > 5;
    $App::MultiModule::Task::emit_counts->{$message->{source}} = 0
        unless $App::MultiModule::Task::emit_counts->{$message->{source}};
    $App::MultiModule::Task::emit_counts->{$message->{source}}++;
    IPC::Transit::send(qname => 'Router', message => $message);
    $self->debug('emit: local transit queue info', local_queues => $IPC::Transit::local_queues)
        if $self->{debug} > 5;
}

=head2 is_stateful

This method is called by the MultiModule daemon to determine if your task
is stateful.  is_stateful() returns 'false' in this class.  Override
in your task to return some true value if you want MultiModule to maintain
your state.

Example:

 sub is_stateful {
    return 'yes';
 }

=cut
sub is_stateful {
    return undef;
}

=head2 set_config($config)

This method is called by the MultiModule daemon when it has updated
config for your task.  The default behaviour (as implemented in the
Task class) is to simply take the passed config and assign it to
the 'config' field on the $self reference.

The other important purpose of this method is to give your task a chance
to setup various POE events.

If your task needs to, for instance, follow logfiles, that setup should
happen in this method.

This method is re-called every time the underlying config changes.  So
whatever setup that was done in an initial process-space invocation of
this should probably be re-considered in future calls, since the setup
was likely controlled by the config, and future calls have differences
in the config.

It is important to be mindful of this flow; it would be easy to leak
descriptors and/or resources over various calls to set_config().

Concretely, if an initial process-space call to this method setup
a POE event to watch a file /var/log/some_file.log, as defined in
the passed config, and a later call did not have any reference to
following /var/log/some_file.log, it is expected that the POE
event associated with /var/log/some_file.log would be deallocated.

Example: (copied from lib/MultiModuleTest/Example1.pm in this distribution)

 sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    $self->{state} = { ct => 0 } unless $self->{state};
    $self->named_recur(  #See perldoc App::MultiModule::Core
        recur_name => 'Example1',
        repeat_interval => 1, #runs every second
        work => sub {
            my $message = {
                ct => $self->{state}->{ct}++,
                outstr => $config->{outstr},
            };
            $self->emit($message);
        },
    }
 }

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
}

1;
