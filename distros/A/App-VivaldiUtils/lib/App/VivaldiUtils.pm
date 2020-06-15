package App::VivaldiUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-13'; # DATE
our $DIST = 'App-VivaldiUtils'; # DIST
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use App::BrowserUtils ();

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to the Vivaldi browser',
};

$SPEC{ps_vivaldi} = {
    v => 1.1,
    summary => "List Vivaldi processes",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub ps_vivaldi {
    App::BrowserUtils::_do_browser('ps', 'vivaldi', @_);
}

$SPEC{pause_vivaldi} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Vivaldi",
    description => $App::BrowserUtils::desc_pause,
    args => {
       %App::BrowserUtils::args_common,
    },
};
sub pause_vivaldi {
    App::BrowserUtils::_do_browser('pause', 'vivaldi', @_);
}

$SPEC{unpause_vivaldi} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Vivaldi",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub unpause_vivaldi {
    App::BrowserUtils::_do_browser('unpause', 'vivaldi', @_);
}

$SPEC{vivaldi_has_processes} = {
    v => 1.1,
    summary => "Check whether Vivaldi has processes",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub vivaldi_has_processes {
    App::BrowserUtils::_do_browser('has_processes', 'vivaldi', @_);
}

$SPEC{vivaldi_is_paused} = {
    v => 1.1,
    summary => "Check whether Vivaldi is paused",
    description => <<'_',

Vivaldi is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub vivaldi_is_paused {
    App::BrowserUtils::_do_browser('is_paused', 'vivaldi', @_);
}

$SPEC{vivaldi_is_running} = {
    v => 1.1,
    summary => "Check whether Vivaldi is running",
    description => <<'_',

Vivaldi is defined as running if there are some Vivaldi processes that are *not*
in 'stop' state. In other words, if Vivaldi has been started but is currently
paused, we do not say that it's running. If you want to check if Vivaldi process
exists, you can use `ps_vivaldi`.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub vivaldi_is_running {
    App::BrowserUtils::_do_browser('is_running', 'vivaldi', @_);
}

$SPEC{terminate_vivaldi} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Vivaldi",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub terminate_vivaldi {
    App::BrowserUtils::_do_browser('terminate', 'vivaldi', @_);
}

$SPEC{restart_vivaldi} = {
    v => 1.1,
    summary => "Restart Vivaldi",
    args => {
        %App::BrowserUtils::argopt_vivaldi_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub restart_vivaldi {
    App::BrowserUtils::restart_browsers(@_, restart_vivaldi=>1);
}

$SPEC{start_vivaldi} = {
    v => 1.1,
    summary => "Start Vivaldi if not already started",
    args => {
        %App::BrowserUtils::argopt_vivaldi_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub start_vivaldi {
    App::BrowserUtils::start_browsers(@_, start_vivaldi=>1);
}

1;
# ABSTRACT: Utilities related to the Vivaldi browser

__END__

=pod

=encoding UTF-8

=head1 NAME

App::VivaldiUtils - Utilities related to the Vivaldi browser

=head1 VERSION

This document describes version 0.007 of App::VivaldiUtils (from Perl distribution App-VivaldiUtils), released on 2020-06-13.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to the Vivaldi browser:

=over

=item * L<kill-vivaldi>

=item * L<list-vivaldi-profiles>

=item * L<pause-vivaldi>

=item * L<ps-vivaldi>

=item * L<restart-vivaldi>

=item * L<start-vivaldi>

=item * L<terminate-vivaldi>

=item * L<unpause-vivaldi>

=item * L<vivaldi-has-processes>

=item * L<vivaldi-is-paused>

=item * L<vivaldi-is-running>

=back

=head1 FUNCTIONS


=head2 pause_vivaldi

Usage:

 pause_vivaldi(%args) -> [status, msg, payload, meta]

Pause (kill -STOP) Vivaldi.

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



=head2 ps_vivaldi

Usage:

 ps_vivaldi(%args) -> [status, msg, payload, meta]

List Vivaldi processes.

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



=head2 restart_vivaldi

Usage:

 restart_vivaldi(%args) -> [status, msg, payload, meta]

Restart Vivaldi.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

=item * B<vivaldi_cmd> => I<array[str]|str> (default: "vivaldi")


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



=head2 start_vivaldi

Usage:

 start_vivaldi(%args) -> [status, msg, payload, meta]

Start Vivaldi if not already started.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<quiet> => I<true>

=item * B<vivaldi_cmd> => I<array[str]|str> (default: "vivaldi")


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



=head2 terminate_vivaldi

Usage:

 terminate_vivaldi(%args) -> [status, msg, payload, meta]

Terminate  (kill -KILL) Vivaldi.

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



=head2 unpause_vivaldi

Usage:

 unpause_vivaldi(%args) -> [status, msg, payload, meta]

Unpause (resume, continue, kill -CONT) Vivaldi.

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



=head2 vivaldi_has_processes

Usage:

 vivaldi_has_processes(%args) -> [status, msg, payload, meta]

Check whether Vivaldi has processes.

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



=head2 vivaldi_is_paused

Usage:

 vivaldi_is_paused(%args) -> [status, msg, payload, meta]

Check whether Vivaldi is paused.

Vivaldi is defined as paused if I<all> of its processes are in 'stop' state.

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



=head2 vivaldi_is_running

Usage:

 vivaldi_is_running(%args) -> [status, msg, payload, meta]

Check whether Vivaldi is running.

Vivaldi is defined as running if there are some Vivaldi processes that are I<not>
in 'stop' state. In other words, if Vivaldi has been started but is currently
paused, we do not say that it's running. If you want to check if Vivaldi process
exists, you can use C<ps_vivaldi>.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-VivaldiUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-VivaldiUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-VivaldiUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other CLI utilities related to Vivaldi: L<dump-vivaldi-history> (from
L<App::DumpVivaldiHistory>).

L<App::OperaUtils>

L<App::FirefoxUtils>

L<App::OperaUtils>

L<App::BrowserUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
