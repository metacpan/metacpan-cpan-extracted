package Acme::CPANLists::PERLANCAR::Task::CheckingModuleInstalledLoadable;

our $DATE = '2017-06-19'; # DATE
our $VERSION = '0.22'; # VERSION

our @Module_Lists = (
    {
        summary => 'Checking if a module is installed or loadable',
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
    },
);

1;
# ABSTRACT: Checking if a module is installed or loadable

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANLists::PERLANCAR::Task::CheckingModuleInstalledLoadable - Checking if a module is installed or loadable

=head1 VERSION

This document describes version 0.22 of Acme::CPANLists::PERLANCAR::Task::CheckingModuleInstalledLoadable (from Perl distribution Acme-CPANLists-PERLANCAR), released on 2017-06-19.

=head1 MODULE LISTS

=head2 Checking if a module is installed or loadable

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


=over

=item * L<Module::Path>

=item * L<Module::Path::More>

=item * L<Module::Load::Conditional>

=item * L<Module::Installed::Tiny>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANLists-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANLists-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANLists-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANLists> - about the Acme::CPANLists namespace

L<acme-cpanlists> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
