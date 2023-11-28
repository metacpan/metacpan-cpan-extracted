use v5.12;
use warnings;
use Wx;
use utf8;

package App::GUI::Juliagraph;
our $NAME = __PACKAGE__;
our $VERSION = '0.5';

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

App::GUI::Juliagraph - drawing Mandelbrot and Julia fractals

=head1 SYNOPSIS

=over 4

=item 1.

read this POD

=item 2.

start the program (juliagraph)

=item 3.

move knobs and observe how preview sketch reacts til you got
an interesting image

=item 4.

push "Draw" (below drawing board or Ctrl+D or I<Draw> in I<Image> menu)
to produce full resolution image

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

Mandelbrot (first thee) and Julia fractals (second three following) are
just mathematical diagrams, showing you how iterating the equation
C<z_n+1 = z_n ** 2 + C> behaves in the complex plane.
The values at the pixel coordinates or some chosen constant is taken as
input (z_0) and the count of iterations it took to exceed the stop/breakout
value decide which color this point will painted in. In Mandelbrot
fraktals the coordinates will be put into the variable C and in Julia
fraktals into the variable z_0 (initial values of the iterator variable).

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
The settings are devided into several thematic tabs.

Please mind the tool tips - short help texts which appear if the mouse
stands still over a button. Also helpful are messages in the status bar
at the bottom that appear while browsing the menu.


=head2 Constraints

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Constraints.png"    alt=""  width="630" height="410">
</p>

The controls of the first tab are the settings that define most of the math,
but not the higher polynomials. The page is divided from top to bottom in
4 sections for fractal type, scrolling and zooming, iteration constant,
and stop condition.

The first section allows you to set the fractal type: I<Mandelbrot>,
I<Julia>, of something in between (option I<Any>). If you choose I<Mandelbrot>
the complex value of the current dot in the coordinate system becomes C
in the above mentioned formula and the complex constant of section 3
is the starting value Z_0. With I<Julia> both these values switch their
usage and with I<Any> you are free to choose their usage. You could discard
them of even use them as factor of the higher monomials.

The second section allows you to zoom in and out and to select the
central coordinates of the visible cutout. For this it has a three partial_hash_deformat
widget, which need a little more explanation. The leftmost part is a text
field, in which you could change the numbers directly by pasting or typing.
The ladder is not recommended, since every change will trigger a redraw
of the fractal preview. Instead of it use the slider on the right and dial
in the amount you want to see the value on the left changed. If you hover
the mouse over the slider, it will show you the amount.
Then push the buttons in the middle to add or subtract the dialed in value.
In the same way you can choose X and Y position to move the visible window.

The third section works the same, but helps you to set the a complex value,
that will be used in the manner you have set in section 1. Just note
I<A> is the real part of the constant and I<B> is the imaginary part.

The fourth section contains two choices. First the stop value. If the
iteration variable I<Z> has a greater value than it, the iteration stops.
Because we compare an complex iteration variable with a real number,
we compute the absolute value of the iteration variable (displayed by C<|var|>).
But other metrics are possible. Just keep in mind x is the real part of the
iteration variable I<Z> and y is the imaginary part.

=head2 Polynomial

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Polynomial.png"    alt=""  width="630" height="410">
</p>

The second tab contains 4 identical sections which also work the same.
Each of them stand for a monomial of the iteration equation, but only
if the checkbox I<On> is marked. A second checkbox allows you discard the
complex factor below which will be set in the same way as the constant on
the first tab/page. (Read there how to use the slider button widget.)
The maybe most important control of an monomial is the exponent, which
you select on the right side of the first row. A I<Mandelbrot>
or I<Julia> fractal is usually computed just with C<Z_n+1 = Z_n ** 2 + C>,
but higher exponents are gateways into other worlds with more symmetry.
You could select via this page a term like C<Z_n+1 = F_1 * Z_n ** 5 + F_2 * Z_n ** 2 + C>
An exponent of one will just add a linear component which usually smears
the fractal in sometimes interesting ways. An exponent of zero will
make the factor of this monomial into a constant, same as one on the first
tab. If you you have several monomials with the same exponent, the factors
will be multiplied.


=head2 Color Mapping

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Mapping.png"    alt=""  width="630" height="410">
</p>

On the second tab we have three rows of settings which determine how the
selected colors will be applied.

The first checkbox selects if we use the colors at all or just the
default grey gradient. The combobox in the first row let you pick how many
of the selected colors will be used. If you choose for instance 6, the
first six (1..6) are used to display the fraktal, plus of course black
as the background color for the area where the iteration variable never
reaches the stop value. Never in this context mean the maximum available
amunt of iterations as computed by the product of the numbers shown on
this page except I<Dynamics>.

The second row defines how we proceed from one color to the next.
If for instance I<Gradient> set to 5, there will be 5 additional colors
between each of the selected colors, to make the transition smoother.
If I<Dynamics> is set to 0, this transition will be linear. Otherwise
it will tilt into one or the other side.

The third row has two more settings which will influence the shape
of these gradients. By setting the I<Grouping> value higher than 1
you stretch the gradient by a factor. If for instance I<Grouping> is set
to three, three neighbouring areas which normally would have three different
colors will have the same color and just the next, forth area will contain
the next color. The I<Repeat> value also multiplies the number of used
colors. As soon the painter runs out of colors it will take the first again
and repeat this process the ordered amount of times.

=head2 Colors

=for HTML <p>
<img src="https://raw.githubusercontent.com/lichtkind/App-GUI-Juliagraph/master/img/POD/Color.png"    alt=""  width="630" height="410">
</p>

This page helps you to select the color that will be used to paint the fractal.
Only the background color is currently fixed to black. You can see these
colors in the middle section named "Currently Used State Colors".
If you click on one - it will be selected which you can see from_rgbthe
arrow below the selected color.

In the section below named "Selected State Color" you see the values
in RGB space and HSL space of the selected color. Yan change any of them
directly by slider, typing them in or pressing the plus and minus buttons.

The "Color Store" in the last row allows you store the selected color for
later reuse (just press save and type in its name). With the combo box or
the arrow buttons you can also select there a color and press load to
chhose it as the new currently selected color. Press there Del(ete) to
delete the visible color from the store.

Analogues to that there is a color set store in the first row of this
page which enables you to store and load all currently used colors at once.
Please use there the I<New> button to create a new color set to avoid
overwriting the currently seleced color set, when pressing I<Save>.

The second row contains some color set functions to create gradients between
the leftmost and selected color or to compute colors that are complementary
to the selected.


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

The third menu has only a dialog with some additional information of version numbers and our homepage.

=head1 SEE ALSO

L<App::GUI::Cellgraph>

L<App::GUI::Harmonograph>

L<App::GUI::Sierpingraph>


=head1 AUTHOR

Herbert Breunung (lichtkind@cpan.org)

=head1 COPYRIGHT

Copyright(c) 2023 by Herbert Breunung

All rights reserved.
This program is free software and can be used and distributed
under the GPL 3 licence.

=cut
