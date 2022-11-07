package App::StringQueryToRegexpUtils;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-04'; # DATE
our $DIST = 'App-StringQueryToRegexpUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{query2re} = {
    v => 1.1,
    summary => 'Convert a query to regex and show it',
    args => {
        queries => {
            summary => 'Query terms',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'query',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        bool => {
            schema => ['str*', in=>['and','or']],
            default => 'and',
            cmdline_aliases => {
                or  => {is_flag=>1, summary=>'Shortcut or --bool=or' , code=>sub {$_[0]{bool} = 'or' }},
                and => {is_flag=>1, summary=>'Shortcut or --bool=and', code=>sub {$_[0]{bool} = 'and'}},
            },
        },
        ci => {
            summary => 'Search case-insensitively',
            schema => 'true*',
            cmdline_aliases => {i=>{}},
        },
        word => {
            summary => 'Perform word searching (terms must be whole words)',
            schema => 'true*',
        },
        re => {
            summary => 'Whether to allow regex in query terms',
            schema => 'bool*',
            default => 1,
        },
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Must match all terms',
            args => {queries=>[qw/term1 term2/]},
        },
        {
            summary => 'Must contain term1 and term2 but must not contain term3',
            argv => [qw/-- term1 term2 -term3/],
        },
        {
            summary => 'Need to only match one term, search case-insensitively',
            argv => [qw/--or -i term1 term2 term3/],
        },
        {
            summary => 'Regex in term',
            argv => [qw(term1 /term2.*/ term3)],
        },
        {
            summary => 'Word searching (terms must be whole words)',
            argv => [qw(--word word1 word2 word3)],
        },
        {
            summary => 'Disallow regex searching',
            argv => [qw(--no-re term1 /term2.+/ term3)],
        },
    ],
};
sub query2re {
    require String::Query::To::Regexp;

    my %args = @_;
    "" . String::Query::To::Regexp::query2re(
        {bool=>$args{bool}, ci=>$args{ci}, re=>$args{re}, word=>$args{word}},
        @{ $args{queries} });
}

1;
# ABSTRACT: CLIs for String::Query::To::Regexp

__END__

=pod

=encoding UTF-8

=head1 NAME

App::StringQueryToRegexpUtils - CLIs for String::Query::To::Regexp

=head1 VERSION

This document describes version 0.001 of App::StringQueryToRegexpUtils (from Perl distribution App-StringQueryToRegexpUtils), released on 2022-11-04.

=head1 DESCRIPTION

This distribution includes the following command-line utilities:

=over

=item * L<query2re>

=back

=head1 FUNCTIONS


=head2 query2re

Usage:

 query2re(%args) -> any

Convert a query to regex and show it.

Examples:

=over

=item * Must match all terms:

 query2re(queries => ["term1", "term2"]); # -> "(?^s:\\A(?=.*term1)(?=.*term2).*\\z)"

=item * Must contain term1 and term2 but must not contain term3:

 query2re(queries => ["term1", "term2", "-term3"]);

Result:

 "(?^s:\\A(?=.*term1)(?=.*term2)(?!.*term3).*\\z)"

=item * Need to only match one term, search case-insensitively:

 query2re(queries => ["term1", "term2", "term3"], bool => "or", ci => 1);

Result:

 "(?^si:\\A(?:(?=.*term1)|(?=.*term2)|(?=.*term3)).*\\z)"

=item * Regex in term:

 query2re(queries => ["term1", "/term2.*/", "term3"]);

Result:

 "(?^s:\\A(?=.*term1)(?=.*(?^:term2.*))(?=.*term3).*\\z)"

=item * Word searching (terms must be whole words):

 query2re(queries => ["word1", "word2", "word3"], word => 1);

Result:

 "(?^s:\\A(?=.*\\bword1\\b)(?=.*\\bword2\\b)(?=.*\\bword3\\b).*\\z)"

=item * Disallow regex searching:

 query2re(queries => ["term1", "/term2.+/", "term3"], re => 0);

Result:

 "(?^s:\\A(?=.*term1)(?=.*\\/term2\\.\\+\\/)(?=.*term3).*\\z)"

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bool> => I<str> (default: "and")

(No description)

=item * B<ci> => I<true>

Search case-insensitively.

=item * B<queries>* => I<array[str]>

Query terms.

=item * B<re> => I<bool> (default: 1)

Whether to allow regex in query terms.

=item * B<word> => I<true>

Perform word searching (terms must be whole words).


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-StringQueryToRegexpUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-StringQueryToRegexpUtils>.

=head1 SEE ALSO

L<String::Query::To::Regexp>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-StringQueryToRegexpUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
