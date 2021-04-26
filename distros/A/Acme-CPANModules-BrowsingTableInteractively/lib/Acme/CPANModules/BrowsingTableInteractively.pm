package Acme::CPANModules::BrowsingTableInteractively;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-25'; # DATE
our $DIST = 'Acme-CPANModules-BrowsingTableInteractively'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';

The following are some options on CPAN if you have a table data (typically as an
array of arrayrefs) and want to browse it interactively.

<pm:Tickit::Table::Widget> - this module lets you browse the table in a
terminal. Using the <pm:Tickit> library, the advantages it's supposed to have is
mouse support. It's still very basic: you either have to specify each column
width manually or the width of all columns will be the same. There's no
horizontal scrolling support or a way to see long text in a column. Not updated
since 2016.

<pm:Term::TablePrint> - this module lets you browse the table in a terminal.
Provides roughly the same features like Tickit::Table::Widget with an extra one:
you can press Enter on a row to view it as a "card" where each column will be
displayed vertically, so you can better see a row that has many columns or
columns with long text.

Personally, both the above modules are not satisfactory for me. They are not
that much better than drawing the text table and then filtering the output
through a pager like *less*. At least with *less* you can scroll horizontally or
perform incremental searching (though not interactive filtering of rows).

<pm:Text::Table::HTML::DataTables> - this module bundles the wonderful
DataTables [1] JavaScript library and lets you see your table in a web browser
to interact with. I use this method the most often (usually through my CLI
framework and the option `--format=html+datatables` specified through my CLIs).
The main advantage is incremental searching/filtering. DataTables also lets you
hide/show/reorder columns, change the page size, and so on. This is leaps and
bounds more useful than simply scrolling pages of text provided by
Tickit::Table::Widget or Term::TablePrint.

[1] <https://datatables.net/>

_

our $LIST = {
    summary => 'Browsing table interactively',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Browsing table interactively

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::BrowsingTableInteractively - Browsing table interactively

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::BrowsingTableInteractively (from Perl distribution Acme-CPANModules-BrowsingTableInteractively), released on 2021-04-25.

=head1 DESCRIPTION

The following are some options on CPAN if you have a table data (typically as an
array of arrayrefs) and want to browse it interactively.

L<Tickit::Table::Widget> - this module lets you browse the table in a
terminal. Using the L<Tickit> library, the advantages it's supposed to have is
mouse support. It's still very basic: you either have to specify each column
width manually or the width of all columns will be the same. There's no
horizontal scrolling support or a way to see long text in a column. Not updated
since 2016.

L<Term::TablePrint> - this module lets you browse the table in a terminal.
Provides roughly the same features like Tickit::Table::Widget with an extra one:
you can press Enter on a row to view it as a "card" where each column will be
displayed vertically, so you can better see a row that has many columns or
columns with long text.

Personally, both the above modules are not satisfactory for me. They are not
that much better than drawing the text table and then filtering the output
through a pager like I<less>. At least with I<less> you can scroll horizontally or
perform incremental searching (though not interactive filtering of rows).

L<Text::Table::HTML::DataTables> - this module bundles the wonderful
DataTables [1] JavaScript library and lets you see your table in a web browser
to interact with. I use this method the most often (usually through my CLI
framework and the option C<--format=html+datatables> specified through my CLIs).
The main advantage is incremental searching/filtering. DataTables also lets you
hide/show/reorder columns, change the page size, and so on. This is leaps and
bounds more useful than simply scrolling pages of text provided by
Tickit::Table::Widget or Term::TablePrint.

[1] L<https://datatables.net/>

=head1 MODULES INCLUDED IN THIS ACME::CPANMODULES MODULE

=over

=item * L<Tickit::Table::Widget>

=item * L<Tickit>

=item * L<Term::TablePrint>

=item * L<Text::Table::HTML::DataTables>

=back

=head1 FAQ

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BrowsingTableInteractively>

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
