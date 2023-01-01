package App::BraveUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-07'; # DATE
our $DIST = 'App-BraveUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

use App::BrowserUtils ();

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Brave browser',
};

$SPEC{ps_brave} = {
    v => 1.1,
    summary => "List Brave processes",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub ps_brave {
    App::BrowserUtils::_do_browser('ps', 'brave', @_);
}

$SPEC{pause_brave} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Brave",
    description => $App::BrowserUtils::desc_pause,
    args => {
       %App::BrowserUtils::args_common,
    },
};
sub pause_brave {
    App::BrowserUtils::_do_browser('pause', 'brave', @_);
}

$SPEC{unpause_brave} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Brave",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub unpause_brave {
    App::BrowserUtils::_do_browser('unpause', 'brave', @_);
}

$SPEC{pause_and_unpause_brave} = {
    v => 1.1,
    summary => "Pause and unpause Brave alternately",
    description => $App::BrowserUtils::desc_pause_and_unpause,
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_periods,
    },
};
sub pause_and_unpause_brave {
    App::BrowserUtils::_do_browser('pause_and_unpause', 'brave', @_);
}

$SPEC{brave_has_processes} = {
    v => 1.1,
    summary => "Check whether Brave has processes",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub brave_has_processes {
    App::BrowserUtils::_do_browser('has_processes', 'brave', @_);
}

$SPEC{brave_is_paused} = {
    v => 1.1,
    summary => "Check whether Brave is paused",
    description => <<'_',

Brave is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub brave_is_paused {
    App::BrowserUtils::_do_browser('is_paused', 'brave', @_);
}

$SPEC{brave_is_running} = {
    v => 1.1,
    summary => "Check whether Brave is running",
    description => <<'_',

Brave is defined as running if there are some Brave processes that are *not*
in 'stop' state. In other words, if Brave has been started but is currently
paused, we do not say that it's running. If you want to check if Brave process
exists, you can use `ps_brave`.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub brave_is_running {
    App::BrowserUtils::_do_browser('is_running', 'brave', @_);
}

$SPEC{terminate_brave} = {
    v => 1.1,
    summary => "Terminate Brave (by default with -KILL signal)",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_signal,
    },
};
sub terminate_brave {
    App::BrowserUtils::_do_browser('terminate', 'brave', @_);
}

$SPEC{restart_brave} = {
    v => 1.1,
    summary => "Restart brave",
    args => {
        %App::BrowserUtils::argopt_brave_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub restart_brave {
    App::BrowserUtils::restart_browsers(@_, restart_brave=>1);
}

$SPEC{start_brave} = {
    v => 1.1,
    summary => "Start brave if not already started",
    args => {
        %App::BrowserUtils::argopt_brave_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub start_brave {
    App::BrowserUtils::start_browsers(@_, start_brave=>1);
}

1;
# ABSTRACT: Utilities related to Brave browser

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BraveUtils - Utilities related to Brave browser

=head1 VERSION

This document describes version 0.001 of App::BraveUtils (from Perl distribution App-BraveUtils), released on 2022-10-07.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Brave browser:

=over

=item * L<brave-has-processes>

=item * L<brave-is-paused>

=item * L<brave-is-running>

=item * L<kill-brave>

=item * L<pause-and-unpause-brave>

=item * L<pause-brave>

=item * L<ps-brave>

=item * L<restart-brave>

=item * L<start-brave>

=item * L<terminate-brave>

=item * L<unpause-brave>

=back

=head1 FUNCTIONS


=head2 brave_has_processes

Usage:

 brave_has_processes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Brave has processes.

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



=head2 brave_is_paused

Usage:

 brave_is_paused(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Brave is paused.

Brave is defined as paused if I<all> of its processes are in 'stop' state.

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



=head2 brave_is_running

Usage:

 brave_is_running(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Brave is running.

Brave is defined as running if there are some Brave processes that are I<not>
in 'stop' state. In other words, if Brave has been started but is currently
paused, we do not say that it's running. If you want to check if Brave process
exists, you can use C<ps_brave>.

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



=head2 pause_and_unpause_brave

Usage:

 pause_and_unpause_brave(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause and unpause Brave alternately.

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



=head2 pause_brave

Usage:

 pause_brave(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause (kill -STOP) Brave.

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



=head2 ps_brave

Usage:

 ps_brave(%args) -> [$status_code, $reason, $payload, \%result_meta]

List Brave processes.

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



=head2 restart_brave

Usage:

 restart_brave(%args) -> [$status_code, $reason, $payload, \%result_meta]

Restart brave.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

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



=head2 start_brave

Usage:

 start_brave(%args) -> [$status_code, $reason, $payload, \%result_meta]

Start brave if not already started.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

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



=head2 terminate_brave

Usage:

 terminate_brave(%args) -> [$status_code, $reason, $payload, \%result_meta]

Terminate Brave (by default with -KILL signal).

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



=head2 unpause_brave

Usage:

 unpause_brave(%args) -> [$status_code, $reason, $payload, \%result_meta]

Unpause (resume, continue, kill -CONT) Brave.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-BraveUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BraveUtils>.

=head1 SEE ALSO

L<https://brave.com>

L<App::ChromeUtils>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BraveUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
