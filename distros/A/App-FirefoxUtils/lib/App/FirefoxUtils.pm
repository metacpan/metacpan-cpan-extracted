package App::FirefoxUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-24'; # DATE
our $DIST = 'App-FirefoxUtils'; # DIST
our $VERSION = '0.018'; # VERSION

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

1;
# ABSTRACT: Utilities related to Firefox

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FirefoxUtils - Utilities related to Firefox

=head1 VERSION

This document describes version 0.018 of App::FirefoxUtils (from Perl distribution App-FirefoxUtils), released on 2022-07-24.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Firefox:

=over

=item * L<firefox-has-processes>

=item * L<firefox-is-paused>

=item * L<firefox-is-running>

=item * L<get-firefox-profile-dir>

=item * L<kill-firefox>

=item * L<list-firefox-profiles>

=item * L<pause-and-unpause-firefox>

=item * L<pause-firefox>

=item * L<ps-firefox>

=item * L<restart-firefox>

=item * L<start-firefox>

=item * L<terminate-firefox>

=item * L<unpause-firefox>

=back

=head1 FUNCTIONS


=head2 firefox_has_processes

Usage:

 firefox_has_processes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Firefox has processes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<periods> => I<array[duration]>

Pause and unpause times, in seconds.

For example, to pause for 5 minutes, then unpause 10 seconds, then pause for 2
minutes, then unpause for 30 seconds (then repeat the pattern), you can use:

 300,10,120,30

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

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

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<firefox_cmd> => I<array[str]|str> (default: "firefox")

=item * B<quiet> => I<true>


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

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<firefox_cmd> => I<array[str]|str> (default: "firefox")

=item * B<quiet> => I<true>


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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<signal> => I<unix::signal>

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

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FirefoxUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
