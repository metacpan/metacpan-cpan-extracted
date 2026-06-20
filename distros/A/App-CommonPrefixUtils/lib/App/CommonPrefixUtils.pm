package App::CommonPrefixUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-06-03'; # DATE
our $DIST = 'App-CommonPrefixUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

$SPEC{common_prefix} = {
    v => 1.1,
    summary => 'Calculate common prefix from supplied strings',
    args => {
        strings => {
            schema => ['array*', of=>'str*'],
            cmdline_src => 'stdin_or_args',
            pos => 0,
            slurpy => 1,
        },
    },
};
sub common_prefix {
    require String::CommonPrefix;

    my %args = @_;

    [200, "OK", String::CommonPrefix::common_prefix(@{ $args{strings} // [] })];
}

$SPEC{majority_prefix} = {
    v => 1.1,
    summary => 'Calculate majority prefix from supplied strings',
    args => {
        strings => {
            schema => ['array*', of=>'str*'],
            cmdline_src => 'stdin_or_args',
            pos => 0,
            slurpy => 1,
        },
    },
};
sub majority_prefix {
    require String::CommonPrefix;

    my %args = @_;

    [200, "OK", String::CommonPrefix::majority_prefix(@{ $args{strings} // [] })];
}

1;
# ABSTRACT: Utilities related to common prefix

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CommonPrefixUtils - Utilities related to common prefix

=head1 VERSION

This document describes version 0.002 of App::CommonPrefixUtils (from Perl distribution App-CommonPrefixUtils), released on 2026-06-03.

=head1 SYNOPSIS

See the included scripts:

=over

=item * L<common-prefix>

=item * L<majority-prefix>

=item * L<remove-common-prefix>

=item * L<strip-common-prefix>

=back

=head1 DESCRIPTION

This distribution includes the following CLI scripts related to common prefix.

=head1 FUNCTIONS


=head2 common_prefix

Usage:

 common_prefix(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate common prefix from supplied strings.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings> => I<array[str]>

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



=head2 majority_prefix

Usage:

 majority_prefix(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate majority prefix from supplied strings.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<strings> => I<array[str]>

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

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CommonPrefixUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CommonPrefixUtils>.

=head1 SEE ALSO

L<String::CommonPrefix>

L<App::CommonSuffixUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar (on netbook-dell-xps13)

perlancar (on netbook-dell-xps13) <perlancar@gmail.com>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CommonPrefixUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
