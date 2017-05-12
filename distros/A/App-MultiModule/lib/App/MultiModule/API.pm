package App::MultiModule::API;
$App::MultiModule::API::VERSION = '1.143160';
use strict;use warnings;
use Data::Dumper;
use Sereal::Encoder qw(encode_sereal);
use Sereal::Decoder qw(looks_like_sereal decode_sereal);


=head2 new

Constructor

=over 4

=item state

Directory path where various run-time files are kept.  Defaults to state/.

=back


=cut
sub new {
    my $class = shift;
    my %args = @_;
    my $debug = $args{debug};
    $debug = 5 unless defined $debug;
    $args{state_dir} = 'state' unless $args{state_dir};
    my $self = {
        state_dir => $args{state_dir},
    };
    bless ($self, $class);

    return $self;
}

=head1 METHODS

=cut
sub _read_file {
    my $self = shift;
    my $filename = shift;
    my %args = @_;
    return undef unless my $state_dir = $self->{state_dir};
    mkdir $state_dir unless -e $state_dir;
    return undef unless -r "$state_dir/$filename";
    my $ret;
    eval {
        my $f;
        die "passed state_dir $state_dir not writable"
            unless -w $state_dir;
        die "passed state_dir $state_dir not a directory"
            unless -d $state_dir;
        my $file_path = "$state_dir/$filename";
        open my $fh, '<', $file_path or die "failed to open $file_path for reading: $!";
        while(<$fh>) {
            $f .= $_;
        }
        close $fh or die "failed to close $file_path: $!";
        if(looks_like_sereal($f)) {
            $ret = decode_sereal $f or die 'returned false';
        } else {
            $ret = do $file_path or die "failed to deserialize $file_path: $@";
        }
    };
    die "App::MultiModule::API::_read_file failed: $@\n" if $@;
    return $ret;
}


sub _write_file {
    my $self = shift;
    my $filename = shift;
    my $contents = shift;
    my %args = @_;
    eval {
        mkdir $self->{state_dir} unless -e $self->{state_dir};
        open my $fh, '>', "$self->{state_dir}/$filename.tmp"
            or die "open failed: $!\n";
#        print $fh Data::Dumper::Dumper $contents or die "print failed: $!\n";
        print $fh encode_sereal $contents or die "print failed: $!\n";
        close $fh or die "close failed: $!\n";
        rename "$self->{state_dir}/$filename.tmp","$self->{state_dir}/$filename" or die "rename failed: $!\n";
    };
    die "App::MultiModule::API::_write_file failed: $@\n" if $@;
}

sub _my_read_file {
    my $path = shift;
    open my $fh, '<', $path or die "failed to open $path: $!\n";
    read $fh, my $ret, 1024000
        or die "failed to read from $path: $!\n";
    close $fh or die "failed to close $path: $!\n";
    return $ret;
}

=head2 get_task_status($task_name)

Returns the saved status

Example:
    status => {
          'is_my_pid' => 0,
          'is_running' => 1,
          'save_ts' => 1370987265,
          'task_count' => 1,
          'fd_count' => 5,
          'cmdline' => '/usr/bin/perlbin/MultiModule-qtqueue-pMultiModuleTest::-oalert:test_alert_queue,this:that-mOtherExternalModule',
          'stat' => '3577 (MultiModule) S 1 13564 19489 34848 13564 4202496 3202 0 0 0 16 3 0 0 20 0 1 0 36033429 71139328 2949 18446744073709551615 4194304 4198756 140735555873936 140735555873176 139685157236755 0 0 4096 16384 18446744071580469929 0 0 17 2 0 0 0 0 0
',
          'pid' => 3577,
          'statm' => '17368 2949 624 2 0 5133 0
    },

=cut
sub get_task_status {
    my $self = shift;
    my $task_name = shift;
    my %args = @_;

    my $status;
    eval {
        $status = $self->_read_file($task_name . '.status')
            or die 'no status';
    };
    if($@) {
        return {
            initial_state => 1,
        };
    }

    my $status_pid; my $status_cmdline;
    eval {
        $status_pid = $status->{pid};
        die "loaded status does not have required attribute 'cmdline'"
            unless $status_cmdline = $status->{cmdline};
        die "loaded status does not have required attribute 'save_ts'"
            unless my $status_save_ts = $status->{save_ts};
    };
    if($@) {
        die "App::MultiModule::API::get_task_status: $@\n" if $@;
    }

    #default the status to 'not running'
    $status->{is_running} = 0;
    $status->{is_my_pid} = 0;
    #what does it take to claim the process in the status file is
    #running
    #1. the PID has to be running
    #2. the cmdline saved in the status file has to match the cmdline running
    if($status_pid) {
        eval {
            my $status_pid_cmdline = _my_read_file("/proc/$status_pid/cmdline");
            chomp $status_cmdline; chomp $status_pid_cmdline;
            die "not running\n" if $status_cmdline ne $status_pid_cmdline;

            $status->{is_running} = 1;
            $status->{is_my_pid} = 1
                if $status_pid == $$;
            $status->{$_} = _my_read_file("/proc/$status_pid/$_")
                for ('stat','statm');
            if(-d "/proc/$status_pid/fd/") {
                eval {
                    opendir my $dh, "/proc/$status_pid/fd/" or die;
                    my @files = grep { not /^\./ } readdir $dh or die;
                    closedir $dh;
                    $status->{fd_count} = scalar @files;
                };
            }
            if(-d "/proc/$status_pid/task/") {
                eval {
                    opendir my $dh, "/proc/$status_pid/task/" or die;
                    my @files = grep { not /^\./ } readdir $dh or die;
                    closedir $dh;
                    $status->{task_count} = scalar @files;
                };
            }
        };
        if($@) {
            #all of these are ignored, because it just means the process isn't
            #running
        }
    }

    return $status;
}

=head2 get_task_config($task_name)

Return the tasks's config.

Example:
    config => {
          'increment_by' => 8427,
          'is_external' => 1
        };
=cut
{
my $time_slice;
my $cache;
sub get_task_config {
    my $self = shift;
    my $task_name = shift;
    my %args = @_;
    if(not $time_slice) {
        $time_slice = {};
        $cache = {};
    }
    $time_slice->{$task_name} = time unless $time_slice->{$task_name};
    if($cache->{$task_name} and $time_slice->{$task_name} == time) {
#        print STDERR "returning cached config for $task_name\n";
        return $cache->{$task_name};
    }
    $time_slice->{$task_name} = time;

    my $config;
    eval {
        $config = $self->_read_file($task_name . '.conf');
    };
#    $self->debug("get_task_config for $task_name failed: $@") if $@;
    print STDERR "get_task_config for $task_name failed: $@\n" if $@;
    $cache->{$task_name} = $config;
    return $config;
}
}

=head2 get_task_state($task_name)

Returns the saved state

Example:
    state =>
          '.multimodule' => {
                              'save_ts' => 1370987685
                            },
          'most_recent' => 10246,
          'sum_increment_by' => 6585

    }

=cut
sub get_task_state {
    my $self = shift;
    my $task_name = shift;
    my %args = @_;

    my $state;
    eval {
        $state = $self->_read_file($task_name . '.state')
            or die 'no state';
    };
    if($@) {
        return {
            '.multimodule' => {
                initial_state => 1,
            },
        };
    }
#    die "App::MultiModule::API::get_task_state failed: $@\n" if $@;

    return $state;
}


=head2 unfailsafe_task($task_name)

Causes a task to no longer be failsafe

=cut
sub unfailsafe_task {
    my $self = shift;
    my $task_name = shift;
    my %args = @_;
    return undef unless my $state_dir = $self->{state_dir};
    my $file = "$state_dir/$task_name.failsafe";
    return 1 unless -e $file;
    unlink $file
        or die "App::MultiModule::API::unfailsafe_task: unable to unlink $file: $!";
    return 1;
}

=head2 failsafe_task($task_name)

Marks a task as failsafed.

=cut
sub failsafe_task {
    my $self = shift;
    my $task_name = shift;
    my $message = shift;
    my %args = @_;
    return undef unless my $state_dir = $self->{state_dir};
    local $SIG{ALRM} = sub { die "timed out\n"; };
    my $file = "$state_dir/$task_name.failsafe";
    alarm 2;
    eval {
        open my $fh, '>', $file
            or die "failed to open $file for writing: $!";
        print $fh Data::Dumper::Dumper $message
            or die "failed to write to $file: $!";
        close $fh
            or die "failed to $file: $!";
    };
    alarm 0;
    die "App::MultiModule::API::failsafe_task: failed: $@" if $@;
    return 1;
}

=head2 task_is_failsafe($task_name)

Returns 'true' if the task is failsafe

=cut
sub task_is_failsafe {
    my $self = shift;
    my $task_name = shift;
    my %args = @_;
    return undef unless my $state_dir = $self->{state_dir};
    return 1 if -e "$state_dir/$task_name.failsafe";
}


=head2 save_task_status($task_name, $status)

Save the task status.

=cut
sub save_task_status {
    my $self = shift;
    my $task_name = shift; my $status = shift;
    my %args = @_;
    $status = {} unless $status;
    if($args{no_save_pid}) {
        delete $status->{pid};
    } else {
        $status->{pid} = $$;
    }
    $status->{save_ts} = time;
    {   open my $fh, '<', "/proc/$$/cmdline";
        read $fh, $status->{cmdline}, 10240;
        close $fh;
    }
    eval {
        $self->_write_file($task_name . '.status', $status);
    };
    print STDERR "save_task_status _write_file call failed: $@\n" if $@;
}

=head2 save_task_state($task_name, $state)

Save the task state.

=cut
sub save_task_state {
    my $self = shift;
    my $task_name = shift;my $state = shift;
    my %args = @_;
    $state->{'.multimodule'} = {} unless $state->{'.multimodule'};
    my $m = $state->{'.multimodule'};
#    if($args{no_save_pid}) {
#        delete $m->{pid};
#    } else {
#        $m->{pid} = $$;
#    }
    $m->{save_ts} = time;
#    {   open my $fh, '<', "/proc/$$/cmdline";
#        read $fh, $m->{cmdline}, 10240;
#        close $fh;
#    }
    eval {
        $self->_write_file($task_name . '.state', $state);
    };
}

=head2 get_task_status_files

Return an array of state files.

=cut
sub get_task_status_files {
    my $self = shift;
    my %args = @_;
    return undef unless my $state_dir = $self->{state_dir};

    my @files = ();
    eval {
        opendir(my $dh, $state_dir) or die "failed to opendir $state_dir: $!";
        foreach my $file (
                grep { not /^\./ and -f "$state_dir/$_" and /\.status$/ }
                readdir($dh)) {
            $file =~ s/\..*//;
            push @files, $file;
        }
        closedir $dh or die "failed to closedir $state_dir: $!\n";
    };
    return @files;
}

=head2 save_task_config($task_name, $config)

Save the task config.

=cut
sub save_task_config {
    my $self = shift;
    my $task_name = shift;my $config = shift;
    my %args = @_;
    eval {
        $self->_write_file($task_name . '.conf', $config);
    };
    #$self->debug("save_task_config for $task_name failed: $@") if $@;
    print STDERR "save_task_config for $task_name failed: $@\n" if $@;
}

=head2 send_signal($task_name, $integer_UNIX_signal)

Send specified signal to task.

=cut
sub send_signal {
    my $self = shift;
    my $task_name = shift; my $signal = shift;
    my %args = @_;
    my $pid;
    eval {
        die "undef\n" unless my $status = $self->get_task_status($task_name);
        die "undef\n" unless $pid = $status->{pid};
        die "undef\n" if $pid == $$;
    };
    print STDERR "$$: send_signal failed: $@\n" if $@;
    return undef if $@;
    return undef unless $pid;
    return kill $signal, $pid;
}



1;
