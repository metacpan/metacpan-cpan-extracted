package Acme::CPANModules::ModuleAutoinstallers;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-06'; # DATE
our $DIST = 'Acme-CPANModules-ModuleAutoinstallers'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules that autoinstalls other modules during run-time',
    description => <<'_',

These "module autoinstallers" modules can automatically install missing module
during run-time using one of installers (usually `cpanm` a.k.a.
<pm:App::cpanminus>). Convenient when running a Perl script (that comes without
a proper distribution or `cpanfile`) that uses several modules which you might
not have. The alternative to lib::xi is the "trial and error" method: repeatedly
run the Perl script to see which module it tries and fails to load.

They work by installing a hook in `@INC`. Read more about require hooks in
`perlfunc` under the `require` function.

_
    entries => [
        {module => 'lib::xi'},
        {module => 'Module::AutoINC'},
        {module => 'Require::Hook::More'}, # actually autoinstalling feature not yet implemented
    ],
};

1;
# ABSTRACT: Modules that autoinstalls other modules during run-time

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModuleAutoinstallers - Modules that autoinstalls other modules during run-time

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ModuleAutoinstallers (from Perl distribution Acme-CPANModules-ModuleAutoinstallers), released on 2020-02-06.

=head1 DESCRIPTION

Modules that autoinstalls other modules during run-time.

These "module autoinstallers" modules can automatically install missing module
during run-time using one of installers (usually C<cpanm> a.k.a.
L<App::cpanminus>). Convenient when running a Perl script (that comes without
a proper distribution or C<cpanfile>) that uses several modules which you might
not have. The alternative to lib::xi is the "trial and error" method: repeatedly
run the Perl script to see which module it tries and fails to load.

They work by installing a hook in C<@INC>. Read more about require hooks in
C<perlfunc> under the C<require> function.

=head1 INCLUDED MODULES

=over

=item * L<lib::xi>

=item * L<Module::AutoINC>

=item * L<Require::Hook::More>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ModuleAutoinstallers | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ModuleAutoinstallers -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModuleAutoinstallers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModuleAutoinstallers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModuleAutoinstallers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::ModuleAutoloaders>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
