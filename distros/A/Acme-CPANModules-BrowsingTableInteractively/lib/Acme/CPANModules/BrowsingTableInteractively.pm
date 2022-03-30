package Acme::CPANModules::BrowsingTableInteractively;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-BrowsingTableInteractively'; # DIST
our $VERSION = '0.005'; # VERSION

our $LIST = {
    summary => 'List of modules for browsing table data interactively',
    description => <<'_',

This list catalogs are some options on CPAN if you have a table data (typically as an
array of arrayrefs) and want to browse it interactively.

_
    entries => [
        {
            module => 'Tickit::Widget::Table',
            description => <<'_',

This module lets you browse the table in a terminal. Using the <pm:Tickit>
library, the advantages it's supposed to have is mouse support. It's still very
basic: you either have to specify each column width manually or the width of all
columns will be the same. There's no horizontal scrolling support or a way to
see long text in a column. Not updated since 2016.

_
        },

        {
            module => 'Term::TablePrint',
            description => <<'_',

This module lets you browse the table in a terminal. Provides roughly the same
features like Tickit::Widget::Table with an extra one: you can press Enter on a
row to view it as a "card" where each column will be displayed vertically, so
you can better see a row that has many columns or columns with long text.

_
        },

        {
            module => 'Text::Table::HTML::DataTables',
            description => <<'_',

Personally, all the terminal modules listed here (<pm:Term::TablePrint> and
<pm:Tickit::Widget::Table>) are currently not satisfactory for me. They are not
that much better than drawing the text table (using something like
<pm:Text::Table::More> or <pm:Text::ANSITable>) and then piping the output
through a pager like *less*. At least with *less* you can scroll horizontally or
perform incremental searching (though not interactive filtering of rows).

Text::Table::HTML::DataTables bundles the wonderful DataTables [1] JavaScript
library and lets you see your table in a web browser to interact with. I use
this method the most often (usually through my CLI framework and the option
`--format=html+datatables` specified through my CLIs). The main advantage is
incremental searching/filtering. DataTables also lets you hide/show/reorder
columns, change the page size, and so on. This is leaps and bounds more useful
than simply scrolling pages of text provided by Tickit::Widget::Table or
Term::TablePrint.

[1] <https://datatables.net/>

_
        },
    ],
};

1;
# ABSTRACT: List of modules for browsing table data interactively

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::BrowsingTableInteractively - List of modules for browsing table data interactively

=head1 VERSION

This document describes version 0.005 of Acme::CPANModules::BrowsingTableInteractively (from Perl distribution Acme-CPANModules-BrowsingTableInteractively), released on 2022-03-18.

=head1 DESCRIPTION

This list catalogs are some options on CPAN if you have a table data (typically as an
array of arrayrefs) and want to browse it interactively.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Tickit::Widget::Table> - table widget with support for scrolling/paging

Author: L<TEAM|https://metacpan.org/author/TEAM>

This module lets you browse the table in a terminal. Using the L<Tickit>
library, the advantages it's supposed to have is mouse support. It's still very
basic: you either have to specify each column width manually or the width of all
columns will be the same. There's no horizontal scrolling support or a way to
see long text in a column. Not updated since 2016.


=item * L<Term::TablePrint> - Print a table to the terminal and browse it interactively.

Author: L<KUERBIS|https://metacpan.org/author/KUERBIS>

This module lets you browse the table in a terminal. Provides roughly the same
features like Tickit::Widget::Table with an extra one: you can press Enter on a
row to view it as a "card" where each column will be displayed vertically, so
you can better see a row that has many columns or columns with long text.


=item * L<Text::Table::HTML::DataTables> - Generate HTML table with jQuery and DataTables plugin

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

Personally, all the terminal modules listed here (L<Term::TablePrint> and
L<Tickit::Widget::Table>) are currently not satisfactory for me. They are not
that much better than drawing the text table (using something like
L<Text::Table::More> or L<Text::ANSITable>) and then piping the output
through a pager like I<less>. At least with I<less> you can scroll horizontally or
perform incremental searching (though not interactive filtering of rows).

Text::Table::HTML::DataTables bundles the wonderful DataTables [1] JavaScript
library and lets you see your table in a web browser to interact with. I use
this method the most often (usually through my CLI framework and the option
C<--format=html+datatables> specified through my CLIs). The main advantage is
incremental searching/filtering. DataTables also lets you hide/show/reorder
columns, change the page size, and so on. This is leaps and bounds more useful
than simply scrolling pages of text provided by Tickit::Widget::Table or
Term::TablePrint.

[1] L<https://datatables.net/>


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

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BrowsingTableInteractively>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
