package Acme::CPANModules::ModuleAutoinstallers;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-29'; # DATE
our $DIST = 'Acme-CPANModules-ModuleAutoinstallers'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => 'List of modules that autoinstalls other modules during run-time',
    description => <<'MARKDOWN',

These "module autoinstallers" modules can automatically install missing module
during run-time using one of installers (usually `cpanm` a.k.a.
<pm:App::cpanminus>). Convenient when running a Perl script (that comes without
a proper distribution or `cpanfile`) that uses several modules which you might
not have. The alternative to lib::xi is the "trial and error" method: repeatedly
run the Perl script to see which module it tries and fails to load.

They work by installing a hook in `@INC`. Read more about require hooks in
`perlfunc` under the `require` function.

MARKDOWN
    entries => [
        {module => 'lazy'},
        {module => 'lib::xi'},
        {module => 'Module::AutoINC'},
        {module => 'Require::Hook::More'}, # actually autoinstalling feature not yet implemented
    ],
};

1;
# ABSTRACT: List of modules that autoinstalls other modules during run-time

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::ModuleAutoinstallers - List of modules that autoinstalls other modules during run-time

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::ModuleAutoinstallers (from Perl distribution Acme-CPANModules-ModuleAutoinstallers), released on 2024-08-29.

=head1 DESCRIPTION

These "module autoinstallers" modules can automatically install missing module
during run-time using one of installers (usually C<cpanm> a.k.a.
L<App::cpanminus>). Convenient when running a Perl script (that comes without
a proper distribution or C<cpanfile>) that uses several modules which you might
not have. The alternative to lib::xi is the "trial and error" method: repeatedly
run the Perl script to see which module it tries and fails to load.

They work by installing a hook in C<@INC>. Read more about require hooks in
C<perlfunc> under the C<require> function.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<lazy>

=item L<lib::xi>

=item L<Module::AutoINC>

=item L<Require::Hook::More>

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

 % cpanm-cpanmodules -n ModuleAutoinstallers

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries ModuleAutoinstallers | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=ModuleAutoinstallers -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::ModuleAutoinstallers -E'say $_->{module} for @{ $Acme::CPANModules::ModuleAutoinstallers::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-ModuleAutoinstallers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-ModuleAutoinstallers>.

=head1 SEE ALSO

L<Acme::CPANModules::ModuleAutoloaders>

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

This software is copyright (c) 2024, 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-ModuleAutoinstallers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
