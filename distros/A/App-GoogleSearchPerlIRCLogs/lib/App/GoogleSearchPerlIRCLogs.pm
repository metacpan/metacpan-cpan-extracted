package App::GoogleSearchPerlIRCLogs;

our $DATE = '2016-02-11'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

our %SPEC;

my $cur_year = (localtime)[5] + 1900;

$SPEC{google_search_perl_irc_logs} = {
    v => 1.1,
    summary => 'Search Google for stuffs in Perl IRC logs',
    description => <<'_',

Currently searching with `site:irclog.perlgeek.org`.

_
    args => {
        query => {
            schema => ['array*', of => 'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
        year => {
            schema => ['int*', min=>1990, max=>$cur_year],
            cmdline_aliases => {y=>{}},
        },
        # XXX channel, limit site to irclog.perlgeek.de/CHANNEL/
    },
    examples => [
        {
            summary => 'Who mentions me?',
            src => 'google-search-perl-irc-logs perlancar',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Who mentions me in 2016?',
            src => 'google-search-perl-irc-logs perlancar -y 2016',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub google_search_perl_irc_logs {
    require Browser::Open;
    require URI::Escape;

    my %args = @_;

    my $query = join(
        " ",
        "site:irclog.perlgeek.de",
        @{$args{query}},
        ($args{year} ? ("inurl:/$args{year}") : ()),

        # skip text/raw version
        qq(-inurl:/text),
    );

    my $url = "https://www.google.com/search?num=100&q=".
        URI::Escape::uri_escape($query);

    my $res = Browser::Open::open_browser($url);

    $res ? [500, "Failed"] : [200, "OK"];
}

1;
# ABSTRACT: Search Google for stuffs in Perl IRC logs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GoogleSearchPerlIRCLogs - Search Google for stuffs in Perl IRC logs

=head1 VERSION

This document describes version 0.01 of App::GoogleSearchPerlIRCLogs (from Perl distribution App-GoogleSearchPerlIRCLogs), released on 2016-02-11.

=head1 SYNOPSIS

Use the included script L<google-search-perl-irc-logs>.

=head1 FUNCTIONS


=head2 google_search_perl_irc_logs(%args) -> [status, msg, result, meta]

Search Google for stuffs in Perl IRC logs.

Currently searching with C<site:irclog.perlgeek.org>.

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<query>* => I<array[str]>

=item * B<year> => I<int>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-GoogleSearchPerlIRCLogs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GoogleSearchPerlIRCLogs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GoogleSearchPerlIRCLogs>

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
