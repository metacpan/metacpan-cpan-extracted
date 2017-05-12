package App::MultiModule;
$App::MultiModule::VERSION = '1.143160';
use 5.006;
use strict;
use warnings FATAL => 'all';

use POE;
use Digest::MD5;
use Storable;
use App::MultiModule::API;
use IPC::Transit;
use Message::Transform qw(mtransform);

use parent 'App::MultiModule::Core';

=head1 NAME

App::MultiModule - Framework to intelligently manage many parallel tasks

=head1 WARNING

This is a very early release.  That means it has a whole pile of
technical debt.  One clear example is that, at this point, this
distribution doesn't even try to function on any OS except Linux.

=head1 SYNOPSIS

Look at the documentation for the MultiModule program proper; it will be
rare to use this module directly.

=head1 EXPORT

none

=head1 SUBROUTINES/METHODS

=head2 new

Constructor

=over 4

=item state_dir

=item qname (required)

IPC::Transit queue name that controls this module

=item module_prefixes

=item module

=item debug

=item oob

=back

=cut

sub new {
    my $class = shift;
    my %args = @_;
    die 'App::MultiModule::new: it is only safe to instantiate this one time per process space'
        if $App::MultiModule::instantiated;
    $App::MultiModule::instantiated = 1;
    die "App::MultiModule::new failed: required argument 'state_dir' must be a scalar"
        if  not $args{state_dir} or
            ref $args{state_dir};
    my @module_prefixes = ('App::MultiModule::Tasks::');
    if($args{module_prefixes}) {
        if(     ref $args{module_prefixes} and
                ref $args{module_prefixes} eq 'ARRAY') {
            push @module_prefixes, $_ for @{$args{module_prefixes}};
        } else {
            die "App::MultiModule::new failed: passed argument module_prefixes must either be a scalar or ARRAY ref";
        }
    }

    my $debug = $args{debug};
    $debug = 0 unless defined $debug;
    my $self = {
        module_prefixes => \@module_prefixes,
        api => App::MultiModule::API->new(state_dir => $args{state_dir}),
        my_qname => $args{qname},
        module => $args{module},
        tasks => {},
        message_counts => {},
        debug => $debug,
        oob_opts => $args{oob},
        hold_events_for => {}, #when we issue a 'shutdown' event in POE,
            #it may or may not stop the next, scheduled event to fire.
            #it's important for some of the task migration 'stuff' that
            #save_task_state() not be called in the per-task state save recur
            #after we want to deallocate.
            #When we deallocate an internal task, we force a state save, but
            #with a special flag, no_save_pid, to cause the written state
            #file to not have a PID.  This is important so _manage_tasks()
            #in the MultiModule task will not think the task is running.
        pristine_opts => $args{pristine_opts},
        task_name => 'main',
    };
    $self->{config_file} = $args{config_file} if $args{config_file};
    bless ($self, $class);
    POE::Kernel->run(); #silence warning about run not being called
    if($args{config_file}) {
        $self->recur(repeat_interval => 1, work => sub {
            eval {
                die "App::MultiModule::new failed: optional passed argument config_file($args{config_file}) must either be a scalar and exist and be readable"
                    if ref $args{config_file} or not -r $args{config_file};
                my $ctime = (stat($args{config_file}))[9];
                $self->{last_config_stat} = 0
                    unless defined $self->{last_config_stat};
                die "all good\n" if $ctime == $self->{last_config_stat};
                $self->{last_config_stat} = $ctime;
                $self->log("reading config from $args{config_file}");
                local $SIG{ALRM} = sub { die "timed out\n"; };
                alarm 2;
                my $conf = do $args{config_file} or die "failed to deserialize $args{config_file}: $@";
                #handle config 'either way'
                if(not $conf->{'.multimodule'}) {
                    $conf = {
                        '.multimodule' => {
                            config => $conf
                        }
                    };
                }
                IPC::Transit::local_queue(qname => $args{qname});
                IPC::Transit::send(qname => $args{qname}, message => $conf);
            };
            alarm 0;
            if($@ and $@ ne "all good\n") {
                $self->error("failed to read config file $args{config_file}: $@");
            }
        });
    }

    $self->{all_modules_info} = $self->get_multimodules_info();

    $self->recur(repeat_interval => 60, work => sub {
        $self->{message_counts} = {};
        $App::MultiModule::Task::emit_counts = {};
    });
    $self->recur(repeat_interval => 10, work => sub {
=head1 cut
        if($args{module} and $args{module} eq 'main') {
            $self->{my_counter} = 0 unless $self->{my_counter};
            $self->{my_counter}++;
            open my $fh, '>>', '/tmp/my_logf';
            print $fh $args{module} . ':' . $self->{my_counter}, "\n";
            close $fh;
            exit if $self->{my_counter} > 60;
        }
=cut
        $self->{all_modules_info} = $self->get_multimodules_info();
    });
    $self->recur(repeat_interval => 1, work => sub {
        $self->_receive_messages;
    });
    $SIG{TERM} = sub {
        print STDERR "caught SIGTERM. starting orderly exit\n";
        $self->log('caught term');
        _cleanly_exit($self);
    };
    $SIG{INT} = sub {
        print STDERR "caught SIGINT. starting orderly exit\n";
        $self->log('caught int');
        IPC::Transit::send(qname => $args{qname}, message => {
            '.multimodule' => {
                control => [
                    {   type => 'cleanly_exit',
                        exit_externals => 1,
                    }
                ],
            }
        });
        #_cleanly_exit($self, exit_external => 1);
    };
    $App::MultiModule::Task::emit_counts = {};
    return $self;
}

sub _control {
    my $self = shift;my $message = shift;
    my %args = @_;
    my $control = $message->{'.multimodule'};
    if($control->{config}) {
        foreach my $task_name (keys %{$control->{config}}) {
            my $config = $control->{config}->{$task_name};
            $self->{api}->save_task_config($task_name, $config);
            $self->{all_modules_info}->{$task_name}->{config} = $config;
            eval {
                my $task = $self->get_task($task_name);
            };
            if($@) {
                $self->debug("_control: failed to get_task($task_name): $@\n") if $self->{debug} > 1;
            }
        }
    }
    if($control->{control}) {
        $self->debug('_control: passed control structure must be ARRAY reference') if $self->{debug} > 1 and ref $control->{control} ne 'ARRAY';
        foreach my $control (@{$control->{control}}) {
            if($control->{type} eq 'cleanly_exit') {
                $self->debug('control cleanly exit') if $self->{debug} > 1;
                $self->_cleanly_exit(%$control);
            }
        }
    }
}

sub _cleanly_exit {
    my $self = shift;
    my %args = @_;
    $self->debug('beginning cleanly_exit');
    #how to exit cleanly:
    #call save_task_state on all internal stateful tasks
    #if exit_externals is set:
    ##send TERM to all external tasks if exit_externals is set
    ##wait a few seconds
    ##send KILL to all external tasks and all of their children and children

    my @all_tasks;
    foreach my $task_name (keys %{$self->{all_modules_info}}) {
        push @all_tasks, $task_name;
    }
    #first: 'flush' all of the internal queues
    for(1..5) { #lolwut
    foreach my $task_name (@all_tasks) {
        next unless $self->{tasks}->{$task_name};
        IPC::Transit::local_queue(qname => $task_name);
        my $stats = IPC::Transit::stat(
            qname => $task_name,
            override_local => _receive_mode_translate('local'));
        next unless $stats->{qnum}; #nothing to receive
        while(  my $message = IPC::Transit::receive(
                    qname => $task_name,
                    override_local => _receive_mode_translate('local'))) {
            eval {
                $self->{tasks}->{$task_name}->message(
                    $message,
                    root_object => $self
                );
            };
            if($@) {
                $self->error("_cleanly_exit($task_name) threw: $@");
            }
        }
    }
    }
    #second: save state and send signals, as appropriate
    foreach my $task_name (@all_tasks) {
        eval {
            my $task_info = $self->{all_modules_info}->{$task_name};
            my $task_is_stateful = $task_info->{is_stateful};
            my $task_config = $task_info->{config} || {};
            my $task_state = $self->{api}->get_task_state($task_name);
            my $task_status = $self->{api}->get_task_status($task_name);
            my $is_loaded = $self->{tasks}->{$task_name};
            my $is_running = 0;
            if(     $task_status and
                    $task_status->{is_running}) {
                $is_running = $task_status->{is_running};
            }
            my $is_my_pid = 0;
            if(     $task_status and
                    $task_status->{is_my_pid}) {
                $is_my_pid = $task_status->{is_my_pid};
            }
            #first case: internal, stateful task
            if(     $is_loaded and
                    $task_is_stateful) {
                $self->{api}->save_task_state($task_name, $self->{tasks}->{$task_name}->{'state'});
                my $status = Storable::dclone($self->{tasks}->{$task_name}->{'status'});
                $status->{is_internal} = 1;
                $self->{api}->save_task_status($task_name, $status);
            }

            #second case: external task
            if(     not $is_loaded and
                    $is_running and
                    not $is_my_pid and
                    $args{exit_externals}) {
                my $sig = $self->{api}->send_signal($task_name, 15);
                sleep 2;
                $self->log("cleanly_exit: exit_internals: sending signal 9 to $task_name");
                $sig = $self->{api}->send_signal($task_name, 9) || 'undef';
            }
        };
    }
    $self->log('exit');
    exit;
}

sub _receive_messages {
    my $self = shift;


    {   #handle messages directed at MultiModule proper
        #first, we do local queue reads for the management queue
        IPC::Transit::local_queue(qname => $self->{my_qname});
        while(  my $message = IPC::Transit::receive(
                    qname => $self->{my_qname},
                    nonblock => 1,
                )
        ) {
            $self->_control($message);
        }
        #only the parent MultiModule process reads non-local for itself
        if($self->{module} eq 'main') {
            while(  my $message = IPC::Transit::receive(
                        qname => $self->{my_qname},
                        nonblock => 1,
                        override_local => 1,
                    )
            ) {
                $self->_control($message);
            }
        }
    }

    #we always do local queue reads for all possible local queues
    foreach my $module_name (keys %{$self->{all_modules_info}}) {
        $self->_receive_messages_from($module_name, 'local');
    }

    if($self->{module} ne 'main') {
        $self->_receive_messages_from($self->{module}, 'non-local');
    } else { #main process
        #non-local queue reads for every task that is not external
        while(my($module_name, $module_info) = each %{$self->{all_modules_info}}) {
            if(     $module_info->{config} and
                    $module_info->{config}->{is_external}) {
                #external; do not receive
                next;
            }
            $self->_receive_messages_from($module_name, 'non-local');
        }
    }
}

sub _receive_mode_translate {
    my $mode = shift;
    return 0 if $mode eq 'local';
    return 1 if $mode eq 'non-local';
    die "unknown mode: $mode\n";
}

sub _receive_messages_from {
    my $self = shift;
    my $qname = shift; my $receive_mode = shift;
    my %args = @_;
    IPC::Transit::local_queue(qname => $qname);
    my $stats = IPC::Transit::stat(
        qname => $qname,
        override_local => _receive_mode_translate($receive_mode));
    return unless $stats->{qnum}; #nothing to receive
    #at this point, there are one or more messages for us to receive
    #we can only deliver messages to tasks that are loaded AND configured

    if(     $self->{tasks}->{$qname} and
            $self->{tasks}->{$qname}->{config_is_set}) {
        while(  my $message = IPC::Transit::receive(
                    qname => $qname,
                    nonblock => 1,
                    override_local => _receive_mode_translate($receive_mode),
                )
        ) {
            #handle dynamic state transforms
            if(     $message->{'.multimodule'} and
                    $message->{'.multimodule'}->{transform}) {
                $self->debug("_receive_messages_from($qname, _receive_mode_translate($receive_mode): in transform")
                    if $self->{debug} > 1;
                eval {
                    mtransform( $self->{tasks}->{$qname}->{'state'},
                                $message->{'.multimodule'}->{transform}
                    );
                };
                $self->error("_receive_messages_from: transform failed: $@")
                    if $@;
                $self->debug('post-transform state',
                        'state' => $self->{tasks}->{$qname}->{'state'})
                    if $self->{debug} > 5;

                return;
            }
            #actually deliver the message
            eval {
                $self->{message_counts}->{$qname} = 0 unless
                    $self->{message_counts}->{$qname};
                $self->{message_counts}->{$qname}++;
                $self->{tasks}->{$qname}->message($message, root_object => $self);
            };
            if($@) {
                my $err = $@;
                $self->error("_receive_messages_from: handle_message failed: $@");
                $self->bucket({
                    task_name => $qname,
                    check_type => 'admin',
                    cutoff_age => 300,
                    min_points => 1,
                    min_bucket_span => 0.01,
                    bucket_name => "$qname:local.admin.task_message_failure",
                    bucket_metric => 'local.admin.task_message_failure',
                    bucket_type => 'sum',
                    value => 1,
                });
            }
        }
    } elsif(    $self->{tasks}->{$qname} and
                not $self->{tasks}->{$qname}->{config_is_set}) {
        #in this case, the task is loaded but not configured
        #we just wait for the configure to happen
        $self->debug("_receive_messages_from($qname): config_is_set is false")
            if $self->{debug} > 5;
    } else {
        #in this case, the task is not loaded; we need to load it,
        #but not deliver the message to it
        $self->debug("_receive_messages_from($qname): task is not loaded")
            if $self->{debug} > 5;
        eval {
            my $task = $self->get_task($qname);
        };
        if($@) {
            $self->error("_receive_messages_from($qname): failed to get_task($qname): $@");
            return;
        }
    }
}

{ #close over get_task() and its helper function
#http://stackoverflow.com/questions/433752/how-can-i-determine-if-a-perl-function-exists-at-runtime
my $function_exists = sub {
    no strict 'refs';
    my $funcname = shift;
    return \&{$funcname} if defined &{$funcname};
    return;
};

=head2 get_task
=cut
sub get_task {
    my $self = shift; my $task_name = shift;
    my %args = @_;
    $self->debug("in get_task($task_name)") if $self->{debug} > 5;
    $self->debug("get_task($task_name)", tasks => $self->{tasks})
        if $self->{debug} > 5;
    return $self->{tasks}->{$task_name} if $self->{tasks}->{$task_name};
    $self->debug("get_task:($task_name)",
            module_prefixes => $self->{module_prefixes})
        if $self->{debug} > 5;

    #first let's find out if this thing is running externally
    my $task_status = $self->{api}->get_task_status($task_name);
#    $self->debug('get_task: ', task_state => $task_state, task_status => $task_status) if $self->{debug} > 5;
    $self->debug('get_task: ', task_status => $task_status) if $self->{debug} > 5;
    if(     $task_status and
            $task_status->{is_running} and
            not $task_status->{is_my_pid}) {
        #this thing is running and it is NOT our PID.  That means it's
        #running externally, so we just leave it alone
        $self->error("($task_name): get_task: already running externally");
        return undef;
        #we do not consider what SHOULD be here; that's left to another function
    }

    #at this point, we need to consider loading a task, either internal or
    #external so we need to concern ourselves with what should be
    my $module_info = $self->{all_modules_info}->{$task_name};
    my $module_config = $module_info->{config} || {};
    my $wants_external = $module_config->{is_external};
    my $task_is_stateful = $module_info->{is_stateful};

    #find some reasons we should not load this module
    #all program instances may load any non-stateful module.
    #The main program instance may load any module (if it's not already loaded)
    #the only stateful module external program instances may load is themselves
    if($self->{module} ne 'main') {
        #I am some external program instance
        if($task_name ne $self->{module}) {
            #I am trying to load a module besides myself
            if($task_is_stateful) {
                #and the task is stateful; not allowed
                $self->error("get_task: external($self->{module}) tried to load stateful task $task_name");
                return undef;
            }
        }
    }

    if($wants_external and not $task_is_stateful) {
        #this is currently not allowed, since non-stateful tasks don't have
        #any way of communicating their PID back
        $self->error("task_name $task_name marked as external but is not stateful; this is not allowed");
        return undef;
    }


    if($wants_external and $self->{module} eq 'main') {
        #in this brave new world, we double fork then exec with the proper
        #arguments to run an external
        #fork..exec...
        $self->bucket({
            task_name => $task_name,
            check_type => 'admin',
            cutoff_age => 300,
            min_points => 3,
            min_bucket_span => 0.5,
            bucket_name => "$task_name:local.admin.start.external",
            bucket_metric => 'local.admin.start.external',
            bucket_type => 'sum',
            value => 1,
        });
        my $pid = fork(); #first fork
        die "first fork failed: $!" if not defined $pid;
        if(not $pid) { #first child
            my $pid = fork(); #second (final) fork
            die "second fork failed: $!" if not defined $pid;
            if($pid) { #middle parent; just exit
                exit;
            }
            #technically, 'grand-child' of the program, but it is init parented
            my $pristine_opts = $self->{pristine_opts};
            my $main_prog = $0;
            my @args = split ' ', $pristine_opts;
            push @args, '-m';
            push @args, $task_name;
            $self->debug("preparing to exec: $main_prog " . (join ' ', @args))
                if $self->{debug} > 1;
            exec $main_prog, @args;
            die "exec failed: $!";
        }
        return undef;
    }

    #at this point, we are loading a module into our process space.
    #we could be in module 'main' and loading our 5th stateful task,
    #or we could be an external loading our single allowed stateful task
    #I want to claim that there is no difference at this point
    #I believe the only conditional should be on $task_is_stateful

    my $module;
    foreach my $module_prefix (@{$self->{module_prefixes}}) {
        my $class_name = $module_prefix . $task_name;
        $self->debug("get_task $task_name - $class_name\n") if $self->{debug} > 5;
        my $eval = "require $class_name;";
        $self->debug("get_task:($task_name): \$eval=$eval")
            if $self->{debug} > 5;
        eval $eval;
        my $err = $@;
        $self->debug("get_task:($task_name): \$err = $err")
            if $err and $self->{debug} > 4;
        if($err) {
            if($err !~ /Can't locate /) {
                $self->error("get_task:($task_name) threw trying to load module: $@");
                my $type = 'internal';
                $type = 'external' if $wants_external;
                print STDERR "bucket: $task_name:local.admin.task_compile_failure.$type\n";
                $self->bucket({
                    task_name => $task_name,
                    check_type => 'admin',
                    cutoff_age => 300,
                    min_points => 1,
                    min_bucket_span => 0.01,
                    bucket_name => "$task_name:local.admin.task_compile_failure.$type",
                    bucket_metric => "local.admin.task_compile_failure.$type",
                    bucket_type => 'sum',
                    value => 1,
                });
            }
            next;
        }
        for ('message') {
            my $function_path = $class_name . '::' . $_;
            if(not $function_exists->($function_path)) {
                die "required function $function_path not found in loaded task";
            }
        }
        #make the module right here
        my $task_state = $self->{api}->get_task_state($task_name);
        $module = {
            config => undef,
            'state' => $task_state,
            status => undef,
            config_is_set => undef,
            debug => $self->{debug},
            root_object => $self,
            task_name => $task_name,
        };
        bless ($module, $class_name);
        $self->debug("get_task:($task_name): made module", module => $module)
            if $self->{debug} > 5;
        last;
    }
    if(not $module) {
        $self->error("get_task:($task_name) failed to load module");
        return undef;
    }
    $self->debug("get_task:($task_name): loaded module", module => $module)
        if $self->{debug} > 5;

    $self->{tasks}->{$task_name} = $module;

    #stateful or not gets the get_task_config() recur
    $self->recur(
        repeat_interval => 1,
        tags => ['get_task_config'],
        work => sub {
            $module->{config_is_set} = 1;
            my $config = $self->{api}->get_task_config($task_name);
            if($config) {
                local $Storable::canonical = 1;
                my $config = Storable::dclone($config);
                my $config_hash = Digest::MD5::md5_base64(Storable::freeze($config));
                $module->{config_hash} = 'none' unless $module->{config_hash};
                if($module->{config_hash} ne $config_hash) {
                    $module->{config_hash} = $config_hash;
                    $module->set_config($config);
                }
            }
        }
    );

    if($task_is_stateful) {
        delete $self->{hold_events_for}->{$task_name};
        $self->recur(
            repeat_interval => 1,
            tags => ['save_task_state'],
            override_repeat_interval => sub {
#                print STDERR "$task_name: " . Data::Dumper::Dumper $self->{all_modules_info}->{$task_name}->{config}->{intervals};
                if(     $self->{all_modules_info} and
                        $self->{all_modules_info}->{$task_name} and
                        $self->{all_modules_info}->{$task_name}->{config} and
                        $self->{all_modules_info}->{$task_name}->{config}->{intervals} and
                        $self->{all_modules_info}->{$task_name}->{config}->{intervals}->{save_state}) {
#                    print STDERR 'override_repeat_interval returned ' . $self->{all_modules_info}->{$task_name}->{config}->{intervals}->{save_state} . "\n";
                    return $self->{all_modules_info}->{$task_name}->{config}->{intervals}->{save_state};
                } else {
#                    print STDERR "override_repeat_interval returned undef\n";
                    return undef;
                }
            },
            work => sub {
                #see comments in the App::MultiModule constructor
                return if $self->{hold_events_for}->{$task_name};
                $self->debug("saving state and status for $task_name") if $self->{debug} > 2;
                eval {
                    $self->{api}->save_task_status($task_name, $module->{'status'});
                };
                eval {
                    $self->{api}->save_task_state($task_name, $module->{'state'});
                };
            }
        );
    }
}
}
=head1 AUTHOR

Dana M. Diederich, C<diederich@gmail.com>

=head1 BUGS

Please report any bugs or feature requests at
    https://github.com/dana/perl-App-MultiModule/issues


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule


You can also look for information at:

=over 4

=item * Github bug tracker:

L<https://github.com/dana/perl-App-MultiModule/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule>

=item * Search CPAN

L<http://search.cpan.org/dist/App-MultiModule/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::MultiModule
