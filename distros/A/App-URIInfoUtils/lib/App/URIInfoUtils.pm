package App::URIInfoUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-26'; # DATE
our $DIST = 'App-URIInfoUtils'; # DIST
our $VERSION = '0.003'; # VERSION

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
    examples => [
        {args=>{uris=>["https://www.tokopedia.com/search?st=product&q=comic%20books"]}},
        {
            args => {uris=>[
                "https://www.google.com/search?client=firefox-b-d&q=how+much+drink+water+everyday",
                "https://www.youtube.com/results?search_query=alkaline+water",
                ]},
        },
    ],
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

This document describes version 0.003 of App::URIInfoUtils (from Perl distribution App-URIInfoUtils), released on 2021-11-26.

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

Examples:

=over

=item * Example #1:

 uri_info(
   uris => [
     "https://www.tokopedia.com/search?st=product&q=comic%20books",
   ]
 );

Result:

 [
   200,
   "OK",
   [
     {
       host => "www.tokopedia.com",
       is_search => 1,
       search_query => "comic books",
       search_type => "product",
       url => "https://www.tokopedia.com/search?st=product&q=comic%20books",
     },
   ],
   {},
 ]

=item * Example #2:

 uri_info(
   uris => [
     "https://www.google.com/search?client=firefox-b-d&q=how+much+drink+water+everyday",
     "https://www.youtube.com/results?search_query=alkaline+water",
   ]
 );

Result:

 [
   200,
   "OK",
   [
     {
       host => "www.google.com",
       is_search => 1,
       search_query => "how much drink water everyday",
       search_source => "google",
       search_type => "search",
       url => "https://www.google.com/search?client=firefox-b-d&q=how+much+drink+water+everyday",
     },
     {
       host => "www.youtube.com",
       url  => "https://www.youtube.com/results?search_query=alkaline+water",
     },
   ],
   {},
 ]

=back

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

L<parse-search-string-from-url> from L<App::ParseSearchStringFromURL>, which is
currently based from L<URI::ParseSearchString>.

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
