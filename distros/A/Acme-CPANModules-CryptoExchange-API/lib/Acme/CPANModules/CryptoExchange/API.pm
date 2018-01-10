package Acme::CPANModules::CryptoExchange::API;

our $DATE = '2018-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "Modules that interface to cryptocurrency exchanges",
    entries => [
        {
            module => 'WebService::Cryptopia',
        },
        {
            module => 'WebService::Binance',
        },
        {
            module => 'Finance::BTCIndo',
        },
        {
            module => 'Finance::BitFlip',
        },
        {
            module => 'Finance::Bank::Kraken',
        },
        {
            module => 'Poloniex::API',
        },
        {
            module => 'WWW::API::Bitfinex',
        },
        {
            module => 'Finance::BitStamp::API',
        },
        {
            module => 'Finance::GDAX::API',
        },
        {
            module => 'Finance::LocalBitcoins::API',
        },
    ],
};

1;
# ABSTRACT: Modules that interface to cryptocurrency exchanges

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CryptoExchange::API - Modules that interface to cryptocurrency exchanges

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::CryptoExchange::API (from Perl distribution Acme-CPANModules-CryptoExchange-API), released on 2018-01-09.

=head1 DESCRIPTION

Modules that interface to cryptocurrency exchanges.

=head1 INCLUDED MODULES

=over

=item * L<WebService::Cryptopia>

=item * L<WebService::Binance>

=item * L<Finance::BTCIndo>

=item * L<Finance::BitFlip>

=item * L<Finance::Bank::Kraken>

=item * L<Poloniex::API>

=item * L<WWW::API::Bitfinex>

=item * L<Finance::BitStamp::API>

=item * L<Finance::GDAX::API>

=item * L<Finance::LocalBitcoins::API>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CryptoExchange-API>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CryptoExchange-API>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CryptoExchange-API>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
