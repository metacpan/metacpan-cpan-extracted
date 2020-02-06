package Acme::CPANModules::ModuleAutoloaders;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-06'; # DATE
our $DIST = 'Acme-CPANModules-ModuleAutoloaders'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules that autoload other modules',
    description => <<'_',

"Module autoloader" modules work using Perl's autoloading mechanism (read
`perlsub` for more details). By declaring a subroutine named `AUTOLOAD` in the
`UNIVERSAL` package, you setup a fallback mechanism when you call an undefined
subroutine. The module autoloader's's AUTOLOADER loads the module using e.g.
<pm:Module::Load> or plain `require()` then try to invoke the undefined
subroutine once again.

These modules are usually convenient for one-liner usage.

_
    entries => [
        {module => 'L'},
        {module => 'Class::Autouse'},
    ],
};

1;
# ABSTRACT: Modules that autoload other modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModuleAutoloaders - Modules that autoload other modules

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::ModuleAutoloaders (from Perl distribution Acme-CPANModules-ModuleAutoloaders), released on 2020-02-06.

=head1 DESCRIPTION

Modules that autoload other modules.

"Module autoloader" modules work using Perl's autoloading mechanism (read
C<perlsub> for more details). By declaring a subroutine named C<AUTOLOAD> in the
C<UNIVERSAL> package, you setup a fallback mechanism when you call an undefined
subroutine. The module autoloader's's AUTOLOADER loads the module using e.g.
L<Module::Load> or plain C<require()> then try to invoke the undefined
subroutine once again.

These modules are usually convenient for one-liner usage.

=head1 INCLUDED MODULES

=over

=item * L<L>

=item * L<Class::Autouse>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries ModuleAutoloaders | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ModuleAutoloaders -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModuleAutoloaders>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModuleAutoloaders>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModuleAutoloaders>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules::ModuleAutoinstallers>

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
