package App::GoogleSearchPerlmonksUser;

our $DATE = '2016-01-19'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

our %SPEC;

$SPEC{google_search_perlmonks_user} = {
    v => 1.1,
    summary => 'Search Google for user mentions in perlmonks.org',
    description => <<'_',

Basically a shortcut for launching Google search for a user (specifically, user
mentions in discussion threads) in `perlmonks.org` site, with some unwanted
pages excluded.

_
    args => {
        user => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub google_search_perlmonks_user {
    require Browser::Open;
    require URI::Escape;

    my %args = @_;
    # XXX schema
    my $user = $args{user} or return [400, "Please specify user"];

    my $query = join(
        " ",
        "site:perlmonks.org",
        $user,
        qq(-inurl:/bare), # skip bare pages
        qq(-intitle:"$user\'s scratchpad"), # skip scratchpad

        # skip some versions of pages
        qq(-inurl:"displaytype=print"),
        qq(-inurl:"displaytype=xml"),
        qq(-inurl:"displaytype=edithistory"),

        qq(-intitle:"Perl Monks User Search"), # skip search result page

        # TODO: how to exclude "Other Users" box? it would be nice if
        # perlmonks.org marks some sections to be excluded by google, ref:
        # http://www.perlmonks.org/?node_id=1136864
    );

    my $url = "https://www.google.com/search?num=100&q=".
        URI::Escape::uri_escape($query);

    my $res = Browser::Open::open_browser($url);

    $res ? [500, "Failed"] : [200, "OK"];
}

1;
# ABSTRACT: Search Google for user mentions in perlmonks.org

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GoogleSearchPerlmonksUser - Search Google for user mentions in perlmonks.org

=head1 VERSION

This document describes version 0.01 of App::GoogleSearchPerlmonksUser (from Perl distribution App-GoogleSearchPerlmonksUser), released on 2016-01-19.

=head1 SYNOPSIS

Use the included script L<google-search-perlmonks-user>.

=head1 FUNCTIONS


=head2 google_search_perlmonks_user(%args) -> [status, msg, result, meta]

Search Google for user mentions in perlmonks.org.

Basically a shortcut for launching Google search for a user (specifically, user
mentions in discussion threads) in C<perlmonks.org> site, with some unwanted
pages excluded.

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<user>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-GoogleSearchPerlmonksUser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GoogleSearchPerlmonksUser>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GoogleSearchPerlmonksUser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
