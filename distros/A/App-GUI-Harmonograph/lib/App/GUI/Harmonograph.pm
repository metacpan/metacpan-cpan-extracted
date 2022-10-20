use v5.12;
use warnings;
use Wx;
use utf8;
use FindBin;

package App::GUI::Harmonograph;
our $NAME = __PACKAGE__;
our $VERSION = '0.56';

use base qw/Wx::App/;
use App::GUI::Harmonograph::Frame;

sub OnInit {
    my $app   = shift;
    my $frame = App::GUI::Harmonograph::Frame->new( undef, 'Harmonograph '.$VERSION);
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

App::GUI::Harmonograph - sculpting beautiful circular drawings

=head1 SYNOPSIS 

=over 4

=item 1.

start the program (harmonograph)

=item 2.

read this POD or check dialogs from help menu

=item 3.

move knobs and observe how preview sketch reacts til you got 
an interesting configuration 

=item 4.

push "Draw" (below drawing board or Ctrl+D) to produce full image

=item 5.

choose "Save" in Image menu (or Ctrl+S) to store image in a PNG / JPEG / SVG file

=item 6.

choose "Write" in settings menu (Ctrl+W) to save settings into an
INI file for tweaking them later

=back

Please note that quick preview gets only triggered by the pendulum
controls (section X, Y Z and R).

After first use of the program, a config file .harmonograph will be
created in you home directory. You may move it into "Documents" or your
local directory you start the app from.


=head1 DESCRIPTION

An Harmonograph is an apparatus with several connected pendula,
creating together spiraling pictures :


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wirbel.jpg"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/baum.png"      alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/hose.png"      alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wirbel_4.png"  alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/wolke.png"     alt=""  width="300" height="300">
</p>


This is a cybernetic recreation of an Prof. Blackburns invention with 
several enhancements:

=over 4

=item *

third pendulum can rotate

=item *

pendula can oscillate at none integer frequencies

=item *

changeable amplitude and damping

=item *

changeable dot density and dot size

=item *

3 types of color changes with changeable speed and polynomial dynamics

=back


=head1 Mechanics

The classic Harmonograph is sturdy metal rack which does not move 
while 3 pendula swing independently.
Let us call the first pendulum X, because it only moves along the x-axis
(left to right and back).
In the same fashion the second (Y) only moves up and down.
When both are connected to a pen, we get a combination of both movements.
As long as X and Y swing at the same speed, the result is a diagonal line.
Because when X goes right Y goes up and vice versa.
But if we start one pendulum at the center and the other 
at the upmost position we get a circle.
In other words: we added an offset of 90 degrees to Y (or X).
Our third pendulum Z moves the paper and does exactly 
the already described circular movement without rotating around its center.
If both circular movements (of X, Y and Z) are concurrent - 
the pen just stays at one point, If both are countercurrent - 
we get a circle. Interesting things start to happen, if we alter
the speed of of X, Y and Z. Than famous harmonic pattern appear.
And for even more complex drawings I added R, which is not really
a pendulum, but an additional rotary movement of Z around its center.
The pendula out of metal do of course fizzle out with time, 
which you can see in the drawing, in a spiraling movement toward the center.
We emulate this with a damping factor.


=head1 GUI

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/GUI.png"    alt=""  width="630" height="410">
</p>

The general layout of the program has three parts,
which flow from the position of the drawing board.

=over 4

=item 1

In the left upper corner is the drawing board - showing the result of the Harmonograph.

=item 2

The whole right half of the window contains the settings, which guide the drawing operation.
These are divided into two tabs - roughly devided in form and decoration.

=item 3

The lower left side contains buttons which are a few commands,
mostly for mass productions of image files, but most commands are in 
the main menu.

=back

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button or slider. Also helpful are messages in the
status bar at the bottom: on left regarding images and right about settings.
When brwosing the main menu, a help texts about the highlighted item
also appears in the status bar. The Menu can completely navigated with
the keyboard. Just hold Alt and use the direction keys (up, down, left
and right) or the highlighted letters. When holding the Alt key you can
also see which Alt + letter combinations trigger which button.

=head2 Pendulum

The first tab contains the settings that define the properties
of the pendula (X and Y), which move along the x and y axis in a lateral
manner. On the second Tab are identical controls for the Pendula Z and R
which together with X and Y determine the shape of the drawing.
Z does a circling movement, R is a rotation (around Z's axis or origin).

All controls from top to bottom and left to right are:
an on/off switch which activates the whole pendulum with all settings.
After that follows the pendulum's amplitude (here called radius).
This determines the size in the direction the pendulum moves.
Below that follows amplitude damping, which reduces the amplitude over time,
so that the drawing will spiral toward the center. Since this is all
computed, time refers to the line length. Damping can take place in a steady
(minus '-') or in a slowing, procentual manner ('*').
The third row is labeled acceleration, which refers to an additional
dynamic of the amplitude damping.

The forth row lets you dial in the speed (frequency). This is the most
fundamental to the shape. For instance 2 means that the pendulum swings
back and fourth twice as fast. To the right you can choose an additional
factor the frequency gets multiplied with. This can be a constant like
Pi or Phi or the frequency of another pendulum or just simply one.
This is especially handy when browsing the classic shapes 
with three pendula. For these the frequency of X and Y has to be the same -
which will be ensured when you set the frequency factor of Y to X 
(or vice versa) and keep the frequency of Y to one.
The next combo control below adds decimals  to the frequency value 
for more complex rotating drawings. Behind that are two check boxes to
invert the final frequency value to 1/x or to flip the direction of
the pendulum. Below that follows a frequency damping, which works
the same as the second row only with slightly different optical results.

The last row starts with a slider to fine tune the starting point of the
pendulum. It can be chosen between zero and a quater rotation. This can 
have great effects on the shape. Because of the special desirability
offsets of an half (180 degree) or quarter (90 degree) rotation can be
activated by checkbox (to the right of the slider). The final offset is
the sum of the checked.

=head2 Line

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/GUI2.png"   alt=""  width="630" height="410">
</p>

The third tab on the right side has knobs that set the properties of the pen.
In left upper corder ist the slide to set the amount of rotations to be
drawn. Right beside is the distance between dots. 
Greater distances, together with color changes, help to clearify
muddled up drawings. Also - many rotations and little distance between
dots will slow down the computation. In the second row left is a checkbox
to answer if the dots should be connected. 
The fourth selector sets the dot size in pixel. Zero mens here very thin
= one half of an pixel - which is still somewhat visible, but very airy.

=head2 Colors

Below that on the second tab are the options for colorization and this
has in itself three parts.
Topmost are the settings for the color change, which is set on default to "no".
In that case only the start (upper) color (below the color change section)
will be used, and not the end (target) color (which is even below that).

Both colors can be changed via controls for the red, green and blue value
(see labels "R", "G" and "B" ) or hue, saturation and lightness (HSL).
The result can be seen in the color monitor at the center of a color browser.

An one time or alternating gradient between both colors with different
dynamics (first in second row) can be employed. Circular gradients travel
around the rainbow through a complement color with saturation and lightness
of the target settings.
Steps size refers always to how maby circles are draw before the color changes.

The third part on the second tab grants you access to the color store of
config file .harmonograph. There you can store your favorite colors under
a name and reload or delet them later. The upper row is for interactions
with the sart color and the lower with the end color.

=head2 Commands

In the lower left corner are two rows of command buttons. All other 
commands are in the menu.

The upper row has only one button for making a full drawing. This
might take some time if line length and dot density are high.
For that reason - changes on the pendulum settings (first tab)
(and only these) produce an immediate drawing to better understand the
nature of your changes. In the interest of time, these are only sketches.
For a full drawing that takes all settings into account you need to push
the "Draw" button or Press Ctrl + D.

The second row has commands to quickly save many files.
First push "Dir" to select the directory and then type directly into the
secand text fiel the file base name - the index is found automatically.
Every time you now press "Save" a file with the current image is saved
under the path: dir + base name + index + ending (set in config). 
The index automatically autoincrements when changing the settings.
Push "INI" next to it to also save the settings of the current state
under same file name, but with the ending .ini.


=head2 Menu

The upmost menu bar has only three very simple menus.
Please not that each menu shows which key combination triggers the same
command and while hovering over an menu item you see a short help text
the left status bar field.

The first menu is for loading and storing setting files with arbitrary 
names. Also a sub menu allows a quick load of the recently used files.
The first entry lets you reset the whole program to the starting state
and the last is just to exit (safely with saving the configs).

The second menu has only two commands for drawing an complete image
and saving it in an arbitrary named PNG, JPG or SVG file (the file ending decides).
The submenu above onle set the preferred format, which is the format
of serial images and the first wild card in dialog. Above that is another
submenu for setting the image size.

The third menu has some dialogs with documentation and additional information.


=head1 SEE ALSO

L<App::GUI::Cellgraph>

L<App::GUI::Dynagraph>

=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 by Herbert Breunung

All rights reserved. 
This program is free software and can be used, changed and distributed
under the GPL 3 licence.

=cut
