package App::LocaleCodesUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'App-LocaleCodesUtils'; # DIST
our $VERSION = '0.004'; # VERSION

our %SPEC;

$SPEC{country_code2code} = {
    v => 1.1,
    summary => 'Convert country code (alpha2 <-> alpha3)',
    args => {
        code => {
            schema => 'country::code',
            req => 1,
            pos => 0,
        },
    },
};
sub country_code2code {
    require Locale::Codes::Country;

    my %args = @_;
    my $code = $args{code};

    my $code2;
    if (length($code) == 2) {
        $code2 = Locale::Codes::Country::country_code2code($code, 'alpha-2', 'alpha-3');
    } elsif (length($code) == 3) {
        $code2 = Locale::Codes::Country::country_code2code($code, 'alpha-3', 'alpha-2');
    } else {
        return [400, "Please specify alpha-2 or alpha-3 code"];
    }
    return [404, "Unknown or non-unique code '$code'"] unless defined $code2;
    [200, "OK", $code2];
}

$SPEC{language_code2code} = {
    v => 1.1,
    summary => 'Convert language code (alpha2 <-> alpha3)',
    args => {
        code => {
            schema => 'language::code',
            req => 1,
            pos => 0,
        },
    },
};
sub language_code2code {
    require Locale::Codes::Language;

    my %args = @_;
    my $code = $args{code};

    my $code2;
    if (length($code) == 2) {
        $code2 = Locale::Codes::Language::language_code2code($code, 'alpha-2', 'alpha-3');
    } elsif (length($code) == 3) {
        $code2 = Locale::Codes::Language::language_code2code($code, 'alpha-3', 'alpha-2');
    } else {
        return [400, "Please specify alpha-2 or alpha-3 code"];
    }
    return [404, "Unknown or non-unique code '$code'"] unless defined $code2;
    [200, "OK", $code2];
}

1;
# ABSTRACT: Utilities related to locale codes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LocaleCodesUtils - Utilities related to locale codes

=head1 VERSION

This document describes version 0.004 of App::LocaleCodesUtils (from Perl distribution App-LocaleCodesUtils), released on 2023-08-06.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<country-code2code>

=item * L<language-code2code>

=item * L<list-countries>

=item * L<list-currencies>

=item * L<list-languages>

=item * L<list-scripts>

=back

=head1 FUNCTIONS


=head2 country_code2code

Usage:

 country_code2code(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert country code (alpha2 <-E<gt> alpha3).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<country::code>

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



=head2 language_code2code

Usage:

 language_code2code(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert language code (alpha2 <-E<gt> alpha3).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<language::code>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-LocaleCodesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LocaleCodesUtils>.

=head1 SEE ALSO

L<Locale::Codes>

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

This software is copyright (c) 2023, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LocaleCodesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
