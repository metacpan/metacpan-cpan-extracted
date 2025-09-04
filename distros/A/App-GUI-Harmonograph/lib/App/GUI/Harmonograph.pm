
# app starter and main event lop

package App::GUI::Harmonograph;
use v5.12;
use warnings;
use Wx;
use utf8;
use FindBin;
our $NAME = __PACKAGE__;
our $VERSION = '1.01';

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

App::GUI::Harmonograph - drawing by lateral and rotary pendula

=head1 SYNOPSIS

=over 4

=item 1.

read this POD page

=item 2.

start the program in shell: > C<harmonograph>

=item 3.

move knobs in tabs and observe preview sketch reacting until the drawing is interesting

=item 4.

push I<Draw> (right below drawing board or C<Ctrl+D> or C<Alt+D> or in Image menu)
to produce a full image

=item 5.

choose in menu I<"Image"> > I<"Size"> size of output image in pixel and
right below also output format. Then select there I<"Save"> (or push C<Ctrl+S>)
to store image in a PNG / JPEG / SVG file.

=item 6.

choose I<"Write"> in I<"Settings"> menu (C<Ctrl+W>) to save settings into
an INI file. Load it from there later to restore settings for further tweaking.

=back

After first use of the program, a config file will be created under
I<~/.config/harmonograph> in your home directory. It contains mainly
stored colors and dir entries that tell the app from where to load and
store files. You may change it manually or deleted it to reset defaults.


=head1 DESCRIPTION

An Harmonograph is an apparatus with several connected pendula,
creating together spiraling pictures :


=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/baum.png"      alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/wirbel.jpg"    alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/hose.png"      alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/wirbel_4.png"  alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/wolke.png"     alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/df.png"        alt=""  width="300" height="300">
</p>


This is a cybernetic recreation of an Prof. Blackburns invention with
several enhancements:

=over 4

=item *

fourth pendulum is a rotation of drawing board

=item *

pendulum five and six create an epicycle

=item *

pendula can oscillate at none integer frequencies

=item *

separate complex amplitude and frequency damping in 8 flavours

=item *

draw lines or dots with changeable size, density and probability

=item *

complex color rainbows with up to 10 color, 3 types of color change patterns
and with changeable speed and polynomial dynamics

=back


=head1 Mechanics

The classic Harmonograph is sturdy metal rack which does not move while
3 pendula swing independently. Let us call the first pendulum X,
because it only moves along the x-axis (left to right and back).
In the same fashion the second (Y) only moves up and down.
When both are connected to a pen, we get a combination of both movements.
As long as X and Y swing at the same speed (frequency), the result is a
diagonal line. Because when X goes right Y goes up and vice versa.
But if we start one pendulum at the center and the other
at the upmost position we get a circle.
In other words: we added an offset of 90 degrees to Y (or X).
Our third pendulum W moves (wobbles) the paper in circulating manner around
its center (but not rotating, so a dot in the left corner will always left).
If both circular movements (of X, Y and the one of W) are concurrent -
the pen just stays at one point over the paper and paints only a dot.
If both are countercurrent - we get a circle.
Interesting things start to happen, if we alter the speed of of X, Y and W.
Than famous harmonic pattern appear.
And for even more complex drawings I added R, which is not really
a pendulum and not part of the original Harmonograph,
but an additional rotary movement of the paper around its center.
I added even 2 more pendula (E and F which are also lateral like X and Y),
which draw an epicycle around the point where the dot would be normally drawn.

The pendula out of metal do of course fizzle out over time,
which you can see in the drawing as a spiraling movement toward the center.
We emulate this with two damping factors: one for amplitude/radius and one
for the frequency (speed). The radius or ampitude of Pendulum R is special
and allows you to zoom in or out in case you wish to do so. Normally this
is not necessary, since the program autoadjusts to the settings, so that
the picture is always fully visible and as big as possible.


=head1 GUI

The general layout of the program has three parts:

=over 4

=item 1

In the left upper corner is the drawing board - showing the result of the Harmonograph.

=item 2

The whole right half of the window contains the settings, which guide the drawing operation.
These are divided into six tabs, which will be explained in detail below.

=item 3

In the lower left corner are two rows of buttons. The first row contains
only the progress bar and the I<Draw> button for drawing a full picture.
The progress bar remains white whily previe sketches are shown. But when
a full picture is drawn, then it gets filled with colors that reflect
the color flow used while drawing.

The second row of buttons allow the mass production of graphic files
without using the menu. That is explained in detail under L</Commands>.

=back

Please mind the tool tips - short help texts which appear if the mouse
stands still over a widgets. Also helpful are messages in the
status bar at the bottom - on bottom left regarding current state of the image
and bottom right about state of the settings. Settings are all the
parameters that guide the drawing. You change them via widgets controls
on the right side. They can be saved and loaded from a file via the
settings menu. Configuration are the general settings of this program,
which are mostly saved colors and paths were to store images and settings.

When browsing the main menu, help texts about the highlighted item
also appears in the status bar. The Menu can be completely navigated with
the keyboard. Just hold Alt and use the direction keys (up, down, left
and right) or the highlighted letters. When holding the Alt key you can
also see which Alt + letter combinations trigger which button.


=head2 Pendulum

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/Tab_Pendulum.png"    alt=""  width="85%" height="85%">
</p>

Each of the first three tabs contains the settings of two pendula.
The first tab holds the lateral or linear pendula: X (left right movement)
and Y (up and down). The second tab shows settings of the epicycle pendula
E (left right) and F (up down). They also just move in x or y direction,
but they swing not around the center of the image but around the point,
where the pencil would have been. The third tab allows you to tweak
the pendula W (wobble) and R (rotation). W moves the center of the paper
beneath the pencil in a rotating manner whereas R rotates the paper
around its center. Each of these 6 pendula have the exact same settings
which behave all the same, except radius of R, which works as a zoom.

In the left upper corner of each pendulum settings is a checkbox to
activate or deactivate the pendulum - good to see the pendulums part
in the pen movement. The rest is organized in 8 rows, which can be divided
into 3 parts. Row 1 - 4 are about the pendulum frequency in Hertz.
Row five allows you set the starting point (offset) and the last 3 rows
are about the radius or amplitude of the pendulum mirroring the rows
1, 3 and 4 because the work exactly the same way just not for the
frequency but the radius parameter.

Row one sets the whole number part of the frequency. This is the part you
need to generate to generate the famous images which are based on integer
rations. You can either use the slider the + an - buttons or insert a
number into the text field (which is true off all slider combo widgets).
Behind the slider combo in row one is a drop down menu which lets you
choose a natural constant like Pi or Phi. It gets multiplied with the
frequency. This allows you to explore the nature of these famous constants.
Among the constants are also the natural numbers 1, 2 and 3 in case you
need to crank up the frequency up to 300.

The second row enables you to set values with three decimals. If you for
instance choose a base frequency of 5 and dial in 15 in the second row,
the actual frequency will be 5.015 times the natural constant. Behind the
slider are two checkboxes. One to additionally invert (1/x) the frequency
value and one to flip the pendulum direction (f = -f).

The third row lets you dial in a damping value which makes the pendulum
each round slower (bigger value -> more damping). Behind it is a selector.
If its on minus the damping will be same each round but set on "*" the
damping will be proportional to the frequency. Still behind it is a
checkbox. When selected the frequency is allowed to become negative by
damping.

The fourth row is about daming acceleration or with other words, how much
the damping changes from dot to dot. Beside the c value you have
this time four types of acceleration. Minus and times work as before
and plus and divided by are just their opposite.

The fifth row has a slider that sets the starting position of the
pendulum along its expected track. If the slider is on max you move
the pendulum a quater rotation ahead. To add another quarter check the
box left beside it. The last box adds another half rotation. This allows
you to flip or mirror the image in meaningful ways.

The sixth row mirrors the first but with 2 distinctions. Its not about
integer values but percentage values of the original pendulum length.
This length will be calculated by the program for opimal display.
Thi slider helps you only to change the proportions of the amplitude
towards the other pendula. Natural constants are also here available as
a factor and behind the on the most right is a button to reset the
radius to 100 percent.

The seventh row is the amplitude size, which simple allows to make the
picture larger or smaller depending if the pendulum left the frame or
doesn't move enough. As with reqency, also the amplitude can be damped
over time and this damping can accelerated.

Row eight and nine are exact copies of row three and four, they just
affect the radius / amplitude.


=head2 Functions

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/Tab_Functions.png"    alt=""  width="85%" height="85%">
</p>

This tab lets you meddle with the equations that compute the mechanics
of a pendulum. Because all ten rows are built the same I will explain only
one. For instance the X pendulum has only influence on the x coordinate
of a dot, it is computed: C<x = radius * cos (time)>. The first selector
allows you to swap out the cosine function. Instead you could get sine,
tangent, cotangent, secant, cosekcant and the hyperbolic twin of the
already mentioned functions.

The second selector has five options: "= + - * /". If you choose the
first (equal sign) your time variable will be just swapped out with another
variable. The other four option describe the operation that will be applied
upon you time value. So e.g. if you select plus the resulting formula
will be C<x = radius * cos (time + (...))>. The dots allude to whatever
you will choose with the next three selectors.

Selector three and four are just factors. They contain natural numbers
and natural constants you can multiply the variable with. And last not
least selector five holds the variables time frequency and radus/amplitude
of each pendulum. This allows you for instance add the (always) current
pendulum frequency of pendulum W to the time value of Pendulum X resulting
in unpredictable shapes. There is lot to explore.

Pendulum W affects the x and y coordinate, hence it has two rows for each
case. Even more special is "Pendulum" R - the rotation movement of the paper.
This is computed by an ordinary 2 x 2 rotation matrix (we are in 2D).
Each cell of this matrix has here its own row. Its R_11, R_12, R_21, R_22.
But if you not sure just hover with the mouse and get the hints.

The very last row is different and contains only one switch that will
determine if W or R pendulum is applied first. Default and what is also
more comprehensible is that R is apllied first. But the arstist in you
might can choose here differently.

=head2 Visual Settings

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/Tab_Visuals.png"   alt=""  width="85%" height="85%">
</p>

Due to the section headins, this tab is self explanatory. First choos if
you want to paint dots or connect them. Please not that pen thickness of
one is very thin and you might not see any dots in that setting. The pen
style is more of an gimmick. Most useful are solid and dotted lines.
The dot density allows you to juggle two extremes. Low density makes for
fast drawn lines and dots but also pointy curves. So you might want to
raise the value for smooth curves. The fine tuning of dot density makes
only sense if you draw dots, becasue even a slight change can produce
very different dot pattern. The line length is in seconds in minutes so
you can understand their proportion to the frequencies, which are in
Hertz (rotation / second).

The last section on this tab is about the color change or color flow.
You have 4 types and according to the current type only the widgets which
have an impact are enabled. When flow type I<"no"> in on, you paint only
with color number 1 and the progress bar in the left lower corner will
have one color. It allows you always to track which color rainbow you
actually chose. But its only visible if you make a full picture. So push
the Draw button. When color flow type I<"one_time"> is active, you have to
also select how many colors you like. And if you e.g. choose 3, your
rainbow will go from color 1 to color 2  to color 3. And it will be
spreat of the whole painting time, depending how much you selected.
The dynamic option tells something about how the change from one color
to the next will look like. Positive values bend the rainbow toward the
start of a gradient and negative toward the end. So with a dynamic of 5
the rainbow will linger on the starting color for a long time and will
then change faster and faster. The color flow type "alternate" moves from
color one to two, three and so forth and then backwards back to one and
then again forward as long as your chosen painting time permits.
Regulate the  color change speed with the C<Speed> slider. For extra
slow color changes hit the C<Invert> checkbox. Than high speed values
will make it extra slow. The last color flow type is I<"circular">. Here
you go again from color one to the selected last color and from there
directly to color one. This round will repeated as time permits.

=head2 Colors

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Harmonograph/main/examples/POD/Tab_Colors.png"   alt=""  width="85%" height="85%">
</p>

This tab is just for choosing the available colors. There are alway ten
colors visible, but colors with a "x" below are currently not in use.
This tab page has five sections which will be explained from top to bottom.

The first section is about loading saving sets of colors, so you don't
have to dial in your favorit arrangements every time. Just choose your
set via the drop down menu or browse there with the arrow buttons.
A preview will be shown below th e selector. Then press load and the
selected set will be loaded into the currently used colors in the middle
of the page. If you want to tweak a set you can do so color by color
(as shown below) and then save (overwrite) the color set which is currently
displayed. Or press new to create a new color set that contains the
currently displayed colors. You will be asked to give it a name that is
not already taken. And caution with the C<Del> button. If you press it,
the currently displayed set is gone.

Below that is the second section with buttons that trigger color functions.
This helps you to compute related colors. To better understand their working
check the module L<Graphics::Toolkit::Color>. If you push the C<Gradient>
button that a smooth color gradient will be calculated between the leftmost
color number one and the currently selected color. The value after the
button skews the gradient towart the start (positive values) or the end
(negative values). The C<Complement> button also computes colors between
color one and the current but these will have equally distanced hues but
the same brightness and saturation. The text fields after the button
allow you to skew the brightness and saturation. Behind that, at the
rightmost position are two buttons to move the currently selected color
around.

The third section below that displays the colors than can be used to draw
the picture. They are ten colors, numbered from left to right. Below
each color field there is a second rectangle showing the status of the
color. If this rectangle is empty, the status is normal (used). If it's
crossed out, them the color is inactive because in the visual settings
you choose to use less than ten colors. The third option is selected
color. To select a color, just click on the rectangle displaying that
color or the status rectangle below. Then the status will show an arrow
down.

This means the section below displays the values of this color.
And the values can also be changed there. First your have the I<red> (R),
I<green> (G) and I<blue> (B) values of the RGB color space. below that
are ones of HSB: I<hue>, I<saturation> and I<lightness>. These are more
meaningful to the human mind. At the right end of each row that shows
amd changes one color value is a button with a question mark. Push
that to randomize this one value.

The last and fifth section is analogous to the first one. It is a store
for your favorite single colors. Just load and safe the currently selected
color via the buttons. Be again cautious with the C<Del> button.

=head2 Commands

In the lower left corner are two rows of command buttons. All other
commands are in the menu.

The lower left part of the window contains buttons in two rows.
The upper row is just for drawing the complete image. It has a progress
bar and the draw button. If the progress bar is white, you see just a sketch
drawing - a preview of the full image that can be computed fast enought
to react to all setting changes. If you push the draw button (or <Ctrl>+<S>),
you will get a full image and the progress bar has the color of the drawing
and also can show you the color progression over time, so you can see,
which are the early and the later parts of the drawing.

The second button row is for easy mass production of drawings.
The three text fields are combined the parts of the file path.
The first text field is naturally the directory where the files get saved.
You can change it by pushing the I<Dir> in front (left) of the text button
and use the then opening  Dir-Dialog to select another directory.
The second text field holds the base file name, which has to be inserted
by clicking on in and typing. The third text field is the file number and
is readonly. That counter increments automatically when a file is generated.
The complete file path is <dir>+<base name>+'_'+<counter>+<file ending>.
The file ending is I<.ini> for setting files and I<.jpg> or I<.png> or I<.svg>
for image files. The exact ending depends on what is the current configuration
set in the image > format menu. Lets say your directory is
"/home/user/images/h" and the base file name is beauty. If there is already
a file "/home/user/images/h/beauty_4.png" - the program will detect that
and set the counter to 5. You can play with the settings and than (no matter
if there is currently a complete drawing or not) push the I<Save> button
to produce a complete drawing into "/home/user/images/h/beauty_5.png".
If you push the I<INI> button you safe the current settings into
"/home/user/images/h/beauty_5.ini". This file can later be loaded via
settings menu to restore the current state of all buttons in the tabs.


=head2 Menu

The upmost menu bar has only three very simple menus.
Please not that each menu shows which key combination triggers the same
command and while hovering over an menu item you see a short help text
the left status bar field.

The first menu is for loading and storing setting files with arbitrary
names. I recommend giving them the file ending C<.ini> for transparency
reasons. A submenu allows a quick load of the recently used files.
The first entry lets you reset the whole program to the starting state
and the last is just to exit (safely with saving the configs).

The second menu has only two commands for drawing an complete image
and saving it in an arbitrary named PNG, JPG or SVG file (the file ending decides).
The submenu above only sets the preferred format, which is the format
of the serially save images by the command buttons in the left lower corner.
The preferred file format is also the first wild card in the save dialog.
Above that is another submenu for setting the image size.

The third menu has only one item to oben the I<about> - dialog,
where you can see which perl, Wx and other versions you are currently using.


=head1 SEE ALSO

L<App::GUI::Cellgraph>

L<App::GUI::Juliagraph>

L<App::GUI::Sierpingraph>

L<App::GUI::Spirograph>

=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022-25 by Herbert Breunung

All rights reserved.
This program is free software and can be used, changed and distributed
under the GPL 3 licence.

=cut
