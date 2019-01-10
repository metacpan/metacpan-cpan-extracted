package Acme::CPANModules::HidingModules;

our $DATE = '2019-01-10'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Simulate the unavailability of modules',
    description => <<'_',

The tools listed here can simulate the absence of modules, usually for testing
purposes. For example, you have Foo::Bar installed but want to test how your
code would behave when Foo::Bar is not installed.

These tools usually work by installing a require() hook in `@INC`. If the hook
sees that you are trying to load one of the target modules, it dies instead.

_
    entries => [
        {module=>'lib::filter'},
        {module=>'lib::disallow'},
        {module=>'Devel::Hide'},
        {module=>'Test::Without::Module'},
        {module=>'Module::Path::Patch::Hide', summary=>'This only hides modules from Module::Path'},
        {module=>'Module::Path::More::Patch::Hide', summary=>'This only hides modules from Module::Path::More'},
        {module=>'Module::List::Patch::Hide', summary=>'This only hides modules from Module::List'},
        {module=>'PERLANCAR::Module::List::Patch::Hide', summary=>'This only hides modules from PERLANCAR::Module::List'},
    ],
};

1;
# ABSTRACT: Simulate the unavailability of modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::HidingModules - Simulate the unavailability of modules

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::HidingModules (from Perl distribution Acme-CPANModules-HidingModules), released on 2019-01-10.

=head1 DESCRIPTION

Simulate the unavailability of modules.

The tools listed here can simulate the absence of modules, usually for testing
purposes. For example, you have Foo::Bar installed but want to test how your
code would behave when Foo::Bar is not installed.

These tools usually work by installing a require() hook in C<@INC>. If the hook
sees that you are trying to load one of the target modules, it dies instead.

=head1 INCLUDED MODULES

=over

=item * L<lib::filter>

=item * L<lib::disallow>

=item * L<Devel::Hide>

=item * L<Test::Without::Module>

=item * L<Module::Path::Patch::Hide> - This only hides modules from Module::Path

=item * L<Module::Path::More::Patch::Hide> - This only hides modules from Module::Path::More

=item * L<Module::List::Patch::Hide> - This only hides modules from Module::List

=item * L<PERLANCAR::Module::List::Patch::Hide> - This only hides modules from PERLANCAR::Module::List

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-HidingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-HidingModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-HidingModules>

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
