package App::GUI::GoLP;

use 5.014;
use strict;
use warnings;

our $VERSION = "1.0";

1;

__END__

=head1 NAME

App::GUI::GoLP - A GUI for viewing Life-like cellular automata, in Perl/Prima

=head1 VERSION

Version 1.0

=head1 SYNOPSIS

    golp [<filename>]

=head1 DESCRIPTION

This program will load and run Life-like cellular automata from .rle or .cells files. A good source for files is L<https://conwaylife.com/wiki/Main_Page>. It uses L<Game::Life::Faster> for the engine and L<Prima> for the GUI. 

=for HTML <p>
<img src="https://raw.githubusercontent.com/mjohnson108/p5-App-GUI-GoLP/main/example/POD/c5diagonalpuffer1.png" alt="" width="400" height="325">
<img src="https://raw.githubusercontent.com/mjohnson108/p5-App-GUI-GoLP/main/example/POD/owssagarstretcher.png" alt="" width="400" height="325">
</p>


=head2 Menus

=head3 File

The I<Open> option provides a dialog box allowing the user to select a .rle or .cells format file to be loaded. The I<Exit> option exits the program.

=head3 Options

I<Play/Pause> starts and pauses the simulation. This can also be done from the space bar.

I<Grid> toggles the cell grid on and off.

I<Autogrow> toggles the 'autogrow' on and off. When activated, the size of the board will be enlarged if there are live cells close to the edge of the board.

I<Status line> toggles the status text which can be displayed along the bottom of the main window. This gives some information as to the current state of the simulation.

I<Snapshot board> will create a .png image file of the board in the current working directory.

I<Loop delay> presents a list of presets which affects the speed of the simulation. 

I<Rules> allows the user to select from a preset list of birth/survival rules, or use the I<Custom rule> dialog to specify one.

I<Zoom> opens the zoom dialog.

I<Live cell color> allows the user to select the color of a 'live' cell.

I<Dead cell color> allows the user to select the color of a 'dead' cell.

I<Grid color> allows the user to select the color of the grid.

=head3 About

Provides a small 'about' dialog.

=head2 Mouse interaction

The mouse wheel can be used to adjust the zoom setting (otherwise use the menu option). If the zoom is such that the board is clipped, the user can click and drag within the window to move the viewed section of the board.

=head1 TODO

Options for stepping through the simulation, and editing and saving the board.

=head1 SEE ALSO

L<Prima>

L<Game::Life::Faster>

=head1 AUTHOR

Matt Johnson, C<< <mjohnson at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Matt Johnson.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

