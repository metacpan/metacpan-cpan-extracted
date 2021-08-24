package Acme::CPANModules::CPANModules::API;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-27'; # DATE
our $DIST = 'Acme-CPANModules-CPANModules-API'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Acme::CPANModules modules relating to API",
    entries => [
        {module=>'Acme::CPANModules::API::Dead::Currency'},
        {module=>'Acme::CPANModules::API::Domain::Registrar'},
    ],
};

1;
# ABSTRACT: Acme::CPANModules modules relating to API

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CPANModules::API - Acme::CPANModules modules relating to API

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::CPANModules::API (from Perl distribution Acme-CPANModules-CPANModules-API), released on 2021-03-27.

=head1 DESCRIPTION

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Acme::CPANModules::API::Dead::Currency>

=item * L<Acme::CPANModules::API::Domain::Registrar>

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

    % cpanmodules ls-entries CPANModules::API | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CPANModules::API -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CPANModules::API -E'say $_->{module} for @{ $Acme::CPANModules::CPANModules::API::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CPANModules-API>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CPANModules-API>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-CPANModules-API/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
