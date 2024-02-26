package Acme::CPANModules::LocalCPANIndex;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-29'; # DATE
our $DIST = 'Acme-CPANModules-LocalCPANIndex'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules/tools to create an index against local CPAN mirror',
    description => <<'_',

Since CPAN repository index is just a couple of text files (currently: list of
authors in `authors/01mailrc.txt.gz` and list of packages in
`modules/02packages.details.txt.gz`), to perform more complex or detailed
queries additional index is often desired. The following modules accomplish
that.

_
    entries => [
        {
            module=>'App::lcpan',
            description => <<'_',

In addition to downloading a CPAN mini mirror (using <pm:CPAN::Mini>), this
utility also indexes the package list and distribution metadata into a SQLite
database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.

_
        },
        {
            module=>'CPAN::SQLite',
            description => <<'_',

This module parses the two CPAN text file indexes (`authors/01mailrc.txt.gz` and
`modules/02packages.details.txt.gz`) and puts the information into a SQLite
database. This lets you perform queries more quickly without reparsing the text
files each time. But it does not parse distribution metadata so you don't get
additional querying capability like dependencies.

_
        },
    ],
};

1;
# ABSTRACT: List of modules/tools to create an index against local CPAN mirror

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::LocalCPANIndex - List of modules/tools to create an index against local CPAN mirror

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::LocalCPANIndex (from Perl distribution Acme-CPANModules-LocalCPANIndex), released on 2023-10-29.

=head1 DESCRIPTION

Since CPAN repository index is just a couple of text files (currently: list of
authors in C<authors/01mailrc.txt.gz> and list of packages in
C<modules/02packages.details.txt.gz>), to perform more complex or detailed
queries additional index is often desired. The following modules accomplish
that.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::lcpan>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

In addition to downloading a CPAN mini mirror (using L<CPAN::Mini>), this
utility also indexes the package list and distribution metadata into a SQLite
database so you can perform various queries, like list of
modules/distributions/scripts of a CPAN author, or related modules using
cross-mention information on modules' PODs, or various rankings.


=item L<CPAN::SQLite>

Author: L<STRO|https://metacpan.org/author/STRO>

This module parses the two CPAN text file indexes (C<authors/01mailrc.txt.gz> and
C<modules/02packages.details.txt.gz>) and puts the information into a SQLite
database. This lets you perform queries more quickly without reparsing the text
files each time. But it does not parse distribution metadata so you don't get
additional querying capability like dependencies.


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

 % cpanm-cpanmodules -n LocalCPANIndex

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries LocalCPANIndex | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=LocalCPANIndex -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::LocalCPANIndex -E'say $_->{module} for @{ $Acme::CPANModules::LocalCPANIndex::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-LocalCPANIndex>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-LocalCPANIndex>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Acme::CPANModules::LocalCPANMirror>

L<Acme::CPANModules::CustomCPAN>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-LocalCPANIndex>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
