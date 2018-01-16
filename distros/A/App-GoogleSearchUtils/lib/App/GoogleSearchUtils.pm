package App::GoogleSearchUtils;

our $DATE = '2018-01-13'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{google_search} = {
    v => 1.1,
    summary => 'Open google search page in browser',
    args => {
        query => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        num => {
            summary => 'Number of results per page',
            schema => 'posint*',
            default => 100,
        },
    },
};
sub google_search {
    require Browser::Open;
    require URI::Escape;

    my %args = @_;
    # XXX schema
    my $query = $args{query} or return [400, "Please specify query"];
    my $num = $args{num} + 0;

    my $url = "https://www.google.com/search?num=$num&q=".
        URI::Escape::uri_escape($query);

    my $res = Browser::Open::open_browser($url);

    $res ? [500, "Failed"] : [200, "OK"];
}

1;
# ABSTRACT: CLI utilites related to google searching

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GoogleSearchUtils - CLI utilites related to google searching

=head1 VERSION

This document describes version 0.001 of App::GoogleSearchUtils (from Perl distribution App-GoogleSearchUtils), released on 2018-01-13.

=head1 SYNOPSIS

This distribution provides the following utilities:

=over

=item * L<google-search>

=back

=head1 FUNCTIONS


=head2 google_search

Usage:

 google_search(%args) -> [status, msg, result, meta]

Open google search page in browser.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num> => I<posint> (default: 100)

Number of results per page.

=item * B<query>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GoogleSearchUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GoogleSearchUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GoogleSearchUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
