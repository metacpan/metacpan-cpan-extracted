package AppBase::Sort;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-05'; # DATE
our $DIST = 'AppBase-Sort'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

$SPEC{sort_appbase} = {
    v => 1.1,
    summary => 'A base for sort-like CLI utilities',
    description => <<'MARKDOWN',

This routine provides a base for Unix sort-like CLI utilities. It accepts
coderef as source of lines, which in the actual utilities can be from
stdin/files or other sources. It provides common options like `-i`, `-r`, and so
on.

Examples of CLI utilities that are based on this: <prog:sort-by-example> (which
is included in the `AppBase-Sort` distribution).

Why? For sorting lines from files or stdin and "standard" sorting criteria, this
utility is no match for the standard Unix `sort` (or its many alternatives). But
`AppBase::Sort` is a quick way to create sort-like utilities that sort
lines from alternative sources and/or using custom sort criteria.

MARKDOWN
    args => {
        ignore_case => {
            summary => 'If set to true, will search case-insensitively',
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
            #tags => ['category:'],
        },
        reverse => {
            summary => 'Reverse sort order',
            schema => 'bool*',
            cmdline_aliases => {r=>{}},
            #tags => ['category:'],
        },
        _source => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'MARKDOWN',

Code to produce *chomped* lines of text to sort. Required.

Will be called with these arguments:

    ()

Should return the next line or undef if the source is exhausted.

MARKDOWN
        },
        _sortgen => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'MARKDOWN',

Code to generate sorting routine. Required.

Will be called with these arguments:

    ($args)

Should return the following:

    ($sort, $handle_ci_and_reverse)

where `$sort` is the sort routine which in turn will be called during sort with:

    ($a, $b)

and `$handle_ci_and_reverse` can be set to true if the sorting routine already
observes the `--ignore-case` (`-i`) and `--reverse` (`-r`). Otherwise,
AppBase::Sort will handle the case conversion and reversing.

MARKDOWN
        },
    },
};
sub sort_appbase {
    my %args = @_;

    my $opt_ci      = $args{ignore_case};
    my $opt_reverse = $args{reverse};

    my $source = $args{_source};
    my @lines;
    while (defined(my $line = $source->())) { push @lines, $line }

    my ($sort, $handle_ci_and_reverse) = $args{_sortgen}->(%args);

    if ($handle_ci_and_reverse) {
        @lines = sort { $sort->($a, $b) } @lines;
    } else {
        if ($opt_ci) {
            if ($opt_reverse) {
                @lines = sort { $sort->(lc($b), lc($a)) } @lines;
            } else {
                @lines = sort { $sort->(lc($a), lc($b)) } @lines;
            }
        } else {
            if ($opt_reverse) {
                @lines = sort { $sort->($b, $a) } @lines;
            } else {
                @lines = sort { $sort->($a, $b) } @lines;
            }
        }
    }

    return [
        200,
        "OK",
        \@lines,
    ];
}

1;
# ABSTRACT: A base for sort-like CLI utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

AppBase::Sort - A base for sort-like CLI utilities

=head1 VERSION

This document describes version 0.002 of AppBase::Sort (from Perl distribution AppBase-Sort), released on 2023-09-05.

=head1 FUNCTIONS


=head2 sort_appbase

Usage:

 sort_appbase(%args) -> [$status_code, $reason, $payload, \%result_meta]

A base for sort-like CLI utilities.

This routine provides a base for Unix sort-like CLI utilities. It accepts
coderef as source of lines, which in the actual utilities can be from
stdin/files or other sources. It provides common options like C<-i>, C<-r>, and so
on.

Examples of CLI utilities that are based on this: L<sort-by-example> (which
is included in the C<AppBase-Sort> distribution).

Why? For sorting lines from files or stdin and "standard" sorting criteria, this
utility is no match for the standard Unix C<sort> (or its many alternatives). But
C<AppBase::Sort> is a quick way to create sort-like utilities that sort
lines from alternative sources and/or using custom sort criteria.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ignore_case> => I<bool>

If set to true, will search case-insensitively.

=item * B<reverse> => I<bool>

Reverse sort order.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/AppBase-Sort>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-AppBase-Sort>.

=head1 SEE ALSO

L<App::subsort>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=AppBase-Sort>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
