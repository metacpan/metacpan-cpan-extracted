package Acme::CPANModules::DiffingStuffs;

use strict;
use warnings;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-08'; # DATE
our $DIST = 'Acme-CPANModules-DiffingStuffs'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'_';

**Archive files**

<prog:diff-tarballs> (from <pm:App::DiffTarballs>) diffs two tarballs.

<prog:diff-cpan-releasess> (from <pm:App::DiffCPANReleases>) diffs two CPAN
release tarballs.


**Database schema**

<pm:DBIx::Diff::Schema> compares two databases and reports tables/columns which
are added/deleted/modified. L<App::DiffDBSchemaUtils> provides CLI's for it like
<prog:diff-db-schema>, <prog:diff-mysql-schema>, <prog:diff-sqlite-schema>,
<prog:diff-pg-schema>.


**PDF files**

<prog:diff-doc-text> (from <pm:App::DiffDocText>) diffs two DOC/DOCX/ODT
documents by converting the documents to plaintext and diff-ing the plaintext
files.


**Spreadsheet files**

<prog:diff-xls-text> (from <pm:App::DiffXlsText>) diffs two XLS/XLSX/ODS
workbooks by converting each worksheet in each workbook as files in the
workbook's directory and then diff-ing the two workbook directories.


**Structured data**

See separated list: <pm:Acme::CPANModules::DiffingStructuredData>.


**Word processor documents**

<prog:diff-doc-text> (from <pm:App::DiffDocText>) diffs two DOC/DOCX/ODT
documents by converting the documents to plaintext and diff-ing the plaintext
files.

_

our $LIST = {
    summary => 'List of modules/applications to diff various stuffs',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules/applications to diff various stuffs

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::DiffingStuffs - List of modules/applications to diff various stuffs

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::DiffingStuffs (from Perl distribution Acme-CPANModules-DiffingStuffs), released on 2022-09-08.

=head1 DESCRIPTION

B<Archive files>

L<diff-tarballs> (from L<App::DiffTarballs>) diffs two tarballs.

L<diff-cpan-releasess> (from L<App::DiffCPANReleases>) diffs two CPAN
release tarballs.

B<Database schema>

L<DBIx::Diff::Schema> compares two databases and reports tables/columns which
are added/deleted/modified. L<App::DiffDBSchemaUtils> provides CLI's for it like
L<diff-db-schema>, L<diff-mysql-schema>, L<diff-sqlite-schema>,
L<diff-pg-schema>.

B<PDF files>

L<diff-doc-text> (from L<App::DiffDocText>) diffs two DOC/DOCX/ODT
documents by converting the documents to plaintext and diff-ing the plaintext
files.

B<Spreadsheet files>

L<diff-xls-text> (from L<App::DiffXlsText>) diffs two XLS/XLSX/ODS
workbooks by converting each worksheet in each workbook as files in the
workbook's directory and then diff-ing the two workbook directories.

B<Structured data>

See separated list: L<Acme::CPANModules::DiffingStructuredData>.

B<Word processor documents>

L<diff-doc-text> (from L<App::DiffDocText>) diffs two DOC/DOCX/ODT
documents by converting the documents to plaintext and diff-ing the plaintext
files.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<App::DiffTarballs> - Diff contents of two tarballs

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::DiffCPANReleases> - Diff contents of two CPAN releases

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<DBIx::Diff::Schema> - Compare schema of two DBI databases

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::DiffDocText> - Diff the text of two Office word-processor documents (.doc, .docx, .odt, etc)

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::DiffXlsText> - Diff the text of two Office spreadsheets (.ods, .xls, .xlsx) as two directories of CSV files

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Acme::CPANModules::DiffingStructuredData>

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

 % cpanm-cpanmodules -n DiffingStuffs

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries DiffingStuffs | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=DiffingStuffs -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::DiffingStuffs -E'say $_->{module} for @{ $Acme::CPANModules::DiffingStuffs::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-DiffingStuffs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-DiffingStuffs>.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-DiffingStuffs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
