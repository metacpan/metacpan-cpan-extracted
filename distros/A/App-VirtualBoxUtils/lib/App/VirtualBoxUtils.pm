package App::VirtualBoxUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Hash::Subset qw(hash_subset);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-15'; # DATE
our $DIST = 'App-VirtualBoxUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to VirtualBox',
};

our $default_filter = sub {
    my $p = shift;

    do { $p->{_note} = "fname looks like VirtualBox"; goto FOUND } if $p->{fname} =~ /\A(VirtualBoxVM|VirtualBox|VBoxSVC)\z/;
    goto NOT_FOUND;
  FOUND:
    log_trace "Found VirtualBox process (PID=%d, cmdline=%s, note=%s)", $p->{pid}, $p->{cmndline}, $p->{_note};
    return 1;
  NOT_FOUND:
    0;
};

our $sch_cmd = ['any*', of=>[ ['array*',of=>'str*',min_len=>1], ['str*'] ]];

#our %argopt_cmd = (
#    cmd => {
#        schema => $sch_cmd,
#        default => 'virtualbox',
#    },
#);

our %argsopt_start = (
    start => {
        schema => 'bool*',
    },
);

our %argsopt_restart = (
    restart => {
        schema => 'bool*',
    },
);

our %argopt_users = (
    users => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'user',
        summary => 'Kill VirtualBox processes that belong to certain user(s) only',
        schema => ['array*', of=>'unix::uid::exists*', 'x.perl.coerce_rules' => ['From_str::comma_sep']],
    },
);

our %argopt_quiet = (
    quiet => {
        schema => 'true*',
        cmdline_aliases => {q=>{}},
    },
);

our %argopt_signal = (
    signal => {
        schema=>'unix::signal*',
        cmdline_aliases => {s=>{}},
    },
);

our %argopt_periods = (
    periods => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'period',
        summary => 'Pause and unpause times, in seconds',
        schema => ['array*', {
            of=>'duration',
            min_len=>2,
            #'x.perl.coerce_rules'=>['From_str::comma_sep'], # not working yet
        }],
        description => <<'MARKDOWN',

For example, to pause for 5 minutes, then unpause 10 seconds, then pause for 2
minutes, then unpause for 30 seconds (then repeat the pattern), you can use:

    300,10,120,30

MARKDOWN
    },
);

my $desc_pat = <<'MARKDOWN';

If one of the `*-pat` options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these `*-pat` options are
solely used to determine which processes are the VirtualBox processes.

MARKDOWN

my %argopt_cmndline_pat = (
    cmndline_pat => {
        summary => 'Filter processes using regex against their cmndline',
        schema => 're_from_str*',
        description => $desc_pat,
        tags => ['category:filtering'],
    },
);

my %argopt_exec_pat = (
    exec_pat => {
        summary => 'Filter processes using regex against their exec',
        schema => 're_from_str*',
        description => $desc_pat,
        tags => ['category:filtering'],
    },
);

my %argopt_fname_pat = (
    fname_pat => {
        summary => 'Filter processes using regex against their fname',
        schema => 're_from_str*',
        description => $desc_pat,
        tags => ['category:filtering'],
    },
);

my %argopt_pid_pat = (
    pid_pat => {
        summary => 'Filter processes using regex against their pid',
        schema => 're_from_str*',
        description => $desc_pat,
        tags => ['category:filtering'],
    },
);

our %args_common = (
    %argopt_users,
    %argopt_cmndline_pat,
    %argopt_exec_pat,
    %argopt_fname_pat,
    %argopt_pid_pat,
);

our $desc_pause = <<'MARKDOWN';

MARKDOWN

our $desc_pause_and_unpause = $desc_pause . <<'MARKDOWN';
The `pause-and-unpause` action pause and unpause VirtualBox in an alternate
fashion, by default every 5 minutes and 30 seconds. This is a compromise to save
CPU time most of the time.

If you run this routine, it will start pausing and unpausing VirtualBox. When
you want to use the VirtualBox, press Ctrl-C to interrupt the routine. Then
after you are done with the virtual machines and want to pause-and-unpause
again, you can re-run this routine.

You can customize the periods via the `periods` option.

MARKDOWN

sub _do_virtualbox {
    require Proc::Find;

    my ($which_action, %args) = @_;

    my @periods = @{ $args{periods} // [300,30] };
    my @stopped_pids;
    my $period_idx = -1;

    local $SIG{INT} = sub {
        if (@stopped_pids) {
            log_info "Unpausing stopped PID(s) ...";
            kill CONT => @stopped_pids;
        }
        log_info "Exiting ...";
        exit 0;
    };

    my $filter = (defined $args{cmndline_pat} || defined $args{exec_pat} || defined $args{fname_pat} || defined $args{pid_pat}) ? sub {
        my $p = shift;
        no warnings 'uninitialized';
        for my $f (qw(cmndline exec fname pid)) {
            if (defined $args{"${f}_pat"}) {
                if ($p->{$f} =~ /$args{"${f}_pat"}/) {
                    log_trace "Process %s '%s' matches pattern '%s'", $f, $p->{$f}, $args{"${f}_pat"};
                } else {
                    log_trace "Process %s '%s' does NOT match pattern '%s'", $f, $p->{$f}, $args{"${f}_pat"};
                    return 0;
                }
            }
        }
        1;
    } : $default_filter;

    while (1) {
        my $procs = Proc::Find::find_proc(
            detail => 1,
            filter => $filter,
        );

        my @pids = map { $_->{pid} } @$procs;

        if ($which_action eq 'ps') {
            if ($args{-cmdline_r} && (!defined($args{-cmdline_r}{format}) ||
                                      $args{-cmdline_r}{format} =~ /text/)) {
                # convert arrayrefs etc so the result can still be rendered as
                # simple 2d table
                for my $proc (@$procs) {
                    # too big
                    delete $proc->{environ};
                    delete $proc->{cmndline}; # duplicate info with cmdline

                    for my $key (keys %$proc) {
                        $proc->{$key} = join(" ", @{ $proc->{$key} })
                            if ref $proc->{$key} eq 'ARRAY';
                    }
                }
            }
            return [200, "OK", $procs, {'table.fields'=>[qw/pid uid euid state cmdline/]}];
        } elsif ($which_action eq 'pause') {
            kill STOP => @pids;
            return [200, "OK", "", {"func.pids" => \@pids}];
        } elsif ($which_action eq 'unpause') {
            kill CONT => @pids;
            return [200, "OK", "", {"func.pids" => \@pids}];
        } elsif ($which_action eq 'terminate') {
            my $signal;
            if (defined $args{signal}) {
                log_info "Sending %s signal to VirtualBox ...", $args{signal};
                $signal = $args{signal};
            } else {
                log_info "Terminating VirtualBox ...";
                $signal = 'KILL';
            }
            kill $signal => @pids;
            return [200, "OK", "", {"func.pids" => \@pids}];
        } elsif ($which_action eq 'has_processes' || $which_action eq 'is_paused' || $which_action eq 'is_running') {
            my $num_stopped = 0;
            my $num_unstopped = 0;
            my $num_total = 0;
            for my $proc (@$procs) {
                $num_total++;
                if ($proc->{state} eq 'stop') { $num_stopped++ } else { $num_unstopped++ }
            }
            if ($which_action eq 'has_processes') {
                my $has_processes = $num_total > 0 ? 1:0;
                my $msg = $has_processes ? "VirtualBox has processes" : "VirtualBox does NOT have processes";
                return [200, "OK", $has_processes, {
                    "cmdline.exit_code" => $has_processes ? 0:1,
                    "cmdline.result" => $args{quiet} ? '' : $msg,
                }];
            } elsif ($which_action eq 'is_paused') {
                my $is_paused  = $num_total == 0 ? undef : $num_stopped == $num_total ? 1 : 0;
                my $msg = $num_total == 0 ? "There are NO VirtualBox processes" :
                    $num_stopped   == $num_total ? "VirtualBox is paused (all processes are in stop state)" :
                    $num_unstopped == $num_total ? "VirtualBox is NOT paused (all processes are not in stop state)" :
                    "VirtualBox is NOT paused (some processes are not in stop state)";
                return [200, "OK", $is_paused, {
                    'cmdline.exit_code' => $is_paused ? 0:1,
                    'cmdline.result' => $args{quiet} ? '' : $msg,
                }];
            } else {
                my $is_running = $num_total == 0 ? undef : $num_unstopped > 0 ? 1 : 0;
                my $msg = $num_total == 0 ? "There are NO VirtualBox processes" :
                    $num_unstopped > 0 ? "VirtualBox is running (some processes are not in stop state)" :
                    "VirtualBox exists but is NOT running (all processes are in stop state)";
                return [200, "OK", $is_running, {
                    'cmdline.exit_code' => $is_running ? 0:1,
                    'cmdline.result' => $args{quiet} ? '' : $msg,
                }];
            }
        } elsif ($which_action eq 'pause_and_unpause') {
            $period_idx++;
            $period_idx = 0 if $period_idx >= @periods;
            my $period = $periods[$period_idx];
            if ($period_idx == 0) {
                log_info "Pausing VirtualBox for $period second(s) ...";
                kill STOP => @pids;
                @stopped_pids = @pids;
            } else {
                log_info "Unpausing VirtualBox for $period second(s) ...";
                kill CONT => @stopped_pids;
                @stopped_pids = ();
            }
            sleep $period;
        } else {
            die "BUG: unknown command";
        }
    } # while 1
}

$SPEC{ps_virtualbox} = {
    v => 1.1,
    summary => "List VirtualBox processes",
    args => {
        %args_common,
    },
};
sub ps_virtualbox {
    _do_virtualbox('ps', @_);
}

$SPEC{pause_virtualbox} = {
    v => 1.1,
    summary => "Pause (kill -STOP) VirtualBox",
    description => $desc_pause .
    "See also the `unpause_virtualbox` and the `pause_and_unpause_virtualbox` routines.\n\n",
    args => {
        %args_common,
    },
};
sub pause_virtualbox {
    _do_virtualbox('pause', @_);
}

$SPEC{unpause_virtualbox} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) VirtualBox",
    description => <<'MARKDOWN',

See also the `pause_virtualbox` and the `pause_and_unpause_virtualbox` routines.

MARKDOWN
    args => {
        %args_common,
    },
};
sub unpause_virtualbox {
    _do_virtualbox('unpause', @_);
}

$SPEC{pause_and_unpause_virtualbox} = {
    v => 1.1,
    summary => "Pause and unpause VirtualBox alternately",
    description => $desc_pause_and_unpause .
    "See also the separate `pause_virtualbox` and the `unpause_virtualbox` routines.\n\n",
    args => {
        %args_common,
        %argopt_periods,
    },
};
sub pause_and_unpause_virtualbox {
    _do_virtualbox('pause_and_unpause', @_);
}

$SPEC{virtualbox_is_paused} = {
    v => 1.1,
    summary => "Check whether VirtualBox is paused",
    description => <<'MARKDOWN',

VirtualBox is defined as paused if *all* of its processes are in 'stop' state.

MARKDOWN
    args => {
        %args_common,
        %argopt_quiet,
    },
};
sub virtualbox_is_paused {
    my %args = @_;

    my $has_processes;

    my $res = _do_virtualbox('is_paused', %args);
    return $res unless $res->[0] == 200;
    return $res if defined $res->[2] && !$res->[2];
    $has_processes++ if defined $res->[2];

    my $msg = !$has_processes ? "There are no VirtualBox processes" :
        "VirtualBox is paused (all processes are in stop state)";
    return [200, "OK", 1, {
        'cmdline.exit_code' => 0,
        'cmdline.result' => $args{quiet} ? '' : $msg,
    }];
}

$SPEC{terminate_virtualbox} = {
    v => 1.1,
    summary => "Terminate VirtualBox (by default with -KILL)",
    args => {
        %args_common,
        %argopt_signal,
    },
};
sub terminate_virtualbox {
    _do_virtualbox('terminate', @_);
}

# sub _start_or_restart_browsers {
#     require Capture::Tiny;
#     require Proc::Background;

#     my ($which_action, %args) = @_;
#     my %pbs; # key=browser name, val=Proc::Background objects
#     my %outputs; # key=browser name, val=output

#     my %started;       # key=browser name, val=1
#     my %fail;          # key=browser name, val=reason
#     my %has_processes; # key=browser name, val=1
#     my %terminated;    # key=browser name, val=1

#     my $num_start_requests = 0;
#     for my $browser (sort keys %browsers) {
#         next if $which_action eq 'start'   && !$args{"start_$browser"};
#         next if $which_action eq 'restart' && !$args{"restart_$browser"};
#         $num_start_requests++;

#         # TODO: cache? we are running ps once for each browser
#         #log_trace "Checking whether $browser has processes ...";
#         my $res_hp = _do_browser('has_processes', $browser, users=>[$>]);
#         if ($res_hp->[0] != 200) {
#             log_error "Can't check whether $browser has processes: $res_hp->[0] - $res_hp->[1], skipped";
#             $fail{$browser} //= "Can't check for processes";
#             next;
#         }
#         my $has_processes = $res_hp->[2];
#         if ($which_action eq 'start') {
#             if ($has_processes) {
#                 $has_processes{$browser}++;
#                 next;
#             }
#         } else { # restart
#             my $res_term;
#           TERMINATE: {
#                 last unless $has_processes;
#                 if ($args{-dry_run}) {
#                     log_info "[DRY] Terminating $browser ...";
#                     $terminated{$browser}++;
#                     last;
#                 }

#                 $res_term = _do_browser('terminate', $browser, users=>[$>]);
#                 if ($res_term->[0] != 200) {
#                     log_error "Can't terminate $browser: $res_term->[0] - $res_term->[1], skipped";
#                     $fail{$browser} //= "Can't terminate";
#                     next;
#                 }

#                 sleep 3;

#                 $res_hp = _do_browser('has_processes', $browser, users=>[$>]);
#                 if ($res_hp->[0] != 200) {
#                     log_error "Can't check whether $browser has processes (after terminatign): $res_hp->[0] - $res_hp->[1], skipped";
#                     $fail{$browser} //= "Can't check for processes (after terminating)";
#                     next;
#                 }
#                 $has_processes = $res_hp->[2];
#                 if ($has_processes) {
#                     log_error "$browser still has processes after terminating, skipped";
#                     $fail{$browser} //= "Still has process after terminating";
#                     next;
#                 }
#                 $terminated{$browser}++;
#             } # TERMINATE
#         }

#       START: {
#             my $cmd = $args{"${browser}_cmd"} //
#                 $argsopt_browser_start{"${browser}_cmd"}{default};

#             if ($args{-dry_run}) {
#                 log_info "[DRY] Starting %s (cmd: %s) ...", $browser, $cmd;
#                 $started{$browser}++;
#                 last;
#             }

#             log_info "Starting %s (cmd: %s) ...", $browser, $cmd;
#             $outputs{$browser} = Capture::Tiny::capture_merged(
#                 sub { $pbs{$browser} = Proc::Background->new($cmd) });
#             $started{$browser}++;
#         }
#     }

#     my $num_started = keys %started;
#     if ($num_started == 0) {
#         return [304,
#                 $num_start_requests ? "All browsers already have processes" :
#                     "Not ${which_action}ing any browsers"];
#     }

#     my (%alive, %not_alive);
#     if ($args{-dry_run}) {
#         %alive = %started;
#     } else {
#         for my $wait_time (2, 5, 10) {
#             %alive = ();
#             %not_alive = ();
#             log_trace "Checking if the started browsers are alive ...";
#             for my $browser (keys %pbs) {
#                 if ($pbs{$browser}->alive) {
#                     $alive{$browser}++;
#                 } else {
#                     $not_alive{$browser}++;
#                 }
#             }
#             last if scalar(keys %alive) == $num_started;
#         }
#     }

#     my $num_alive = keys %alive;
#     my $num_not_alive = keys %not_alive;

#     my $status;
#     my $reason;
#     my $msg;
#     my $verb_started = $which_action eq 'restart' ? 'Started/restarted' : 'Started';
#     if ($num_alive == $num_started) {
#         $status = 200;
#         $reason = "OK";
#         $msg = "$verb_started ".join(", ", sort keys %alive);
#     } elsif ($num_alive == 0) {
#         $status = 500;
#         $reason = $msg = "Can't start any browser (".join(", ", %not_alive).")";
#     } else {
#         $status = 200;
#         $reason = "OK";
#         $msg = "$verb_started ".join(", ", sort keys %alive)."; but failed to start ".
#             join(", ", sort keys %not_alive);
#     }

#     $fail{$_} //= "Can't start" for keys %not_alive;

#     [$status, $msg, undef, {
#         'func.outputs' => \%outputs,
#         ($which_action eq 'start' ? ('func.has_processes' => [sort keys %has_processes]) : ()),
#         'func.started' => [sort grep {!$terminated{$_}} keys %alive],
#         ($which_action eq 'restart' ? ('func.restarted' => [sort grep {$terminated{$_}} keys %alive]) : ()),
#         'func.fail' => [sort keys %fail],
#     }];
# }

# $SPEC{start_browsers} = {
#     v => 1.1,
#     summary => "Start browsers",
#     description => <<'MARKDOWN',

# For each of the requested browser, check whether browser processes (that run as
# the current user) exist and if not then start the browser. If browser processes
# exist, even if all are paused, then no new instance of the browser will be
# started.

# when starting each browser, console output will be captured and returned in
# function metadata. Will wait for 2/5/10 seconds and check if the browsers have
# been started. If all browsers can't be started, will return 500; otherwise will
# return 200 but report the browsers that failed to start to the STDERR.

# Example on the CLI:

#     % start-browsers --start-firefox

# To customize command to use to start:

#     % start-browsers --start-firefox --firefox-cmd 'firefox -P myprofile'

# MARKDOWN
#     args => {
#         # args_common is not relevant here, for now (unless we want to start
#         # browsers as other users)

#         %argsopt_start,
#         %argsopt_cmd,
#         %argopt_quiet,
#     },
#     features => {
#         dry_run => 1,
#     },
# };
# sub start_browsers {
#     _start_or_restart_browsers('start', @_);
# }

# $SPEC{restart_browsers} = {
#     v => 1.1,
#     summary => "Restart browsers",
#     description => <<'MARKDOWN',

# For each of the requested browser, first check whether browser processes (that
# run the current user) exist. If they do then terminate the browser first. After
# that, start the browser again.

# Example on the CLI:

#     % restart-browsers --restart-firefox

# To customize command:

#     % restart-browsers --start-firefox --firefox-cmd 'firefox -P myprofile'

# when starting each browser, console output will be captured and returned in
# function metadata. Will wait for 2/5/10 seconds and check if the browsers have
# been started. If all browsers can't be started, will return 500; otherwise will
# return 200 but report the browsers that failed to start to the STDERR.

# MARKDOWN
#     args => {
#         # args_common is not relevant here, for now (unless we want to start
#         # browsers as other users)

#         %argsopt_browser_restart,
#         %argsopt_browser_cmd,
#         %argopt_quiet,
#     },
#     features => {
#         dry_run => 1,
#     },
# };
# sub restart_browsers {
#     _start_or_restart_browsers('restart', @_);
# }

1;
# ABSTRACT: Utilities related to VirtualBox

__END__

=pod

=encoding UTF-8

=head1 NAME

App::VirtualBoxUtils - Utilities related to VirtualBox

=head1 VERSION

This document describes version 0.001 of App::VirtualBoxUtils (from Perl distribution App-VirtualBoxUtils), released on 2024-11-15.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to VirtualBox:

=over

=item 1. L<kill-virtualbox>

=item 2. L<pause-and-unpause-virtualbox>

=item 3. L<pause-virtualbox>

=item 4. L<ps-virtualbox>

=item 5. L<terminate-virtualbox>

=item 6. L<unpause-virtualbox>

=item 7. L<virtualbox-is-paused>

=back

=head1 FUNCTIONS


=head2 pause_and_unpause_virtualbox

Usage:

 pause_and_unpause_virtualbox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause and unpause VirtualBox alternately.

The C<pause-and-unpause> action pause and unpause VirtualBox in an alternate
fashion, by default every 5 minutes and 30 seconds. This is a compromise to save
CPU time most of the time.

If you run this routine, it will start pausing and unpausing VirtualBox. When
you want to use the VirtualBox, press Ctrl-C to interrupt the routine. Then
after you are done with the virtual machines and want to pause-and-unpause
again, you can re-run this routine.

You can customize the periods via the C<periods> option.

See also the separate C<pause_virtualbox> and the C<unpause_virtualbox> routines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<periods> => I<array[duration]>

Pause and unpause times, in seconds.

For example, to pause for 5 minutes, then unpause 10 seconds, then pause for 2
minutes, then unpause for 30 seconds (then repeat the pattern), you can use:

 300,10,120,30

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<users> => I<array[unix::uid::exists]>

Kill VirtualBox processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pause_virtualbox

Usage:

 pause_virtualbox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause (kill -STOP) VirtualBox.

See also the C<unpause_virtualbox> and the C<pause_and_unpause_virtualbox> routines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<users> => I<array[unix::uid::exists]>

Kill VirtualBox processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 ps_virtualbox

Usage:

 ps_virtualbox(%args) -> [$status_code, $reason, $payload, \%result_meta]

List VirtualBox processes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<users> => I<array[unix::uid::exists]>

Kill VirtualBox processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 terminate_virtualbox

Usage:

 terminate_virtualbox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Terminate VirtualBox (by default with -KILL).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<signal> => I<unix::signal>

(No description)

=item * B<users> => I<array[unix::uid::exists]>

Kill VirtualBox processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 unpause_virtualbox

Usage:

 unpause_virtualbox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Unpause (resume, continue, kill -CONT) VirtualBox.

See also the C<pause_virtualbox> and the C<pause_and_unpause_virtualbox> routines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<users> => I<array[unix::uid::exists]>

Kill VirtualBox processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 virtualbox_is_paused

Usage:

 virtualbox_is_paused(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether VirtualBox is paused.

VirtualBox is defined as paused if I<all> of its processes are in 'stop' state.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the VirtualBox processes, these C<*-pat> options are
solely used to determine which processes are the VirtualBox processes.

=item * B<quiet> => I<true>

(No description)

=item * B<users> => I<array[unix::uid::exists]>

Kill VirtualBox processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-VirtualBoxUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-VirtualBoxUtils>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-VirtualBoxUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
