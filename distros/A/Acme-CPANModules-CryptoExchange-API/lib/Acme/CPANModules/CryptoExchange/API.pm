package Acme::CPANModules::CryptoExchange::API;

our $DATE = '2020-12-27'; # DATE
our $VERSION = '0.004'; # VERSION

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
            module => 'Finance::Indodax',
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
            summary => 'Last time I tried, not working',
            alternate_modules => ['Finance::GDAX::Lite'],
        },
        {
            module => 'Finance::GDAX::Lite',
            summary => 'An alternative which I wrote because Finance::GDAX::API was not working',
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

This document describes version 0.004 of Acme::CPANModules::CryptoExchange::API (from Perl distribution Acme-CPANModules-CryptoExchange-API), released on 2020-12-27.

=head1 ACME::MODULES ENTRIES

=over

=item * L<WebService::Cryptopia>

=item * L<WebService::Binance>

=item * L<Finance::Indodax>

=item * L<Finance::BitFlip>

=item * L<Finance::Bank::Kraken>

=item * L<Poloniex::API>

=item * L<WWW::API::Bitfinex>

=item * L<Finance::BitStamp::API>

=item * L<Finance::GDAX::API> - Last time I tried, not working

Alternate modules: L<Finance::GDAX::Lite>

=item * L<Finance::GDAX::Lite> - An alternative which I wrote because Finance::GDAX::API was not working

=item * L<Finance::LocalBitcoins::API>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries CryptoExchange::API | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CryptoExchange::API -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CryptoExchange::API -E'say $_->{module} for @{ $Acme::CPANModules::CryptoExchange::API::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CryptoExchange-API>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CryptoExchange-API>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-CryptoExchange-API/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
