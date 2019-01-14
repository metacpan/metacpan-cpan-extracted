package Acme::CPANModules::API::Domain::Registrar;

our $DATE = '2019-01-13'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => "API to domain registrars",
    description => <<'_',

If you know of others, please drop me a message.

_
    entries => [
        {module => 'WWW::DaftarNama::Reseller'},
        {module => 'WWW::Enom'},
        {module => 'Net::OpenSRS'},
        {module => 'WWW::GoDaddy::REST'},
        {module => 'WWW::Domain::Registry::Joker'},
        {module => 'WWW::Domain::Registry::VeriSign'},
        {module => 'WWW::NameCheap::API'},
    ],
};

1;
# ABSTRACT: API to domain registrars

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::API::Domain::Registrar - API to domain registrars

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::API::Domain::Registrar (from Perl distribution Acme-CPANModules-API-Domain-Registrar), released on 2019-01-13.

=head1 DESCRIPTION

API to domain registrars.

If you know of others, please drop me a message.

=head1 INCLUDED MODULES

=over

=item * L<WWW::DaftarNama::Reseller>

=item * L<WWW::Enom>

=item * L<Net::OpenSRS>

=item * L<WWW::GoDaddy::REST>

=item * L<WWW::Domain::Registry::Joker>

=item * L<WWW::Domain::Registry::VeriSign>

=item * L<WWW::NameCheap::API>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-API-Domain-Registrar>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-API-Domain-Registrar>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-API-Domain-Registrar>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
