package Acme::CPANModules::CustomCPAN;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-06'; # DATE
our $DIST = 'Acme-CPANModules-CustomCPAN'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules to create your own CPAN-like repository',
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
# ABSTRACT: List of modules to create your own CPAN-like repository

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::CustomCPAN - List of modules to create your own CPAN-like repository

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::CustomCPAN (from Perl distribution Acme-CPANModules-CustomCPAN), released on 2023-08-06.

=head1 DESCRIPTION

You can create a CPAN-like repository which contains your own modules. Look at
the modules in this list to see what tools you can use to do this.

Keywords: DarkPAN

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<CPAN::Mini::Inject>

Author: L<MITHALDU|https://metacpan.org/author/MITHALDU>

If you just want to add one to a few of your own modules to your own CPAN, you
can start with a regular CPAN (or mini CPAN) mirror, then inject your modules
into it using this module.


=item L<OrePAN>

Author: L<TOKUHIROM|https://metacpan.org/author/TOKUHIROM>

With this tool, you can create a CPAN-like repository from scratch, by adding
your modules one at a time.


=item L<WorePAN>

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

A flavor of OrePAN that works under Windows.


=item L<OrePAN2>

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

The next generation of OrePAN, although I personally still use OrePAN (version
1).


=item L<CPAN::Mirror::Tiny>

Author: L<SKAJI|https://metacpan.org/author/SKAJI>

Like OrePAN/OrePAN2/CPAN::Mini::Inject, but the goal is not to depend on XS
modules (thus, the use of HTTP::Tinyish which uses curl/wget to download https
pages instead of LWP).


=item L<Pinto>

Author: L<THALJEF|https://metacpan.org/author/THALJEF>

Pinto allows you to create custom CPAN-like repository of Perl modules with
features like stacking, version pinning, and so on.


=item L<App::lcpan>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Not a CPAN-like repository creator/builder, but once you have your CPAN-like
repository, you can also index it like you would a regular CPAN mirror/mini
mirror using this tool.


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

 % cpanm-cpanmodules -n CustomCPAN

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries CustomCPAN | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=CustomCPAN -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::CustomCPAN -E'say $_->{module} for @{ $Acme::CPANModules::CustomCPAN::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-CustomCPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-CustomCPAN>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::LocalCPANMirror>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-CustomCPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
