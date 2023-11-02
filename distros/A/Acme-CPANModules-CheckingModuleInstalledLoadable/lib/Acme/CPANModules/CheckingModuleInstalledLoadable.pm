package Acme::CPANModules::CheckingModuleInstalledLoadable;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-CheckingModuleInstalledLoadable'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules to check if a module is installed or loadable',
    description => <<'_',

If you simply want to check that a module's `.pm` file is locatable in `@INC`,
you can just do something like:

    my $mod = "Foo/Bar.pm";
    for my $dir (@INC) {
        next if ref $dir;
        if (-f "$dir/$mod") {
            print "Module $mod is installed";
            last;
        }
    }

Or you can use something like <pm:Module::Path> or <pm:Module::Path::More> which
does similar to the above.

A module can also be loaded from a require hook in ~@INC~ (like in the case of
fatpacked or datapacked script) and the above methods does not handle it.
Instead, you'll need to use <pm:Module::Load::Conditional>'s `check_install` or
<pm:Module::Installed::Tiny>'s `module_installed`:

    use Module::Load::Conditional qw(check_install);
    if (check_install(module => "Foo::Bar")) {
        # Foo::Bar is installed
    }

The above does not guarantee that the module will be loaded successfully. To
check that, there's no other way but to actually try to load it:

    if (eval { require Foo::Bar; 1 }) {
        # Foo::Bar can be loaded (and was loaded!)
    }

_
    tags => ['task'],
    entries => [
        {
            module=>'Module::Path',
        },
        {
            module=>'Module::Path::More',
        },
        {
            module=>'Module::Load::Conditional',
        },
        {
            module=>'Module::Installed::Tiny',
        },
    ],
};

1;
# ABSTRACT: List of modules to check if a module is installed or loadable

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CheckingModuleInstalledLoadable - List of modules to check if a module is installed or loadable

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::CheckingModuleInstalledLoadable (from Perl distribution Acme-CPANModules-CheckingModuleInstalledLoadable), released on 2023-08-06.

=head1 DESCRIPTION

If you simply want to check that a module's C<.pm> file is locatable in C<@INC>,
you can just do something like:

 my $mod = "Foo/Bar.pm";
 for my $dir (@INC) {
     next if ref $dir;
     if (-f "$dir/$mod") {
         print "Module $mod is installed";
         last;
     }
 }

Or you can use something like L<Module::Path> or L<Module::Path::More> which
does similar to the above.

A module can also be loaded from a require hook in ~@INC~ (like in the case of
fatpacked or datapacked script) and the above methods does not handle it.
Instead, you'll need to use L<Module::Load::Conditional>'s C<check_install> or
L<Module::Installed::Tiny>'s C<module_installed>:

 use Module::Load::Conditional qw(check_install);
 if (check_install(module => "Foo::Bar")) {
     # Foo::Bar is installed
 }

The above does not guarantee that the module will be loaded successfully. To
check that, there's no other way but to actually try to load it:

 if (eval { require Foo::Bar; 1 }) {
     # Foo::Bar can be loaded (and was loaded!)
 }

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Module::Path>

Author: L<NEILB|https://metacpan.org/author/NEILB>

=item L<Module::Path::More>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<Module::Load::Conditional>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item L<Module::Installed::Tiny>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n CheckingModuleInstalledLoadable

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CheckingModuleInstalledLoadable | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CheckingModuleInstalledLoadable -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CheckingModuleInstalledLoadable -E'say $_->{module} for @{ $Acme::CPANModules::CheckingModuleInstalledLoadable::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CheckingModuleInstalledLoadable>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CheckingModuleInstalledLoadable>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CheckingModuleInstalledLoadable>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
