package App::HeightUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-09-15'; # DATE
our $DIST = 'App-HeightUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

$SPEC{calc_child_height_potential} = {
    v => 1.1,
    summary => "Calculate child potential height based on mother's and father's height",
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        gender => {
            schema => ['str*', in=>['M','F']],
            req => 1,
            pos => 0,
            cmdline_aliases => {
                boy  => { is_flag=>1, summary=>'Shortcut for `--gender=M`', code=>sub { $_[0]{gender} = 'M' } },
                girl => { is_flag=>1, summary=>'Shortcut for `--gender=F`', code=>sub { $_[0]{gender} = 'F' } },
            },
        },
        father_height => {
            summary => "Father's height (in cm)",
            schema => 'posint*',
            req => 1,
            pos => 1,
        },
        mother_height => {
            summary => "Mother's height (in cm)",
            schema => 'posint*',
            req => 1,
            pos => 2,
        },
    },
};
sub calc_child_height_potential {
    my %args = @_;

    my $child_height = ($args{mother_height} + $args{father_height} + ($args{gender} eq 'M' ? 13 : -13))/2;
    [200, "OK", [$child_height-8.5, $child_height+8.5]];
}

1;
# ABSTRACT: Utilities related to body height

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HeightUtils - Utilities related to body height

=head1 VERSION

This document describes version 0.002 of App::HeightUtils (from Perl distribution App-HeightUtils), released on 2024-09-15.

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to body
height:

=over

=item * L<calc-child-height-potential>

=back

=head1 FUNCTIONS


=head2 calc_child_height_potential

Usage:

 calc_child_height_potential(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate child potential height based on mother's and father's height.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<father_height>* => I<posint>

Father's height (in cm).

=item * B<gender>* => I<str>

(No description)

=item * B<mother_height>* => I<posint>

Mother's height (in cm).


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

Please visit the project's homepage at L<https://metacpan.org/release/App-HeightUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-HeightUtils>.

=head1 SEE ALSO

L<App::WeightUtils>

L<App::WHOGrowthReferenceUtils>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-HeightUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
