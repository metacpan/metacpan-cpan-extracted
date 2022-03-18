package Acme::CPANModules::API::Domain::Registrar;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Acme-CPANModules-API-Domain-Registrar'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of API modules for domain registrars",
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
# ABSTRACT: List of API modules for domain registrars

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::API::Domain::Registrar - List of API modules for domain registrars

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::API::Domain::Registrar (from Perl distribution Acme-CPANModules-API-Domain-Registrar), released on 2022-03-08.

=head1 DESCRIPTION

If you know of others, please drop me a message.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<WWW::DaftarNama::Reseller> - Reseller API client for DaftarNama.id

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<WWW::Enom>

=item * L<Net::OpenSRS> - Domain registration via the Tucows OpenSRS HTTPS XML API

Author: L<JEF|https://metacpan.org/author/JEF>

=item * L<WWW::GoDaddy::REST> - Work with services conforming to the GDAPI spec

Author: L<DBARTLE|https://metacpan.org/author/DBARTLE>

=item * L<WWW::Domain::Registry::Joker> - an interface to the Joker.com DMAPI

Author: L<ROAM|https://metacpan.org/author/ROAM>

=item * L<WWW::Domain::Registry::VeriSign> - VeriSign NDS (https://www.verisign-grs.com/) Registrar Tool

Author: L<MASAHITO|https://metacpan.org/author/MASAHITO>

=item * L<WWW::NameCheap::API>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n API::Domain::Registrar

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries API::Domain::Registrar | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=API::Domain::Registrar -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::API::Domain::Registrar -E'say $_->{module} for @{ $Acme::CPANModules::API::Domain::Registrar::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-API-Domain-Registrar>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-API-Domain-Registrar>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-API-Domain-Registrar>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
