package App::LevenshteinUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-18'; # DATE
our $DIST = 'App-LevenshteinUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

our @algos = (
    'editdist',
    'Text::Fuzzy',
    'Text::Levenshtein',
    'Text::Levenshtein::Flexible',
    'Text::Levenshtein::XS',
    'Text::LevenshteinXS',
);

$SPEC{editdist} = {
    v => 1.1,
    summary => 'Calculate edit distance using one of several algorithm',
    args => {
        str1 => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        str2 => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        algo => {
            schema => ['str*', in=>\@algos, default=>'editdist'],
        },
    },
};
sub editdist {
    my %args = @_;

    my $str1 = $args{str1};
    my $str2 = $args{str2};
    my $algo = $args{algo} // 'editdist';

    if ($algo eq 'editdist') {
        require PERLANCAR::Text::Levenshtein;
        return [200,"OK",PERLANCAR::Text::Levenshtein::editdist($str1, $str2)];
    } elsif ($algo eq 'Text::Fuzzy') {
        require Text::Fuzzy;
        return [200,"OK",Text::Fuzzy->new($str1)->distance($str2)];
    } elsif ($algo eq 'Text::Levenshtein') {
        require Text::Levenshtein;
        return [200,"OK",Text::Levenshtein::fastdistance($str1,$str2)];
    } elsif ($algo eq 'Text::Levenshtein::XS') {
        require Text::Levenshtein::XS;
        return [200,"OK",Text::Levenshtein::XS::distance($str1,$str2)];
    } elsif ($algo eq 'Text::LevenshteinXS') {
        require Text::LevenshteinXS;
        return [200,"OK",Text::LevenshteinXS::distance($str1,$str2)];
    } elsif ($algo eq 'Text::Levenshtein::Flexible') {
        require Text::Levenshtein::Flexible;
        return [200,"OK",Text::Levenshtein::Flexible::levenshtein($str1,$str2)];
    } else {
        return [400, "Unknown algorithm '$algo'"];
    }
}

1;
# ABSTRACT: CLI utilities related to Levenshtein algorithm

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LevenshteinUtils - CLI utilities related to Levenshtein algorithm

=head1 VERSION

This document describes version 0.002 of App::LevenshteinUtils (from Perl distribution App-LevenshteinUtils), released on 2024-01-18.

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to
levenshtein algorithm:

=over

=item * L<editdist>

=back

=head1 FUNCTIONS


=head2 editdist

Usage:

 editdist(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate edit distance using one of several algorithm.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<algo> => I<str> (default: "editdist")

(No description)

=item * B<str1>* => I<str>

(No description)

=item * B<str2>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-LevenshteinUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LevenshteinUtils>.

=head1 SEE ALSO

L<Bencher::Scenario::LevenshteinModules>

L<App::TextSimilarityUtils>

L<complete-array-elem> from L<App::CompleteCLIs>, a CLI for L<Complete::Util>'s
C<complete_array_elem>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LevenshteinUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
