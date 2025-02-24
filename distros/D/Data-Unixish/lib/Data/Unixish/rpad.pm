package Data::Unixish::rpad;

use 5.010;
use locale;
use strict;
use syntax 'each_on_array'; # to support perl < 5.12
use warnings;
#use Log::Any '$log';

use Data::Unixish::_pad;
use Data::Unixish::Util qw(%common_args);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.574'; # VERSION

our %SPEC;

$SPEC{rpad} = {
    v => 1.1,
    summary => 'Pad text to the right until a certain column width',
    description => <<'MARKDOWN',

This function can handle text containing wide characters and ANSI escape codes.

Note: to pad to a certain character length instead of column width (note that
wide characters like Chinese can have width of more than 1 column in terminal),
you can turn of `mb` option even when your text contains wide characters.

MARKDOWN
    args => {
        %common_args,
        width => {
            schema => ['int*', min => 0],
            req => 1,
            pos => 0,
            cmdline_aliases => { w => {} },
        },
        ansi => {
            summary => 'Whether to handle ANSI escape codes',
            schema => ['bool', default => 0],
        },
        mb => {
            summary => 'Whether to handle wide characters',
            schema => ['bool', default => 0],
        },
        char => {
            summary => 'Character to use for padding',
            schema => ['str*', len=>1, default=>' '],
            description => <<'MARKDOWN',

Character should have column width of 1. The default is space (ASCII 32).

MARKDOWN
            cmdline_aliases => { c => {} },
        },
        trunc => {
            summary => 'Whether to truncate text wider than specified width',
            schema => ['bool', default => 0],
        },
    },
    tags => [qw/itemfunc text/],
};
sub rpad {
    my %args = @_;
    Data::Unixish::_pad::_pad("r", %args);
}

sub _rpad_begin { Data::Unixish::_pad::__pad_begin('r', @_) }
sub _rpad_item { Data::Unixish::_pad::__pad_item('r', @_) }

1;
# ABSTRACT: Pad text to the right until a certain column width

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Unixish::rpad - Pad text to the right until a certain column width

=head1 VERSION

This document describes version 1.574 of Data::Unixish::rpad (from Perl distribution Data-Unixish), released on 2025-02-24.

=head1 SYNOPSIS

In Perl:

 use Data::Unixish qw(lduxl);
 my @res = lduxl([rpad => {width=>6}],"123", "1234");
 # => ("123   ", "1234  ")

In command line:

 % echo -e "123\n1234" | dux rpad -w 6 -c x --format=text-simple
 123xxx
 1234xx

=head1 FUNCTIONS


=head2 rpad

Usage:

 rpad(%args) -> [$status_code, $reason, $payload, \%result_meta]

Pad text to the right until a certain column width.

This function can handle text containing wide characters and ANSI escape codes.

Note: to pad to a certain character length instead of column width (note that
wide characters like Chinese can have width of more than 1 column in terminal),
you can turn of C<mb> option even when your text contains wide characters.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ansi> => I<bool> (default: 0)

Whether to handle ANSI escape codes.

=item * B<char> => I<str> (default: " ")

Character to use for padding.

Character should have column width of 1. The default is space (ASCII 32).

=item * B<in> => I<array>

Input stream (e.g. array or filehandle).

=item * B<mb> => I<bool> (default: 0)

Whether to handle wide characters.

=item * B<out> => I<any>

Output stream (e.g. array or filehandle).

=item * B<trunc> => I<bool> (default: 0)

Whether to truncate text wider than specified width.

=item * B<width>* => I<int>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
