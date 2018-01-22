package App::CryptoCurrencyUtils;

our $DATE = '2018-01-21'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %arg_symbol_or_name = (
    symbol_or_name => {
        schema => 'cryptocurrency::symbol_or_name*',
        req => 1,
        pos => 0,
    },
);

our %arg_symbols_or_names = (
    symbols_or_names => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'symbol_or_name',
        schema => ['array*', of=>'cryptocurrency::symbol_or_name*'],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

$SPEC{coin_cmc} = {
    v => 1.1,
    summary => "Go to coin's CMC (coinmarketcap.com) currency page",
    args => {
        %arg_symbols_or_names,
    },
};
sub coin_cmc {
    require CryptoCurrency::Catalog;
    my %args = @_;

    my $cat = CryptoCurrency::Catalog->new;

  CURRENCY:
    for my $cur0 (@{ $args{symbols_or_names} }) {

        my $cur;
        {
            eval { $cur = $cat->by_symbol($cur0) };
            last if $cur;
            eval { $cur = $cat->by_name($cur0) };
            last if $cur;
            warn "No such cryptocurrency symbol/name '$cur0'";
            next CURRENCY;
        }

        require Browser::Open;
        my $url = "https://coinmarketcap.com/currencies/$cur->{safename}/";
        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser for '$url'"] if $err;
    }
    [200];
}

$SPEC{coin_mno} = {
    v => 1.1,
    summary => "Go to coin's MNO (masternodes.online) currency page",
    description => <<'_',

Currently does not perform any translation between CMC -> MNO currency code if
there is a difference.

_
    args => {
        %arg_symbols_or_names,
    },
};
sub coin_mno {
    require CryptoCurrency::Catalog;
    require URI::Escape;

    my %args = @_;

    my $cat = CryptoCurrency::Catalog->new;

  CURRENCY:
    for my $cur0 (@{ $args{symbols_or_names} }) {

        my $cur;
        {
            eval { $cur = $cat->by_symbol($cur0) };
            last if $cur;
            eval { $cur = $cat->by_name($cur0) };
            last if $cur;
            warn "No such cryptocurrency symbol/name '$cur0'";
            next CURRENCY;
        }

        require Browser::Open;
        my $url = "https://masternodes.online/currencies/" .
            URI::Escape::uri_escape($cur->{symbol})."/";
        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser for '$url'"] if $err;
    }
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

This document describes version 0.004 of App::CryptoCurrencyUtils (from Perl distribution App-CryptoCurrencyUtils), released on 2018-01-21.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<coin-cmc>

=item * L<coin-mno>

=item * L<grepcoin>

=back

=head1 FUNCTIONS


=head2 coin_cmc

Usage:

 coin_cmc(%args) -> [status, msg, result, meta]

Go to coin's CMC (coinmarketcap.com) currency page.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<symbols_or_names>* => I<array[cryptocurrency::symbol_or_name]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 coin_mno

Usage:

 coin_mno(%args) -> [status, msg, result, meta]

Go to coin's MNO (masternodes.online) currency page.

Currently does not perform any translation between CMC -> MNO currency code if
there is a difference.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<symbols_or_names>* => I<array[cryptocurrency::symbol_or_name]>

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

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
