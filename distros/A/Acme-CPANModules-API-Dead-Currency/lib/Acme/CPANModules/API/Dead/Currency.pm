package Acme::CPANModules::API::Dead::Currency;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Acme-CPANModules-API-Dead-Currency'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "List of dead currency API modules on CPAN",
    description => <<'_',

CPAN is full of unmaintained modules, including dead API's. Sadly, there's
currently no easy way to mark such modules (CPANRatings is also dead, MetaCPAN
only lets us ++ a module), hence this list.

_
    entries => [
        {module=>'Finance::Currency::Convert::WebserviceX'},
        {module=>'Finance::Currency::Convert'},
        {module=>'Finance::Currency::Convert::XE'},
        {module=>'Finance::Currency::Convert::Yahoo'},
    ],
};

1;
# ABSTRACT: List of dead currency API modules on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::API::Dead::Currency - List of dead currency API modules on CPAN

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::API::Dead::Currency (from Perl distribution Acme-CPANModules-API-Dead-Currency), released on 2022-03-08.

=head1 DESCRIPTION

CPAN is full of unmaintained modules, including dead API's. Sadly, there's
currently no easy way to mark such modules (CPANRatings is also dead, MetaCPAN
only lets us ++ a module), hence this list.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Finance::Currency::Convert::WebserviceX> - Lightweight currency conversion using WebserviceX.NET

Author: L<CLACO|https://metacpan.org/author/CLACO>

=item * L<Finance::Currency::Convert> - Convert currencies and fetch their exchange rates (with Finance::Quote)

Author: L<JANW|https://metacpan.org/author/JANW>

=item * L<Finance::Currency::Convert::XE> - Currency conversion module.

Author: L<RMCKAY|https://metacpan.org/author/RMCKAY>

=item * L<Finance::Currency::Convert::Yahoo> - convert currencies using Yahoo

Author: L<LGODDARD|https://metacpan.org/author/LGODDARD>

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

 % cpanm-cpanmodules -n API::Dead::Currency

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries API::Dead::Currency | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=API::Dead::Currency -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::API::Dead::Currency -E'say $_->{module} for @{ $Acme::CPANModules::API::Dead::Currency::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-API-Dead-Currency>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-API-Dead-Currency>.

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

This software is copyright (c) 2022, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-API-Dead-Currency>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
