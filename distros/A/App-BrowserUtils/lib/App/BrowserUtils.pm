package App::BrowserUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Hash::Subset qw(hash_subset);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-27'; # DATE
our $DIST = 'App-BrowserUtils'; # DIST
our $VERSION = '0.015'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to browsers, particularly modern GUI ones',
};

our %browsers = (
    firefox => {
        filter => sub {
            my $p = shift;

            # when firefox is upgraded while an instance is still running, the
            # exec field becomes empty and we need to use cmndline
            my $prog = $p->{exec} || $p->{cmndline};

            # in some OS like linux the binary is firefox-bin, while in some
            # other like FreeBSD, it's firefox.
            do { $p->{_note} = "program is firefox or firefox-bin"; goto FOUND } if $prog =~ m![/\\](firefox-bin|firefox)(\z|\s)!;
            do { $p->{_note} = "fname looks like firefox"; goto FOUND } if $p->{fname} =~ /\A(Web Content|WebExtensions|firefox-bin|firefox)\z/;
            goto NOT_FOUND;
          FOUND:
            log_trace "Found firefox process (PID=%d, prog (exec|cmndline)=%s, note=%s)", $p->{pid}, $prog, $p->{_note};
            return 1;
          NOT_FOUND:
            0;
        },
    },
    chrome => {
        filter => sub {
            my $p = shift;
            do { $p->{_note} = "fname looks like chrome"; goto FOUND } if $p->{fname} =~ /\A(chrome)\z/;
            goto NOT_FOUND;
          FOUND:
            log_trace "Found chrome process (PID=%d, cmdline=%s, note=%s)", $p->{pid}, $p->{cmndline}, $p->{_note};
            return 1;
          NOT_FOUND:
            0;
        },
    },
    opera => {
        filter => sub {
            my $p = shift;
            do { $p->{_note} = "fname looks like opera"; goto FOUND } if $p->{fname} =~ /\A(opera)\z/;
            goto NOT_FOUND;
          FOUND:
            log_trace "Found opera process (PID=%d, cmdline=%s, note=%s)", $p->{pid}, $p->{cmndline}, $p->{_note};
            return 1;
          NOT_FOUND:
            0;
        },
    },
    vivaldi => {
        filter => sub {
            my $p = shift;
            do { $p->{_note} = "fname looks like vivaldi"; goto FOUND } if $p->{fname} =~ /\A(vivaldi-bin)\z/;
            goto NOT_FOUND;
          FOUND:
            log_trace "Found vivaldi process (PID=%d, cmdline=%s, note=%s)", $p->{pid}, $p->{cmndline}, $p->{_note};
            return 1;
          NOT_FOUND:
            0;
        },
    },
);

our $sch_cmd = ['any*', of=>[ ['array*',of=>'str*',min_len=>1], ['str*'] ]];

our %argopt_firefox_cmd = (
    firefox_cmd => {
        schema => $sch_cmd,
        default => 'firefox',
    },
);

our %argopt_chrome_cmd = (
    chrome_cmd => {
        schema => $sch_cmd,
        default => 'google-chrome',
    },
);

our %argopt_opera_cmd = (
    opera_cmd => {
        schema => $sch_cmd,
        default => 'opera',
    },
);

our %argopt_vivaldi_cmd = (
    vivaldi_cmd => {
        schema => $sch_cmd,
        default => 'vivaldi',
    },
);

our %argsopt_browser_cmd = (
    %argopt_firefox_cmd,
    %argopt_chrome_cmd,
    %argopt_opera_cmd,
    %argopt_vivaldi_cmd,
);

our %argsopt_browser_start = (
    start_firefox => {
        schema => 'bool*',
    },
    start_chrome => {
        schema => 'bool*',
    },
    start_opera => {
        schema => 'bool*',
    },
    start_vivaldi => {
        schema => 'bool*',
    },
);

our %argsopt_browser_restart = (
    restart_firefox => {
        schema => 'bool*',
    },
    restart_chrome => {
        schema => 'bool*',
    },
    restart_opera => {
        schema => 'bool*',
    },
    restart_vivaldi => {
        schema => 'bool*',
    },
);

our %argopt_users = (
    users => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'user',
        summary => 'Kill browser processes that belong to certain user(s) only',
        schema => ['array*', of=>'unix::local_uid*', 'x.perl.coerce_rules' => ['From_str::comma_sep']],
    },
);

our %argopt_quiet = (
    quiet => {
        schema => 'true*',
        cmdline_aliases => {q=>{}},
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
        description => <<'_',

For example, to pause for 5 minutes, then unpause 10 seconds, then pause for 2
minutes, then unpause for 30 seconds (then repeat the pattern), you can use:

    300,10,120,30

_
    },
);

our %args_common = (
    %argopt_users,
);

our $desc_pause = <<'_';

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they only run in the background. Pausing
(kill -STOP) the browser processes is a simple and effective way to stop CPU
eating on Unix and prolong your laptop battery life. It can be performed
whenever you are not using your browser for a little while, e.g. when you are
typing on an editor or watching a movie. When you want to use your browser
again, simply unpause (kill -CONT) it.

_

our $desc_pause_and_unpause = $desc_pause . <<'_';
The `pause-and-unpause` action pause and unpause browser in an alternate
fashion, by default every 5 minutes and 30 seconds. This is a compromise to save
CPU time most of the time but then give time for web applications in the browser
to catch up during the unpause window (e.g. for WhatsApp Web to display new
messages and sound notification.) It can be used when you are not browsing but
still want to be notified by web applications from time to time.

If you run this routine, it will start pausing and unpausing browser. When you
want to use the browser, press Ctrl-C to interrupt the routine. Then after you
are done with the browser and want to pause-and-unpause again, you can re-run
this routine.

You can customize the periods via the `periods` option.

_

sub _do_browser {
    require Proc::Find;

    my ($which_action, $which_browser, %args) = @_;

    my $browser_fname_pat = ($which_browser eq 'all known browsers' || $browsers{$which_browser}{filter})
        or return [400, "Unknown browser '$which_browser'"];

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

    my $filter = $which_browser eq 'all known browsers' ? sub {
        for my $br (keys %browsers) {
            return 1 if $browsers{$br}{filter}->(@_);
        }
        0;
    } : $browsers{$which_browser}{filter};

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
            log_info "Terminating $which_browser ...";
            kill KILL => @pids;
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
                my $msg = $has_processes ? "$which_browser has processes" : "$which_browser does NOT have processes";
                return [200, "OK", $has_processes, {
                    "cmdline.exit_code" => $has_processes ? 0:1,
                    "cmdline.result" => $args{quiet} ? '' : $msg,
                }];
            } elsif ($which_action eq 'is_paused') {
                my $is_paused  = $num_total == 0 ? undef : $num_stopped == $num_total ? 1 : 0;
                my $msg = $num_total == 0 ? "There are NO $which_browser processes" :
                    $num_stopped   == $num_total ? "$which_browser is paused (all processes are in stop state)" :
                    $num_unstopped == $num_total ? "$which_browser is NOT paused (all processes are not in stop state)" :
                    "$which_browser is NOT paused (some processes are not in stop state)";
                return [200, "OK", $is_paused, {
                    'cmdline.exit_code' => $is_paused ? 0:1,
                    'cmdline.result' => $args{quiet} ? '' : $msg,
                }];
            } else {
                my $is_running = $num_total == 0 ? undef : $num_unstopped > 0 ? 1 : 0;
                my $msg = $num_total == 0 ? "There are NO $which_browser processes" :
                    $num_unstopped > 0 ? "$which_browser is running (some processes are not in stop state)" :
                    "$which_browser exists but is NOT running (all processes are in stop state)";
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
                log_info "Pausing $which_browser for $period second(s) ...";
                kill STOP => @pids;
                @stopped_pids = @pids;
            } else {
                log_info "Unpausing $which_browser for $period second(s) ...";
                kill CONT => @stopped_pids;
                @stopped_pids = ();
            }
            sleep $period;
        } else {
            die "BUG: unknown command";
        }
    } # while 1
}

$SPEC{ps_browsers} = {
    v => 1.1,
    summary => "List browser processes",
    args => {
        %args_common,
    },
};
sub ps_browsers {
    my %args = @_;

    my @rows;
    for my $browser (sort keys %browsers) {
        my $res = _do_browser('ps', $browser, %args);
        return $res unless $res->[0] == 200;
        push @rows, @{$res->[2]}; # XXX remove duplicate?
    }
    [200, "OK", \@rows];
}

$SPEC{pause_browsers} = {
    v => 1.1,
    summary => "Pause (kill -STOP) browsers",
    description => $desc_pause .
    "See also the `unpause_browsers` and the `pause_and_unpause_browsers` routines.\n\n",
    args => {
        %args_common,
    },
};
sub pause_browsers {
    my %args = @_;

    my @pids;
    for my $browser (sort keys %browsers) {
        my $res = _do_browser('pause', $browser, %args);
        return $res unless $res->[0] == 200;
        push @pids, @{$res->[3]{'func.pids'}};
    }
    [200, "OK", undef, {"func.pids" => \@pids}];
}

$SPEC{unpause_browsers} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) browsers",
    description => <<'_',

See also the `pause_browsers` and the `pause_and_unpause_browsers` routines.

_
    args => {
        %args_common,
    },
};
sub unpause_browsers {
    my %args = @_;

    my @pids;
    for my $browser (sort keys %browsers) {
        my $res = _do_browser('unpause', $browser, %args);
        return $res unless $res->[0] == 200;
        push @pids, @{$res->[3]{'func.pids'}};
    }
    [200, "OK", undef, {"func.pids" => \@pids}];
}

$SPEC{pause_and_unpause_browsers} = {
    v => 1.1,
    summary => "Pause and unpause browsers alternately",
    description => $desc_pause_and_unpause .
    "See also the separate `pause_browsers` and the `unpause_browsers` routines.\n\n",
    args => {
        %args_common,
        %argopt_periods,
    },
};
sub pause_and_unpause_browsers {
    my %args = @_;

    _do_browser('pause_and_unpause', 'all known browsers', %args);
}

$SPEC{browsers_are_paused} = {
    v => 1.1,
    summary => "Check whether browsers are paused",
    description => <<'_',

Browser is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %args_common,
        %argopt_quiet,
    },
};
sub browsers_are_paused {
    my %args = @_;

    my $has_processes = 0;
    for my $browser (sort keys %browsers) {
        my $res = _do_browser('is_paused', $browser, %args);
        return $res unless $res->[0] == 200;
        return $res if defined $res->[2] && !$res->[2];
        $has_processes++ if defined $res->[2];
    }
    my $msg = !$has_processes ? "There are no browser processes" :
        "Browsers are paused (all processes are in stop state)";
    return [200, "OK", 1, {
        'cmdline.exit_code' => 0,
        'cmdline.result' => $args{quiet} ? '' : $msg,
    }];
}

$SPEC{terminate_browsers} = {
    v => 1.1,
    summary => "Terminate (kill -KILL) browsers",
    args => {
        %args_common,
    },
};
sub terminate_browsers {
    my %args = @_;

    my @pids;
    for my $browser (sort keys %browsers) {
        my $res = _do_browser('terminate', $browser, %args);
        return $res unless $res->[0] == 200;
        push @pids, @{$res->[3]{'func.pids'}};
    }
    [200, "OK", undef, {"func.pids" => \@pids}];
}

sub _start_or_restart_browsers {
    require Capture::Tiny;
    require Proc::Background;

    my ($which_action, %args) = @_;
    my %pbs; # key=browser name, val=Proc::Background objects
    my %outputs; # key=browser name, val=output

    my %started;       # key=browser name, val=1
    my %fail;          # key=browser name, val=reason
    my %has_processes; # key=browser name, val=1
    my %terminated;    # key=browser name, val=1

    my $num_start_requests = 0;
    for my $browser (sort keys %browsers) {
        next if $which_action eq 'start'   && !$args{"start_$browser"};
        next if $which_action eq 'restart' && !$args{"restart_$browser"};
        $num_start_requests++;

        # TODO: cache? we are running ps once for each browser
        #log_trace "Checking whether $browser has processes ...";
        my $res_hp = _do_browser('has_processes', $browser, users=>[$>]);
        if ($res_hp->[0] != 200) {
            log_error "Can't check whether $browser has processes: $res_hp->[0] - $res_hp->[1], skipped";
            $fail{$browser} //= "Can't check for processes";
            next;
        }
        my $has_processes = $res_hp->[2];
        if ($which_action eq 'start') {
            if ($has_processes) {
                $has_processes{$browser}++;
                next;
            }
        } else { # restart
            my $res_term;
          TERMINATE: {
                last unless $has_processes;
                if ($args{-dry_run}) {
                    log_info "[DRY] Terminating $browser ...";
                    $terminated{$browser}++;
                    last;
                }

                $res_term = _do_browser('terminate', $browser, users=>[$>]);
                if ($res_term->[0] != 200) {
                    log_error "Can't terminate $browser: $res_term->[0] - $res_term->[1], skipped";
                    $fail{$browser} //= "Can't terminate";
                    next;
                }

                sleep 3;

                $res_hp = _do_browser('has_processes', $browser, users=>[$>]);
                if ($res_hp->[0] != 200) {
                    log_error "Can't check whether $browser has processes (after terminatign): $res_hp->[0] - $res_hp->[1], skipped";
                    $fail{$browser} //= "Can't check for processes (after terminating)";
                    next;
                }
                $has_processes = $res_hp->[2];
                if ($has_processes) {
                    log_error "$browser still has processes after terminating, skipped";
                    $fail{$browser} //= "Still has process after terminating";
                    next;
                }
                $terminated{$browser}++;
            } # TERMINATE
        }

      START: {
            my $cmd = $args{"${browser}_cmd"} //
                $argsopt_browser_start{"${browser}_cmd"}{default};

            if ($args{-dry_run}) {
                log_info "[DRY] Starting %s (cmd: %s) ...", $browser, $cmd;
                $started{$browser}++;
                last;
            }

            log_info "Starting %s (cmd: %s) ...", $browser, $cmd;
            $outputs{$browser} = Capture::Tiny::capture_merged(
                sub { $pbs{$browser} = Proc::Background->new($cmd) });
            $started{$browser}++;
        }
    }

    my $num_started = keys %started;
    if ($num_started == 0) {
        return [304,
                $num_start_requests ? "All browsers already have processes" :
                    "Not ${which_action}ing any browsers"];
    }

    my (%alive, %not_alive);
    if ($args{-dry_run}) {
        %alive = %started;
    } else {
        for my $wait_time (2, 5, 10) {
            %alive = ();
            %not_alive = ();
            log_trace "Checking if the started browsers are alive ...";
            for my $browser (keys %pbs) {
                if ($pbs{$browser}->alive) {
                    $alive{$browser}++;
                } else {
                    $not_alive{$browser}++;
                }
            }
            last if scalar(keys %alive) == $num_started;
        }
    }

    my $num_alive = keys %alive;
    my $num_not_alive = keys %not_alive;

    my $status;
    my $reason;
    my $msg;
    my $verb_started = $which_action eq 'restart' ? 'Started/restarted' : 'Started';
    if ($num_alive == $num_started) {
        $status = 200;
        $reason = "OK";
        $msg = "$verb_started ".join(", ", sort keys %alive);
    } elsif ($num_alive == 0) {
        $status = 500;
        $reason = $msg = "Can't start any browser (".join(", ", %not_alive).")";
    } else {
        $status = 200;
        $reason = "OK";
        $msg = "$verb_started ".join(", ", sort keys %alive)."; but failed to start ".
            join(", ", sort keys %not_alive);
    }

    $fail{$_} //= "Can't start" for keys %not_alive;

    [$status, $msg, undef, {
        'func.outputs' => \%outputs,
        ($which_action eq 'start' ? ('func.has_processes' => [sort keys %has_processes]) : ()),
        'func.started' => [sort grep {!$terminated{$_}} keys %alive],
        ($which_action eq 'restart' ? ('func.restarted' => [sort grep {$terminated{$_}} keys %alive]) : ()),
        'func.fail' => [sort keys %fail],
    }];
}

$SPEC{start_browsers} = {
    v => 1.1,
    summary => "Start browsers",
    description => <<'_',

For each of the requested browser, check whether browser processes (that run as
the current user) exist and if not then start the browser. If browser processes
exist, even if all are paused, then no new instance of the browser will be
started.

when starting each browser, console output will be captured and returned in
function metadata. Will wait for 2/5/10 seconds and check if the browsers have
been started. If all browsers can't be started, will return 500; otherwise will
return 200 but report the browsers that failed to start to the STDERR.

Example on the CLI:

    % start-browsers --start-firefox

To customize command to use to start:

    % start-browsers --start-firefox --firefox-cmd 'firefox -P myprofile'


_
    args => {
        # args_common is not relevant here, for now (unless we want to start
        # browsers as other users)

        %argsopt_browser_start,
        %argsopt_browser_cmd,
        %argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub start_browsers {
    _start_or_restart_browsers('start', @_);
}

$SPEC{restart_browsers} = {
    v => 1.1,
    summary => "Restart browsers",
    description => <<'_',

For each of the requested browser, first check whether browser processes (that
run the current user) exist. If they do then terminate the browser first. After
that, start the browser again.

Example on the CLI:

    % restart-browsers --restart-firefox

To customize command:

    % restart-browsers --start-firefox --firefox-cmd 'firefox -P myprofile'

when starting each browser, console output will be captured and returned in
function metadata. Will wait for 2/5/10 seconds and check if the browsers have
been started. If all browsers can't be started, will return 500; otherwise will
return 200 but report the browsers that failed to start to the STDERR.

_
    args => {
        # args_common is not relevant here, for now (unless we want to start
        # browsers as other users)

        %argsopt_browser_restart,
        %argsopt_browser_cmd,
        %argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub restart_browsers {
    _start_or_restart_browsers('restart', @_);
}

1;
# ABSTRACT: Utilities related to browsers, particularly modern GUI ones

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BrowserUtils - Utilities related to browsers, particularly modern GUI ones

=head1 VERSION

This document describes version 0.015 of App::BrowserUtils (from Perl distribution App-BrowserUtils), released on 2021-09-27.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to browsers:

=over

=item * L<browsers-are-paused>

=item * L<kill-browsers>

=item * L<pause-and-unpause-browsers>

=item * L<pause-browsers>

=item * L<ps-browsers>

=item * L<restart-browsers>

=item * L<start-browsers>

=item * L<terminate-browsers>

=item * L<unpause-browsers>

=back

Supported browsers: Firefox on Linux, Opera on Linux, Chrome on Linux, and
Vivaldi on Linux.

=head1 FUNCTIONS


=head2 browsers_are_paused

Usage:

 browsers_are_paused(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether browsers are paused.

Browser is defined as paused if I<all> of its processes are in 'stop' state.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pause_and_unpause_browsers

Usage:

 pause_and_unpause_browsers(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause and unpause browsers alternately.

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they only run in the background. Pausing
(kill -STOP) the browser processes is a simple and effective way to stop CPU
eating on Unix and prolong your laptop battery life. It can be performed
whenever you are not using your browser for a little while, e.g. when you are
typing on an editor or watching a movie. When you want to use your browser
again, simply unpause (kill -CONT) it.

The C<pause-and-unpause> action pause and unpause browser in an alternate
fashion, by default every 5 minutes and 30 seconds. This is a compromise to save
CPU time most of the time but then give time for web applications in the browser
to catch up during the unpause window (e.g. for WhatsApp Web to display new
messages and sound notification.) It can be used when you are not browsing but
still want to be notified by web applications from time to time.

If you run this routine, it will start pausing and unpausing browser. When you
want to use the browser, press Ctrl-C to interrupt the routine. Then after you
are done with the browser and want to pause-and-unpause again, you can re-run
this routine.

You can customize the periods via the C<periods> option.

See also the separate C<pause_browsers> and the C<unpause_browsers> routines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<periods> => I<array[duration]>

Pause and unpause times, in seconds.

For example, to pause for 5 minutes, then unpause 10 seconds, then pause for 2
minutes, then unpause for 30 seconds (then repeat the pattern), you can use:

 300,10,120,30

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pause_browsers

Usage:

 pause_browsers(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause (kill -STOP) browsers.

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they only run in the background. Pausing
(kill -STOP) the browser processes is a simple and effective way to stop CPU
eating on Unix and prolong your laptop battery life. It can be performed
whenever you are not using your browser for a little while, e.g. when you are
typing on an editor or watching a movie. When you want to use your browser
again, simply unpause (kill -CONT) it.

See also the C<unpause_browsers> and the C<pause_and_unpause_browsers> routines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 ps_browsers

Usage:

 ps_browsers(%args) -> [$status_code, $reason, $payload, \%result_meta]

List browser processes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 restart_browsers

Usage:

 restart_browsers(%args) -> [$status_code, $reason, $payload, \%result_meta]

Restart browsers.

For each of the requested browser, first check whether browser processes (that
run the current user) exist. If they do then terminate the browser first. After
that, start the browser again.

Example on the CLI:

 % restart-browsers --restart-firefox

To customize command:

 % restart-browsers --start-firefox --firefox-cmd 'firefox -P myprofile'

when starting each browser, console output will be captured and returned in
function metadata. Will wait for 2/5/10 seconds and check if the browsers have
been started. If all browsers can't be started, will return 500; otherwise will
return 200 but report the browsers that failed to start to the STDERR.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<chrome_cmd> => I<array[str]|str> (default: "google-chrome")

=item * B<firefox_cmd> => I<array[str]|str> (default: "firefox")

=item * B<opera_cmd> => I<array[str]|str> (default: "opera")

=item * B<quiet> => I<true>

=item * B<restart_chrome> => I<bool>

=item * B<restart_firefox> => I<bool>

=item * B<restart_opera> => I<bool>

=item * B<restart_vivaldi> => I<bool>

=item * B<vivaldi_cmd> => I<array[str]|str> (default: "vivaldi")


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 start_browsers

Usage:

 start_browsers(%args) -> [$status_code, $reason, $payload, \%result_meta]

Start browsers.

For each of the requested browser, check whether browser processes (that run as
the current user) exist and if not then start the browser. If browser processes
exist, even if all are paused, then no new instance of the browser will be
started.

when starting each browser, console output will be captured and returned in
function metadata. Will wait for 2/5/10 seconds and check if the browsers have
been started. If all browsers can't be started, will return 500; otherwise will
return 200 but report the browsers that failed to start to the STDERR.

Example on the CLI:

 % start-browsers --start-firefox

To customize command to use to start:

 % start-browsers --start-firefox --firefox-cmd 'firefox -P myprofile'

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<chrome_cmd> => I<array[str]|str> (default: "google-chrome")

=item * B<firefox_cmd> => I<array[str]|str> (default: "firefox")

=item * B<opera_cmd> => I<array[str]|str> (default: "opera")

=item * B<quiet> => I<true>

=item * B<start_chrome> => I<bool>

=item * B<start_firefox> => I<bool>

=item * B<start_opera> => I<bool>

=item * B<start_vivaldi> => I<bool>

=item * B<vivaldi_cmd> => I<array[str]|str> (default: "vivaldi")


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 terminate_browsers

Usage:

 terminate_browsers(%args) -> [$status_code, $reason, $payload, \%result_meta]

Terminate (kill -KILL) browsers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 unpause_browsers

Usage:

 unpause_browsers(%args) -> [$status_code, $reason, $payload, \%result_meta]

Unpause (resume, continue, kill -CONT) browsers.

See also the C<pause_browsers> and the C<pause_and_unpause_browsers> routines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-BrowserUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BrowserUtils>.

=head1 SEE ALSO

Utilities using this distribution: L<App::FirefoxUtils>, L<App::ChromeUtils>,
L<App::OperaUtils>, L<App::VivaldiUtils>

L<App::BrowserOpenUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BrowserUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
