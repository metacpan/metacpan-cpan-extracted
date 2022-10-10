package App::OperaUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::BrowserUtils ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-24'; # DATE
our $DIST = 'App-OperaUtils'; # DIST
our $VERSION = '0.007'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to the Opera browser',
};

$SPEC{ps_opera} = {
    v => 1.1,
    summary => "List Opera processes",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub ps_opera {
    App::BrowserUtils::_do_browser('ps', 'opera', @_);
}

$SPEC{pause_opera} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Opera",
    description => $App::BrowserUtils::desc_pause,
    args => {
       %App::BrowserUtils::args_common,
    },
};
sub pause_opera {
    App::BrowserUtils::_do_browser('pause', 'opera', @_);
}

$SPEC{unpause_opera} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Opera",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub unpause_opera {
    App::BrowserUtils::_do_browser('unpause', 'opera', @_);
}

$SPEC{opera_has_processes} = {
    v => 1.1,
    summary => "Check whether Opera has processes",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub opera_has_processes {
    App::BrowserUtils::_do_browser('has_processes', 'opera', @_);
}

$SPEC{opera_is_paused} = {
    v => 1.1,
    summary => "Check whether Opera is paused",
    description => <<'_',

Opera is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub opera_is_paused {
    App::BrowserUtils::_do_browser('is_paused', 'opera', @_);
}

$SPEC{opera_is_running} = {
    v => 1.1,
    summary => "Check whether Opera is running",
    description => <<'_',

Opera is defined as running if there are some Opera processes that are *not*
in 'stop' state. In other words, if Opera has been started but is currently
paused, we do not say that it's running. If you want to check if Opera process
exists, you can use `ps_opera`.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub opera_is_running {
    App::BrowserUtils::_do_browser('is_running', 'opera', @_);
}

$SPEC{terminate_opera} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Opera",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_signal,
    },
};
sub terminate_opera {
    App::BrowserUtils::_do_browser('terminate', 'opera', @_);
}

$SPEC{restart_opera} = {
    v => 1.1,
    summary => "Restart opera",
    args => {
        %App::BrowserUtils::argopt_opera_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub restart_opera {
    App::BrowserUtils::restart_browsers(@_, restart_opera=>1);
}

$SPEC{start_opera} = {
    v => 1.1,
    summary => "Start opera if not already started",
    args => {
        %App::BrowserUtils::argopt_opera_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub start_opera {
    App::BrowserUtils::start_browsers(@_, start_opera=>1);
}

1;
# ABSTRACT: Utilities related to the Opera browser

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OperaUtils - Utilities related to the Opera browser

=head1 VERSION

This document describes version 0.007 of App::OperaUtils (from Perl distribution App-OperaUtils), released on 2022-07-24.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to the Opera browser:

=over

=item * L<kill-opera>

=item * L<opera-has-processes>

=item * L<opera-is-paused>

=item * L<opera-is-running>

=item * L<pause-opera>

=item * L<ps-opera>

=item * L<restart-opera>

=item * L<start-opera>

=item * L<terminate-opera>

=item * L<unpause-opera>

=back

=head1 FUNCTIONS


=head2 opera_has_processes

Usage:

 opera_has_processes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Opera has processes.

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



=head2 opera_is_paused

Usage:

 opera_is_paused(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Opera is paused.

Opera is defined as paused if I<all> of its processes are in 'stop' state.

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



=head2 opera_is_running

Usage:

 opera_is_running(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether Opera is running.

Opera is defined as running if there are some Opera processes that are I<not>
in 'stop' state. In other words, if Opera has been started but is currently
paused, we do not say that it's running. If you want to check if Opera process
exists, you can use C<ps_opera>.

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



=head2 pause_opera

Usage:

 pause_opera(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pause (kill -STOP) Opera.

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



=head2 ps_opera

Usage:

 ps_opera(%args) -> [$status_code, $reason, $payload, \%result_meta]

List Opera processes.

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



=head2 restart_opera

Usage:

 restart_opera(%args) -> [$status_code, $reason, $payload, \%result_meta]

Restart opera.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<opera_cmd> => I<array[str]|str> (default: "opera")

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



=head2 start_opera

Usage:

 start_opera(%args) -> [$status_code, $reason, $payload, \%result_meta]

Start opera if not already started.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<opera_cmd> => I<array[str]|str> (default: "opera")

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



=head2 terminate_opera

Usage:

 terminate_opera(%args) -> [$status_code, $reason, $payload, \%result_meta]

Terminate  (kill -KILL) Opera.

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



=head2 unpause_opera

Usage:

 unpause_opera(%args) -> [$status_code, $reason, $payload, \%result_meta]

Unpause (resume, continue, kill -CONT) Opera.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-OperaUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OperaUtils>.

=head1 SEE ALSO

Some other CLI utilities related to Opera: L<dump-opera-history> (from
L<App::DumpOperaHistory>).

L<App::ChromeUtils>

L<App::FirefoxUtils>

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

This software is copyright (c) 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OperaUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
