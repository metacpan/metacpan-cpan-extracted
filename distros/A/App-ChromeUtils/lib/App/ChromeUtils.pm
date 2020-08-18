package App::ChromeUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-18'; # DATE
our $DIST = 'App-ChromeUtils'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::BrowserUtils ();

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

This document describes version 0.008 of App::ChromeUtils (from Perl distribution App-ChromeUtils), released on 2020-08-18.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Google Chrome browser:

=over

=item * L<chrome-has-processes>

=item * L<chrome-is-paused>

=item * L<chrome-is-running>

=item * L<kill-chrome>

=item * L<list-chrome-profiles>

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

 chrome_has_processes(%args) -> [status, msg, payload, meta]

Check whether Chrome has processes.

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



=head2 chrome_is_paused

Usage:

 chrome_is_paused(%args) -> [status, msg, payload, meta]

Check whether Chrome is paused.

Chrome is defined as paused if I<all> of its processes are in 'stop' state.

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



=head2 chrome_is_running

Usage:

 chrome_is_running(%args) -> [status, msg, payload, meta]

Check whether Chrome is running.

Chrome is defined as running if there are some Chrome processes that are I<not>
in 'stop' state. In other words, if Chrome has been started but is currently
paused, we do not say that it's running. If you want to check if Chrome process
exists, you can use C<ps_chrome>.

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



=head2 pause_chrome

Usage:

 pause_chrome(%args) -> [status, msg, payload, meta]

Pause (kill -STOP) Chrome.

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they only run in the background. Stopping
(kill -STOP) the browser processes is a simple and effective way to stop CPU
eating on Unix. It can be performed whenever you are not using your browser for
a little while, e.g. when you are typing on an editor or watching a movie. When
you want to use your browser again, simply unpause it.

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



=head2 ps_chrome

Usage:

 ps_chrome(%args) -> [status, msg, payload, meta]

List Chrome processes.

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



=head2 restart_chrome

Usage:

 restart_chrome(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 start_chrome

Usage:

 start_chrome(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 terminate_chrome

Usage:

 terminate_chrome(%args) -> [status, msg, payload, meta]

Terminate  (kill -KILL) Chrome.

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



=head2 unpause_chrome

Usage:

 unpause_chrome(%args) -> [status, msg, payload, meta]

Unpause (resume, continue, kill -CONT) Chrome.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ChromeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ChromeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ChromeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other CLI utilities related to Chrome: L<dump-chrome-history> (from
L<App::DumpChromeHistory>).

L<App::FirefoxUtils>

L<App::OperaUtils>

L<App::VivaldiUtils>

L<App::BrowserUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
