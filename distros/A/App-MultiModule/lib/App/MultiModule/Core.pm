package App::MultiModule::Core;
$App::MultiModule::Core::VERSION = '1.143160';
use strict;use warnings;
use POE;
use Storable;
use IPC::Transit;

=head1 METHODS

=cut
{
my $tags = {};

sub _shutdown {
#http://poe.perl.org/?POE_FAQ/How_do_I_force_a_session_to_shut_down
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    delete $heap->{wheel};
    $kernel->alias_remove($heap->{alias}) if $heap->{alias};
    $kernel->alarm_remove_all();
    $kernel->refcount_decrement($session, 'my ref name');
    $kernel->post($heap->{child_session}, 'shutdown') if $heap->{child_session};

    return;
}

=head2 named_recur(%args)

This is the preferred method to schedule recurring code in this framework.
Typically called from within set_config(), it automatically ensures
that only a single POE recurring event is setup, no matter how many times
named_recur() is called.

Simply put: if your tasks has code that needs to run on an interval,
use this method to schedule it.

The value in the 'recur_name' argument is used by this method to guard
against unwanted redundant scheduling of a code reference.

That is, for all calls to named_recur inside a process space, there
will be one and only one scheduled event per unique value of the
argument 'recur_name'.

This method takes all named arguments:

=over 4

=item recur_name (required) (process-globally unique string)

Process global unique identifier for a recurring POE event.

=item repeat_interval (required) (in seconds)

How often the work should repeat.

=item work (required) (CODE reference)

The Perl code that is run on an interval

=item tags (optional) (ARRAY reference of strings)

The list of tags associated with this recurring work. These are referenced
by del_recurs() to deallocate scheduled POE events.

=back

Example: (copied from lib/MultiModuleTest/Example1.pm in this distribution)

    $self->named_recur(
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

=cut
sub named_recur {
    my $self = shift;
    my %args = @_;
    my $recur_name = $args{recur_name} || 'none';
    $App::MultiModule::Core::named_recur_times = {}
        unless $App::MultiModule::Core::named_recur_times;
    my $repeat_interval = $args{repeat_interval};
    if(     $self->{config} and
            $self->{config}->{intervals} and
            $self->{config}->{intervals}->{$args{recur_name}}) {
        print STDERR "Setting repeat_interval for $args{recur_name} to " . $self->{config}->{intervals}->{$args{recur_name}} . " (default $repeat_interval)\n";
        $repeat_interval = $self->{config}->{intervals}->{$args{recur_name}};
    }
    $App::MultiModule::Core::named_recur_times->{$args{recur_name}}
        = $repeat_interval if $repeat_interval;
    $self->{recurs} = {} unless $self->{recurs};
    return 1 if $self->{recurs}->{$recur_name};
    $self->{recurs}->{$recur_name} = 1;
    return recur($self, %args);
}

=head2 del_recurs($tag)

Call this method to deallocate all of the previously scheduled POE
events that contain the passed $tag.

NOTE NOTE NOTE

Because of the way POE scheduling works, it is possible and likely that
a scheduled task could run one additional time AFTER del_recurs is called
on it.

Example:
 $self->del_recurs('some_tag');

=cut
sub del_recurs {
    my $self = shift;
    my $tag = shift;
    my %args = @_;
    return unless $tags->{$tag};
    foreach my $session_id (keys %{$tags->{$tag}}) {
        POE::Kernel->post($session_id, 'shutdown', $session_id);
    }
    delete $tags->{$tag};
}

=head2 get_tags

Return an array reference of all of the tags that have been assigned to
all of the currently scheduled POE events.

See NOTE in del_recurs(): a call to get_tags() immediately after a call
to del_recurs() will NOT show the deleted tag, but it is possible
that one or more delete scheduled events will run one additional time.

Example:
 foreach my $tag (@{$self->get_tags()) {

 }

=cut
sub get_tags {
    return $tags;
}

=head2 recur(%args)

It is probably best to call named_recur().

This method actually does all of the scheduling work, and is called
from named_recur().  However, named_recur() does the global named
uniqueness check, and this method does not.  So if you call this method
directly, especially in set_config(), take care to not allow a build-up
of POE events.

All of this method's arguments are the same as named_recur(), except
it does not consider the recur_name field.

=cut
sub recur {
    my $self = shift;
    my %args = @_;

    $args{repeat_interval} = 300 unless $args{repeat_interval};
    $args{work} = sub { print "Somebody forgot to pass work\n"; } unless $args{work};
    $self->add_session(
        {   inline_states => {
                _start => sub {
                    $_[HEAP]{alarm_id} = $_[KERNEL]->alarm_set(
                        party => time() + 1
                    );
                    $_[KERNEL]->delay(tick => 1);
                },
                tick => sub {
                    my $repeat_interval = $args{repeat_interval};
                    if($args{recur_name}) {
                       $repeat_interval = $App::MultiModule::Core::named_recur_times->{$args{recur_name}};
                    } elsif($args{override_repeat_interval}) {
                        my $r;
                        eval {
                            $r = $args{override_repeat_interval}->();
                        };
                        $repeat_interval = $r if $r;
#                        print STDERR "\$repeat_interval=$repeat_interval\n" if $r;
                    }
                    $_[KERNEL]->delay(tick => $repeat_interval);
                    &{$args{work}}(@_);
                },
            },
        },
        %args,
    );
}

=head2 add_session($session_def)

=cut
sub add_session {
    my $self = shift;
    my $session_def = shift;
    my %args = @_;
    my $my_tags = $args{tags} || [$self->{task_name}];
    die 'App::MultiModule::Core::add_sesion: passed argument "tags" must be an ARRAY reference'
        if not ref $my_tags or ref $my_tags ne 'ARRAY';
    push @{$my_tags}, $self->{task_name}
        unless grep { /^$self->{task_name}$/ } @$my_tags;
    $session_def->{inline_states}->{'shutdown'} = \&_shutdown;
    my $session_id = POE::Session->create(%$session_def);
    foreach my $tag (@{$my_tags}) {
        $tags->{$tag} = {} unless $tags->{$tag};
        $tags->{$tag}->{$session_id} = 1;
    }
}
}

{
my $get_info = sub {
    my $file = shift;
    my $has_message_method = 0;
    my $has_set_config_method = 0;
    my $is_stateful = 0;
    eval {
        open my $fh, '<', $file or die "failed to open $file: $!";
        while(my $line = <$fh>) {
            $has_message_method = 1 if $line =~ /^sub message/;
            $has_set_config_method = 1 if $line =~ /^sub set_config/;
            $is_stateful = 1 if $line =~ /^sub is_stateful/;
        }
        close $fh or die "failed to close $file: $!";
    };
    die "get_info: $@\n" if $@;
    my $is_multimodule = $has_message_method;
    return {
        is_stateful => $is_stateful,
        is_multimodule => $is_multimodule,
    };
};

=head2 get_multimodules_info

This returns a hash reference that contains information about every
task that the MultiModule framework is aware of.  'aware of' is not
limited to running and/or loaded.  A MultiModule task module that
exists in the configured search path, even though it is not referenced
or configured, will also be in this structure.

The key to the return hash is the task name.  The value is a reference
to a hash that contains a variety of fields:

=over 4

=item is_multimodule

Always true at this point; this is a legacy field that will be removed

=item is_stateful

Has a true value if the referenced task is stateful.

=item config

Contains undef if there is no config currently available for the task.
Otherwise, this field contains the config for the task.

=back

NOTE NOTE NOTE

At this time, calling this method from a task object will fail.  It can
only be called from the 'root', MultiModule object.

Example:
 while(my($task_name, $task_info) =
        each %{$root_object->get_multimodules_info}) {

 }

=cut
sub get_multimodules_info {
    my $self = shift;
    my %args = @_;
    my $module_prefixes = Storable::dclone($self->{module_prefixes});
    my $hits = {};
    foreach my $inc (@INC) {
        foreach my $prefix (@$module_prefixes) {
            $prefix =~ s/::/\//g;
            my $path = "$inc/$prefix";
            eval {  #ignore everything...
                die unless -d $path;
                opendir(my $dh, $path) or die "can't opendir $path: $!\n";
                foreach my $file (grep { not /^\./ and -f "$path/$_" and /\.pm$/ } readdir($dh)) {
                    my $info = $get_info->("$path/$file");
                    $file =~ s/\.pm$//;
                    if($info->{is_multimodule}) {
                        eval {
                            $info->{config} =
                                $self->{api}->get_task_config($file);
                        };
                        $hits->{$file} = $info;
                    }
                }
                closedir $dh;
            }; #...really. Does that make me a terrible person?
        }
    }
    return $hits;
}
}

=head2 bucket($message)

This method is called to send data to the monitoring/management subsystem
of MultiModule.

=over 4

=item task_name

=item check_type

=item cutoff_age

=item min_points

=item min_bucket_span

=item bucket_name

=item bucket_metric

=item bucket_type

=item value

=back

=cut
sub bucket {
    my $self = shift;
    my $message = shift;
    $message->{is_bucket} = 1;
    my %args = @_;
    IPC::Transit::send(
        qname => 'MultiModule',
        message => $message,
        override_local => 1
    );
}

=head1 OUT OF BAND METHODS

The following methods are all a standardized interface to the
Out Of Band subsystem, which is fully documented in
perldoc App::MultiModule::Tasks::OutOfband

For all of the following methods (except send_oob()), the first,
required argument is meant to be a relatively short, human readable
'summary', as appropriate.  Key/value pairs can optionally be passed in as
well, which are optionally accessible for viewing and/or filtering.

=head2 log($logstr, %optional_extra_info)

This method sends some information to the logging subsystem.

Example:
 $self->log('Something boring and relatively rare.', something => $else);
=cut
sub log {
    my $self = shift;
    my $str = shift;
    my %args = @_;
    $self->send_oob('log', {
        args => \%args,
        str => $str,
        pid => $$,
    });
}

=head2 debug($debugstr, %optional_extra_info)

This method sends some information to the debugging subsystem.

Example:
 $self->debug("This $thing might be of interest", something => $else)
    if $self->{debug} > 2;

=cut
sub debug {
    my $self = shift;
    my $str = shift;
    my %args = @_;
    $self->send_oob('debug', {
        args => \%args,
        str => $str,
        pid => $$,
    });
}

=head2 alert($lalertstr, %optional_extra_info)

This method sends some information to the alerting subsystem.

An alert() should always be 'actionable'.  This is used by the
MultiModule internal monitoring infrastructure to communicate
resource violations, and when tasks are shutdown and failsafed.

Example:
 $self->alert("This $thing needs immediate attention", also => $this);
=cut
sub alert {
    my $self = shift;
    my $str = shift;
    my %args = @_;
    $self->send_oob('alert', {
        args => \%args,
        str => $str,
        pid => $$,
    });
}

=head2 error($errorstr, %optional_extra_info)

This method sends some information to the error subsystem.

An error() should always be relevant, but it does not have to
be 'actionable'.  MultiModule sends these, for example, if a
referenced task has a compile error or a run-time exception.

Example:
 $self->error('Something reasonably bad happened.', also => $this);
=cut
sub error {
    my $self = shift;
    my $str = shift;
    my %args = @_;
    $self->send_oob('error', {
        args => \%args,
        str => $str,
        pid => $$,
    });
}

=head2 send_oob($oob_type, $oob_message)

This is the method that log, error, debug and alert all call.
There can be any number of Out Of Band types.  Think of each
'type' as a separate channel for messages that come out of MultiModule.
These channels are configurably handled.  As mentioned before, see
perldoc App::MultiModule::Tasks::OutOfband for full documentation.

=over 4

=item $oob_type A string that defines the OOB channel

=item $oob_message A HASH reference that is sent through the OOB channel

=back

=cut
#The idea is that all OOB calls are sent locally to
#the OutOfBand task.

#That task, if running externally, will re-send the message, non-
#locally, to the same queue, which will be picked up by the main
#OutOfBand task, which actually does the dirty work of
#handling the OOB message stream, but in a central process space.
sub send_oob {
    my $self = shift;
    my $type = shift;
    my $message = shift;
    $message->{type} = $type;
    IPC::Transit::local_queue(qname => 'OutOfBand');
    IPC::Transit::send(qname => 'OutOfBand', message => $message);
}

1;
