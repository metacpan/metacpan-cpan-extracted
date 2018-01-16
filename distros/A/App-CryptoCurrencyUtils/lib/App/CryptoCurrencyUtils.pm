package App::CryptoCurrencyUtils;

our $DATE = '2018-01-12'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{cmc_currency} = {
    v => 1.1,
    summary => 'Open CMC (coinmarketcap.com) currency page',
    args => {
        symbol_or_name => {
            schema => 'cryptocurrency::symbol_or_name*',
            req => 1,
            pos => 0,
        },
    },
};
sub cmc_currency {
    require CryptoCurrency::Catalog;
    my %args = @_;

    my $cat = CryptoCurrency::Catalog->new;

    my $cur0 = $args{symbol_or_name}
        or return [400, "Please specify symbol/name"];

    my $cur;
    {
        eval { $cur = $cat->by_symbol($cur0) };
        last if $cur;
        eval { $cur = $cat->by_name($cur0) };
        last if $cur;
        return [404, "No such cryptocurrency symbol/name"];
    }

    require Browser::Open;
    my $err = Browser::Open::open_browser(
        "https://coinmarketcap.com/currencies/$cur->{safename}/");
    return [500, "Can't open browser"] if $err;
    [200];
}

1;
# ABSTRACT: CLI utilities related to cryptocurrencies

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CryptoCurrencyUtils - CLI utilities related to cryptocurrencies

=head1 VERSION

This document describes version 0.002 of App::CryptoCurrencyUtils (from Perl distribution App-CryptoCurrencyUtils), released on 2018-01-12.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<cmc-currency>

=item * L<grepcrypto>

=back

=head1 FUNCTIONS


=head2 cmc_currency

Usage:

 cmc_currency(%args) -> [status, msg, result, meta]

Open CMC (coinmarketcap.com) currency page.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<symbol_or_name>* => I<cryptocurrency::symbol_or_name>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CryptoCurrencyUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CryptoCurrencyUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CryptoCurrencyUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::CoinMarketCapUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
