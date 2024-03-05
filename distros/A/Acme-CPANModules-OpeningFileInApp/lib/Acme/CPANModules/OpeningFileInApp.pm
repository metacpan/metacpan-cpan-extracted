package Acme::CPANModules::OpeningFileInApp;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-19'; # DATE
our $DIST = 'Acme-CPANModules-OpeningFileInApp'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'List of modules to open a file with appropriate application',
    entries => [
        {
            module => 'Desktop::Open',
            description => <<'MARKDOWN',

This module tries to select the appropriate application to open a file: using
`start` (on Windows) or `xdg-open` (on other OS, if available), the falls back
to <pm:Browser::Open>.

See <pm:App::DesktopOpenUtils> which includes a CLI for this module:
<prog:open-desktop>.

MARKDOWN
        },

        {
            module => 'Spreadsheet::Open',
            description => <<'MARKDOWN',

Similar to <pm:Desktop::Open>, but limiting the apps to spreadsheet
applications.

MARKDOWN
        },

        {
            module => 'App::Open',
            scripts => ['openit'],
            description => <<'MARKDOWN',

This module and tool requires configuration beforehand.

MARKDOWN
        },

        {
            module => 'Open::This',
            scripts => ['ot'],
            description => <<'MARKDOWN',

This module (and the included <prog:ot> tool) is geared upon opening a Perl
source code file with a browser. You can specify a module name (e.g.
`Foo::Bar`), a qualified function name (`Foo::Bar::func_name()`), or a sentence
copy-pasted from `git-grep` or stack trace output.

MARKDOWN
        },

        {
            module => 'Browser::Open',
            description => <<'MARKDOWN',

A web browser can open many types of files, so this application is sometimes
appropriate. The module will pick an available browser. You don\'t have to
specify the path in URL form, e.g. `file:/path/to/file`; the module recognizes
standard `/unix/path/syntax`.

See <pm:App::BrowserOpenUtils> which provides a simple CLI for the module:
<prog:open-browser>.

MARKDOWN
        },
    ],
};

1;
# ABSTRACT: List of modules to open a file with appropriate application

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::OpeningFileInApp - List of modules to open a file with appropriate application

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::OpeningFileInApp (from Perl distribution Acme-CPANModules-OpeningFileInApp), released on 2023-12-19.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Desktop::Open>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This module tries to select the appropriate application to open a file: using
C<start> (on Windows) or C<xdg-open> (on other OS, if available), the falls back
to L<Browser::Open>.

See L<App::DesktopOpenUtils> which includes a CLI for this module:
L<open-desktop>.


=item L<Spreadsheet::Open>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Similar to L<Desktop::Open>, but limiting the apps to spreadsheet
applications.


=item L<App::Open>

Author: L<ERIKH|https://metacpan.org/author/ERIKH>

This module and tool requires configuration beforehand.


Script: L<openit>

=item L<Open::This>

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

This module (and the included L<ot> tool) is geared upon opening a Perl
source code file with a browser. You can specify a module name (e.g.
C<Foo::Bar>), a qualified function name (C<Foo::Bar::func_name()>), or a sentence
copy-pasted from C<git-grep> or stack trace output.


Script: L<ot>

=item L<Browser::Open>

Author: L<CFRANKS|https://metacpan.org/author/CFRANKS>

A web browser can open many types of files, so this application is sometimes
appropriate. The module will pick an available browser. You don\'t have to
specify the path in URL form, e.g. C<file:/path/to/file>; the module recognizes
standard C</unix/path/syntax>.

See L<App::BrowserOpenUtils> which provides a simple CLI for the module:
L<open-browser>.


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

 % cpanm-cpanmodules -n OpeningFileInApp

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries OpeningFileInApp | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=OpeningFileInApp -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::OpeningFileInApp -E'say $_->{module} for @{ $Acme::CPANModules::OpeningFileInApp::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-OpeningFileInApp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-OpeningFileInApp>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-OpeningFileInApp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
