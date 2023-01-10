package App::ChromeUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::BrowserUtils ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-07'; # DATE
our $DIST = 'App-ChromeUtils'; # DIST
our $VERSION = '0.011'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Google Chrome browser',
};

$SPEC{ps_chrome} = {
    v => 1.1,
    summary => "List Chrome processes",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub ps_chrome {
    App::BrowserUtils::_do_browser('ps', 'chrome', @_);
}

$SPEC{pause_chrome} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Chrome",
    description => $App::BrowserUtils::desc_pause,
    args => {
       %App::BrowserUtils::args_common,
    },
};
sub pause_chrome {
    App::BrowserUtils::_do_browser('pause', 'chrome', @_);
}

$SPEC{unpause_chrome} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Chrome",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub unpause_chrome {
    App::BrowserUtils::_do_browser('unpause', 'chrome', @_);
}

$SPEC{pause_and_unpause_chrome} = {
    v => 1.1,
    summary => "Pause and unpause Chrome alternately",
    description => $App::BrowserUtils::desc_pause_and_unpause,
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_periods,
    },
};
sub pause_and_unpause_chrome {
    App::BrowserUtils::_do_browser('pause_and_unpause', 'chrome', @_);
}

$SPEC{chrome_has_processes} = {
    v => 1.1,
    summary => "Check whether Chrome has processes",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub chrome_has_processes {
    App::BrowserUtils::_do_browser('has_processes', 'chrome', @_);
}

$SPEC{chrome_is_paused} = {
    v => 1.1,
    summary => "Check whether Chrome is paused",
    description => <<'_',

Chrome is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub chrome_is_paused {
    App::BrowserUtils::_do_browser('is_paused', 'chrome', @_);
}

$SPEC{chrome_is_running} = {
    v => 1.1,
    summary => "Check whether Chrome is running",
    description => <<'_',

Chrome is defined as running if there are some Chrome processes that are *not*
in 'stop' state. In other words, if Chrome has been started but is currently
paused, we do not say that it's running. If you want to check if Chrome process
exists, you can use `ps_chrome`.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub chrome_is_running {
    App::BrowserUtils::_do_browser('is_running', 'chrome', @_);
}

$SPEC{terminate_chrome} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Chrome",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub terminate_chrome {
    App::BrowserUtils::_do_browser('terminate', 'chrome', @_);
}

$SPEC{restart_chrome} = {
    v => 1.1,
    summary => "Restart chrome",
    args => {
        %App::BrowserUtils::argopt_chrome_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub restart_chrome {
    App::BrowserUtils::restart_browsers(@_, restart_chrome=>1);
}

$SPEC{start_chrome} = {
    v => 1.1,
    summary => "Start chrome if not already started",
    args => {
        %App::BrowserUtils::argopt_chrome_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub start_chrome {
    App::BrowserUtils::start_browsers(@_, start_chrome=>1);
}

1;
# ABSTRACT: Utilities related to Google Chrome browser

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ChromeUtils - Utilities related to Google Chrome browser

=head1 VERSION

This document describes version 0.011 of App::ChromeUtils (from Perl distribution App-ChromeUtils), released on 2022-10-07.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Google Chrome browser:

=over

=item * L<chrome-has-processes>

=item * L<chrome-is-paused>

=item * L<chrome-is-running>

=item * L<kill-chrome>

=item * L<list-chrome-profiles>

=item * L<pause-and-unpause-chrome>

=item * L<pause-chrome>

=item * L<ps-chrome>

=item * L<restart-chrome>

=item * L<start-chrome>

=item * L<terminate-chrome>

=item * L<unpause-chrome>

=back

=head1 FUNCTIONS


=head2 chrome_has_processes

Usage:

 chrome_has_processes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Chrome has processes.

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



=head2 chrome_is_paused

Usage:

 chrome_is_paused(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Chrome is paused.

Chrome is defined as paused if I<all> of its processes are in 'stop' state.

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



=head2 chrome_is_running

Usage:

 chrome_is_running(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Chrome is running.

Chrome is defined as running if there are some Chrome processes that are I<not>
in 'stop' state. In other words, if Chrome has been started but is currently
paused, we do not say that it's running. If you want to check if Chrome process
exists, you can use C<ps_chrome>.

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



=head2 pause_and_unpause_chrome

Usage:

 pause_and_unpause_chrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause and unpause Chrome alternately.

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



=head2 pause_chrome

Usage:

 pause_chrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause (kill -STOP) Chrome.

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



=head2 ps_chrome

Usage:

 ps_chrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

List Chrome processes.

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



=head2 restart_chrome

Usage:

 restart_chrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

Restart chrome.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<chrome_cmd> => I<array[str]|str> (default: "google-chrome")

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



=head2 start_chrome

Usage:

 start_chrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

Start chrome if not already started.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<chrome_cmd> => I<array[str]|str> (default: "google-chrome")

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



=head2 terminate_chrome

Usage:

 terminate_chrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

Terminate  (kill -KILL) Chrome.

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



=head2 unpause_chrome

Usage:

 unpause_chrome(%args) -> [$status_code, $reason, $payload, \%result_meta]

Unpause (resume, continue, kill -CONT) Chrome.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ChromeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ChromeUtils>.

=head1 SEE ALSO

Some other CLI utilities related to Chrome: L<dump-chrome-history> (from
L<App::DumpChromeHistory>).

L<App::BraveUtils>

L<App::FirefoxUtils>

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

This software is copyright (c) 2022, 2021, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ChromeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
