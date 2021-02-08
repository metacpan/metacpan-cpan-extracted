package Acme::CPANModules::Sudoku;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-12'; # DATE
our $DIST = 'Acme-CPANModules-Sudoku'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use Acme::CPANModulesUtil::Misc;

my $text = <<'_';

Recently (Dec 2020) I picked up more interest in Sudoku, as I was spending more
time at home with the kids, and there was a book of Sudoku puzzles lying around
in the room.

There are certainly more modules on CPAN for solving Sudoku puzzles compared to
modules/scripts that let you play Sudoku. Basically, I find that there's no good
playable Sudoku game on CPAN.

**Playing**

<pm::Games::Sudoku::CLI>. Since it's CLI (prompt-based) instead of TUI, it's not
really convenient to play unless you're a CLI freak.

<pm::Games::Sudoku::Component::TkPlayer>. It's GUI and barely playable, but
clunky and not pretty. There's no visual indicator for separating the larger 3x3
boxes.


**Generating**

These modules can generate Sudoku puzzles for you, though not let you
interactively play/solve them.

<pm:Spreadsheet::HTML::Presets::Sudoku>


**Solving**

There's no shortage of modules written to solve Sudoku puzzles. I plan to
benchmark these but for now here's the list:

<pm:Games::Sudoku::Lite>

<pm:Games::Sudoku::Solver>

<pm:Games::Sudoku::General>

<pm:Games::Sudoku::CPSearch>

<pm:Games::Sudoku::Kubedoku>

<pm:Games::Sudoku::SudokuTk>

<pm:Games::Sudoku::OO::Board>

<pm:Games::YASudoku>

_

our $LIST = {
    summary => 'Sudoku-related modules on CPAN',
    description => $text,
    tags => ['task'],
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: Sudoku-related modules on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Sudoku - Sudoku-related modules on CPAN

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::Sudoku (from Perl distribution Acme-CPANModules-Sudoku), released on 2021-01-12.

=head1 DESCRIPTION

Recently (Dec 2020) I picked up more interest in Sudoku, as I was spending more
time at home with the kids, and there was a book of Sudoku puzzles lying around
in the room.

There are certainly more modules on CPAN for solving Sudoku puzzles compared to
modules/scripts that let you play Sudoku. Basically, I find that there's no good
playable Sudoku game on CPAN.

B<Playing>

<pm::Games::Sudoku::CLI>. Since it's CLI (prompt-based) instead of TUI, it's not
really convenient to play unless you're a CLI freak.

<pm::Games::Sudoku::Component::TkPlayer>. It's GUI and barely playable, but
clunky and not pretty. There's no visual indicator for separating the larger 3x3
boxes.

B<Generating>

These modules can generate Sudoku puzzles for you, though not let you
interactively play/solve them.

L<Spreadsheet::HTML::Presets::Sudoku>

B<Solving>

There's no shortage of modules written to solve Sudoku puzzles. I plan to
benchmark these but for now here's the list:

L<Games::Sudoku::Lite>

L<Games::Sudoku::Solver>

L<Games::Sudoku::General>

L<Games::Sudoku::CPSearch>

L<Games::Sudoku::Kubedoku>

L<Games::Sudoku::SudokuTk>

L<Games::Sudoku::OO::Board>

L<Games::YASudoku>

=head1 ACME::MODULES ENTRIES

=over

=item * L<Spreadsheet::HTML::Presets::Sudoku>

=item * L<Games::Sudoku::Lite>

=item * L<Games::Sudoku::Solver>

=item * L<Games::Sudoku::General>

=item * L<Games::Sudoku::CPSearch>

=item * L<Games::Sudoku::Kubedoku>

=item * L<Games::Sudoku::SudokuTk>

=item * L<Games::Sudoku::OO::Board>

=item * L<Games::YASudoku>

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

    % cpanmodules ls-entries Sudoku | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Sudoku -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Sudoku -E'say $_->{module} for @{ $Acme::CPANModules::Sudoku::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Sudoku>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Sudoku>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-Sudoku/issues>

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
