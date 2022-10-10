package Acme::CPANModules::WorkingWithCSV;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-27'; # DATE
our $DIST = 'Acme-CPANModules-WorkingWithCSV'; # DIST
our $VERSION = '0.001'; # VERSION

my $text = <<'_';
The following are tools (modules and scripts) to work with the CSV format:


**Parsing**

First things first, the most important module to work with CSV in Perl is
<pm:Text::CSV> (which will use <pm:Text::CSV_XS> backend when possible but fall
back to <pm:Text::CSV_PP> otherwise). It's not in core, but only a cpanm command
away.


**Generating CSV from Perl array/structure**

<pm:Text::CSV> (as well as <pm:Text::CSV_XS>) can render a line of CSV from Perl
array(ref) with their `say()` method.

<prog:dd2csv> from <pm:App::CSVUtils>

<pm:Perinci::CmdLine> framework can render function result (CLI output) as CSV.


**Converting to/from other formats**

*INI*: <prog:ini2csv> from <pm:App::TextTableUtils>

*TSV*: <prog:csv2tsv> and L<prog:tsv2csv> from <pm:App::CSVUtils>

*LTSV*: <prog:csv2ltsv> from <pm:App::CSVUtils> and L<prog:ltsv2csv> from
<pm:App::LTSVUtils>

*XLS* and *XLSX*: <prog:csv2tsv> and <prog:tsv2csv> from <pm:App::CSVUtils>

*JSON*: <prog:csv2json> and <prog:json2csv> from <pm:App::TextTableUtils>

*Markdown table*: <prog:csv2mdtable> from <pm:App::TextTableUtils>

*Org table*: <prog:csv2orgtable> from <pm:App::TextTableUtils>

*SQLite database*: <prog:csv2sqlite> from <pm:App::SQLiteUtils>


**Rendering as text/ASCII table**

<prog:csv2texttable> from <pm:App::TextTableUtils>


**Changing field separator character, field quote character, and/or escape character**

<prog:csv-csv> from <pm:App::CSVUtils>


**Adding/removing columns**

<prog:csv-add-field>, <prog:csv-delete-field>, <prog:csv-select-fields> from
<pm:App::CSVUtils>


**Processing columns of CSV with Perl code**

<prog:csv-munge-field> from <pm:App::CSVUtils>


**Processing rows of CSV with Perl code**

Aside from the obvious <pm:Text::CSV>, you can also use <prog:csv-each-row>,
<prog:csv-munge-row>, <prog:csv-mp> from <pm:App::CSVUtils>.


**Merging several CSV files into one**

<prog:csv-concat> from <pm:App::CSVUtils>


**Splitting a CSV file into several**

<prog:csv-split> from <pm:App::CSVUtils>


**Sorting CSV rows**

<prog:csv-sort> from <pm:App::CSVUtils>


**Sorting CSV columns**

<prog:csv-sort-fields> from <pm:App::CSVUtils>


**Filtering CSV columns**

<prog:csv-select-fields> from <pm:App::CSVUtils>


**Filtering CSV rows**

<prog:csv-grep> and <prog:csv-select-rows> from <pm:App::CSVUtils>

<prog:csvgrep> from <pm:csvgrep>


**Transposing CSV**

<prog:csv-transpose> from <pm:App::CSVUtils>


**Summing and averaging rows**

<prog:csv-sum> and <prog:csv-avg> from <pm:App::CSVUtils>


**Producing frequency table from CSV**

<prog:csv-freqtable> from <pm:App::CSVUtils>


**Performing set operations (intersection, union, difference) on CSV**

<prog:csv-setop> from <pm:App::CSVUtils>

_

our $LIST = {
    summary => 'Working with CSV (comma-separated value) data in Perl',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Working with CSV (comma-separated value) data in Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::WorkingWithCSV - Working with CSV (comma-separated value) data in Perl

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::WorkingWithCSV (from Perl distribution Acme-CPANModules-WorkingWithCSV), released on 2022-07-27.

=head1 DESCRIPTION

The following are tools (modules and scripts) to work with the CSV format:

B<Parsing>

First things first, the most important module to work with CSV in Perl is
L<Text::CSV> (which will use L<Text::CSV_XS> backend when possible but fall
back to L<Text::CSV_PP> otherwise). It's not in core, but only a cpanm command
away.

B<Generating CSV from Perl array/structure>

L<Text::CSV> (as well as L<Text::CSV_XS>) can render a line of CSV from Perl
array(ref) with their C<say()> method.

L<dd2csv> from L<App::CSVUtils>

L<Perinci::CmdLine> framework can render function result (CLI output) as CSV.

B<Converting to/from other formats>

I<INI>: L<ini2csv> from L<App::TextTableUtils>

I<TSV>: L<csv2tsv> and LL<tsv2csv> from L<App::CSVUtils>

I<LTSV>: L<csv2ltsv> from L<App::CSVUtils> and LL<ltsv2csv> from
L<App::LTSVUtils>

I<XLS> and I<XLSX>: L<csv2tsv> and L<tsv2csv> from L<App::CSVUtils>

I<JSON>: L<csv2json> and L<json2csv> from L<App::TextTableUtils>

I<Markdown table>: L<csv2mdtable> from L<App::TextTableUtils>

I<Org table>: L<csv2orgtable> from L<App::TextTableUtils>

I<SQLite database>: L<csv2sqlite> from L<App::SQLiteUtils>

B<Rendering as text/ASCII table>

L<csv2texttable> from L<App::TextTableUtils>

B<Changing field separator character, field quote character, and/or escape character>

L<csv-csv> from L<App::CSVUtils>

B<Adding/removing columns>

L<csv-add-field>, L<csv-delete-field>, L<csv-select-fields> from
L<App::CSVUtils>

B<Processing columns of CSV with Perl code>

L<csv-munge-field> from L<App::CSVUtils>

B<Processing rows of CSV with Perl code>

Aside from the obvious L<Text::CSV>, you can also use L<csv-each-row>,
L<csv-munge-row>, L<csv-mp> from L<App::CSVUtils>.

B<Merging several CSV files into one>

L<csv-concat> from L<App::CSVUtils>

B<Splitting a CSV file into several>

L<csv-split> from L<App::CSVUtils>

B<Sorting CSV rows>

L<csv-sort> from L<App::CSVUtils>

B<Sorting CSV columns>

L<csv-sort-fields> from L<App::CSVUtils>

B<Filtering CSV columns>

L<csv-select-fields> from L<App::CSVUtils>

B<Filtering CSV rows>

L<csv-grep> and L<csv-select-rows> from L<App::CSVUtils>

L<csvgrep> from L<csvgrep>

B<Transposing CSV>

L<csv-transpose> from L<App::CSVUtils>

B<Summing and averaging rows>

L<csv-sum> and L<csv-avg> from L<App::CSVUtils>

B<Producing frequency table from CSV>

L<csv-freqtable> from L<App::CSVUtils>

B<Performing set operations (intersection, union, difference) on CSV>

L<csv-setop> from L<App::CSVUtils>

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Text::CSV> - comma-separated values manipulator (using XS or PurePerl)

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item * L<Text::CSV_XS> - comma-separated values manipulation routines

Author: L<HMBRAND|https://metacpan.org/author/HMBRAND>

=item * L<Text::CSV_PP> - Text::CSV_XS compatible pure-Perl module

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item * L<App::CSVUtils> - CLI utilities related to CSV

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Perinci::CmdLine> - Rinci/Riap-based command-line application framework

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::TextTableUtils>

=item * L<App::LTSVUtils> - CLI utilities related to LTSV

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<App::SQLiteUtils> - Utilities related to SQLite

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<csvgrep>

Author: L<NEILB|https://metacpan.org/author/NEILB>

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

 % cpanm-cpanmodules -n WorkingWithCSV

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries WorkingWithCSV | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=WorkingWithCSV -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::WorkingWithCSV -E'say $_->{module} for @{ $Acme::CPANModules::WorkingWithCSV::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-WorkingWithCSV>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-WorkingWithCSV>.

=head1 SEE ALSO

L<App::CSVUtils::Manual::Cookbook>

The See Also section in L<App::CSVUtils> documentation

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-WorkingWithCSV>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
