package Acme::CPANModules::Sudoku;

use strict;
use Acme::CPANModulesUtil::Misc;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-Sudoku'; # DIST
our $VERSION = '0.007'; # VERSION

my $text = <<'_';

Recently (Dec 2020) I picked up more interest in Sudoku, as I was spending more
time at home with the kids, and there was a book of Sudoku puzzles lying around
in the room.

**Playing**

There are certainly more modules on CPAN for solving Sudoku puzzles compared to
for playing. And between the two available modules for playing, I find that
there's currently no good playable Sudoku game on CPAN. Sad but true. You'd be
better off opening your browser and visiting <https://websudoku.com> or
<https://sudoku.com>, or installing *ksudoku* or *gnome-sudoku* if you're using
KDE/GNOME, or *sudoku* (by Michael Kennett) or *nudoku* if you like playing on
the terminal.

(CPAN does still contain some playable games though. I did enjoy
*Games::FrozenBubble* and still play *Games::2048* from time to time.)

These modules are available for playing Sudoku:

<pm:Games::Sudoku::CLI>. Since it's CLI (prompt-based) instead of TUI, it's not
really convenient to play unless you're a CLI freak.

<pm:Games::Sudoku::Component::TkPlayer>. It's GUI, but clunky and not pretty.
There's no visual indicator for separating the larger 3x3 boxes.


**Generating**

These modules can generate Sudoku puzzles for you, though not let you
interactively play/solve them:

<pm:Spreadsheet::HTML::Presets::Sudoku>


**Solving**

There is no shortage of modules written to solve Sudoku puzzles. I plan to
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
    summary => 'List of Sudoku-related modules on CPAN',
    description => $text,
};

Acme::CPANModulesUtil::Misc::populate_entries_from_module_links_in_description;

1;
# ABSTRACT: List of Sudoku-related modules on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Sudoku - List of Sudoku-related modules on CPAN

=head1 VERSION

This document describes version 0.007 of Acme::CPANModules::Sudoku (from Perl distribution Acme-CPANModules-Sudoku), released on 2022-03-18.

=head1 DESCRIPTION

Recently (Dec 2020) I picked up more interest in Sudoku, as I was spending more
time at home with the kids, and there was a book of Sudoku puzzles lying around
in the room.

B<Playing>

There are certainly more modules on CPAN for solving Sudoku puzzles compared to
for playing. And between the two available modules for playing, I find that
there's currently no good playable Sudoku game on CPAN. Sad but true. You'd be
better off opening your browser and visiting L<https://websudoku.com> or
L<https://sudoku.com>, or installing I<ksudoku> or I<gnome-sudoku> if you're using
KDE/GNOME, or I<sudoku> (by Michael Kennett) or I<nudoku> if you like playing on
the terminal.

(CPAN does still contain some playable games though. I did enjoy
I<Games::FrozenBubble> and still play I<Games::2048> from time to time.)

These modules are available for playing Sudoku:

L<Games::Sudoku::CLI>. Since it's CLI (prompt-based) instead of TUI, it's not
really convenient to play unless you're a CLI freak.

L<Games::Sudoku::Component::TkPlayer>. It's GUI, but clunky and not pretty.
There's no visual indicator for separating the larger 3x3 boxes.

B<Generating>

These modules can generate Sudoku puzzles for you, though not let you
interactively play/solve them:

L<Spreadsheet::HTML::Presets::Sudoku>

B<Solving>

There is no shortage of modules written to solve Sudoku puzzles. I plan to
benchmark these but for now here's the list:

L<Games::Sudoku::Lite>

L<Games::Sudoku::Solver>

L<Games::Sudoku::General>

L<Games::Sudoku::CPSearch>

L<Games::Sudoku::Kubedoku>

L<Games::Sudoku::SudokuTk>

L<Games::Sudoku::OO::Board>

L<Games::YASudoku>

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Games::Sudoku::CLI> - play Sudoku on the command line

Author: L<SZABGAB|https://metacpan.org/author/SZABGAB>

=item * L<Games::Sudoku::Component::TkPlayer> - Let's play Sudoku

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item * L<Spreadsheet::HTML::Presets::Sudoku> - Generates 9x9 sudoku boards via HTML tables.

Author: L<JEFFA|https://metacpan.org/author/JEFFA>

=item * L<Games::Sudoku::Lite>

Author: L<BOBO|https://metacpan.org/author/BOBO>

=item * L<Games::Sudoku::Solver> - Solve 9x9-Sudokus recursively.

Author: L<MEHNER|https://metacpan.org/author/MEHNER>

=item * L<Games::Sudoku::General>

Author: L<WYANT|https://metacpan.org/author/WYANT>

=item * L<Games::Sudoku::CPSearch> - Solve Sudoku problems quickly.

Author: L<MARTYLOO|https://metacpan.org/author/MARTYLOO>

=item * L<Games::Sudoku::Kubedoku> - Sudoku Solver for any NxN puzzles

Author: L<VELASCO|https://metacpan.org/author/VELASCO>

=item * L<Games::Sudoku::SudokuTk> - Sudoku Game 

Author: L<CGUINE|https://metacpan.org/author/CGUINE>

=item * L<Games::Sudoku::OO::Board> - Object oriented Sudoku solver

Author: L<COPE|https://metacpan.org/author/COPE>

=item * L<Games::YASudoku> - Yet Another Sudoku Solver

Author: L<WYLLIE|https://metacpan.org/author/WYLLIE>

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

 % cpanm-cpanmodules -n Sudoku

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Sudoku | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Sudoku -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Sudoku -E'say $_->{module} for @{ $Acme::CPANModules::Sudoku::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Sudoku>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Sudoku>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Sudoku>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
