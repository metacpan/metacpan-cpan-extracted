package App::MultiModule::Tasks::MultiModule;
$App::MultiModule::Tasks::MultiModule::VERSION = '1.143160';
use parent 'App::MultiModule::Task';
use strict;use warnings;
use Carp;
use Data::Dumper;
use IPC::Transit;

use App::MultiModule::API;

=head2 is_stateful

See perldoc App::MultiModule::Task

=cut
sub is_stateful {
    return 1;
}

=head2 message

See perldoc App::MultiModule::Task

=cut
sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    if($message->{is_bucket}) {
        $self->_bucket_point($message);
    }
}

sub _manage_tasks {
    my $self = shift;
    my %args = @_;
    my $root_object = $self->{root_object};

    #define what we're trying to do here
    #1. facilitate task migration, internal to external and vice versa
    #2. restart crashed external tasks
    my @all_tasks;
    foreach my $task_name (keys %{$root_object->{all_modules_info}}) {
        push @all_tasks, $task_name;
    }
    foreach my $task_name (@all_tasks) {
        eval {
            my $task_info = $root_object->{all_modules_info}->{$task_name};
            my $task_config = $task_info->{config} || {};
            my $has_config = scalar %{$task_config};
            my $wants_external = $task_config->{is_external};
            my $task_status = $root_object->{api}->get_task_status($task_name);
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

            #first let's handle failsafe
            #simple and rather brutal
            if($root_object->{api}->task_is_failsafe($task_name)) {
                eval {
                    $self->error("task $task_name: in failsafe");
                    my $sig = $root_object->{api}->send_signal($task_name, 9);
                    $self->error("task $task_name: (failsafe) send_signal(\$task_name,9) returned $sig");
                };
                die "failsafe for $task_name failed: $@" if $@;
                die "$task_name is in failsafe\n";
            }

            my $is_loaded = $root_object->{tasks}->{$task_name};
            #an externally running task will not be loaded

            #things we might need to do
            #1. deallocate an internal task that wants to be external
            if($is_loaded and $wants_external) {
                #we need to deallocate the internal task

                #see comments in the App::MultiModule constructor
                $root_object->{hold_events_for}->{$task_name} = 1;
                $root_object->{api}->save_task_state($task_name, $root_object->{tasks}->{$task_name}->{state}, no_save_pid => 1);
                $root_object->{api}->save_task_status($task_name, $root_object->{tasks}->{$task_name}->{status}, no_save_pid => 1);

                $self->debug("$task_name: " . '$is_loaded and $wants_external') 
                    if $self->{debug} > 1;
                $root_object->del_recurs($task_name);
                delete $root_object->{tasks}->{$task_name};
                $root_object->bucket({
                    task_name => $task_name,
                    check_type => 'admin',
                    cutoff_age => 300,
                    min_points => 3,
                    min_bucket_span => 0.5,
                    bucket_name => "$task_name:local.admin.stop.internal",
                    bucket_metric => 'local.admin.stop.internal',
                    bucket_type => 'sum',
                    value => 1,
                });
            }

            #2. an external tasks now wants to be internal; ask it to exit
            if(     not $is_loaded and
                    $is_running and
                    not $is_my_pid and
                    not $wants_external) {
                $self->debug("$task_name: " . 'not $is_loaded and $is_running and not $is_my_pid and not $wants_external') if $self->{debug} > 1;
                #in this case, the task is not loaded, but it is
                #running externally, but the config is for not external,
                #so we need to shut it down
                my $sig = $root_object->{api}->send_signal($task_name, 15);
                $root_object->bucket({
                    task_name => $task_name,
                    check_type => 'admin',
                    cutoff_age => 300,
                    min_points => 3,
                    min_bucket_span => 0.5,
                    bucket_name => "$task_name:local.admin.stop_request.external",
                    bucket_metric => 'local.admin.stop_request.external',
                    bucket_type => 'sum',
                    value => 1,
                });
            }

            #3. an external task isn't running, and should be
            if(     not $is_loaded and
                    not $is_running and
                    $has_config and
                    $wants_external) {
                $self->debug("$task_name: " . 'not $is_loaded and not $is_running and $has_config and $wants_external') if $self->{debug} > 1;
                $root_object->bucket({
                    task_name => $task_name,
                    check_type => 'admin',
                    cutoff_age => 300,
                    min_points => 3,
                    min_bucket_span => 0.5,
                    bucket_name => "$task_name:local.admin.start_request.external",
                    bucket_metric => 'local.admin.start_request.external',
                    bucket_type => 'sum',
                    value => 1,
                });
                my $task = $root_object->get_task($task_name);
            }

            #4. an internal task isn't loaded, and should be
            if(     not $is_loaded and
                    not $is_running and
                    $has_config and
                    not $wants_external) {
                $self->debug("task_name: " . 'not $is_loaded and not $is_running and $has_config and not $wants_external') if $self->{debug} > 1;
                $root_object->bucket({
                    task_name => $task_name,
                    check_type => 'admin',
                    cutoff_age => 300,
                    min_points => 3,
                    min_bucket_span => 0.5,
                    bucket_name => "$task_name:local.admin.start_request.internal",
                    bucket_metric => 'local.admin.start_request.internal',
                    bucket_type => 'sum',
                    value => 1,
                });
                my $task = $root_object->get_task($task_name);
            }
        };
        if($@) {
            $self->error("exception($task_name): $@");
        }
    }
}

sub _get_proc_file {
    my $self = shift;
    my $file_path = shift;
    my %args = @_;
    my $ret = {};
    eval {
        open my $fh, $file_path or die "failed to open file for reading: $!";
        while(my $line = <$fh>) {
            chomp $line;
            my ($section, $rest) = split /:\s+/, $line;
            if($rest =~ /kB$/) {
                $rest =~ s/\s+kB$//;
            }
            $ret->{$section} = $rest;
        }
        close $fh or die "failed to close file: $!";
    };
    die "_get_proc_file: failed for $file_path: $@" if $@;
    return $ret;
}

sub _get_transit_stats {
    my $self = shift;
    my %args = @_;
    my $ret = {};
    my $by_id = {};
    foreach my $stat (@{IPC::Transit::stats()}) {
        next unless $stat->{qid};
        $by_id->{$stat->{qid}} = $stat->{qname};
    }
    #OPTIMIZE by reading from /proc/sysvipc/msg
    foreach my $line (`ipcs -q`) {
        chomp $line;
        if($line =~ /^(.*?)\s+\d+\s+(.*?)\s+(\d+)\s+(\d+)\s+(\d+)/) {
            my $key = $1; my $owner = $2; my $perms = $3; my $used_bytes = $4; my $message_ct = $5;
            my $qid = hex $key;
            my $qname = $by_id->{$qid};
            next unless $qname;
            $ret->{$qname} = {
                queue_key => $key,
                qid => $qid,
                owner => $owner,
                perms => $perms,
                used_bytes => $used_bytes,
                message_ct => $message_ct,
            };
        }
    }

    return $ret;
}
{
my $slurp = sub {
    my $filename = shift;
    local $\ = undef;
    my $ret;
    eval {
        open my $fh, '<', $filename or die "failed to open: $!";
        read $fh, $ret, 102400 or die "failed to read: $!";
        close $fh or die "failed to close: $!";
    };
    die "\$slurp($filename): $@" if $@;
    return $ret;
};
sub _get_queue_maxes {
    my $self = shift;
    my %args = @_;
    my $ret = {};
    foreach my $path (  '/proc/sys/kernel/msgmax',
                        '/proc/sys/kernel/msgmni',
                        '/proc/sys/kernel/msgmnb'
    ) {
        my $field_name = $path;
        $field_name =~ s/.*\///;
        $ret->{$field_name} = $slurp->($path);
        chomp $ret->{$field_name};
    }
    return $ret;
}
}

sub _get_relevant_config {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    my $config = $self->{config};
    if(     $message->{bucket_metric} and
            $config and
            $config->{thresholds} and
            $config->{thresholds} and
            $config->{thresholds}->{$message->{bucket_metric}}) {
        return $config->{thresholds}->{$message->{bucket_metric}};
    }
    if(     $message->{bucket_metric} and
            $config and
            $config->{thresholds} and
            $config->{thresholds}->{defaults} and
            $config->{thresholds}->{defaults}->{$message->{bucket_metric}}) {
        return $config->{thresholds}->{defaults}->{$message->{bucket_metric}};
    }
    return undef;
}

sub _simple_alert_dedup {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->{dedup} = {} unless $self->{dedup};
    my $key = $message->{dedup_key};
    my $toggle = $message->{summary};
    $self->{dedup}->{$key} = 'initial thingy that matches nothing!11!'
        unless defined $self->{dedup}->{$key};
    if($self->{dedup}->{$key} ne $toggle) {
        $self->{dedup}->{$key} = $toggle;
        return 1;
    } else {
        return 0;
    }
}

sub _check_alert {
    my $self = shift;
    my $message = shift;
    my $frequency = shift;
    my %args = @_;
    my $root_object = $self->{root_object};
    return undef unless $message;
    my $return_value = $message->{return_value};
    return undef unless defined $return_value;
    my $config = $self->_get_relevant_config($message)
        or return undef;  #no config...no alert
    $message->{level} = 'ok';
#    $message->{is_internal_monitor} = 1;
    $message->{summary} = "$frequency: $message->{bucket_name} is ok";
    $message->{dedup_key} = "$frequency:$message->{bucket_name}";
    foreach my $level_config (@{$config->{levels}}) {
        if($return_value > $level_config->{threshold}) {
            $message->{level} = $level_config->{name};
            $message->{threshold} = $level_config->{threshold};
            $message->{summary} = "$frequency: $message->{bucket_name}: $return_value ($level_config->{threshold}) is $level_config->{name}";
            last;
        }
    }
    if(     $message->{level} eq 'failsafe' and
            $config->{can_failsafe} and
            $message->{task_name}) {
        #First, we failsafe the task
        $root_object->{api}->failsafe_task($message->{task_name}, $message);
        #then we wipe out the history of it.
        #if we don't do this, then we won't be able to unfailsafe a task
        #for up to five minutes, because the task won't be running, and
        #as such we won't be able to collect any metrics.
        delete $self->{state}->{buckets}->{$message->{bucket_name}};
    }
    $self->alert($message->{summary}, message => $message)
        if $self->_simple_alert_dedup($message);
}

sub _monitor_aggregate {
    my $self = shift;
    my %args = @_;
    my $config = $self->{config};
    foreach my $frequency ('one_minute', 'five_minutes') {
        my $seconds = 60;
        $seconds = 300 if $frequency eq 'five_minutes';
        foreach my $bucket_name ($self->_get_all_buckets()) {
            next unless $bucket_name;
            my $message = $self->_bucket_get_average($bucket_name, $seconds);
            $self->_check_alert($message, $frequency);
        }
    }
}

sub _monitor {
    my $self = shift;
    my %args = @_;
    my $config = $self->{config};
    my $root_object = $self->{root_object};
    my $sys_info = $self->{runtime_state}->{sys_info};
    my $queue_maxes = $self->{runtime_state}->{queue_maxes};
    my $tasks_by_pid = {
        $$ => $root_object->{api}->get_task_status('main'),
    };
    $tasks_by_pid->{$$}->{task_name} = 'main';
    eval {
        foreach my $task_name ($root_object->{api}->get_task_status_files()) {
            eval {
                my $task_status = $root_object->{api}->get_task_status($task_name);
                my $pid;
                if(     $task_status and
                        $task_status->{pid} and
                        $task_status->{pid} != $$) {
                    $pid = $task_status->{pid};
                    $tasks_by_pid->{$pid} = $task_status;
                    $tasks_by_pid->{$pid}->{task_name} = $task_name;
                }
            };
            $self->error("_monitor: Exception \$task_name=$task_name (inner): $@") if $@;
            #failed for a given task
        }
    };
    $self->error("_monitor: Exception (outer): $@") if $@;
    my $tasks_by_name = {};
    foreach my $task_pid (keys %{$tasks_by_pid}) {
        next unless -e "/proc/$task_pid";
        my $task_name = $tasks_by_pid->{$task_pid}->{task_name};
        my $proc_status; my $io_status;
        eval {
            $proc_status = $self->_get_proc_file("/proc/$task_pid/status");
            $io_status = $self->_get_proc_file("/proc/$task_pid/io")
                if -e "/proc/$task_pid/io";
            open my $fh, '<', "/proc/$task_pid/stat" or die "Failed to open /proc/$task_pid/stat for reading: $!";
            my $line;
            read $fh, $line, 102400 or die "Failed to read from /proc/$task_pid/stat: $!";
            close $fh or die "Failed to close /proc/$task_pid/stat: $!";
            my @line = split /\s+/, $line;
            $proc_status->{jiffies} = $line[13] + $line[14];
        };
        if($@) {
            $self->error("task $task_name: _get_proc_file($task_pid) failed: $@");
            next;
        }
        my $message = {
            task_name => $task_name,
            check_type => 'process',
            cutoff_age => 300,
            proc_status => $proc_status,
            fd_count => $tasks_by_pid->{$task_pid}->{fd_count},
            task_count => $tasks_by_pid->{$task_pid}->{task_count},
            sys_info => $sys_info,
            min_points => 3,
            min_bucket_span => 0.5,
        };
        $message->{bucket_name} = "$task_name:local.handles.fh.count";
        $message->{bucket_metric} = 'local.handles.fh.count';
        $message->{bucket_type} = 'gauge';
        $message->{value} = $message->{fd_count};
        $self->_bucket_point($message);

        $message->{bucket_name} = "$task_name:local.handles.tasks.count";
        $message->{bucket_metric} = 'local.handles.tasks.count';
        $message->{bucket_type} = 'gauge';
        $message->{value} = $message->{task_count};
        $self->_bucket_point($message);

        $message->{bucket_name} = "$task_name:local.memory.vss_of_box_physical";
        $message->{bucket_metric} = 'local.memory.vss_of_box_physical';
        $message->{bucket_type} = 'gauge';
        $message->{value} = $proc_status->{VmRSS} / $sys_info->{mem_info}->{MemTotal};
        $self->_bucket_point($message);


        if($io_status) {
            $message->{bucket_name} = "$task_name:local.io.disk.read_bytes";
            $message->{bucket_metric} = 'local.io.disk.read_bytes';
            $message->{bucket_type} = 'counter';
            $message->{value} = $io_status->{read_bytes};
            $self->_bucket_point($message);

            $message->{bucket_name} = "$task_name:local.io.disk.write_bytes";
            $message->{bucket_metric} = 'local.io.disk.write_bytes';
            $message->{bucket_type} = 'counter';
            $message->{value} = $io_status->{write_bytes};
            $self->_bucket_point($message);
        }

        $message->{bucket_name} = "$task_name:local.cpu.one_core";
        $message->{bucket_metric} = 'local.cpu.one_core';
        $message->{bucket_type} = 'counter';
        $message->{value} = $proc_status->{jiffies} / $sys_info->{jiffies_per_second};
        $self->_bucket_point($message);

    }

    #queue monitoring
    my $transit_stats = $self->_get_transit_stats();
    while(my($qname, $info) = each %{$transit_stats}) {
        my $message = {
            qname => $qname,
            check_type => 'queue',
            cutoff_age => 300,
            queue_maxes => $queue_maxes,
            task_name => 'transit',
            min_points => 3,
            min_bucket_span => 0.5,
        };
        $message->{bucket_name} = "$qname:local.queue.bytes_of_max";
        $message->{bucket_metric} = 'local.queue.bytes_of_max';
        $message->{bucket_type} = 'gauge';
        $message->{value} = $info->{used_bytes} / $queue_maxes->{msgmnb};
        $self->_bucket_point($message);
    }
    while(my($task_name, $message_count) = each %{$root_object->{message_counts}}) {
        my $message = {
            task_name => $task_name,
            check_type => 'tasks',
            cutoff_age => 300,
            min_points => 3,
            min_bucket_span => 0.5,
        };
        $message->{bucket_name} = "$task_name:local.admin.passed_messages";
        $message->{bucket_metric} = 'local.admin.passed_messages';
        $message->{bucket_type} = 'gauge';
        $message->{value} = $message_count;
        $self->_bucket_point($message);
    }
    while(my($task_name, $message_count) = each %{$App::MultiModule::Task::emit_counts}) {
        my $message = {
            task_name => $task_name,
            check_type => 'tasks',
            cutoff_age => 300,
            min_points => 3,
            min_bucket_span => 0.5,
        };
        $message->{bucket_name} = "$task_name:local.admin.emit_messages";
        $message->{bucket_metric} = 'local.admin.emit_messages';
        $message->{bucket_type} = 'gauge';
        $message->{value} = $message_count;
        $self->_bucket_point($message);
    }
    if($IPC::Transit::Router::stats and $IPC::Transit::Router::stats->{queues}) {

        while(my($task_name, $info) = each %{$IPC::Transit::Router::stats->{queues}}) {
            my $message = {
                task_name => $task_name,
                check_type => 'tasks',
                cutoff_age => 300,
                min_points => 3,
                min_bucket_span => 0.5,
            };
            $message->{bucket_type} = 'counter';
            foreach my $type ('success_ct','fail_ct') {
                $message->{bucket_name} = "$task_name:local.admin.transit_$type";
                $message->{bucket_metric} = 'local.admin.transit_$type';
                $message->{value} = $info->{$type};
                $self->_bucket_point($message);
            }
        }
    }
}

=head2 set_config

See perldoc App::MultiModule::Task

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    my $state = $self->{state};

    #gather system information one time
    if(not $self->{runtime_state}) {
        $self->{runtime_state} = {};
        my $s = $self->{runtime_state};
        eval {
            $s->{queue_maxes} = $self->_get_queue_maxes();
        };
        $s->{sys_info} = {} unless $s->{sys_info};
        $s = $s->{sys_info};
        eval {
            $s->{mem_info} = $self->_get_proc_file('/proc/meminfo');

            $s->{max_files} = `ulimit -n 2> /dev/null`;
            chomp $s->{max_files};
            $s->{max_files} = 1024 if $s->{max_files} eq 'unlimited';

            $s->{max_memory} = `ulimit -m 2> /dev/null`;
            chomp $s->{max_memory};
            $s->{max_memory} = 1024 * 1024 * 1024 * 4 if $s->{max_memory} eq 'unlimited';

            $s->{jiffies_per_second} = `getconf CLK_TCK 2> /dev/null`;
            chomp $s->{jiffies_per_second};
            $s->{jiffies_per_second} = 100 unless $s->{jiffies_per_second};

            $s->{cpu_count} = `grep ^processor /proc/cpuinfo |wc -l`;
            chomp $s->{cpu_count};
            $s->{cpu_count} = 1 unless $s->{cpu_count};
        };
    }

    $config->{thresholds} = {} unless $config->{thresholds};
    $config->{thresholds}->{defaults} = {
        'local.queue.bytes_of_max' => {
            levels => [
                {   name => 'failsafe',
                    threshold => .95,
                },{ name => 'severe',
                    threshold => .8,
                },{ name => 'warn',
                    threshold => .60,
                }
            ],
            can_failsafe => 0,
            fast_failsafe => 0,
        },
        'local.cpu.one_core' => {
            levels => [
                {   name => 'failsafe',
                    threshold => 1.9,
                },{ name => 'severe',
                    threshold => 1.6,
                },{ name => 'warn',
                    threshold => 1.4,
                }
            ],
            can_failsafe => 1,
        },
        'local.handles.fh.count' => {
            levels => [
                {   name => 'failsafe',
                    threshold => 200,
                },{ name => 'severe',
                    threshold => 150,
                },{ name => 'warn',
                    threshold => 100,
                }
            ],
            can_failsafe => 1,
        },
        'local.handles.tasks.count' => {
            levels => [
                {   name => 'failsafe',
                    threshold => 200,
                },{ name => 'severe',
                    threshold => 150,
                },{ name => 'warn',
                    threshold => 100,
                }
            ],
            can_failsafe => 1,
        },
        'local.memory.vss_of_box_physical' => {
            levels => [
                {   name => 'failsafe',
                    threshold => 0.3,
                },{ name => 'severe',
                    threshold => 0.15,
                },{ name => 'warn',
                    threshold => 0.1,
                }
            ],
            can_failsafe => 1,
        },
        'local.io.disk.read_bytes' => {
            levels => [
                {   name => 'failsafe',
                    threshold => 18603324,
                },{ name => 'severe',
                    threshold => 8801662,
                },{ name => 'warn',
                    threshold => 4900831,
                }
            ],
            can_failsafe => 1,
        },
        'local.io.disk.write_bytes' => {
            levels => [
                {   name => 'failsafe',
                    threshold => 118603324,
                },{ name => 'severe',
                    threshold => 18801662,
                },{ name => 'warn',
                    threshold => 14900831,
                }
            ],
            can_failsafe => 1,
        },
        'local.admin.start.external' => {
            levels => [
                {   name => 'failsafe',
                    threshold => 0.2,
                },{ name => 'severe',
                    threshold => 0.1,
                },{ name => 'warn',
                    threshold => 0.01,
                }
            ],
        },
        'local.admin.task_compile_failure.internal' => {
            levels => [
                {   name => 'severe',
                    threshold => 0.1,
                },{ name => 'warn',
                    threshold => 0.01,
                }
            ],
        },
        'local.admin.task_compile_failure.external' => {
            levels => [
                {   name => 'severe',
                    threshold => 0.1,
                },{ name => 'warn',
                    threshold => 0.01,
                }
            ],
        },
        'local.admin.emit_messages' => {
            levels => [
                {   name => 'severe',
                    threshold => 20000,
                },{ name => 'warn',
                    threshold => 10000,
                }
            ],
        },
        'local.admin.passed_messages' => {
            levels => [
                {   name => 'severe',
                    threshold => 20000,
                },{ name => 'warn',
                    threshold => 10000,
                }
            ],
        },
        'local.admin.task_message_failure' => {
            levels => [
                {   name => 'severe',
                    threshold => 0.1,
                },{ name => 'warn',
                    threshold => 0.01,
                }
            ],
        },
    };
    $self->{config} = $config;

    my %args = @_;
    $self->debug('MultiModule.pm: set_config') if $self->{debug} > 4;

    my $root_object = $args{root_object};
    $self->named_recur(
            recur_name => 'multimodule_manage_tasks',
            repeat_interval => 2,
            work => sub {
        eval {
            $self->_manage_tasks(%args);
        };
        $self->error("exception in _manage_tasks: $@") if $@;
    });
    $self->named_recur(
            recur_name => 'multimodule_monitor_tasks_aggregate',
            repeat_interval => 5,
            work => sub {
        eval {
            $self->_monitor_aggregate(%args);
        };
        $self->error("exception in _monitor_aggregate: $@") if $@;
    });
    $self->named_recur(
            recur_name => 'multimodule_monitor_tasks',
            repeat_interval => 1,
            work => sub {
        eval {
            $self->_monitor(%args);
        };
        $self->error("exception in _monitor: $@") if $@;
    });
    $self->named_recur(
            recur_name => 'multimodule_main',
            repeat_interval => 1,
            work => sub {
        $self->debug('MultiModule.pm: calling named_recur')
            if $self->{debug} > 4;
        $self->{state}->{ct} = 0 unless $self->{state}->{ct};
        $self->{state}->{ct}++;
    });
}

sub _get_all_buckets {
    my $self = shift;
    return undef unless $self->{state}->{buckets};
    return keys %{$self->{state}->{buckets}};
}

sub _bucket_return {
    my $self = shift;
    my $config = $self->{config};
    my $bucket_name = shift; my $value = shift; my $window_width = shift;
    my $b = $self->{state}->{buckets}->{$bucket_name};
    my $m = Storable::dclone $b->{last_message};
    $m->{window_width} = $window_width;
    $m->{return_value} = $value;
    if($m->{min_points} and scalar @{$b->{points}} < $m->{min_points}) {
        return undef;
    }
    if($m->{min_bucket_span}) {
        my $earliest_ts = $b->{points}->[0]->{ts};
        my $bucket_span = time - $earliest_ts;
        if($bucket_span / $window_width < $m->{min_bucket_span}) {
            return undef;
        }
    }
    if($m->{return_multiplier}) {
        $m->{return_value} = $value * $m->{return_multiplier};
    }
#    print STDERR Data::Dumper::Dumper $m if $m->{bucket_name} =~ /admin/;
    $m->{is_internal_monitoring} = 1;
    $self->emit($m) if $m->{return_value};
    return $m;
}
sub _bucket_point {
    my $self = shift;
    my $message = shift;
    my $value = $message->{value};
    confess "value required" if not defined $value;
    my $bucket_name = $message->{bucket_name} or die "bucket name required";
    $self->{state}->{buckets}->{$bucket_name} = {
        points => [],
    } unless $self->{state}->{buckets}->{$bucket_name};
    my $b = $self->{state}->{buckets}->{$bucket_name};
    $b->{last_message} = Storable::dclone $message;
    push @{$b->{points}}, {
        value => $value,
        ts => time,
    };
    my $cutoff_age = $b->{last_message}->{cutoff_age} || 10;
    while($b->{points}->[0]->{ts} < time - $cutoff_age) {
        shift @{$b->{points}};
    }
    if(not scalar @{$b->{points}}) {
        delete $self->{state}->{buckets}->{$bucket_name};
    }
}
sub _bucket_get_points {
    my $self = shift;
    my $bucket_name = shift;
    return $self->{state}->{buckets}->{$bucket_name}->{points};
}
sub _bucket_get_average {
    my $self = shift;
    my $bucket_name = shift;my $window_width = shift;
    return undef unless $window_width;
    return undef unless $bucket_name;
    return undef unless $self->{state}->{buckets}->{$bucket_name};
    my $b = $self->{state}->{buckets}->{$bucket_name};
    return undef unless $b->{last_message}->{bucket_type};
    if($b->{last_message}->{bucket_type} eq 'sum') {
        my $sum = 0;
        foreach my $point (@{$self->_bucket_get_points($bucket_name)}) {
            if($point->{ts} > time - $window_width) {
                $sum += $point->{value};
            }
        }
        return $self->_bucket_return($bucket_name, 0, $window_width) unless $window_width;
        return $self->_bucket_return($bucket_name, $sum / $window_width, $window_width);
    }
    if($b->{last_message}->{bucket_type} eq 'gauge') {
        my $point_ct = 0;
        my $sum = 0;
        foreach my $point (@{$self->_bucket_get_points($bucket_name)}) {
            if($point->{ts} > time - $window_width) {
                $sum += $point->{value};
                $point_ct++;
            }
        }
        return $self->_bucket_return($bucket_name, 0, $window_width) unless $point_ct;
        return $self->_bucket_return($bucket_name, $sum / $point_ct, $window_width);
    }
    #counter type; just look at the first and last for now
    my @points = @{$self->_bucket_get_points($bucket_name)};
    return $self->_bucket_return($bucket_name, 0, $window_width)
        if (not (scalar @points)) or ((scalar @points) == 1);
    while($points[0] and ($points[0]->{ts} < time - $window_width)) {
        shift @points 
    }
    return $self->_bucket_return($bucket_name, 0, $window_width)
        if (not (scalar @points)) or ((scalar @points) == 1);

    my $time_delta = $points[-1]->{ts} - $points[0]->{ts};
    my $value_delta = $points[-1]->{value} - $points[0]->{value};
    return $self->_bucket_return($bucket_name, 0, $window_width)
        if ($value_delta < 0) or ($time_delta == 0) or ($time_delta < 0);
    return $self->_bucket_return($bucket_name, $value_delta / $time_delta, $window_width);
}

1;
