package Acme::CPANModules::WorkingWithPDF;

use strict;

use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-04'; # DATE
our $DIST = 'Acme-CPANModules-WorkingWithPDF'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'MARKDOWN';

The following are tools (programs, modules, scripts) to work with PDF (Portable
Document Format) files.


**Converting from other formats**

<pm:App::pod2pdf>

<pm:PDF::FromHTML>

<pm:PDF::FromImage>

<pm:PDF::Boxer> creates PDF from a simple markup language called "boxer".


**Converting to other formats**



**Diffing**

<prog:diff-pdf-text> (from <pm:App::DiffPDFText>) converts each PDF to text and
performs `diff` on the text files.


**Generating**

<pm:PDF::Builder>

<pm:PDF::Create>

<pm:PDF::Cairo>


**Passwords**

<prog:add-pdf-password> (from <pm:App::PDFUtils>) adds password to PDF.

<prog:remove-pdf-password> (from <pm:App::PDFUtils>) strips password from PDF.


**Searching**

<prog:pdfgrep> (from <pm:App::pdfgrep>) converts PDF to text and performs grep
on it.


**Transforming**

<pm:PDF::API2>, <pm:PDF::API3>

<prog:paperback> (from <pm:App::paperback>) collages smaller pages from original
PDF into bigger pages.

<prog:pdfolay> (from <pm:App::PDF::Overlay>) overlays (superimposes) PDF pages
to the pages of other PDF.

<PDF::Collage> also creates collages.

<prog:pdflink> (from <pm:App::PDF::Link>) adds clickable icons in PDF that link
to other documents.

MARKDOWN

our $LIST = {
    summary => 'List of modules to work with Excel formats (XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS)',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of modules to work with Excel formats (XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithPDF - List of modules to work with Excel formats (XLS, XLSX) or other spreadsheet formats like LibreOffice Calc (ODS)

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::WorkingWithPDF (from Perl distribution Acme-CPANModules-WorkingWithPDF), released on 2023-12-04.

=head1 DESCRIPTION

The following are tools (programs, modules, scripts) to work with PDF (Portable
Document Format) files.

B<Converting from other formats>

L<App::pod2pdf>

L<PDF::FromHTML>

L<PDF::FromImage>

L<PDF::Boxer> creates PDF from a simple markup language called "boxer".

B<Converting to other formats>

B<Diffing>

L<diff-pdf-text> (from L<App::DiffPDFText>) converts each PDF to text and
performs C<diff> on the text files.

B<Generating>

L<PDF::Builder>

L<PDF::Create>

L<PDF::Cairo>

B<Passwords>

L<add-pdf-password> (from L<App::PDFUtils>) adds password to PDF.

L<remove-pdf-password> (from L<App::PDFUtils>) strips password from PDF.

B<Searching>

L<pdfgrep> (from L<App::pdfgrep>) converts PDF to text and performs grep
on it.

B<Transforming>

L<PDF::API2>, L<PDF::API3>

L<paperback> (from L<App::paperback>) collages smaller pages from original
PDF into bigger pages.

L<pdfolay> (from L<App::PDF::Overlay>) overlays (superimposes) PDF pages
to the pages of other PDF.

<PDF::Collage> also creates collages.

L<pdflink> (from L<App::PDF::Link>) adds clickable icons in PDF that link
to other documents.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<App::pod2pdf>

Author: L<JONALLEN|https://metacpan.org/author/JONALLEN>

=item L<PDF::FromHTML>

Author: L<AUDREYT|https://metacpan.org/author/AUDREYT>

=item L<PDF::FromImage>

Author: L<TYPESTER|https://metacpan.org/author/TYPESTER>

=item L<PDF::Boxer>

Author: L<LECSTOR|https://metacpan.org/author/LECSTOR>

=item L<App::DiffPDFText>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<PDF::Builder>

Author: L<PMPERRY|https://metacpan.org/author/PMPERRY>

=item L<PDF::Create>

Author: L<MANWAR|https://metacpan.org/author/MANWAR>

=item L<PDF::Cairo>

Author: L<JGREELY|https://metacpan.org/author/JGREELY>

=item L<App::PDFUtils>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::pdfgrep>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<PDF::API2>

Author: L<SSIMMS|https://metacpan.org/author/SSIMMS>

=item L<PDF::API3>

Author: L<OTTO|https://metacpan.org/author/OTTO>

=item L<App::paperback>

Author: L<MONACCI|https://metacpan.org/author/MONACCI>

=item L<App::PDF::Overlay>

Author: L<JV|https://metacpan.org/author/JV>

=item L<App::PDF::Link>

Author: L<JV|https://metacpan.org/author/JV>

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

 % cpanm-cpanmodules -n WorkingWithPDF

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries WorkingWithPDF | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=WorkingWithPDF -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::WorkingWithPDF -E'say $_->{module} for @{ $Acme::CPANModules::WorkingWithPDF::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithPDF>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithPDF>.

=head1 SEE ALSO

L<Acme::CPANModules::WorkingWithDOC>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithPDF>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
