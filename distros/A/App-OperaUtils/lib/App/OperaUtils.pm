package App::OperaUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-11'; # DATE
our $DIST = 'App-OperaUtils'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::BrowserUtils ();

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

$SPEC{terminate_opera} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Opera",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub terminate_opera {
    App::BrowserUtils::_do_browser('terminate', 'opera', @_);
}

1;
# ABSTRACT: Utilities related to the Opera browser

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OperaUtils - Utilities related to the Opera browser

=head1 VERSION

This document describes version 0.003 of App::OperaUtils (from Perl distribution App-OperaUtils), released on 2020-04-11.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to the Opera browser:

=over

=item * L<kill-opera>

=item * L<opera-is-paused>

=item * L<pause-opera>

=item * L<ps-opera>

=item * L<terminate-opera>

=item * L<unpause-opera>

=back

=head1 FUNCTIONS


=head2 opera_is_paused

Usage:

 opera_is_paused(%args) -> [status, msg, payload, meta]

Check whether Opera is paused.

Opera is defined as paused if I<all> of its processes are in 'stop' state.

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



=head2 pause_opera

Usage:

 pause_opera(%args) -> [status, msg, payload, meta]

Pause (kill -STOP) Opera.

A modern browser now runs complex web pages and applications. Despite browser's
power management feature, these pages/tabs on the browser often still eat
considerable CPU cycles even though they only run in the background. Stopping
(kill -STOP) the browser processes is a simple and effective way to stop CPU
eating on Unix. It can be performed whenever you are not using your browsers for
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



=head2 ps_opera

Usage:

 ps_opera(%args) -> [status, msg, payload, meta]

List Opera processes.

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



=head2 terminate_opera

Usage:

 terminate_opera(%args) -> [status, msg, payload, meta]

Terminate  (kill -KILL) Opera.

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



=head2 unpause_opera

Usage:

 unpause_opera(%args) -> [status, msg, payload, meta]

Unpause (resume, continue, kill -CONT) Opera.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-OperaUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OperaUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OperaUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other CLI utilities related to Opera: L<dump-opera-history> (from
L<App::DumpOperaHistory>).

L<App::ChromeUtils>

L<App::FirefoxUtils>

L<App::VivaldiUtils>

L<App::BrowserUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
