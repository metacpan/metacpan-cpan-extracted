use v5.12;
use warnings;
use Wx;
use utf8;

package App::GUI::Cellgraph;
our $NAME = __PACKAGE__;
our $VERSION = '0.03';

use base qw/Wx::App/;
use App::GUI::Cellgraph::Frame;

sub OnInit {
    my $app   = shift;
    my $frame = App::GUI::Cellgraph::Frame->new( undef, 'Cellgraph '.$VERSION);
    $frame->Show(1);
    $frame->CenterOnScreen();
    $app->SetTopWindow($frame);
    1;
}
sub OnQuit { my( $self, $event ) = @_; $self->Close( 1 ); }
sub OnExit { my $app = shift;  1; }


1;

__END__

=pod

=head1 NAME

App::GUI::Cellgraph - draw pattern by cellular automata

=head1 SYNOPSIS 

=over 4

=item 1.

start the program (cellgraph)

=item 2.

push buttons and see patterns change

=item 3.

choose I<"Save"> in Image menu (or C<Ctrl+S>) to store image in a PNG / JPEG / SVG file
(choose image size  in menu beforehand)

=item 4.

choose I<Write> in settings menu (C<Ctrl+W>) to save settings into an
INI file for tweaking them later

=back

=head1 DESCRIPTION

This is a row (one dimensional arrangement) of cellular automata.
Their starting state can be seen in the first row. Each subsequent row
below reflects the following state (Y is time axis). 

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/126.png"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/30.png"    alt=""  width="300" height="300">
</p>


=head1 Mechanics

One automaton is called cell and works like described in I<Steve Wolfram>s
book  I<"A new kind of science">. Each cell can be in one of several states.
The most simple cells have only two: 0 and 1 (pictured as white and black squares).
The state of each cell may change each round (think of processor cycles).
How exactly they change s defined by a transfer function. The input of
that function are the states of neighbours left and right and the cell
itself. Other neighbourhoods are possible. For every combination of states
in the neighbourhood there is one partial rule that defines the next state
of the cell. If neighbourhoods get greater - the number of rules grows
exponentially. To reduce again the rule count one might only take the 
average value of the neighbourhood as input.

To each partial rule also belongs an instruction how to pass on which 
cells should apply the transfer function. In the simplest case all cells
are activated all the time. But you can also decide if the current cell
or its neighbours remain active, dependent on the state of the neighbourhood.

=head1 GUI

The general layout is very simple: the settings are on the right and 
the drawing board is left. The settings are devided into several tabs.

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button. Also helpful are messages in the status bar
at the bottom that appear while browsing the menu.

=head2 Start

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/GUIstart.png"   alt=""  width="630" height="410">
</p>

The first tab contains the general settings.

In the left top corner you can select if the grid should be of visible
gray lines, gaps (white lines) or no gaps between the squares. Right
beside you set the aize of the squares in pixel.

Below that you set the content of the starting row of the grid. By 
clicking on the squares they change their state. Their combined value
is summarized in the displayed integer abover the squares. The buttons
left and right will count that number down or up to circle easily through
all the starting states. The button I<"1"> simply resets the value to 1
(one activated cell), and I<"?"> selects a random strting sequence.
When I<"Repeat"> is selected the chosen sequence gets repeated as often
as the first row is long.


=head2 Rules

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/GUIrule.png"   alt=""  width="630" height="410">
</p>

On the second tab you can set the individual partial rules. 
Just click on the result square in the chosen subrule (after the =>). 
All rule results are combined in a rule number, which you can see on top.
With the buttons left and right you can again count that number down and
up or even shift the rule results left and right (<< and >>). The buttons
below allow you to easily reach related rules, like the inverted,
symmetric or opposite. Inverted means every rule result will be inverted. 
Symmetric means ever rule switches its result with its symmetric partner
(if there is one). Opposite rule means ever rule switches its result the
rule of inverted input. The button I<"?"> again selects a random rule.

Behind the result of each subrule is another subrule for the action
propagation. The circles show if the cell or its neighbours can do the
transfer function next cycle. These settings are again combined in a
singular action value (behind the label "Active:"). Here are also four 
buttons to select the init state, a grid patter or a random state.
The first buttom set the inverted distribution of action propagation.

=head2 Menu

The upmost menu bar has only three very simple menus.
Please not that each menu shows which key combination triggers the same
command and while hovering over an menu item you see a short help text
the left status bar field.

The first menu is for loading and storing setting files with arbitrary 
names. Also a sub menu allows a quick load of the recently used files.
The first entry lets you reset the whole program to the starting state
and the last is just to exit (safely with saving the configs).

The second menu has only two commands for saving the grin into a image file.
It can have an arbitrary name - the ending I<PNG>, I<JPG> or I<SVG> decides
the format. The submenu above sets the image size. Please note that if 
you choose a larger image than shown, a larger grid will be computed.
If you want larger squares, please change that in the settings.

=head1 SEE ALSO

L<App::GUI::Harmonograph>

L<App::GUI::Dynagraph>


=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022 by Herbert Breunung

All rights reserved. 
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
