package App::URIInfoUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-17'; # DATE
our $DIST = 'App-URIInfoUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{uri_info} = {
    v => 1.1,
    summary => 'Extract information from one or more URIs',
    args => {
        uris => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'uri',
            schema => ['array*', of=>'str*'], # XXX uri
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
        # XXX include_plugins
        # XXX exclude_plugins
    },
};
sub uri_info {
    require URI::Info;

    my %args = @_;

    my $ui = URI::Info->new(
        # include_plugins => ...
        # exclude_plugins => ...
    );

    my @rows;
    for my $uri (@{$args{uris}}) {
        my $res = $ui->info($uri);
        push @rows, $res;
    }
    [200, "OK", \@rows];
}

1;
# ABSTRACT: Utilities related to URI::Info

__END__

=pod

=encoding UTF-8

=head1 NAME

App::URIInfoUtils - Utilities related to URI::Info

=head1 VERSION

This document describes version 0.001 of App::URIInfoUtils (from Perl distribution App-URIInfoUtils), released on 2021-10-17.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<uri-info>

=back

=head1 FUNCTIONS


=head2 uri_info

Usage:

 uri_info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Extract information from one or more URIs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<uris>* => I<array[str]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-URIInfoUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-URIInfoUtils>.

=head1 SEE ALSO

L<URI::Info>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-URIInfoUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
