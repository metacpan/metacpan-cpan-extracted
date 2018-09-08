package App::finquotehist;

our $DATE = '2018-09-07'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

my $sch_date = [
    'date*', {
        'x.perl.coerce_to' => 'DateTime',
        'x.perl.coerce_rules' => ['str_natural'],
    },
];

$SPEC{finquotehist} = {
    v => 1.1,
    summary => 'Fetch historical stock quotes',
    args => {
        action => {
            schema => 'str*',
            description => <<'_',

Choose what action to perform. The default is 'fetch_quotes'. Other actions include:

* 'fetch_splits' - Fetch splits.
* 'fetch_dividends' - Fetch dividends.
* 'list_engines' - List available engines (backends).

_
            default => 'fetch_quotes',
            cmdline_aliases => {
                l => {is_flag=>1, summary => 'Shortcut for --action list_engines', code => sub { $_[0]{action} = 'list_engines' }},
            },
        },
        symbols => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'symbol',
            schema => ['array*', of=>'str*', min_len=>1],
            pos => 0,
            greedy => 1,
        },
        from => {
            schema => $sch_date,
            tags => ['category:filtering'],
        },
        to => {
            schema => $sch_date,
            tags => ['category:filtering'],
        },
       engines => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'engine',
            schema => ['array*', of=>'perl::modname*'],
            default => ['Yahoo', 'Google'],
            element_completion => sub {
                require Complete::Module;
                my %args = @_;
                my $ans = Complete::Module::complete_module(
                    word => $args{word},
                    ns_prefix => 'Finance::QuoteHist',
                );
                [grep {$_ !~ /\A(Generic)\z/} @$ans];
            },
            cmdline_aliases => {
                e => {},
            },
        },
    },
    examples => [
        {
            summary => 'List available engines (backends)',
            argv => [qw/-l/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch historical quote (by default 1 year) for a few NASDAQ stocks',
            argv => [qw/AAPL AMZN MSFT/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quotes for a few Indonesian stocks, for a certain date range',
            argv => [qw/--from 2018-01-01 --to 2018-09-07 BBCA.JK BBRI.JK TLKM.JK/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quotes for a stock, from 3 years ago',
            argv => ['--from', '3 years ago', 'AAPL'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch splits for a few Indonesian stocks',
            argv => [qw/--action fetch_splits BBCA.JK BBRI.JK TLKM.JK/],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub finquotehist {
    my %args = @_;
    my $action = $args{action} // 'fetch';

    if ($action eq 'list_engines') {
        require PERLANCAR::Module::List;
        my $mods = PERLANCAR::Module::List::list_modules(
            "Finance::QuoteHist::", {list_modules=>1});
        return [200, "OK", [
            grep {!/\A(Generic)\z/}
                map {my $x = $_; $x =~ s/\AFinance::QuoteHist:://; $x}
                sort keys %$mods]];
    } elsif ($action eq 'fetch_quotes' || $action eq 'fetch_splits' || $action eq 'fetch_dividends') {
        require DateTime;
        require Finance::QuoteHist;

        return [400, "Please specify one or more symbols"]
            unless $args{symbols} && @{ $args{symbols} };

        my $from = $args{from} // DateTime->today->subtract(years=>1);
        my $to   = $args{to}   // DateTime->today;
        my $q = Finance::QuoteHist->new(
            lineup  => [map {"Finance::QuoteHist::$_"} @{ $args{engines} }],
            symbols => $args{symbols},
            start_date => $from->strftime("%m/%d/%Y"),
            end_date   => $to  ->strftime("%m/%d/%Y"),
        );
        my @rows;
        my @rows0;
        if    ($action eq 'fetch_quotes'   ) { @rows0 = $q->quotes }
        elsif ($action eq 'fetch_splits'   ) { @rows0 = $q->splits }
        elsif ($action eq 'fetch_dividends') { @rows0 = $q->dividends }
        my $fields;
        for my $row0 (@rows0) {
            my $row;
            if ($action eq 'fetch_quotes') {
                $fields //= [qw/symbol date open high low close volume adjclose/];
                $row = {
                    symbol   => $row0->[0],
                    date     => $row0->[1],
                    open     => $row0->[2],
                    high     => $row0->[3],
                    low      => $row0->[4],
                    close    => $row0->[5],
                    volume   => $row0->[6],
                    adjclose => $row0->[7],
                };
            } elsif ($action eq 'fetch_splits') {
                $fields //= [qw/symbol date post pre/];
                $row = {
                    symbol   => $row0->[0],
                    date     => $row0->[1],
                    post     => $row0->[2],
                    pre      => $row0->[3],
                };
            } elsif ($action eq 'fetch_dividends') {
                $fields //= [qw/symbol date dividend/];
                $row = {
                    symbol   => $row0->[0],
                    date     => $row0->[1],
                    dividend => $row0->[2],
                };
            }
            push @rows, $row;
        }
        [200, "OK", \@rows, {'table.fields' => $fields}];
    } else {
        return [400, "Unknown action"];
    }
}

1;
# ABSTRACT: Fetch historical stock quotes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::finquotehist - Fetch historical stock quotes

=head1 VERSION

This document describes version 0.001 of App::finquotehist (from Perl distribution App-finquotehist), released on 2018-09-07.

=head1 SYNOPSIS

See L<finquotehist> script.

=head1 FUNCTIONS


=head2 finquotehist

Usage:

 finquotehist(%args) -> [status, msg, result, meta]

Fetch historical stock quotes.

Examples:

=over

=item * List available engines (backends):

 finquotehist( action => "list_engines");

=item * Fetch historical quote (by default 1 year) for a few NASDAQ stocks:

 finquotehist( symbols => ["AAPL", "AMZN", "MSFT"]);

=item * Fetch quotes for a few Indonesian stocks, for a certain date range:

 finquotehist(
   symbols => ["BBCA.JK", "BBRI.JK", "TLKM.JK"],
   from => "2018-01-01",
   to => "2018-09-07"
 );

=item * Fetch quotes for a stock, from 3 years ago:

 finquotehist( symbols => ["AAPL"], from => "3 years ago");

=item * Fetch splits for a few Indonesian stocks:

 finquotehist(
   symbols => ["BBCA.JK", "BBRI.JK", "TLKM.JK"],
   action  => "fetch_splits"
 );

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "fetch_quotes")

Choose what action to perform. The default is 'fetch_quotes'. Other actions include:

=over

=item * 'fetch_splits' - Fetch splits.

=item * 'fetch_dividends' - Fetch dividends.

=item * 'list_engines' - List available engines (backends).

=back

=item * B<engines> => I<array[perl::modname]> (default: ["Yahoo","Google"])

=item * B<from> => I<date>

=item * B<symbols> => I<array[str]>

=item * B<to> => I<date>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-finquotehist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-finquotehist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-finquotehist>

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
