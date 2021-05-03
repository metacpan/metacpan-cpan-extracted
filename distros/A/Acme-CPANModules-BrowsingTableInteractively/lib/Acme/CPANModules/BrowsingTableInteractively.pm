package Acme::CPANModules::BrowsingTableInteractively;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-01'; # DATE
our $DIST = 'Acme-CPANModules-BrowsingTableInteractively'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;

our $LIST = {
    summary => 'Browsing table data interactively',
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
# ABSTRACT: Browsing table data interactively

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::BrowsingTableInteractively - Browsing table data interactively

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::BrowsingTableInteractively (from Perl distribution Acme-CPANModules-BrowsingTableInteractively), released on 2021-05-01.

=head1 DESCRIPTION

This list catalogs are some options on CPAN if you have a table data (typically as an
array of arrayrefs) and want to browse it interactively.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Tickit::Widget::Table>

This module lets you browse the table in a terminal. Using the L<Tickit>
library, the advantages it's supposed to have is mouse support. It's still very
basic: you either have to specify each column width manually or the width of all
columns will be the same. There's no horizontal scrolling support or a way to
see long text in a column. Not updated since 2016.


=item * L<Term::TablePrint>

This module lets you browse the table in a terminal. Provides roughly the same
features like Tickit::Widget::Table with an extra one: you can press Enter on a
row to view it as a "card" where each column will be displayed vertically, so
you can better see a row that has many columns or columns with long text.


=item * L<Text::Table::HTML::DataTables>

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
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries BrowsingTableInteractively | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=BrowsingTableInteractively -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::BrowsingTableInteractively -E'say $_->{module} for @{ $Acme::CPANModules::BrowsingTableInteractively::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-BrowsingTableInteractively>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-BrowsingTableInteractively>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-BrowsingTableInteractively/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
