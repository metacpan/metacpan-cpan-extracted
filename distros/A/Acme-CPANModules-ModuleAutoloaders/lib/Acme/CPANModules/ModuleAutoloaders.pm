package Acme::CPANModules::ModuleAutoloaders;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'Acme-CPANModules-ModuleAutoloaders'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'List of modules that autoload other modules',
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
# ABSTRACT: List of modules that autoload other modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModuleAutoloaders - List of modules that autoload other modules

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::ModuleAutoloaders (from Perl distribution Acme-CPANModules-ModuleAutoloaders), released on 2023-11-20.

=head1 DESCRIPTION

"Module autoloader" modules work using Perl's autoloading mechanism (read
C<perlsub> for more details). By declaring a subroutine named C<AUTOLOAD> in the
C<UNIVERSAL> package, you setup a fallback mechanism when you call an undefined
subroutine. The module autoloader's's AUTOLOADER loads the module using e.g.
L<Module::Load> or plain C<require()> then try to invoke the undefined
subroutine once again.

These modules are usually convenient for one-liner usage.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<L>

Author: L<SONGMU|https://metacpan.org/author/SONGMU>

=item L<Class::Autouse>

Author: L<ADAMK|https://metacpan.org/author/ADAMK>

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

 % cpanm-cpanmodules -n ModuleAutoloaders

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ModuleAutoloaders | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ModuleAutoloaders -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ModuleAutoloaders -E'say $_->{module} for @{ $Acme::CPANModules::ModuleAutoloaders::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModuleAutoloaders>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModuleAutoloaders>.

=head1 SEE ALSO

L<Acme::CPANModules::ModuleAutoinstallers>

L<Acme::CPANModules::LoadingModules> for a more general list of modules related
to loading other Perl moduless.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModuleAutoloaders>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
