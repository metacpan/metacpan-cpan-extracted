package App::ModuleReleaseSelectUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-03-09'; # DATE
our $DIST = 'App-ModuleReleaseSelectUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Module::Release::Select',
};

$SPEC{check_release_matches} = {
    v => 1.1,
    summary => "Given an expression and one or more releases, show which releases match the expression",
    args => {
        expr => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        releases => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'release',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 1,
            slurpy => 1,
        },
        quiet => {
            schema => 'bool*',
            cmdline_aliases => {q=>{}},
        },
    },
    examples => [
        {
            argv => [">1.31", "2.1"],
            test => 0,
        },
        {
            argv => [">1.31", "1.3"],
            test => 0,
        },
        {
            argv => [">1.31", "1.31"],
            test => 0,
        },
        {
            argv => [">1.31", "2.1", "1.32", "1.31", "1.3"],
            test => 0,
        },
    ],
};
sub check_release_matches {
    require Module::Release::Select;
    my %args = @_;

    my @rels = Module::Release::Select::select_releases($args{expr}, $args{releases});

    if (@rels) {
        return [200, "OK (matches)", $args{quiet} ? undef : "Release(s) match expression", {"cmdline.exit_code"=>0}];
    } else {
        return [200, "OK (no match)", $args{quiet} ? undef : "Release(s) do NOT match expression", {"cmdline.exit_code"=>1}];
    }
}

1;
# ABSTRACT: Utilities related to Module::Release::Select

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ModuleReleaseSelectUtils - Utilities related to Module::Release::Select

=head1 VERSION

This document describes version 0.001 of App::ModuleReleaseSelectUtils (from Perl distribution App-ModuleReleaseSelectUtils), released on 2023-03-09.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<check-release-matches>

=back

=head1 FUNCTIONS


=head2 check_release_matches

Usage:

 check_release_matches(%args) -> [$status_code, $reason, $payload, \%result_meta]

Given an expression and one or more releases, show which releases match the expression.

Examples:

=over

=item * Example #1:

 check_release_matches(expr => ">1.31", releases => [2.1]);

Result:

 [
   200,
   "OK (matches)",
   "Release(s) match expression",
   { "cmdline.exit_code" => 0 },
 ]

=item * Example #2:

 check_release_matches(expr => ">1.31", releases => [1.3]);

Result:

 [
   200,
   "OK (no match)",
   "Release(s) do NOT match expression",
   { "cmdline.exit_code" => 1 },
 ]

=item * Example #3:

 check_release_matches(expr => ">1.31", releases => [1.31]);

Result:

 [
   200,
   "OK (no match)",
   "Release(s) do NOT match expression",
   { "cmdline.exit_code" => 1 },
 ]

=item * Example #4:

 check_release_matches(expr => ">1.31", releases => [2.1, 1.32, 1.31, 1.3]);

Result:

 [
   200,
   "OK (matches)",
   "Release(s) match expression",
   { "cmdline.exit_code" => 0 },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<expr>* => I<str>

(No description)

=item * B<quiet> => I<bool>

(No description)

=item * B<releases>* => I<array[str]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ModuleReleaseSelectUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ModuleReleaseSelectUtils>.

=head1 SEE ALSO

L<Module::Release::Select>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ModuleReleaseSelectUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
