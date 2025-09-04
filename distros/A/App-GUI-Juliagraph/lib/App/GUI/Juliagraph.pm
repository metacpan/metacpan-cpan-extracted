
# main program (main loop), documentation

package App::GUI::Juliagraph;
use v5.12;
use warnings;
use Wx;
use utf8;
our $NAME = __PACKAGE__;
our $VERSION = '0.72';

use base qw/Wx::App/;
use App::GUI::Juliagraph::Frame;

sub OnInit {
    my $app   = shift;
    my $frame = App::GUI::Juliagraph::Frame->new( undef, 'Juliagraph '.$VERSION);
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

App::GUI::Juliagraph - drawing Mandelbrot-, Julia fractals and more

=head1 SYNOPSIS

=over 4

=item 1.

read this POD

=item 2.

start the program in the shell: > C<juliagraph>

=item 3.

move knobs and observe how preview sketch reacts til you got
an interesting image

=item 4.

push "Draw" (below drawing board) or Ctrl+D or I<Draw> in I<Image> menu,
or middle click of the drawing board, to produce full resolution image

=item 5.

choose "Save" in Image menu (or Ctrl+S) to store image in a PNG / JPEG / SVG file

=item 6.

choose "Write" in settings menu (Ctrl+W) to save settings into an
INI file for tweaking them later

=back

After first use of the program, a config file I<~/.config/juliagraph> will be
created in you home directory. It contains mainly
stored colors, color sets and dirs where to load and store setting files.
You may also change it by editor or delet it to reset configs to default.


=head1 DESCRIPTION

Mandelbrot (first two pictures) and Julia fractals (four after that) are
just mathematical diagrams, showing you how iterating the equation
C<z_n+1 = z_n ** 2 + C> behaves on the complex plane.
Our running variable gets an initial value and gets squared each time,
plus an constant is added, also each time. Mandelbrot mean this constant
are the pixel coordinates, Julia means the coordinates are the starting
value. And the pixel color just contains the information how many
iterations (times) it took until z got greater than our bailout value.

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/examples/first.png"         alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/examples/first_detail.png"  alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/examples/feingoldkreutz.png"alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/examples/julia.png"         alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/examples/set.png"           alt=""  width="300" height="300">
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/examples/sonne.png"         alt=""  width="300" height="300">
</p>


This program has additional capabilities/options:

=over 4

=item *

iteration formula with up to four monomials

=item *

choosable exponent and factor for each of them

=item *

choosable stop value and stop metric

=item *

free selection of colors

=item *

many option to map th colors onto iteration result values

=back



=head1 GUI


The general layout is very simple: the settings (which define the fractal)
are on the right and the drawing board is left.
The settings are devided into several thematic tabs. Every change of the
settings triggers a redraw of the fractal, but only in a blurry preview
mode, so it can be fast enough. To get a high resolution rendering,
press C<Ctrl>+C<D> or push the draw button down left center or click
at the drawing board with a middle mouse click. (The image menu has also
a draw item.) With a full rendering the progress bar beside the draw button
becomes colorful. It is white in preview mode.

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button. Also helpful are messages in the status bar
at the bottom that appear while browsing the menu. Please take also special
note at the I<mouse> section since you can browse the fractals by mouse.


=head2 Constraints

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Tab_Constraints.png"    alt=""  width="630" height="410">
</p>

The controls on the first tab panel are the settings that define most of
the rules by which the equation is computed. The page is divided from top
to bottom into 5 sections that will be discussed in that order.

The first section allows you to set the fractal type: I<Mandelbrot>,
I<Julia>, of something in between (option I<Any>). If you choose I<Mandelbrot>,
the sections 3 and 4 get blurred and set to zero, since the play no role
in computing this type of fractal. If chosen I<Julia> only section 4 is
blurred and reset. On the right side of this sections you can observe,
how the checkboxes dance, when switching the fractal type. There you can
see that Mandelbrot means the pixel coordinates are the constant added
at each iteration. And I<Julia> means that coordinates turn to starting
values, but you can choose the constant to get different shapes. But
these checkboxes can only reached, when type I<Any> is chosen. Only then
you can select or deselect both options or even choose a third one,
that pixel coordinates can become a monomial factor.

The second section contains the information that select the visible
part the image. These are zoom factor (its higher when you zoom in)
and the coordinates that are at the center of the visible section.
Chenge them to scroll left, right, up or down. Each of these values
are controlled by a slider step widget. It allows you to change the value
in two different ways. Either you type in the numbers directly (click first
at the widget). Or you change the value by clicking the plus and minus
buttons. The slider beside them determines the size of the value change,
done by the buttons. The buttons on the most right just reset the values
in case you got lost.

The third section is about the mentioned constant number, added to C<z>
at each iteration. A is the real part corresponding to the X-axis and
B the imaginary part corresponding to Y. In same manner, section four
is holding the starting value. To both of these values the coordinates
can be added. Just click the checkbox in the upper right corner. If
chosen the constant or starting value is then the sum of pixel coordinates
with the displayed value.

The fifth section holds all values that determine the end of the computation
on one spot. There are two conditions that can trigger that. Either you run
out of iterations (exceeded the maximal interation I<count>). Please note,
that the actual number is the displayed number squared. This gives you a
wider range eof options and a little more comfort while changing the value.
When the computation runs out of iterations, the current pixel will get
the background  color. The second stop criterion is fulfilled when
the value exceeds the bailout limit (I<Value>), which is also the displayed
number squared. In the right corner you got ten different ways how to compute
the amount of z. Mathematicians call them merics. They mostly influence
the shape around the main shape (the crwon - corona).

=head2 Monomials

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Tab_Polynomials.png"    alt=""  width="630" height="410">
</p>

The second tab contains 4 identical sections which also work the same way.
Each of them stand in for a monomial of the iteration equation, but only
if the checkbox I<On> is marked. A second checkbox decides if this monomial
gets added or subtracted. The third allows you discard the complex factor
below the checkboxes. The fourth checkbox allows you to use the current
pixel coordinates as second factor in the monomial. Please be aware this
option can only be chosen if fractal type C<Any> is active and the I<Monomial>
checkbox in the upper right corner is on. Both of these settings are on
the previous C<Constrains> page. This might seem cumbersome, but I wanted
to make it very clear that this is no longer a C<Julia> fractal as most
people would understand it. The last and fifth checkbox lets you calculate
a complex logarithm of the power term z^n. This is useful when combined
with a very larg factor or another monomial. This just mentioned power
C<n> ca be chosen right beside the checkboxes. The higher this power is,
the longer it takes to calculate the picture, but it adds also a nice
rotational symmetry. C<Mandelbrot> has a (n-1)-times rot symmetry and
C<Julia> a n-times rotational symmetry.

=head2 Color Mapping

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Tab_Mapping.png"    alt=""  width="630" height="410">
</p>

This page is about mapping the iteration number at bailout to a color.
To be able to do that better you can preview here the color rainbow
between the first and second section. Below the color rainbow is another
this monochrome strip. It displayes the currently active background color.
The rainbow is from left (low iteration number) to right (high).

The first section starts with a checkbox. When deselected, the fractal
gets a gray scale. When selected all color choices are in effect. The
rainbow goes from begin color number to end color number over every color
in between. So if you for instance selected 2 and 4, the rainbow has a
gradient from color 2 to color 3 and a second from 3 to 4. The exact colors
will be changes on the next page. The gradients might vary dependant on
chosen C<dynamic> and color C<space> in which they are computed.

The second section is for people who want only a few color regions.
Just activate the custom checkbox and select the C<Steps> count. If they
are at 20 only 20 differently colored reagions are drawn. The readonly
textbox below with the current iteration max is only for better orientation.
When it is at lets say 60 you know: this scale of one to 60 possible
iteratons will be divided into 20 parts. If the distribution is I<linear>
they all have the size of three.  But you might want to skew the color
distribution. The mapping types are sorted by their skewness.

If the second section is deactivated you are able to activate the third.
It is for folks that think that the color gradient is not dense enough.
That might makes sense if the iteration already stops at maximum of 5
but you want to get a long smooth gradient. Then you want to I<Activate>
subgradients, based on the Value at iteration stop. The greater that is
the further on the subgradient the resulting color will be. The five
options here parallel what we already described. Subgradients will have
the amount of steps as dialed in under C<Steps>. The gradient will be
computed from 1 (above bailout value) up to the C<Size> value. Everything
above just lands in the last bucket. The subgradient can again be skewed
by a C<Distribution> and C<Dynamic> value (as described above). Also
the resulting color change dependant in which color C<Space> it is
computed in. I<RBG> gives usually more smooth results and I<HSL> more
contrast.


=head2 Colors

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Tab_Color.png"    alt=""  width="630" height="410">
</p>

This page helps you to select the color that will be used to paint the fractal.
You can see them in the middle row.
The background color is often the one at the most left.  That is why it
is marked by a vertical bar. The colors are numbered from left to right
with 1 to 11.

The first section on the pages is for loading and saving custom sets of
colors. Please use the delete button carefully. C<New> saves the current
colors under a new name, C<Save> under the current name. There are no
undo buttons yet.

The section below helps you to compute related colors beweet the second
and the currently selected. This can be either a gradient (with C<Gradient>
button). Right beside is a text box to skew the gradient in one or anotehr
direction. To get complementary colors push the C<Complement> button.
This also can be skewed on the saturation and lightness axis (text boxes
beside). The arrow butons there help you to move colors to another position.

To change a color you have to fist select it by clicking on it or the
marker below. After that the marker turns into an arrow pointing down.
Because below are the 6 slider to change the either RGB or HSL values
of the color. Each slider has a randomize button with a quastion mark.

The second method to change the selected color is to load one from the
store (last section below). Just select the color by drop down menu or
arrows. If you like the seen color push C<Load>. This single color store
has also Buttons to store your own favorite colors or delete the ones
you dont like. The only way to bring back deleted default colors is to
delete the config file:  ~/.config/juliagraph.


=head2 Mouse

The drawing board responds to three types of clicks. A left click moves
the visible section. Double click means zoom in and right click is zoom out.

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

The third menu has only one item that opens a help dialog. That displays
some core information about author, version number and a link to this page,
the main documentation.

=head1 SEE ALSO

L<App::GUI::Cellgraph>

L<App::GUI::Harmonograph>

L<App::GUI::Sierpingraph>

L<App::GUI::Spirograph>


=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2023-25 by Herbert Breunung

All rights reserved.
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
