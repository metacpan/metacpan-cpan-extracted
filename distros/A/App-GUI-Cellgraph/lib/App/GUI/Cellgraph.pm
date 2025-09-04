
# gui main loop and main documentation

package App::GUI::Cellgraph;
use v5.12;
use warnings;
use Wx;
use utf8;
our $NAME = __PACKAGE__;
our $VERSION = '0.82';

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

read this POD page

=item 2.

start the program in shell: >C<cellgraph>

=item 3.

push buttons and see preview patterns change

=item 4.

push button I<Draw> in right bottom corner (or C<Ctrl+D>) to get a full picture

=item 5.

choose I<"Save"> in Image menu (or C<Ctrl+S>) to store image in a PNG / JPEG / SVG file
(choose image size beforehand in menu "Image" > "Size" > ...)

=item 6.

choose I<"Write"> in I<"Settings"> menu (C<Ctrl+W>) to save current
settings into an INI file for loading it and tweaking the parameters later

After first use of the program, a config file will be created under
I<~/.config/cellgraph> in your home directory. It contains mainly
stored colors and dirs where to load and store setting files.
You may change it manually or deleted it to reset it to default.

=back

=head1 DESCRIPTION

This graphical application uses cellular automata logic, as described in
I<Steve Wolfram>s book  I<"A new kind of science">, to paint tiled pictures.
Although, the original concept got expanded by many additional options
and functionalities.

It is meant for B<fun>, leasure, B<beautiful>, personalized images
and a deeper B<understanding> about how cellular automatons work.


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/30.png"      alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/blauberg.png"alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/7io.png"     alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/teppich2.png"alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/igt.png"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/cascadestar.png"    alt=""  width="300" height="300">
</p>


=head1 Mechanics

Every tile (square) in the picture represents one automaton (called B<cell>).
The tile color depicts the state of that cell. The B<state> is just an one
digit B<number> (0 or 1 at start). To see and change which B<color> stands
for which state - choose the rightmost tab titled "I<Colors>". The uppermost
row of the picture represents a row of automata in its initial state,
that is given by the user via settings in the second tab ("I<Starting Row>").
The row below is painted by the same string of cells, just after one
round of computation later and so forth. The vertical Y-axis is so to
speak the time axis, with top being the beginning and bottom the end.

During each round of computation every cell might change its state.
It depends on which subrule matches. Each subrule is layed out as a
row at the third tab ("I<State Rules>"). On a left side of the arrow (=>)
you see there a number of colored tiles. At the beginning its three tiles,
representing our focal automaton in the middle and its left neighbour
on its left flank and its right neighbour on the right. In case all three
colors around our example cell are as displayed, then the new state of
this cell can be read on the right side of the arrow. Its also called
the result of this sub-rule. Of course this was simplified, since many
options might complicate that picture, as decribed in next paragraphs.

One big addition are B<action rules>. Parallel to its state, every cell has
also an activity value. It starts with a value also set in the
"I<Starting Row>" tab. It drops every round by a fixed amount but it
also gets raised depending on the result of action rules. Only if the
activity value reaches a threshold, the cell can change its state.
More details about this mechanics are to be found in the chapter
"I<General Settings>" and "I<Action Rules>".


=head1 GUI

The general layout is very simple: the picture gets drawn on the left
window side. On the right side you change the settings from which the
picture is computed. Please note there the tabs, in the top row.
They select which page of settings is visible.

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button. Also helpful are messages in the status bar
at the bottom that appear while browsing the menu of after a command given.

=head2 General Settings

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIglobal7.png"   alt="" width="85%" height="85%">
</p>

The first tab contains settings, that shape the drawing in the most broad way.
It is segmented into three parts that somewhat parallel the last three tabs.

The topmost section sets the framework for rules by which the cell state
changes - computation round by computation round. B<Input Size> appoints
the size of neighbourhood, the left side of an subrule. If you set it to
an odd number like 5, then the cells current state plus its two neighbours
on each side determine the next state of a cell. But if you set it to an
even number like 2 then only one neighbour on each side has this power,
but not the focal cell itself. You can recognize this by the struck through
middle cell in each subrule in the "I<State Rules>" tab. B<Cell States>
sets the number of different cell states / colors. The B<Select> option
defines an subrule mapping - meaning: how many of the possible subrule
results you can define manually? This aimes to solve the none trivial
problem of combinatorial explosion. To guide you in that decision which
mapping to choose - there are also two read only text fields in the second row,
that display how many rules and subrules are possible during current settings.
Let's clarify with an example: If you got 5 I<Cell State>s and an
I<Input Size> of 3, each of these 3 neighbourhood cells can be in one of
5 states. Since 5 to the power 3 is 125 , thats how many subrules get
displayed in tab thee and four. For a lot of people this is no longer
convenient. Other combinations like 8 ** 5 = 32768 would just overload
the programm (caution when set these values!). But given the example of
5 ** 3 = 125. 125 subrules can be managed. But since every subrule can
have any state as result - there are 5 ** 125 = (way too many) subrule
combinations = rules possible. The rule number display in tab 1 and 3
stop working but the rest of app still churns on. To reduce the subrule
count, you could set the subrule mapping from I<all> to I<symmetric>.
Symmetric twins like the subrule input pattern 123 and 321 would have
the then the same result. Only the pattern 123 (left neighbour has state 1,
cell has 2 and right neighbour 3) will be displayed - 75 subrules in total.
If that is still too much, select subrule mapping I<sorted>. Then also
132, 213, 231 and 312 belong to the same group, because if sorted they
all are equal to 123. Now we got only 35 subrules. The most compression
you get with the mapping named I<summing>. Since 1+2+3 = 6, all input
pattern that result in the same sum belong to the same group and there
will be only 13 groups left. And furthermore 5**13 = 1_220_703_125 - all
displays can work as intended. And you stil have 1_220_703_125 pattern to
choose from. Please note if you select any mapping other than I<all> the
picture becomes mirror-symmetric. The option B<Result> is normally set
to I<insert>, meaning the new state defined by the matching subrule
will be inserted = is the new cell state. But for sake of variation you
could also add, subtract or multiply the new state with the previous
state. The outcome of that operation modulo cell state count will become
the new state. Two options contain the suffix _rot which means an
additional one wil be added so you rotate through the states even if
all subrules are not set and blank. Cells on the left and right edge
normally have only a reduced amount of neighbours. During computation
the virtual left neighbour of the left most cell has always the state zero.
But if you activate the option B<Circular>, then the left neighbour of
the leftmost cell is the rightmost cell and vice versa. This can fix
certain types of irregularities in the drawing.


The middle section sets the framework for the action rules, which change
the activity value of a cell. The activity value can never be below zero
or above one. The B<Apply> option activates the aplication of action rules.
And if action rules are in effect then the state of a cell can only change,
if the activity value is equal or above the B<Threshold>. Action rules
react to the same input pattern as state rules. However, the result of
an action subrule is the increase of the activity value by an amount
that is different for any subrule that can have its own result state.
This amount of increase is usually but doesn't have to be positive.
There is also another amount which is usually negative and which decreases
the activity value of all cells each round. This decrease value is labeled
here B<Change> and has to be negative in order to decrease all activity
values. Then there is also a B<Spread> value, which is set to zero per
default. If set to two, the a cell can influence the activity value of
the neext two neigbours on the left and right. How much will also
determined in the action rule tab. Since ever ection rule has also
associated a second value. This second value defines how much a cell
can influence its outer most neighbours (which value gets added to them).
The neighbours in between the out most neighbour and the pivotal cell
get influence by an amount that is linearly interpolated.


The bottom section is about visual settings, which sometimes are not just
cosmetic. The B<Direction> helps you to draw completely different pictures
with way more symmetry. If set to I<top_down> (default) the picture gets
painted as described in the L</Mechanics> paragraph (above). But if you
set it to I<outside_in>, then you will see only a triangular slice of the
previous pattern, painted four times. Every outer edge of the square shaped
map will be the first row, displaying the same pattern and the computation
will grow toward the center. The option I<inside_out> is a kinda opposite.
Here it starts in the center of the grid growing outward in all four
directions. If you deactivate B<Fill>, each tile is no longer filled by
the state color. Instead only two small lines get drawn. B<Grid Style>
offers three options: I<lines>, I<gaps> and I<no>. The first (default)
option draws thin grey lines between the cells. These lines are white if
I<gaps> is chosen. And there will be I<no> gaps between the tiles if
that option is selected . And B<Cell Size> simply defines how many pixel
a tile edge is long.


=head2 Starting Row

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIstart6.png" alt="" width="85%" height="85%">
</p>

This tab contains settings that define the start values - the states
and activity values of all cells in the starting row. The upper part is
about the cell states and the lower part about the activity values.
Since both parts parallel each other, lets explain them in one go.


Central in the upper and lower part are 20 cells that change their state
by left or right clicking on them. You either cycle that way through the
cell states or increase and decrease the activity value by steps of 0.2.

Above the cell row you can read the summary of the selected values.
Trailing zero's will get removed and to fit the value into the summary,
each activity value will be multiplied by 5, so that 5 stands for an
activity value of 1.0 (the maximum) of this cell and a 0 for 0 activity.
The selected values will be placed into the center of the starting row
in the drawing. Unless - you click on the B<Repeat> option. Then the
chosen patter gets repeated until the first row is full. Right beside
the summary display are a few buttons that trigger changes in the starting
row values. The B<1> always (also in other panels) resets the default values.
And B<?> always triggers a random value generator on all cells for happy
accidents. In addition to that there are also the buttons with arrows on it.
They just the summary value up or down, in order to give you the next or
previous start configuration.


=head2 State Rules

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIrules7.png" alt="" width="85%" height="85%">
</p>

This tab contains settings that define the transfer function of cell states.
The upper part is very similar to the previous tab containing a summary
value and several buttons that trigger complex changes. Below that is a
list of all distinct subrules (please check the second paragraph in chapter
about the "general settings" tab). On the right side of each arrow is
one cell. By clicking in with left or right you cycle through its states.
This way you change the result of that subrule. If you see that subrules
are missing, please use the scrollwheel on you mouse or the scrollbar on
the right margin of the window, to unveil the hidden subrules. Right
beside each subrule result is also a text field with a number. It shows
how many times this subrule was applied in the picture. This might give
you hints about the structure of the composition but also where the bottle
necks are and what to change to get a more interesting drawing. For instance:
if behind a subrule is a count of zero - this sub rule was never applied
and changing it will to change the outcome. But changing the result with
a high count might change the picture drastically.

The number in the text field is the number of the currently selected rule,
as Steve Wolfram used them. Right beside the text field are two sets of
arrows. The closer one count the rule number up and down, and changes the
subrule result states accordingly. The next pair of buttons are undo and
redo. They migh be disabled when undo or redo is not possible.

Below the first row is a second row of buttons. These bring forward a
rule that has a relation to the current one. Only exception is the rightmost
button with an B<?> that again triggers a random rule. The pair of buttons
with arrows just do rotate the subrule results to the left (down) or right (up).
The B<%> button flips the result list so the first subrule will get the
result of the last and so forth. By pushing the next button - symmetric
partner (like the input patterns '001' and '100') will exchange their results.
This will only have an effect, when state rule selection (second row in the
general settings) is set to "I<all>". And lastly the B<!> button inverts
every subrule result. If a cell can have 5 states (0..4) and the current
subrule result is 1, it will then switch to 3, since 4 - 1 = 3. 4 woud
switch to zero and a state of 2 would not change because 4 - 2 = 2.


=head2 Action Rules

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIaction7.png" alt="" width="85%" height="85%">
</p>

This tab parallels the previous even more, by also listing all subrules.
But here you can dial in the consequent activity value gain (right beside
the => arrow) and activity value gain spread of each subrule (rightmost
in each subrul row). The logic behind the activity values and their
changes is explained in detail in the third paragraph in the chapter
about the "I<General Settings>" tab.

Since both type of values are different they have their own summary
display and series of buttons. Again, 1 stands for the default values,
? for random values and <= and => for undo and redo. The B<=> button
sets all values to the one present in the first subrule. B<+> and B<->
lets you increase and decrease all values at once. B</> lets all
values move toward zero and B<*> away from zero. B<%> increases the values
in odd numbered subrules and decreases them in even numbered. And
on the left of ? is the B<~> button that changes all values with a small,
random amount.

=head2 Colors

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Cellgraph/main/example/POD/GUIcolor7.png" alt="" width="85%" height="85%">
</p>

This panel helps you to customize the automaton/cell state colors, with
which the picture is drawn. It helps you also to remember you favorite
colors and color sets. The panel is divided into five sections by
horizontal lines. The following paragraphs will describe them from top
to bottom.

The first section is for storing and loading complete sets of state colors.
Just select a set you want to load either in the drop down menu or by
skipping to it with the buttons '<' and '>'. Below this selector you can
see a preview of the selected set. It gets loaded by pushing C<Load>.
Then you can see the colors in large boxes two sections below since there
are the currently used colors. If you want to save the colors, which are
displayed there into the currently selected set push C<Save>. Please
keep in mind this will overwrite whatever was there before. To prevent
this push C<New> to save the currently used colors into a new set.
The name of the new set will be requested via dialog. If you type in an
already used name it will ask again til the name is unique or you press
C<Cancel>. C<Del> just deletes the currently selected color set.

The second section from top contains three buttons that are just functions
calculating new colors based up the colors in the section below. The result
will be also inserted in the row below. The three values beside the buttons
are just arguments to the functions. The gap in this row is by intention,
since both buttons on the left part have this one value on the left as
argument and the third button on the right has the two arguments on the right.
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

L<App::GUI::Harmonograph>

L<App::GUI::Juliagraph>

L<App::GUI::Sierpingraph>

L<App::GUI::Spirograph>

=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2022-25 by Herbert Breunung

All rights reserved.
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
