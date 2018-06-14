package Acme::CPANModules::PERLANCAR::CustomCPAN;

our $DATE = '2018-06-11'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'Creating your own CPAN-like repository',
    description => <<'_',

You can create a CPAN-like repository which contains your own modules. Look at
the modules in this list to see what tools you can use to do this.

Keywords: DarkPAN

_
    entries => [
        {
            module=>'CPAN::Mini::Inject',
            description => <<'_',

If you just want to add one to a few of your own modules to your own CPAN, you
can start with a regular CPAN (or mini CPAN) mirror, then inject your modules
into it using this module.

_
        },
        {
            module=>'OrePAN',
            description => <<'_',

With this tool, you can create a CPAN-like repository from scratch, by adding
your modules one at a time.

_
        },
        {
            module=>'WorePAN',
            description => <<'_',

A flavor of OrePAN that works under Windows.

_
        },
        {
            module=>'OrePAN2',
            description => <<'_',

The next generation of OrePAN, although I personally still use OrePAN (version
1).

_
        },
        {
            module=>'CPAN::Mirror::Tiny',
            description => <<'_',

Like OrePAN/OrePAN2/CPAN::Mini::Inject, but the goal is not to depend on XS
modules (thus, the use of HTTP::Tinyish which uses curl/wget to download https
pages instead of LWP).

_
        },
        {
            module => 'Pinto',
            description => <<'_',

Pinto allows you to create custom CPAN-like repository of Perl modules with
features like stacking, version pinning, and so on.

_
        },
        {
            module => 'App::lcpan',
            description => <<'_',

Not a CPAN-like repository creator/builder, but once you have your CPAN-like
repository, you can also index it like you would a regular CPAN mirror/mini
mirror using this tool.

_
        },
    ],
};

1;
# ABSTRACT: Creating your own CPAN-like repository

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::CustomCPAN - Creating your own CPAN-like repository

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::PERLANCAR::CustomCPAN (from Perl distribution Acme-CPANModulesBundle-PERLANCAR), released on 2018-06-11.

=head1 DESCRIPTION

Creating your own CPAN-like repository.

You can create a CPAN-like repository which contains your own modules. Look at
the modules in this list to see what tools you can use to do this.

Keywords: DarkPAN

=head1 INCLUDED MODULES

=over

=item * L<CPAN::Mini::Inject>

If you just want to add one to a few of your own modules to your own CPAN, you
can start with a regular CPAN (or mini CPAN) mirror, then inject your modules
into it using this module.


=item * L<OrePAN>

With this tool, you can create a CPAN-like repository from scratch, by adding
your modules one at a time.


=item * L<WorePAN>

A flavor of OrePAN that works under Windows.


=item * L<OrePAN2>

The next generation of OrePAN, although I personally still use OrePAN (version
1).


=item * L<CPAN::Mirror::Tiny>

Like OrePAN/OrePAN2/CPAN::Mini::Inject, but the goal is not to depend on XS
modules (thus, the use of HTTP::Tinyish which uses curl/wget to download https
pages instead of LWP).


=item * L<Pinto>

Pinto allows you to create custom CPAN-like repository of Perl modules with
features like stacking, version pinning, and so on.


=item * L<App::lcpan>

Not a CPAN-like repository creator/builder, but once you have your CPAN-like
repository, you can also index it like you would a regular CPAN mirror/mini
mirror using this tool.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesBundle-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesBundle-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesBundle-PERLANCAR>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::PERLANCAR::LocalCPANMirror>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
