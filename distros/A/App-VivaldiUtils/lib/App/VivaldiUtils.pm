package App::VivaldiUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-09'; # DATE
our $DIST = 'App-VivaldiUtils'; # DIST
our $VERSION = '0.002'; # VERSION

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

1;
# ABSTRACT: Utilities related to the Vivaldi browser

__END__

=pod

=encoding UTF-8

=head1 NAME

App::VivaldiUtils - Utilities related to the Vivaldi browser

=head1 VERSION

This document describes version 0.002 of App::VivaldiUtils (from Perl distribution App-VivaldiUtils), released on 2019-12-09.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to the Vivaldi browser:

=over

=item * L<kill-vivaldi>

=item * L<pause-vivaldi>

=item * L<ps-vivaldi>

=item * L<terminate-vivaldi>

=item * L<unpause-vivaldi>

=item * L<vivaldi-is-paused>

=back

=head1 FUNCTIONS


=head2 pause_vivaldi

Usage:

 pause_vivaldi(%args) -> [status, msg, payload, meta]

Pause (kill -STOP) Vivaldi.

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

L<App::ChromeUtils>

L<App::FirefoxUtils>

L<App::OperaUtils>

L<App::BrowserUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
