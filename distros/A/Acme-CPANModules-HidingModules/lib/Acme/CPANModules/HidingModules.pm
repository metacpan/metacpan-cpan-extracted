package Acme::CPANModules::HidingModules;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-30'; # DATE
our $DIST = 'Acme-CPANModules-HidingModules'; # DIST
our $VERSION = '0.004'; # VERSION

our $text = <<'_';

So you want to convince some Perl code that some modules that are actually
installed, aren't? There are several ways to accomplish this, with different
effects and levels of convincing. This list details them.

**Why?**

First of all, why would you want to do this? Almost always, the answer is: for
testing purposes. For example, you want to make sure that your code can work
without an optional module. Or, alternatively, you want to test how your code
fails under the absence of certain modules.


**Making modules not loadable**

Most of the time, you just want to make certain modules not loadable. That is,
making `require SomeModule` or `use Module` fail. To do this, you usually
install a hook at the first element of `@INC`. The hook would die when it
receives a request to load a module that you want to hide. Some tools that work
this way include:

<pm:lib::filter> family, including its thin wrapper <pm:lib::disallow>.
lib::filter et al supports hiding modules that you specify, as well as hiding
all core modules or all non-core modules. They also support recursive allowing,
i.e. you want to allow Moo and all the modules that Moo loads, and all the
modules that they load, and so on.

<pm:Devel::Hide>. Devel::Hide also works by installing a hook in `@INC`. It
supports propagating the hiding to child process by setting PERL5OPT environment
variable.

<pm:Test::Without::Module>.


**Fooling module path finders**

Depending on which tool you use to find a module's path, here are some patches
you can load to fool the finder.

<pm:Module::Path::Patch::Hide>

<pm:Module::Path::More::Patch::Hide>


**Fooling module listers**

Depending on which tool you use to find a module's path, here are some patches
you can load to fool the lister tool.

<pm:Module::List::Patch::Hide>

<pm:PERLANCAR::Module::List::Patch::Hide>

<pm:Module::List::Tiny::Patch::Hide>

<pm:Module::List::Wildcard::Patch::Hide>


**Hard-core hiding**

To fool code that tries to find the module files themselves without using any
module, i.e. by iterating @INC, you will need to actually (temporarily) rename
the module files. <pm:App::pmhiderename> and <lib::hiderename> does this.

_

our $LIST = {
    summary => 'Hiding modules',
    description => $text,
    tags => ['task'],
    entries => [
        map { +{module=>$_} }
            do { my %seen; grep { !$seen{$_}++ }
                 ($text =~ /<pm:(\w+(?:::\w+)+)>/g)
             }
    ],
};


1;
# ABSTRACT: Hiding modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::HidingModules - Hiding modules

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::HidingModules (from Perl distribution Acme-CPANModules-HidingModules), released on 2020-04-30.

=head1 DESCRIPTION

So you want to convince some Perl code that some modules that are actually
installed, aren't? There are several ways to accomplish this, with different
effects and levels of convincing. This list details them.

B<Why?>

First of all, why would you want to do this? Almost always, the answer is: for
testing purposes. For example, you want to make sure that your code can work
without an optional module. Or, alternatively, you want to test how your code
fails under the absence of certain modules.

B<Making modules not loadable>

Most of the time, you just want to make certain modules not loadable. That is,
making C<require SomeModule> or C<use Module> fail. To do this, you usually
install a hook at the first element of C<@INC>. The hook would die when it
receives a request to load a module that you want to hide. Some tools that work
this way include:

L<lib::filter> family, including its thin wrapper L<lib::disallow>.
lib::filter et al supports hiding modules that you specify, as well as hiding
all core modules or all non-core modules. They also support recursive allowing,
i.e. you want to allow Moo and all the modules that Moo loads, and all the
modules that they load, and so on.

L<Devel::Hide>. Devel::Hide also works by installing a hook in C<@INC>. It
supports propagating the hiding to child process by setting PERL5OPT environment
variable.

L<Test::Without::Module>.

B<Fooling module path finders>

Depending on which tool you use to find a module's path, here are some patches
you can load to fool the finder.

L<Module::Path::Patch::Hide>

L<Module::Path::More::Patch::Hide>

B<Fooling module listers>

Depending on which tool you use to find a module's path, here are some patches
you can load to fool the lister tool.

L<Module::List::Patch::Hide>

L<PERLANCAR::Module::List::Patch::Hide>

L<Module::List::Tiny::Patch::Hide>

L<Module::List::Wildcard::Patch::Hide>

B<Hard-core hiding>

To fool code that tries to find the module files themselves without using any
module, i.e. by iterating @INC, you will need to actually (temporarily) rename
the module files. L<App::pmhiderename> and <lib::hiderename> does this.

=head1 INCLUDED MODULES

=over

=item * L<lib::filter>

=item * L<lib::disallow>

=item * L<Devel::Hide>

=item * L<Test::Without::Module>

=item * L<Module::Path::Patch::Hide>

=item * L<Module::Path::More::Patch::Hide>

=item * L<Module::List::Patch::Hide>

=item * L<PERLANCAR::Module::List::Patch::Hide>

=item * L<Module::List::Tiny::Patch::Hide>

=item * L<Module::List::Wildcard::Patch::Hide>

=item * L<App::pmhiderename>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries HidingModules | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=HidingModules -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

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

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
