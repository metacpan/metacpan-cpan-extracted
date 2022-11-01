package Acme::CPANModules::WorkingWithXLS;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-10'; # DATE
our $DIST = 'Acme-CPANModules-WorkingWithXLS'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'_';

The following are tools (programs, modules, scripts) to work with Excel formats
(XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS).



**Parsing**

<pm:Spreadsheet::Read> is a common-interface front-end for
<pm:Spreadsheet::ReadSXC> (for reading LibreOffice Calc ODS format) or one of
<pm:Spreadsheet::ParseExcel>, <pm:Spreadsheet::ParseXLSX>, or Spreadsheet::XLSX
(for reading XLS or XLSX, although Spreadsheet::XLSX is strongly discouraged
because it is a quick-and-dirty hack). Spreadsheet::Read can also read CSV via
Text::CSV_XS. The module can return information about cell's attributes
(formatting, alignment, and so on), merged cells, etc.


**Getting information**

<pm:Spreadsheet::Read>

<prog:xls-info> from <pm:App::XLSUtils>



**Iterating/processing with Perl code**

<prog:XLSperl> CLI from <pm:App::XLSperl> lets you iterate each cell (with
'XLSperl -ne' or row with 'XLSperl -ane') with a Perl code, just like you would
each line of text with `perl -ne` (in fact, the command-line options of XLSperl
mirror those of perl). Only supports the old Excel format (XLS not XLSX). Does
not support LibreOffice Calc format (ODS). If you feed it unsupported format, it
will fallback to text iterating, so if you feed it XLSX or ODS you will iterate
chunks of raw binary data.

<prog:xls-each-cell> from <pm:App::XLSUtils>

<prog:xls-each-row> from <pm:App::XLSUtils>



**Converting to CSV**

`CATDOC` (<http://www.wagner.pp.ru/~vitus/software/catdoc/>) contains following
the programs `catdoc` (to print the plain text of Microsoft Word documents to
standard output), <prog:xls2csv> (to convert Microsoft Excel workbook files to
CSV), and `catppt` (to print plain text of Mirosoft PowerPoint presentations to
standard output). Available as Debian package. They only support the older
format (XLS and not XLSX). They do not support LibreOffice Calc format (ODS).

<prog:xls2csv> from <pm:App::XLSUtils>


**Generating XLS**

TBD

_

our $LIST = {
    summary => 'Working with Excel formats (XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS)',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Working with Excel formats (XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithXLS - Working with Excel formats (XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS)

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::WorkingWithXLS (from Perl distribution Acme-CPANModules-WorkingWithXLS), released on 2022-08-10.

=head1 DESCRIPTION

The following are tools (programs, modules, scripts) to work with Excel formats
(XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS).

B<Parsing>

L<Spreadsheet::Read> is a common-interface front-end for
L<Spreadsheet::ReadSXC> (for reading LibreOffice Calc ODS format) or one of
L<Spreadsheet::ParseExcel>, L<Spreadsheet::ParseXLSX>, or Spreadsheet::XLSX
(for reading XLS or XLSX, although Spreadsheet::XLSX is strongly discouraged
because it is a quick-and-dirty hack). Spreadsheet::Read can also read CSV via
Text::CSV_XS. The module can return information about cell's attributes
(formatting, alignment, and so on), merged cells, etc.

B<Getting information>

L<Spreadsheet::Read>

L<xls-info> from L<App::XLSUtils>

B<Iterating/processing with Perl code>

L<XLSperl> CLI from L<App::XLSperl> lets you iterate each cell (with
'XLSperl -ne' or row with 'XLSperl -ane') with a Perl code, just like you would
each line of text with C<perl -ne> (in fact, the command-line options of XLSperl
mirror those of perl). Only supports the old Excel format (XLS not XLSX). Does
not support LibreOffice Calc format (ODS). If you feed it unsupported format, it
will fallback to text iterating, so if you feed it XLSX or ODS you will iterate
chunks of raw binary data.

L<xls-each-cell> from L<App::XLSUtils>

L<xls-each-row> from L<App::XLSUtils>

B<Converting to CSV>

C<CATDOC> (L<http://www.wagner.pp.ru/~vitus/software/catdoc/>) contains following
the programs C<catdoc> (to print the plain text of Microsoft Word documents to
standard output), L<xls2csv> (to convert Microsoft Excel workbook files to
CSV), and C<catppt> (to print plain text of Mirosoft PowerPoint presentations to
standard output). Available as Debian package. They only support the older
format (XLS and not XLSX). They do not support LibreOffice Calc format (ODS).

L<xls2csv> from L<App::XLSUtils>

B<Generating XLS>

TBD

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Spreadsheet::Read>

Author: L<HMBRAND|https://metacpan.org/author/HMBRAND>

=item * L<Spreadsheet::ReadSXC> - Extract OpenOffice 1.x spreadsheet data

Author: L<CORION|https://metacpan.org/author/CORION>

=item * L<Spreadsheet::ParseExcel> - Read information from an Excel file.

Author: L<DOUGW|https://metacpan.org/author/DOUGW>

=item * L<Spreadsheet::ParseXLSX> - parse XLSX files

Author: L<DOY|https://metacpan.org/author/DOY>

=item * L<App::XLSUtils>

=item * L<App::XLSperl>

Author: L<JONALLEN|https://metacpan.org/author/JONALLEN>

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

 % cpanm-cpanmodules -n WorkingWithXLS

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries WorkingWithXLS | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=WorkingWithXLS -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::WorkingWithXLS -E'say $_->{module} for @{ $Acme::CPANModules::WorkingWithXLS::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithXLS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithXLS>.

=head1 SEE ALSO

L<Acme::CPANModules::WorkingWithCSV>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithXLS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
