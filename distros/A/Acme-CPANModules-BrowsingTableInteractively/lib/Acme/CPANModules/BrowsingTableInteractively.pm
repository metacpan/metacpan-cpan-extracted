package Acme::CPANModules::BrowsingTableInteractively;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-15'; # DATE
our $DIST = 'Acme-CPANModules-BrowsingTableInteractively'; # DIST
our $VERSION = '0.009'; # VERSION

our $LIST = {
    summary => 'List of modules/tools for browsing table data interactively',
    description => <<'_',

This list reviews what tools are available on CPAN and in general to browse
table data interactively.

Let me say first that the best tools are not Perl-based since sadly Perl is not
a favorite choice for writing tools these days. That said, Perl is still a great
glue to help make those tools work together better for you.


1) **Visidata**, <https://www.visidata.org>

This is currently my favorite. It's terminal-based, written in Python, and has
more features than any other tools currently written in Perl, by far. vd has
support for many formats, including CSV, TSV, Excel, JSON, and SQLite. It makes
it particularly easy to create summary for your table like histogram or
sum/average/max/min/etc, or add new columns, or edit some cells. It also has
visualization features like XY-plots.

It has the concept of "sheets" like sheets in a spreadsheet workbook so anytime
you filter rows/columns or create summary or do some other derivation from your
data, you create a new sheet which you can edit, save, and destroy later as
needed and go back to your original table. It even presents settings and
metadata as sheets so you can edit them as a normal sheet.

It has plugins, and I guess it should be simple enough to create a plugin so you
can filter rows or add columns using Perl expression instead of the default
Python, if needed.

My CLI framework <pm:Perinci::CmdLine> (<pm:Perinci::CmdLine::Lite>, v1.918+)
has support for Visidata. You can specify command-line option `--format=vd` to
browse the output of your CLI program in Visidata.


2) **DataTables**, <https://datatables.net>

DataTables is a JavaScript (jQuery-based) library to add controls to your HTML
table so you can filter rows incrementally, sort rows, reorder columns, and so
on. It also has plugins to do more customized stuffs. I still prefer Visidata
most of the time because I am comfortable living in the terminal, but I
particularly love the incremental searching feature that comes built-in with
DataTables.

My CLI framework <pm:Perinci::CmdLine> (<pm:Perinci::CmdLine::Lite>, v1.918+)
also has support for DataTables. You can specify command-line option
`--format=html+datatables` to output your CLI program's result as HTML table
(using <pm:Text::Table::HTML::DataTables>) when possible and then browse the
output in browser.


3) **Tickit::Widget::Table**, <pm:Tickit::Widget::Table>

This module lets you browse the table in a terminal. Using the <pm:Tickit>
library, the advantages it's supposed to have is mouse support. It's still very
basic: you either have to specify each column width manually or the width of all
columns will be the same. There's no horizontal scrolling support or a way to
see long text in a column. Not updated since 2016.


4) **Term::TablePrint**, <pm:Term::TablePrint>

This module lets you browse the table in a terminal. Provides roughly the same
features like Tickit::Widget::Table with an extra one: you can press Enter on a
row to view it as a "card" where each column will be displayed vertically, so
you can better see a row that has many columns or columns with long text.

There is currently no support beyond the most basic stuffs, so no column hiding,
reordering, etc.


5) **less**

Don't forget the good ol' Unix pager. You can render your table data as an ASCII
table (using modules like <pm:Text::Table::More>, <pm:Text::ANSITable>, or
<pm:Text::Table::Any> for more formats to choose from) then pipe the output to
it. At least with *less* you can scroll horizontally or perform incremental
searching (though not interactive filtering of rows).


6) **SQLite browser**, **SQLiteStudio**, or other SQLite-based front-ends

Another way to browse your table data interactively is to export it to SQLite
database then use one of the many front-ends (desktop GUI, web-based, TUI, as
well as CLI) to browse it. If you have your table data as a CSV, you can use the
<prog:csv2sqlite> script from <pm:App::SQLiteUtils> to convert it to SQLite
database.

<https://sqlitebrowser.org>

<http://sqlitestudio.pl>


6) **Microsoft Excel**, **LibreOffice**, or other spreadsheet programs

Yet another way to browse your table data interactively is to use a spreadsheet,
which offers a rich way to view and manipulate data. You can generate a CSV from
your table data; all spreadsheets support opening CSV files.

_
    entries => [
        {
            module => 'Tickit::Widget::Table',
        },

        {
            module => 'Term::TablePrint',
        },

        {
            module => 'Text::Table::HTML::DataTables',
        },

        {
            module => 'App::SQLiteUtils',
        },
    ],
};

1;
# ABSTRACT: List of modules/tools for browsing table data interactively

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::BrowsingTableInteractively - List of modules/tools for browsing table data interactively

=head1 VERSION

This document describes version 0.009 of Acme::CPANModules::BrowsingTableInteractively (from Perl distribution Acme-CPANModules-BrowsingTableInteractively), released on 2023-06-15.

=head1 DESCRIPTION

This list reviews what tools are available on CPAN and in general to browse
table data interactively.

Let me say first that the best tools are not Perl-based since sadly Perl is not
a favorite choice for writing tools these days. That said, Perl is still a great
glue to help make those tools work together better for you.

1) B<Visidata>, L<https://www.visidata.org>

This is currently my favorite. It's terminal-based, written in Python, and has
more features than any other tools currently written in Perl, by far. vd has
support for many formats, including CSV, TSV, Excel, JSON, and SQLite. It makes
it particularly easy to create summary for your table like histogram or
sum/average/max/min/etc, or add new columns, or edit some cells. It also has
visualization features like XY-plots.

It has the concept of "sheets" like sheets in a spreadsheet workbook so anytime
you filter rows/columns or create summary or do some other derivation from your
data, you create a new sheet which you can edit, save, and destroy later as
needed and go back to your original table. It even presents settings and
metadata as sheets so you can edit them as a normal sheet.

It has plugins, and I guess it should be simple enough to create a plugin so you
can filter rows or add columns using Perl expression instead of the default
Python, if needed.

My CLI framework L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>, v1.918+)
has support for Visidata. You can specify command-line option C<--format=vd> to
browse the output of your CLI program in Visidata.

2) B<DataTables>, L<https://datatables.net>

DataTables is a JavaScript (jQuery-based) library to add controls to your HTML
table so you can filter rows incrementally, sort rows, reorder columns, and so
on. It also has plugins to do more customized stuffs. I still prefer Visidata
most of the time because I am comfortable living in the terminal, but I
particularly love the incremental searching feature that comes built-in with
DataTables.

My CLI framework L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>, v1.918+)
also has support for DataTables. You can specify command-line option
C<--format=html+datatables> to output your CLI program's result as HTML table
(using L<Text::Table::HTML::DataTables>) when possible and then browse the
output in browser.

3) B<Tickit::Widget::Table>, L<Tickit::Widget::Table>

This module lets you browse the table in a terminal. Using the L<Tickit>
library, the advantages it's supposed to have is mouse support. It's still very
basic: you either have to specify each column width manually or the width of all
columns will be the same. There's no horizontal scrolling support or a way to
see long text in a column. Not updated since 2016.

4) B<Term::TablePrint>, L<Term::TablePrint>

This module lets you browse the table in a terminal. Provides roughly the same
features like Tickit::Widget::Table with an extra one: you can press Enter on a
row to view it as a "card" where each column will be displayed vertically, so
you can better see a row that has many columns or columns with long text.

There is currently no support beyond the most basic stuffs, so no column hiding,
reordering, etc.

5) B<less>

Don't forget the good ol' Unix pager. You can render your table data as an ASCII
table (using modules like L<Text::Table::More>, L<Text::ANSITable>, or
L<Text::Table::Any> for more formats to choose from) then pipe the output to
it. At least with I<less> you can scroll horizontally or perform incremental
searching (though not interactive filtering of rows).

6) B<SQLite browser>, B<SQLiteStudio>, or other SQLite-based front-ends

Another way to browse your table data interactively is to export it to SQLite
database then use one of the many front-ends (desktop GUI, web-based, TUI, as
well as CLI) to browse it. If you have your table data as a CSV, you can use the
L<csv2sqlite> script from L<App::SQLiteUtils> to convert it to SQLite
database.

L<https://sqlitebrowser.org>

L<http://sqlitestudio.pl>

6) B<Microsoft Excel>, B<LibreOffice>, or other spreadsheet programs

Yet another way to browse your table data interactively is to use a spreadsheet,
which offers a rich way to view and manipulate data. You can generate a CSV from
your table data; all spreadsheets support opening CSV files.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Tickit::Widget::Table>

Author: L<TEAM|https://metacpan.org/author/TEAM>

=item L<Term::TablePrint>

Author: L<KUERBIS|https://metacpan.org/author/KUERBIS>

=item L<Text::Table::HTML::DataTables>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item L<App::SQLiteUtils>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

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

 % cpanm-cpanmodules -n BrowsingTableInteractively

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries BrowsingTableInteractively | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=BrowsingTableInteractively -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::BrowsingTableInteractively -E'say $_->{module} for @{ $Acme::CPANModules::BrowsingTableInteractively::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-BrowsingTableInteractively>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-BrowsingTableInteractively>.

=head1 SEE ALSO

Related lists: L<Acme::CPANModules::TextTable>,
L<Acme::CPANModules::WorkingWithCSV>.

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

This software is copyright (c) 2023, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BrowsingTableInteractively>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
