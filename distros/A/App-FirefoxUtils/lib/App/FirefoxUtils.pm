package App::FirefoxUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'App-FirefoxUtils'; # DIST
our $VERSION = '0.013'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

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
    summary => "Terminate  (kill -KILL) Firefox",
    args => {
        %App::BrowserUtils::args_common,
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

This document describes version 0.013 of App::FirefoxUtils (from Perl distribution App-FirefoxUtils), released on 2020-06-13.

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

 firefox_has_processes(%args) -> [status, msg, payload, meta]

Check whether Firefox has processes.

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



=head2 firefox_is_paused

Usage:

 firefox_is_paused(%args) -> [status, msg, payload, meta]

Check whether Firefox is paused.

Firefox is defined as paused if I<all> of its processes are in 'stop' state.

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



=head2 firefox_is_running

Usage:

 firefox_is_running(%args) -> [status, msg, payload, meta]

Check whether Firefox is running.

Firefox is defined as running if there are some Firefox processes that are I<not>
in 'stop' state. In other words, if Firefox has been started but is currently
paused, we do not say that it's running. If you want to check if Firefox process
exists, you can use C<ps_firefox>.

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



=head2 pause_firefox

Usage:

 pause_firefox(%args) -> [status, msg, payload, meta]

Pause (kill -STOP) Firefox.

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



=head2 ps_firefox

Usage:

 ps_firefox(%args) -> [status, msg, payload, meta]

List Firefox processes.

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



=head2 restart_firefox

Usage:

 restart_firefox(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 start_firefox

Usage:

 start_firefox(%args) -> [status, msg, payload, meta]

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 terminate_firefox

Usage:

 terminate_firefox(%args) -> [status, msg, payload, meta]

Terminate  (kill -KILL) Firefox.

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



=head2 unpause_firefox

Usage:

 unpause_firefox(%args) -> [status, msg, payload, meta]

Unpause (resume, continue, kill -CONT) Firefox.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FirefoxUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ManUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FirefoxUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other CLI utilities related to Firefox: L<dump-firefox-history> (from
L<App::DumpFirefoxHistory>), L<App::FirefoxMultiAccountContainersUtils>.

L<App::ChromeUtils>

L<App::OperaUtils>

L<App::VivaldiUtils>

L<App::BrowserUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
