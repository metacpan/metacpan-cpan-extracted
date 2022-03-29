package Acme::CPANModules::SQLite;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-SQLite'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'_';
**Drivers**

<pm:DBD::SQLite> is a driver for <pm:DBI> framework.

Alternative APIs: <pm:Mojo::SQLite> (wrapper to DBD::SQLite).


**DBI helpers**

<pm:DBIx::Conn::SQLite>


**Applications using SQLite**

Presented alphabetically. Probably an incomplete list.

<pm:App::idxdb>
<pm:App::lcpan>
<pm:App::reposdb>
<pm:App::rimetadb>
<pm:App::TimeTracker>

_

our $LIST = {
    summary => 'List of modules related to SQLite',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules related to SQLite

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::SQLite - List of modules related to SQLite

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::SQLite (from Perl distribution Acme-CPANModules-SQLite), released on 2022-03-18.

=head1 DESCRIPTION

B<Drivers>

L<DBD::SQLite> is a driver for L<DBI> framework.

Alternative APIs: L<Mojo::SQLite> (wrapper to DBD::SQLite).

B<DBI helpers>

L<DBIx::Conn::SQLite>

B<Applications using SQLite>

Presented alphabetically. Probably an incomplete list.

L<App::idxdb>
L<App::lcpan>
L<App::reposdb>
L<App::rimetadb>
L<App::TimeTracker>

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<DBD::SQLite> - Self-contained RDBMS in a DBI Driver

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item * L<DBI> - Database independent interface for Perl

Author: L<TIMB|https://metacpan.org/author/TIMB>

=item * L<Mojo::SQLite> - A tiny Mojolicious wrapper for SQLite

Author: L<DBOOK|https://metacpan.org/author/DBOOK>

=item * L<DBIx::Conn::SQLite> - Shortcut to connect to SQLite database

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::idxdb> - Import data for stocks on the IDX (Indonesian Stock Exchange) and perform queries on them

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::lcpan> - Manage your local CPAN mirror

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::reposdb> - Manipulate repos.db

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::rimetadb> - Manage a Rinci metadata database

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::TimeTracker> - time tracking for impatient and lazy command line lovers

Author: L<DOMM|https://metacpan.org/author/DOMM>

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

 % cpanm-cpanmodules -n SQLite

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries SQLite | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=SQLite -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::SQLite -E'say $_->{module} for @{ $Acme::CPANModules::SQLite::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-SQLite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-SQLite>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-SQLite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
