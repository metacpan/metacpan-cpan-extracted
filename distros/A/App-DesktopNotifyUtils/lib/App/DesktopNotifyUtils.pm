package App::DesktopNotifyUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-30'; # DATE
our $DIST = 'App-DesktopNotifyUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{notify_desktop} = {
    v => 1.1,
    summary => 'Show a notification on your desktop',
    description => <<'MARKDOWN',

Currently a very simple interface to <pm:Desktop::Notify>. Will offer more
options in the future.

MARKDOWN
    args => {
        summary => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        body => {
            schema => 'str*',
            pos => 1,
        },
        timeout => {
            summary => 'Timeout, in ms',
            schema => 'uint*',
            default => 5000,
        },
    },
};
sub notify_desktop {
    require Desktop::Notify;

    my %args = @_;
    my $notify = Desktop::Notify->new;

    my $notification = $notify->create(
        summary => $args{summary},
        body => $args{body},
        timeout => $args{timeout} // 5000,
    );
    $notification->show;

    [200];
}

1;
# ABSTRACT: Utilities related to Desktop::Notify

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DesktopNotifyUtils - Utilities related to Desktop::Notify

=head1 VERSION

This document describes version 0.001 of App::DesktopNotifyUtils (from Perl distribution App-DesktopNotifyUtils), released on 2024-08-30.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities:

#INSERT_EXECS_LIST

=head1 FUNCTIONS


=head2 notify_desktop

Usage:

 notify_desktop(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show a notification on your desktop.

Currently a very simple interface to L<Desktop::Notify>. Will offer more
options in the future.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<body> => I<str>

(No description)

=item * B<summary>* => I<str>

(No description)

=item * B<timeout> => I<uint> (default: 5000)

Timeout, in ms.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-DesktopNotifyUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DesktopNotifyUtils>.

=head1 SEE ALSO

L<Desktop::Notify>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DesktopNotifyUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
