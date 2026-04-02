package App::FirefoxUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-03-29'; # DATE
our $DIST = 'App-FirefoxUtils'; # DIST
our $VERSION = '0.025'; # VERSION

our @EXPORT_OK = qw(
                       ps_firefox
                       pause_firefox
                       unpause_firefox
                       pause_and_unpause_firefox
                       firefox_has_processes
                       firefox_is_paused
                       firefox_is_running
                       terminate_firefox
                       restart_firefox
                       start_firefox
                       open_firefox_tabs
               );

our %SPEC;

use App::BrowserUtils ();

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Firefox',
};

$SPEC{ps_firefox} = {
    v => 1.1,
    summary => "List Firefox processes",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub ps_firefox {
    App::BrowserUtils::_do_browser('ps', 'firefox', @_);
}

$SPEC{pause_firefox} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Firefox",
    description => $App::BrowserUtils::desc_pause,
    args => {
       %App::BrowserUtils::args_common,
    },
};
sub pause_firefox {
    App::BrowserUtils::_do_browser('pause', 'firefox', @_);
}

$SPEC{unpause_firefox} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Firefox",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub unpause_firefox {
    App::BrowserUtils::_do_browser('unpause', 'firefox', @_);
}

$SPEC{pause_and_unpause_firefox} = {
    v => 1.1,
    summary => "Pause and unpause Firefox alternately",
    description => $App::BrowserUtils::desc_pause_and_unpause,
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_periods,
    },
};
sub pause_and_unpause_firefox {
    App::BrowserUtils::_do_browser('pause_and_unpause', 'firefox', @_);
}

$SPEC{firefox_has_processes} = {
    v => 1.1,
    summary => "Check whether Firefox has processes",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub firefox_has_processes {
    App::BrowserUtils::_do_browser('has_processes', 'firefox', @_);
}

$SPEC{firefox_is_paused} = {
    v => 1.1,
    summary => "Check whether Firefox is paused",
    description => <<'_',

Firefox is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub firefox_is_paused {
    App::BrowserUtils::_do_browser('is_paused', 'firefox', @_);
}

$SPEC{firefox_is_running} = {
    v => 1.1,
    summary => "Check whether Firefox is running",
    description => <<'_',

Firefox is defined as running if there are some Firefox processes that are *not*
in 'stop' state. In other words, if Firefox has been started but is currently
paused, we do not say that it's running. If you want to check if Firefox process
exists, you can use `ps_firefox`.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub firefox_is_running {
    App::BrowserUtils::_do_browser('is_running', 'firefox', @_);
}

$SPEC{terminate_firefox} = {
    v => 1.1,
    summary => "Terminate Firefox (by default with -KILL signal)",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_signal,
    },
};
sub terminate_firefox {
    App::BrowserUtils::_do_browser('terminate', 'firefox', @_);
}

$SPEC{restart_firefox} = {
    v => 1.1,
    summary => "Restart firefox",
    args => {
        %App::BrowserUtils::argopt_firefox_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub restart_firefox {
    App::BrowserUtils::restart_browsers(@_, restart_firefox=>1);
}

$SPEC{start_firefox} = {
    v => 1.1,
    summary => "Start firefox if not already started",
    args => {
        %App::BrowserUtils::argopt_firefox_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub start_firefox {
    App::BrowserUtils::start_browsers(@_, start_firefox=>1);
}

$SPEC{open_firefox_tabs} = {
    v => 1.1,
    summary => 'Open a list of Firefox tabs, with options',
    description => <<'MARKDOWN',

This utility is best used via Perl or curried after you supply the list of
items. For example, in script `open-my-tiktok`:

    use App::FirefoxUtils ();
    use Perinci::CmdLine::Any;
    use Perinci::Sub::Util qw(gen_curried_sub);

    my @containers = (
        'account1',
        'account2',
        'account3',
    );

    my @containers_additional = (
        'account4',
        'account5',
    );

    gen_curried_sub(
        'App::FirefoxUtils::open_firefox_tabs',
        {
            items => [
                (map { +{url=>'https://www.tiktok.com/', container=>$_} } @containers),
                (map { +{url=>'https://www.tiktok.com/', container=>$_, include_by_default=>0} } @containers_additional),
            ],
        },
        'open_my_tiktok',
    );

    Perinci::CmdLine::Any->new(
        url => '/main/open_my_tiktok',
        log => 1,
    )->run;

Later on, you run your script:

    # open all items that are included by default
    % open-my-tiktok

    # only open items that match the queries
    % open-my-tiktok account2 account3

    # only open items that do not contain 'account4'
    % open-my-tiktok --new-window --shuffle -- -account4

MARKDOWN
    args => {
        items => {
            schema => ['array*', {
                min_len => 1,
                of => ['hash*', {
                    keys => {
                        url => 'url*',
                        tags => ['array*', {of=>['str*', min_len=>1]}],
                        container => 'str*',
                        include_by_default => ['bool*', default=>1],
                    },
                    req_keys => ['url'],
                }],
            }],
            req => 1,
        },
        new_window => {
            schema => 'bool*',
            cmdline_aliases => {
                w => {},
                # W = --no-new-window
            },
        },
        kde_activity => {
            summary => 'Switch to the specified KDE activity',
            schema => 'str*',

        },
        shuffle => {
            schema => 'bool*',
        },
        include_any_tags => {
            summary => 'Include all items that have any tag specified',
            schema => ['array*', of=>'str*'],
        },
        include_all_tags => {
            summary => 'Include all items that have ALL tags specified',
            schema => ['array*', of=>'str*'],
        },
        exclude_any_tags => {
            summary => 'Exclude all items that have any tags specified',
            schema => ['array*', of=>'str*'],
        },
        exclude_all_tags => {
            summary => 'Exclude all items that have ALL tags specified',
            schema => ['array*', of=>'str*'],
        },
        query => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
        },
    },
    deps => {
        all => [
            {prog=>'firefox-container'},
        ],
    },
};
sub open_firefox_tabs {
    require IPC::System::Options;
    require List::Util;
    require List::Util::Find;

    my %args = @_;

    my $items = $args{items} or return [400, "Please specify items"];
    @$items or return [400, "Please specify at least one item in items"];

    if (defined $args{kde_activity}) {
        require App::KDEActivityUtils;
        my $res_kde_activity = App::KDEActivityUtils::set_current_kde_activity(
            name => $args{kde_activity},
        );
        return [500, "Can't set current KDE activity: $res_kde_activity->[0] - $res_kde_activity->[1]"]
            unless $res_kde_activity->[0] == 200;
    }

    if ($args{shuffle}) {
        $items = [List::Util::shuffle(@$items)];
    }

    my $j = 0;
  ITEM:
    for my $i (0 .. $#{$items}) {
        my $item = $items->[$i];
        my @ff_args;
        my $env = {};

        # if not included by default, will be included only if specifically matching a filter
        my $include_by_default = $item->{include_by_default} // 1;

        my $match_a_filter = 0;

      FILTER: {
          INCLUDE_ANY_TAGS: {
                last unless $args{include_any_tags} && @{ $args{include_any_tags} };
                do { log_debug "Skipping item %s: does not pass include_any_tags %s", $item, $args{include_any_tags}; next ITEM }
                    unless List::Util::Find::hasanystrs($args{include_any_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          INCLUDE_ALL_TAGS: {
                last unless $args{include_all_tags} && @{ $args{include_all_tags} };
                do { log_debug "Skipping item %s: does not pass include_all_tags %s", $item, $args{include_all_tags}; next ITEM }
                    unless List::Util::Find::hasallstrs($args{include_all_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          EXCLUDE_ANY_TAGS: {
                last unless $args{exclude_any_tags} && @{ $args{exclude_any_tags} };
                do { log_debug "Skipping item %s: does not pass exclude_any_tags %s", $item, $args{exclude_any_tags}; next ITEM }
                    if List::Util::Find::hasanystrs($args{exclude_any_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          EXCLUDE_ALL_TAGS: {
                last unless $args{exclude_all_tags} && @{ $args{exclude_all_tags} };
                do { log_debug "Skipping item %s: does not pass exclude_all_tags %s", $item, $args{exclude_all_tags}; next ITEM }
                    if List::Util::Find::hasallstrs($args{exclude_all_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          QUERY: {
                last unless $args{query} && @{ $args{query} };
                my $num_positive_queries = 0;
                my $num_negative_queries = 0;
                my $match = 0;
              Q:
                for my $query0 (@{ $args{query} }) {
                    my ($is_negative, $query) = $query0 =~ /\A(-?)(.*)/;
                    $num_positive_queries++ if !$is_negative;
                    $num_negative_queries++ if  $is_negative;

                    if ($item->{url} =~ /$query/i) {
                        if ($is_negative) { goto L1 } else { $match = 1; last Q }
                    }
                    for my $tag (@{ $item->{tags} // [] }) {
                        if ($tag =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    for my $container ($item->{container} // '') {
                        if ($container =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                } # for query
                $match++ if $num_positive_queries == 0;
              L1:
                do { log_debug "Skipping item %s: does not pass query %s", $item, $args{query}; next ITEM }
                    unless $match;
                $match_a_filter++;
            } # QUERY
        } # FILTER

        if (!$include_by_default && !$match_a_filter) {
            log_debug "Skipping item %s: not included by default and does not match filter(s)", $item;
            next ITEM;
        }

        if ($j == 0 && $args{new_window}) {
            push @ff_args, "--new-window", $item->{url};
        } else {
            push @ff_args, $item->{url};
        }
        $j++;

        if (defined $item->{container}) {
            $env->{FIREFOX_CONTAINER} = $item->{container};
        }

        log_info "Opening tab %d: %s (%s) ...", $j, $item->{url}, (defined $item->{container} ? "container=$item->{container}" : "");
        IPC::System::Options::system({env=>$env, log=>1}, "firefox-container", @ff_args);
    }

    [200];
}

1;
# ABSTRACT: Utilities related to Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FirefoxUtils - Utilities related to Firefox

=head1 VERSION

This document describes version 0.025 of App::FirefoxUtils (from Perl distribution App-FirefoxUtils), released on 2026-03-29.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Firefox:

=over

=item 1. L<firefox-has-processes>

=item 2. L<firefox-is-paused>

=item 3. L<firefox-is-running>

=item 4. L<get-firefox-profile-dir>

=item 5. L<kill-firefox>

=item 6. L<list-firefox-profiles>

=item 7. L<open-firefox-tabs>

=item 8. L<pause-and-unpause-firefox>

=item 9. L<pause-firefox>

=item 10. L<ps-firefox>

=item 11. L<restart-firefox>

=item 12. L<start-firefox>

=item 13. L<terminate-firefox>

=item 14. L<unpause-firefox>

=back

=head1 FUNCTIONS


=head2 firefox_has_processes

Usage:

 firefox_has_processes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Firefox has processes.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<quiet> => I<true>

(No description)

=item * B<users> => I<array[unix::uid::exists]>

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



=head2 firefox_is_paused

Usage:

 firefox_is_paused(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Firefox is paused.

Firefox is defined as paused if I<all> of its processes are in 'stop' state.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<quiet> => I<true>

(No description)

=item * B<users> => I<array[unix::uid::exists]>

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



=head2 firefox_is_running

Usage:

 firefox_is_running(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Firefox is running.

Firefox is defined as running if there are some Firefox processes that are I<not>
in 'stop' state. In other words, if Firefox has been started but is currently
paused, we do not say that it's running. If you want to check if Firefox process
exists, you can use C<ps_firefox>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<quiet> => I<true>

(No description)

=item * B<users> => I<array[unix::uid::exists]>

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



=head2 open_firefox_tabs

Usage:

 open_firefox_tabs(%args) -> [$status_code, $reason, $payload, \%result_meta]

Open a list of Firefox tabs, with options.

This utility is best used via Perl or curried after you supply the list of
items. For example, in script C<open-my-tiktok>:

 use App::FirefoxUtils ();
 use Perinci::CmdLine::Any;
 use Perinci::Sub::Util qw(gen_curried_sub);
 
 my @containers = (
     'account1',
     'account2',
     'account3',
 );
 
 my @containers_additional = (
     'account4',
     'account5',
 );
 
 gen_curried_sub(
     'App::FirefoxUtils::open_firefox_tabs',
     {
         items => [
             (map { +{url=>'https://www.tiktok.com/', container=>$_} } @containers),
             (map { +{url=>'https://www.tiktok.com/', container=>$_, include_by_default=>0} } @containers_additional),
         ],
     },
     'open_my_tiktok',
 );
 
 Perinci::CmdLine::Any->new(
     url => '/main/open_my_tiktok',
     log => 1,
 )->run;

Later on, you run your script:

 # open all items that are included by default
 % open-my-tiktok
 
 # only open items that match the queries
 % open-my-tiktok account2 account3
 
 # only open items that do not contain 'account4'
 % open-my-tiktok --new-window --shuffle -- -account4

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_all_tags> => I<array[str]>

Exclude all items that have ALL tags specified.

=item * B<exclude_any_tags> => I<array[str]>

Exclude all items that have any tags specified.

=item * B<include_all_tags> => I<array[str]>

Include all items that have ALL tags specified.

=item * B<include_any_tags> => I<array[str]>

Include all items that have any tag specified.

=item * B<items>* => I<array[hash]>

(No description)

=item * B<kde_activity> => I<str>

Switch to the specified KDE activity.

=item * B<new_window> => I<bool>

(No description)

=item * B<query> => I<array[str]>

(No description)

=item * B<shuffle> => I<bool>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pause_and_unpause_firefox

Usage:

 pause_and_unpause_firefox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause and unpause Firefox alternately.

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

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<periods> => I<array[duration]>

Pause and unpause times, in seconds.

For example, to pause for 5 minutes, then unpause 10 seconds, then pause for 2
minutes, then unpause for 30 seconds (then repeat the pattern), you can use:

 300,10,120,30

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<users> => I<array[unix::uid::exists]>

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



=head2 pause_firefox

Usage:

 pause_firefox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause (kill -STOP) Firefox.

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they only run in the background. Pausing
(kill -STOP) the browser processes is a simple and effective way to stop CPU
eating on Unix and prolong your laptop battery life. It can be performed
whenever you are not using your browser for a little while, e.g. when you are
typing on an editor or watching a movie. When you want to use your browser
again, simply unpause (kill -CONT) it.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<users> => I<array[unix::uid::exists]>

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



=head2 ps_firefox

Usage:

 ps_firefox(%args) -> [$status_code, $reason, $payload, \%result_meta]

List Firefox processes.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<users> => I<array[unix::uid::exists]>

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



=head2 restart_firefox

Usage:

 restart_firefox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Restart firefox.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<firefox_cmd> => I<array[str]|str> (default: "firefox")

(No description)

=item * B<quiet> => I<true>

(No description)


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



=head2 start_firefox

Usage:

 start_firefox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Start firefox if not already started.

This function is not exported by default, but exportable.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<firefox_cmd> => I<array[str]|str> (default: "firefox")

(No description)

=item * B<quiet> => I<true>

(No description)


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



=head2 terminate_firefox

Usage:

 terminate_firefox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Terminate Firefox (by default with -KILL signal).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<signal> => I<unix::signal>

(No description)

=item * B<users> => I<array[unix::uid::exists]>

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



=head2 unpause_firefox

Usage:

 unpause_firefox(%args) -> [$status_code, $reason, $payload, \%result_meta]

Unpause (resume, continue, kill -CONT) Firefox.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmndline_pat> => I<re_from_str>

Filter processes using regex against their cmndline.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<exec_pat> => I<re_from_str>

Filter processes using regex against their exec.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<fname_pat> => I<re_from_str>

Filter processes using regex against their fname.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<pid_pat> => I<re_from_str>

Filter processes using regex against their pid.

If one of the C<*-pat> options are specified, then instead of the default
heuristic rules to find the browser processes, these C<*-pat> options are solely
used to determine which processes are the browser processes.

=item * B<users> => I<array[unix::uid::exists]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FirefoxUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FirefoxUtils>.

=head1 SEE ALSO

Some other CLI utilities related to Firefox: L<dump-firefox-history> (from
L<App::DumpFirefoxHistory>), L<App::FirefoxMultiAccountContainersUtils>.

L<App::BraveUtils>

L<App::ChromeUtils>

L<App::OperaUtils>

L<App::VivaldiUtils>

L<App::BrowserUtils>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FirefoxUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
