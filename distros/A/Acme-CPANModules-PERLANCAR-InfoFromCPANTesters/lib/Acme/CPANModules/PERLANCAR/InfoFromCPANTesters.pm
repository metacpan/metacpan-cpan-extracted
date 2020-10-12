package Acme::CPANModules::PERLANCAR::InfoFromCPANTesters;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-10'; # DATE
our $DIST = 'Acme-CPANModules-PERLANCAR-InfoFromCPANTesters'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'Distributions that gather information from CPANTesters',
    entries => [
        { module => "Acme::Test::crypt", summary => 'Check crypt() support in various platforms' },
        { module => "App::PlatformInfo", summary => 'Result of Devel::Platform::Info on various testing machines' },
    ],
};

1;
# ABSTRACT: Distributions that gather information from CPANTesters

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::InfoFromCPANTesters - Distributions that gather information from CPANTesters

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PERLANCAR::InfoFromCPANTesters (from Perl distribution Acme-CPANModules-PERLANCAR-InfoFromCPANTesters), released on 2020-10-10.

=head1 MODULES INCLUDED IN THIS ACME::CPANMODULE MODULE

=over

=item * L<Acme::Test::crypt> - Check crypt() support in various platforms

=item * L<App::PlatformInfo> - Result of Devel::Platform::Info on various testing machines

=back

=head1 FAQ

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries PERLANCAR::InfoFromCPANTesters | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::InfoFromCPANTesters -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::InfoFromCPANTesters -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::InfoFromCPANTesters::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PERLANCAR-InfoFromCPANTesters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-InfoFromCPANTesters>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-PERLANCAR-InfoFromCPANTesters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
