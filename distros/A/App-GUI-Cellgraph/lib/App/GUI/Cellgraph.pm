use v5.12;
use warnings;
use Wx;
use utf8;

package App::GUI::Cellgraph;
our $NAME = __PACKAGE__;
our $VERSION = '0.25';

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

push button I<Draw> in right bottom corner to get a full picture

=item 4.

choose I<"Save"> in Image menu (or C<Ctrl+S>) to store image in a PNG / JPEG / SVG file
(choose image size  in menu beforehand)

=item 5.

choose I<Write> in settings menu (C<Ctrl+W>) to save settings into an
INI file for loading in and tweaking the parameters later

After first use of the program, a config file will be created under
I<~/.config/cellgraph> in your home directory. It contains mainly
stored colors and dirs where to load and store setting files.
You may change it manually or deleted it to reset defaults.

=back

=head1 DESCRIPTION

This is a row (one dimensional arrangement) of cellular automata.
Their starting state can be seen as a color in the first row of the grid.
Each subsequent row below reflects the following state (Y is time axis).
Other drawing  directions are optional and explained as part of the
I<Global> panel.

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/126.png"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/30.png"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/7io.png"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/teppich2.png"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/kreuz.png"    alt=""  width="300" height="300">
</p>


=head1 Mechanics

One automaton is called cell and works like described in I<Steve Wolfram>s
book  I<"A new kind of science">. Each cell can be in one of several states,
displayed as a greyscale or user defined color. The most simple cells
have only two states: 0 and 1 (pictured as white and black squares).
The state of each cell may change each round (think of processor cycles).
How exactly they change is defined by a transfer function. The input of
that function are the states of neighbours left and right and the cell
itself. The size of this neighbourhood can be changed. For every combination
of states in the neighbourhood there is one partial rule that defines the
next state of the cell. If large neighbourhoods or large state counts would
result in too many partial rules, than a different logic will apply.
Than there is only a different partial rule for every distinct sum value.
By sum is meant the sum of all states in the neighbourhood, since the
state of a cell is just an integer.

To each partial rule also belongs also an action rule, an instruction
that decides if the transfer function will be even applied or the state
just stays the same. Action rules will be set via the I<Action> panel.

=head1 GUI

The general layout is very simple: the settings are on the right and
the drawing board is left. The settings are devided into several tabs.

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button. Also helpful are messages in the status bar
at the bottom that appear while browsing the menu.

=head2 Global

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIglobal.png"   alt=""  width="630" height="410">
</p>

The first tab contains the general (meta) settings.
In upper left corder is the selector for the optical grid style. With or
without grid lines (always sized one pixel) or just same sized gaps
between the colored squares, which represent the cells. Right beside you
set the size of the squares in pixel.

In the row below are options how to draw the state matrix. Default
is the already in the description mentioned top down drawing method,
where the first row is the initial state of the cells as set in the next
tab named I<start>. Each following state of a cell is in the square below,
which makes Y so to speak the (vertical) time axis (top to down). To
produce more decorative patterns there are two more frawing patters:
I<inside out> and I<outside in>. Both are based on the idea of cutting
the grid square into 4 triangles, by using the diagonals as dividing lines.
With I<outside in> the upper triangle is filled as before and the content
rotated 3 times around the center to fill the other triangles. With the
option I<inside out> is almost everything the same except the upper triangle
is filled from the center up so the central pixel of the square is the
central pixel of the starting row, growing into all four directions.
On the checkbox beside that you hab the option to make the leftmost and
rightmost cells neighbours. It their not the program will calculate
enough so no artefacts stemming from the corner cells will be visible.
But making the cell row into a ring can produce a different kind of artefacts.


The third row in this tab sets the meta properties of the rules: number
of states and size of neighbourhood. If that is even, the cell in question
is not part of its own neighbourhood.

=head2 Start

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIstart.png"   alt=""  width="630" height="410">
</p>

The second tab contains settings for the starting values (states).
By clicking on the squares you change (cycle) the state. Only the cells
from the first to the last none zero (white) one will be recognised and
placed into the center of the first grid row and the rest will be filled
with zeros. If you choose I<Repeat>, the selected cell staes will repeated
to take up the entire cell row. To get only one none zero cell, press the
butoon C<1> and for a random starting sequence C<?>. The arrow buttons
are just increment or decrement the numeric value of the starting sequence.

=head2 Rules

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIrules.png"   alt=""  width="630" height="410">
</p>

On the third tab you can set the individual partial rules.
Just click on the result square in the chosen subrule (after the =>).
The state color will cycle through as in the previous tab.
All rule results are combined in a rule number, which you can see on top.
With the buttons left and right you can again count that number down and
up or even shift the rule results left and right (<< and >>). The buttons
in the second row you to reach related rules, like the inverted, symmetric
or opposite. Inverted means every sub rule result will be inverted.
(Inverted result state, C< = $state_count - $previous_state >)
Symmetric means every subrule switches its result with its symmetric
partner (neighbourhood pattern or sum reversed). Opposite rule means
the pattern of result states will be reversed (mirrored).
The button I<"?"> again selects a random rule.

=head2 Action

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIaction.png"   alt=""  width="630" height="410">
</p>

Here are listed the same sub rule inputs as before (every possible
neighbourhood configuration) on the left hand side of the =&gt;.
The reults of these action rules control which cell are allowed to change
during the next round (only neighbours marked with a circle).
Behind the result of each subrule input is here a result for the action
propagation. The circles show if the cell or its neighbours can do the
transfer function next cycle. These settings are again combined in a
singular action value (behind the label "Active:"). Here are also four
buttons to select the init state, a grid patter or a random state.
The first buttom set the inverted distribution of action propagation.

=head2 Color

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIcolor.png"   alt=""  width="630" height="410">
</p>

This panel help to set custom colors for each automaton state and it is
divided into five sections by horizontal lines. This will be a
description section by section from top to bottom.

The first section is for storing and loading complete sets of state colors.
Just select a set you want to load either in the drop down menu or by
skipping to it with the buttons '<' and '>'. Below this selector you can
see a preview of the selected set. It gets loaded by pushing C<Load>.
Then you can see the colors in large boxes two sections below since there
are the currently used colors. If you want to save the colors, which are
displayed there into the currently selected set push C<Save>. Please
keep in mind this will overwrite whatever was there before. To prefent
this push C<New> to save the currently used colors into a new set.
Its name will be asked for by a dialog. If you type in an already used
name it will ask again, til the name is unique or you press C<Cancel>.
C<Del> just deletes the currently selected color set.

The second section from top contains three buttons that are just functions
calculating new colors based up the colors in the section below. The result
will be also inserted in the row below. The three values beside the buttons
are just arguments to the functions. The gap in this row is by intention,
since both buttons on the left part have this one value as argument and
the third button on the right has the two arguments on the right.
C<Gray> is the is the simplest function, since it produces just a gray
gradient from white as (the leftmost) color 0 to black, stretching over
all currently used states. The only argument (dynamics) has the default
value of 1, which results in a linear gradient. Larger values let it lean
to the right and smaller to the left - meaning that the difference between
the first and second color on the left is the largest, becoming smaller
and smaller toward the left end. C<Gradient> does almost the same, but
uses the leftmost and current (highlighted by arrow) color as input
and computes such a gradient between them. C<Complement> computes
complementary colors to the currently highlighted and does also fill
them into the positions from the left most to the current. The two
arguments are maximal variation in saturation and lightness.

As already mentioned the third sections displays the currently used colors.
The left most color represents state 0, the one right beside is state 1
and so on. Colored squares with an big I<X> below are not currently used.
(Set the amount of currently used states in the I<Global> panel.)
Any click on a color square will select this color as the current one.
It gets highlighted by an arrow below and the next sections always refer
to this current color.

The fourth section allows you to tweak the current color by changing its
red, green or blue component (rows I<R> I<G> and I<B>). The next three
rows are about H(ue) (which color on rainbow), S(saturation) (from grey
to most colorful) and L(ightness) (black to color to white). In each
row you can either insert the value numbers directly by double clicking
the number display and typing it. This value can be incresed or decreased
by clicking the C<+> and C<-> buttons or by moving the slider on the right.

The fifth section works almost like the first. It is a store for single
colors, that loads or stores the currently highlighted color. The only
difference is that there is no C<New> button, since every saved color
will always get a new name.

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

L<App::GUI::Chaosgraph>

L<App::GUI::Dynagraph>

L<App::GUI::Harmonograph>

L<App::GUI::Sierpingraph>

=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022-23 by Herbert Breunung

All rights reserved.
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
