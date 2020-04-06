package App::BrowserUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-10'; # DATE
our $DIST = 'App-BrowserUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to browsers, particularly modern GUI ones',
};

our %browsers = (
    firefox => {
        browser_fname_pat => qr/\A(Web Content|WebExtensions|firefox-bin)\z/,
    },
    chrome => {
        browser_fname_pat => qr/\A(chrome)\z/,
    },
    opera => {
        browser_fname_pat => qr/\A(opera)\z/,
    },
    vivaldi => {
        browser_fname_pat => qr/\A(vivaldi-bin)\z/,
    },
);

our %argopt_users = (
    users => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'user',
        summary => 'Kill browser processes that belong to certain user(s) only',
        schema => ['array*', of=>'unix::local_uid*'],
    },
);

our %argopt_quiet = (
    quiet => {
        schema => 'true*',
        cmdline_aliases => {q=>{}},
    },
);

our %args_common = (
    %argopt_users,
);

our $desc_pause = <<'_';

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they run in the background. Stopping (kill
-STOP) the browser processes is a simple and effective way to stop CPU eating on
Unix. It can be performed whenever you are not using your browsers for a little
while, e.g. when you are typing on an editor or watching a movie. When you want
to use your browser again, simply unpause it.

_

sub _do_browser {
    require Proc::Find;

    my ($which_action, $which_browser, %args) = @_;

    my $browser_fname_pat = $browsers{$which_browser}{browser_fname_pat}
        or return [400, "Unknown browser '$which_browser'"];

    my $procs = Proc::Find::find_proc(
        detail => 1,
        filter => sub {
            my $p = shift;

            if ($args{users} && @{ $args{users} }) {
                return 0 unless grep { $p->{uid} == $_ } @{ $args{users} };
            }
            return 0 unless $p->{fname} =~ $browser_fname_pat;
            log_trace "Found PID %d (cmdline=%s, fname=%s, uid=%d)", $p->{pid}, $p->{cmndline}, $p->{fname}, $p->{uid};
            1;
        },
    );

    my @pids = map { $_->{pid} } @$procs;

    if ($which_action eq 'ps') {
        return [200, "OK", $procs, {'table.fields'=>[qw/pid uid euid state/]}];
    } elsif ($which_action eq 'pause') {
        kill STOP => @pids;
        [200, "OK", "", {"func.pids" => \@pids}];
    } elsif ($which_action eq 'unpause') {
        kill CONT => @pids;
        [200, "OK", "", {"func.pids" => \@pids}];
    } elsif ($which_action eq 'terminate') {
        kill KILL => @pids;
        [200, "OK", "", {"func.pids" => \@pids}];
    } elsif ($which_action eq 'is_paused') {
        my $num_stopped = 0;
        my $num_unstopped = 0;
        my $num_total = 0;
        for my $proc (@$procs) {
            $num_total++;
            if ($proc->{state} eq 'stop') { $num_stopped++ } else { $num_unstopped++ }
        }
        my $is_paused = $num_total == 0 ? undef : $num_stopped == $num_total ? 1 : 0;
        my $msg = $num_total == 0 ? "There are no $which_browser processes" :
            $num_stopped   == $num_total ? "$which_browser is paused (all processes are in stop state)" :
            $num_unstopped == $num_total ? "$which_browser is NOT paused (all processes are not in stop state)" :
            "$which_browser is NOT paused (some processes are not in stop state)";
        return [200, "OK", $is_paused, {
            'cmdline.exit_code' => $is_paused ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
        }];
    } else {
        die "BUG: unknown command";
    }
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
        push @rows, @{$res->[2]};
    }
    [200, "OK", \@rows];
}

$SPEC{pause_browsers} = {
    v => 1.1,
    summary => "Pause (kill -STOP) browsers",
    description => $desc_pause,
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
    summary => "Terminate  (kill -KILL) browsers",
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

1;
# ABSTRACT: Utilities related to browsers, particularly modern GUI ones

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BrowserUtils - Utilities related to browsers, particularly modern GUI ones

=head1 VERSION

This document describes version 0.002 of App::BrowserUtils (from Perl distribution App-BrowserUtils), released on 2019-12-10.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to browsers:

=over

=item * L<browsers-are-paused>

=item * L<kill-browsers>

=item * L<pause-browsers>

=item * L<ps-browsers>

=item * L<terminate-browsers>

=item * L<unpause-browsers>

=back

=head1 FUNCTIONS


=head2 browsers_are_paused

Usage:

 browsers_are_paused(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 pause_browsers

Usage:

 pause_browsers(%args) -> [status, msg, payload, meta]

Pause (kill -STOP) browsers.

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they run in the background. Stopping (kill
-STOP) the browser processes is a simple and effective way to stop CPU eating on
Unix. It can be performed whenever you are not using your browsers for a little
while, e.g. when you are typing on an editor or watching a movie. When you want
to use your browser again, simply unpause it.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 ps_browsers

Usage:

 ps_browsers(%args) -> [status, msg, payload, meta]

List browser processes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 terminate_browsers

Usage:

 terminate_browsers(%args) -> [status, msg, payload, meta]

Terminate  (kill -KILL) browsers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 unpause_browsers

Usage:

 unpause_browsers(%args) -> [status, msg, payload, meta]

Unpause (resume, continue, kill -CONT) browsers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<users> => I<array[unix::local_uid]>

Kill browser processes that belong to certain user(s) only.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-BrowserUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BrowserUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BrowserUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Utilities using this distribution: L<App::FirefoxUtils>, L<App::ChromeUtils>,
L<App::OperaUtils>, L<App::VivaldiUtils>

L<App::BrowserOpenUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
