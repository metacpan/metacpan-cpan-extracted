package App::finquote;

our $DATE = '2018-09-07'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

sub _get_q {
    require Finance::Quote;
    my $q = Finance::Quote->new;
    $q->timeout(60);
    $q;
}

$SPEC{finquote} = {
    v => 1.1,
    summary => 'Get stock and mutual fund quotes from various exchanges',
    args => {
        action => {
            schema => 'str*',
            description => <<'_',

Choose what action to perform. The default is 'fetch'. Other actions include:

* 'list_sources' - List available sources.

_
            default => 'fetch',
            cmdline_aliases => {
                l => {is_flag=>1, summary => 'Shortcut for --action list_sources', code => sub { $_[0]{action} = 'list_sources' }},
            },
        },
        symbols => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'symbol',
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
        },
        sources => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'source',
            schema => ['array*', of=>'str*'],
            #elem_completion => sub {
            #    my %args = @_;
            #},
            cmdline_aliases => {
                s => {},
            },
        },
    },
    examples => [
        {
            summary => 'List available sources',
            argv => [qw/-l/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quote for a few NASDAQ stocks',
            argv => [qw/-s nasdaq AAPL AMZN MSFT/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quote for a few Indonesian stocks',
            argv => [qw/-s asia BBCA.JK BBRI.JK TLKM.JK/],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub finquote {
    my %args = @_;
    my $action = $args{action} // 'fetch';

    if ($action eq 'list_sources') {
        my $q = _get_q();
        return [200, "OK", [sort $q->sources]];
    } elsif ($action eq 'fetch') {
        my $q = _get_q();
        my $symbols = $args{symbols};
        return [400, "Please specify at least one symbol to fetch quotes of"]
            unless $symbols && @$symbols;
        my $sources = $args{sources};
        return [400, "Please specify at least one source to fetch quotes from"]
            unless $symbols && @$sources;
        my $num_success = 0;
        my @rows;
        for my $source (@$sources) {
            my $info = $q->fetch($source, @$symbols);
            if (!$info || !keys(%$info)) {
                log_warn "Couldn't fetch quotes %s from %s", $symbols, $source;
                next;
            }
            $info->{source} = $source;
            push @rows, $info;
            $num_success++;
        }
        if ($num_success) {
            return [200, "OK", \@rows];
        } else {
            return [500, "Couldn't fetch any quote"];
        }
    } else {
        return [400, "Unknown action"];
    }
}

1;
# ABSTRACT: Get stock and mutual fund quotes from various exchanges

__END__

=pod

=encoding UTF-8

=head1 NAME

App::finquote - Get stock and mutual fund quotes from various exchanges

=head1 VERSION

This document describes version 0.003 of App::finquote (from Perl distribution App-finquote), released on 2018-09-07.

=head1 SYNOPSIS

See L<finquote> script.

=head1 FUNCTIONS


=head2 finquote

Usage:

 finquote(%args) -> [status, msg, result, meta]

Get stock and mutual fund quotes from various exchanges.

Examples:

=over

=item * List available sources:

 finquote( action => "list_sources");

=item * Fetch quote for a few NASDAQ stocks:

 finquote( symbols => ["AAPL", "AMZN", "MSFT"], sources => ["nasdaq"]);

=item * Fetch quote for a few Indonesian stocks:

 finquote( symbols => ["BBCA.JK", "BBRI.JK", "TLKM.JK"], sources => ["asia"]);

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "fetch")

Choose what action to perform. The default is 'fetch'. Other actions include:

=over

=item * 'list_sources' - List available sources.

=back

=item * B<sources> => I<array[str]>

=item * B<symbols> => I<array[str]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-finquote>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-finquote>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-finquote>

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
