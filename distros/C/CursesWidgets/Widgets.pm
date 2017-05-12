# Curses::Widgets.pm -- Base widget class for use with the
#   Curses::Application framework
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Widgets.pm,v 1.997 2002/11/14 01:30:19 corliss Exp corliss $
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#####################################################################

=head1 NAME

Curses::Widgets - Base widget class for use with the Curses::Application 
framework

=head1 MODULE VERSION

$Id: Widgets.pm,v 1.997 2002/11/14 01:30:19 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets;

  $rv = test_colour();
  test_color();

  $colpr = select_colour($fore, $back);
  $colpr = select_color($fore, $back);

  $key = scankey($mwh);

  @lines = textwrap($text, 40);

  # The following are provided for use with descendent
  # classes, and while they are not expected to be 
  # overridden, they can be.
  $obj = Curses::Widgets->new({KEY => 'value'});
  $obj->_copy($href1, $href2);
  $obj->reset;
  $obj->input($string);
  $value = $obj->getField('VALUE');
  $obj->setField(
    'FIELD1'  => 1,
    'FIELD2'  => 'value'
    );
  $obj->execute($mwh);
  $obj->draw($mwh, 1);
  @geom = $obj->_geometry;
  @geom = $obj->_cgeometry;
  $dwh = $obj->_canvas($mwh, @geom);
  $obj->_save($mwh);
  $obj->_restore($mwh);
  $obj->_border($mwh);
  $obj->_caption

  # The following are provided for use with descendent
  # classes, and are expected to be overridden.
  $obj->_conf(%conf);
  $obj->input_key($ch);
  $obj->_content($mwh);
  $obj->_cursor

=head1 REQUIREMENTS

=over

=item Curses

=back

=head1 DESCRIPTION

This module serves two purposes:  to provide a framework for creating
custom widget classes, and importing a few useful functions for 
global use.

Widget specific methods are documented in each Widget's pod, of which the
following widgets are currently available:

=over

=item Button Set (Curses::Widgets::ButtonSet)

=item Calendar (Curses::Widgets::Calendar)

=item Combo-Box (Curses::Widgets::ComboBox)

=item Label (Curses::Widgets::Label)

=item List Box (Curses::Widgets::ListBox)

=item Multicolumn List Box (Curses::Widgets::ListBox::MultiColumn)

=item Menu (Curses::Widgets::Menu)

=item Progress Bar (Curses::Widgets::ProgressBar)

=item Text Field (Curses::Widgets::TextField)

=item Text Memo (Curses::Widgets::TextMemo)

=back

The following tutorials are available:

=over

=item Widget Usage -- General Usage & Tips (Curses::Widgets::Tutorial)

=item Widget Creation (Curses::Widgets::Tutorial::Creation)

=item Widget Creation -- ComboBox Example (Curses::Widgets::Tutorial::ComboBox)

=back

For even higher (and simpler) level control over collections of widgets on
"forms", please see B<Curses::Forms>, which uses this module as well.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Carp;
use Curses;
use Exporter;

($VERSION) = (q$Revision: 1.997 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Exporter);
@EXPORT = qw(select_colour select_color scankey textwrap);

my $colour = -1;
my %colours = ( 
  black   => COLOR_BLACK,   cyan    => COLOR_CYAN,
  green   => COLOR_GREEN,   magenta => COLOR_MAGENTA,
  red     => COLOR_RED,     white   => COLOR_WHITE,
  yellow  => COLOR_YELLOW,  blue    => COLOR_BLUE
  );
my %colour_pairs = ();
my ($DEFAULTFG, $DEFAULTBG);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 EXPORTED FUNCTIONS

=head2 test_colour/test_color

  $rv = test_colour();
  test_color();

This function tests the console for colour capability, and if found, it will
set B<$Curses::Widgets::DEFAULTFG> and B<$Curses::Widgets::DEFAULTBG> to the
default foreground and background colour, respectively.

It also calls the Curses B<start_color> for you.  Unless you need to know the
default foreground/background colours ahead of time, you won't need to call
this, B<select_colour> will do it for you the first time it's called, if
necessary.

This function returns a true or false, designating colour support.

=cut

sub test_colour {
  my ($df, $db);

  if (has_colors) {
    start_color;
    pair_content(0, $df, $db);
    foreach (keys %colours) { $df = $_ and last if $df == $colours{$_} };
    foreach (keys %colours) { $db = $_ and last if $db == $colours{$_} };
    $colour_pairs{"$df:$db"} = 0;
    $colour = 1;
    ($DEFAULTFG, $DEFAULTBG) = ($df, $db);
  } else {
    $colour = 0;
  }

  return $colour;
}

sub test_color {
  return test_colour();
}

=head2 select_colour/select_color

  $colpr = select_colour($fore, $back);
  $colpr = select_color($fore, $back);

This function returns the number of the specified colour pair.  In
doing so, it saves quite a few steps.  

After the initial colour test, this function will safely (and quietly)
return on all subsequent calls if no colour support is found.  It returns
'0', which is hardwired to your terminal default.  If colour support is 
present, it allocates the colour pair using (n)curses B<init_pair> for you, 
if it hasn't been done already.

Most terminals have a limited number of colour pairs that can be defined.
Because of this 0 (the terminal default colour pair) will be returned in lieu
of attempting to allocate more colour pairs than the terminal supports.  If
you need a specific set of colours to be available, you might want allocate
each pair ahead of time using this function to prevent less important pairs
from running you out of pairs.

As a final note, yes, both the British and American spellings of 
'colo(u)r' are supported.

Known colours:

  black           cyan
  green           magenta
  red             white
  yellow          blue

The colours are not case sensitive.

=cut

sub select_colour {
  my ($fore, $back) = @_;
  my (@pairs, $pr);

  # Check for colour support if $colours is -1
  if ($colour == -1) {
    test_colour();

  # Take an early exit unless the terminal supports colour
  } elsif ($colour == 0) {
    return 0;
  }

  # Set the background colour if it was omitted
  $back = $DEFAULTBG unless defined $back;

  # Lowercase both arguments
  ($fore, $back) = (lc($fore), lc($back));

  # Check to see if the colour pair has already been defined
  unless (exists $colour_pairs{"$fore:$back"}) {

    # Exit out if we're out of colour pairs (returning the default pair)
    unless (scalar keys %colour_pairs < $COLOR_PAIRS) {
      return 0;
    }

    # Define a new colour pair if valid colours were passed
    if (exists $colours{$fore} && exists $colours{$back}) {
      @pairs = map { $colour_pairs{$_} } keys %colour_pairs;
      $pr = 1;
      while (grep /^$pr$/, @pairs) { ++$pr };
      init_pair($pr, @colours{$fore, $back});
      $colour_pairs{"$fore:$back"} = $pr;

    # Generate a warning if invalid colours were passed
    } else {
      carp "Invalid color pair passed:  $fore/$back--ignoring.";
      return undef;
    }
  }

  # Return the colour pair number
  return $colour_pairs{"$fore:$back"};
}

sub select_color {
  my @args = @_;

  return select_colour(@_);
}

=head2 scankey

  $key = scankey($mwh);

The scankey function returns the key pressed, when it does.  All
it does is loop over a (n)curses B<getch> call until something other
than -1 is returned.  Whether or not the B<getch> call is (half)-blocking
or cooked output is determined by how the (n)curses environment was
initialised by your application.  This is provided only to provide
the most basic input functionality to your application, should you decide 
not to implement your own.

The only argument is a handle to a curses/window object.

=cut

sub scankey {
  my $mwh = shift;
  my $key = -1;

  while ($key eq -1) { $key = $mwh->getch };

  return $key;
}

=head2 textwrap

  @lines = textwrap($text, 40);

The textwrap function takes a string and splits according to the passed column
limit, splitting preferrably along whitespace.  Newlines are preserved.

=cut

sub textwrap {
  my $text = shift;
  my $columns = shift || 72;
  my (@tmp, @rv, $p);

  # Early exit if no text was passed
  return unless (defined $text && length($text));

  # Split the text into paragraphs, but preserve the terminating newline
  @tmp = split(/\n/, $text);
  foreach (@tmp) { $_ .= "\n" };
  chomp($tmp[$#tmp]) unless $text =~ /\n$/;

  # Split each paragraph into lines, according to whitespace
  for $p (@tmp) {

    # Snag lines that meet column limits (not counting newlines
    # as a character)
    if (length($p) <= $columns || (length($p) - 1 <= $columns &&
      $p =~ /\n$/s)) {
      push(@rv, $p);
      next;
    }

    # Split the line
    while (length($p) > $columns) {
      if (substr($p, 0, $columns) =~ /^(.+\s)(\S+)$/) {
        push(@rv, $1);
        $p = $2 . substr($p, $columns);
      } else {
        push(@rv, substr($p, 0, $columns));
        substr($p, 0, $columns) = '';
      }
    }
    push(@rv, $p);
  }

  if ($text =~ /\S\n(\n+)/) {
    $p = length($1);
    foreach (1..$p) { push(@rv, "\n") };
  }

  return @rv;
}


=head1 METHODS

=head2 new

  $obj = Curses::Widgets->new({KEY => 'value'});

The new class method provides a basic constructor for all descendent
widget classes.  Internally, it assumes any configuration information to
be passed in a hash ref as the sole argument.  It dereferences that ref
and passes it to the internal method B<_conf>, which is expected to do
any input validation/initialisation required by your widget.  That method
should return a 1 or 0, which will determine if B<new> returns a handle
to the new object.

If B<_conf> returns a 1, the B<_copy> is called to back up the initial
state information.

If descendent widgets use the methods provided in the class (instead of
overriding them) then the following keys should always be recognised:

  Key             Description
  ====================================================
  FOREGROUND      Foreground colour
  BACKGROUND      Background colour
  BORDERCOL       Border (foreground) colour
  CAPTIONCOL      Caption (foreground) colour
  BORDER          Whether or not to display a border
  CAPTION         The string to use as the caption

The colours will default to the terminal foreground/background defaults.
Other arguments may have defaults defined by the descendent classes.

=cut

sub new {
  my $class = shift;
  my $conf = shift;
  my $self = {};

  bless $self, $class;

  if ($self->_conf(%$conf)) {
    $self->_copy($self->{CONF}, $self->{OCONF});
    return $self;
  } else {
    return undef;
  }
}

=head2 _conf

  $obj->_conf(%conf);

This method should be overridden in your descendant class.  As mentioned
above, it should do any initialisation and validation required, based on
the passed configuration hash.  It should return a 1 or 0, depending on
whether any critical errors were encountered during instantiation.

B<Note:>  your B<_conf> method should call, as a last act, 
B<SUPER::_conf>.  This is important to do, since this method takes care
of some colour initialisation steps for you automatically.  The following keys
are known by this module, and are used by certain rendering and initiation
methods:

  Field              Default      Description
  ============================================================
  FOREGROUND   (terminal default) Default foreground colour
  BACKGROUND   (terminal default) Default background colour
  BORDERCOL       (FOREGROUND)    Default border colour
  CAPTIONCOL      (FOREGROUND)    Default caption colour

As a final note, here are some rules regarding the structure of your
configuration hash.  You *must* save your state information in this hash.  
Another subroutine will copy that information after object instantiation 
in order to support the reset method.  Also note that everything stored 
in this should *not* be more than one additional level deep (in other 
words, values can be hash or array refs, but none of the values in *that* 
structure should be refs), otherwise those refs will be copied over, instead 
of the data inside the structure.  This essentially destroys your backup.

If you have special requirements, override the _copy method as well.

=cut

sub _conf {
  my $self = shift;
  my %conf = @_;
  my ($df, $db, $c);

  # Set the foreground/background, if it wasn't set already
  pair_content(0, $df, $db);
  $conf{FOREGROUND} = (grep { $colours{$_} == $df } keys %colours)[0]
    unless (exists $conf{FOREGROUND});
  $conf{BACKGROUND} = (grep { $colours{$_} == $db } keys %colours)[0]
    unless (exists $conf{BACKGROUND});
  $conf{BORDERCOL} = $conf{FOREGROUND} unless exists $conf{BORDERCOL};
  $conf{CAPTIONCOL} = $conf{FOREGROUND} unless exists $conf{CAPTIONCOL};

  # Lowercase all colours
  foreach (qw(FOREGROUND BACKGROUND CAPTIONCOL BORDERCOL)) {
    $conf{$_} = lc($conf{$_}) };

  # Save conf hashes
  $self->{CONF} = {%conf};
  $self->{OCONF} = {};

  return 1;
}

=head2 _copy

  $obj->_copy($href1, $href2);

This method copies the contents of $href1 to $href2.  This will only copy two
levels of data, so any reference values deeper than that will be passed by
reference, not as a copy of reference's (dereferenced) value.

=cut

sub _copy {
  # Synchronises the current data record with the old 
  # data record.
  # 
  # Internal use only.

  my $self = shift;
  my ($data, $odata) = @_;
  my $field;

  # Empty the target hash
  %$odata = ();

  # Copy each element to the target
  foreach $field (keys %$data) {
    if (ref($$data{$field}) eq 'ARRAY') {
      $$odata{$field} = [ @{$$data{$field}} ];
    } elsif (ref($$data{$field}) eq 'HASH') {
      $$odata{$field} = { %{$$data{$field}} };
    } else {
      $$odata{$field} = $$data{$field};
    }
  }
}

=head2 reset

  $obj->reset;

The reset method resets the object back to the original
state by copying the original configuration information into
the working hash.

=cut

sub reset {
  my $self = shift;

  # Reset the widget to it's original instantiated state
  $self->_copy($self->{OCONF}, $self->{CONF});
}

=head2 input_key

  $obj->input_key($ch);

The input_key method should be overridden in all descendent
classes.  This method should accept character input and update
it's internal state information appropriately.  This method
will be used in both interactive and non-interactive modes to
send keystrokes to the widget.

=cut

sub input_key {
  my $self = shift;
  my $input;

  return 1;
}

=head2 input

  $obj->input($string);

The input method provides a non-interactive method for sending input
to the widget.  This is essentially just a wrapper for the B<input_key>
method, but will accept any number of string arguments at once.  It
splits all of the input into separate characters for feeding to the
B<input_key> method.

=cut

sub input {
  my $self = shift;
  my @input = @_;
  my ($i, @char);

  while (defined ($i = shift @input)) {
    if (length($i) > 1) {
      @char = split(//, $i);
      foreach (@char) { $self->input_key($_) };
    } else {
      $self->input_key($i);
    }
  }
}

=head2 execute

  $obj->execute($mwh);

This method puts the widget into interactive mode, which consists of
calling the B<draw> method, scanning for keyboard input, feeding it
to the B<input_key> method, and redrawing.

execute uses the widget's configuration information to allow easy
modification of its behavoiur.  First, it checks for the existance of
a INPUTFUNC key.  Setting its value to a subroutine reference allows
you to substitute any custom keyboard scanning/polling routine in leiu
of the default  B<scankey> provided by this module.

Second, it checks the return value of the input function against the
regular expression stored in FOCUSSWITCH, if any.  Any matches against
that expression will tell this method to exit, returning the key that
matches it.  This effectively causes the widget to 'lose focus'.

The only argument is a handle to a valid curses window object.

B<NOTE>:  If \t is in your regex, KEY_STAB will also be a trigger for a focus
switch.

=cut

sub execute {
  my $self = shift;
  my $mwh = shift;
  my $conf = $self->{CONF};
  my $func = $$conf{'INPUTFUNC'} || \&scankey;
  my $regex = $$conf{'FOCUSSWITCH'};
  my $key;

  $self->draw($mwh, 1);

  while (1) {
    $key = &$func($mwh);
    if (defined $key) {
      if (defined $regex) {
        return $key if ($key =~ /^[$regex]/ || ($regex =~ /\t/ &&
          $key eq KEY_STAB));
      }
      $self->input_key($key);
    }
    $self->draw($mwh, 1);
  }
}

=head2 getField

  $value = $obj->getField('VALUE');

The getField method retrieves the value(s) for every field requested
that exists in the configuration hash.

=cut

sub getField {
  my $self = shift;
  my @fields = @_;
  my $conf = $self->{CONF};
  my @results;

  foreach (@fields) {
    if (exists $$conf{$_}) {
      push(@results, $$conf{$_});
    } else {
      carp ref($self), ":  attempting to read a non-existent field!";
    }
  }

  return scalar @results > 1 ? @results : $results[0];
}

=head2 setField

  $obj->setField(
    'FIELD1'  => 1,
    'FIELD2'  => 'value'
    );

The setField method sets the value for every key/value pair passed.

=cut

sub setField {
  my $self = shift;
  my %fields = (@_);
  my $conf = $self->{CONF};

  foreach (keys %fields) {
    if (exists $$conf{$_}) {
      $$conf{$_} = $fields{$_};
    } else {
      carp ref($self), ":  attempting to set a non-existent field!";
    }
  }
}

=head2 draw

  $obj->draw($mwh, 1);

The draw method can be overridden in each descendant class.  It
is reponsible for the rendering of the widget, and only that.  The first
argument is mandatory, being a valid window handle with which to create
the widget's derived window.  The second is optional, but if set to
true, will tell the widget to draw itself in an 'active' state.  For 
instance, the TextField widget will also render a cursor, while a 
ButtonSet widget will render the selected button in standout mode.

The rendering sequence defined in this class is as follows:

  # Get the canvas geometry and create a window handle to it
  $dwh = $self->_canvas($mwh, $self->_geometry);
  return 0 unless $dwh;

  $self->_init($dwh);
  $self->_border($dwh);
  $self->_caption($dwh);

  # Get the content area geometry and create a window handle to it
  $cwh = $self->_canvas($dwh, $self->_cgeometry);
  unless (defined $cwh) {
    $dwh->delwin;
    return 0;
  }

  $self->_content($cwh);
  $self->_cursor($cwh) if $active;

=cut

sub draw {
  my $self = shift;
  my $mwh = shift;
  my $active = shift;
  my (@geom, $dwh, $cwh);

  # Get the canvas geometry and create a window handle to it
  $dwh = $self->_canvas($mwh, $self->_geometry);
  return 0 unless $dwh;

  $self->_init($dwh);
  $self->_border($dwh);
  $self->_caption($dwh);

  # Get the content area geometry and create a window handle to it
  $cwh = $self->_canvas($dwh, $self->_cgeometry);
  unless (defined $cwh) {
    $dwh->delwin;
    return 0;
  }

  $self->_content($cwh);
  $self->_cursor($cwh) if $active;

  # Flush the changes to the screen and release the window handles
  $cwh->refresh;
  $cwh->delwin;
  $dwh->refresh;
  $dwh->delwin;

  return 1;
}

=head2 _geometry

  @geom = $obj->_geometry;

This method returns the size of the canvas, with dimensions adjusted to
account for a border (based on the value of B<BORDER> in the configuration 
hash).

=cut

sub _geometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv;

  @rv = @$conf{qw(LINES COLUMNS Y X)};
  if ($$conf{BORDER}) {
    $rv[0] += 2;
    $rv[1] += 2;
  }

  return @rv;
}

=head2 _cgeometry 

  @geom = $obj->_cgeometry;

This method returns the size of the content area.  The Y and X coordinates are
adjusted appropriately for rendering in a widget canvas.  (0, 0) is returned
for widgets with no border, and (1, 1) is returned for widgets with a border
(based on the value of B<BORDER> in the configuration hash).

=cut

sub _cgeometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv;

  @rv = (@$conf{qw(LINES COLUMNS)}, 0, 0);
  @rv[2,3] = (1, 1) if $$conf{BORDER};

  return @rv;
}

=head2 _canvas 

  $dwh = $obj->_canvas($mwh, @geom);

This method returns a window handle to a derived window in the passed window,
using the specified geometry.  This will return undef and produce a warning if
the call fails for any reason.

=cut

sub _canvas {
  my $self = shift;
  my $mwh = shift;
  my @geom = @_;
  my $dwh;

  carp ref($self), ":  Window creation failed, possible geometry problem"
    unless ($dwh = $mwh->derwin(@geom));

  return $dwh;
}

=head2 _init

  $obj->_init($mwh);

This method erases the window and sets the foreground/background colours as
found in the configuration hash.

=cut

sub _init {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};

  $dwh->keypad(1);
  $dwh->bkgdset(COLOR_PAIR(select_colour(
    @$conf{qw(FOREGROUND BACKGROUND)})));
  $dwh->attron(A_BOLD) if $$conf{FOREGROUND} eq 'yellow';
  $dwh->erase;
  $self->_save($dwh);
}

=head2 _save

  $obj->_save($mwh);

This method saves the current attributes and colour pair in the passed window.
This method would typically be called by the draw routine after _init is
called on the derived window (though the current _init method calls this for
you).

=cut

sub _save {
  my $self = shift;
  my $dwh = shift;
  my $conf = shift;
  my ($attr, $cp);

  # WARNING! Compatibility hack for some system curses implementation
  # coming. . .

  # I'd really like to do this. . .
  if ($dwh->can('attr_get')) {
    $dwh->attr_get($attr, $cp, 0);

  # but if I can't, I'll just hope the window defaults are right
  } else {
    $cp = select_colour(@$conf{qw(FOREGROUND BACKGROUND)});
    $attr = $$conf{FOREGROUND} eq 'yellow' ? A_BOLD : 0;
  }

  $self->{ATTR} = [$attr, $cp];
}

=head2 _restore

  $obj->_restore($mwh);

This method restores the last saved attributes and colour pair used in the
window.  This should be called at the end of any rendering phase that may
alter the default colour and attribute settings.

=cut

sub _restore {
  my $self = shift;
  my $dwh = shift;

  # WARNING! Compatibility hack for some system curses implementation
  # coming. . .

  # I'd really like to do this, too. . .
  if ($dwh->can('attr_set')) {
    $dwh->attr_set(@{$self->{ATTR}}, 0);

  # but if you're going to be that way, I'll do it the longer way
  } else {
    $dwh->attrset(COLOR_PAIR($self->{ATTR}->[1]));
    $dwh->attron($self->{ATTR}->[0]);
  }
}

=head2 _border

  $obj->_border($mwh);

This method draws the border around the passed window if B<BORDER> is true
within the configuration hash.

=cut

sub _border {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};

  if ($$conf{BORDER}) {
    $dwh->attrset(COLOR_PAIR(
      select_colour(@$conf{qw(BORDERCOL BACKGROUND)})));
    $dwh->attron(A_BOLD) if $$conf{BORDERCOL} eq 'yellow';
    $dwh->box(ACS_VLINE, ACS_HLINE);
    $self->_restore($dwh);
  }
}

=head2 _caption

  $obj->_caption

This method draws a caption on the first line of the passed window if
B<CAPTION> is defined within the configuration hash.

=cut

sub _caption {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};

  if (defined $$conf{CAPTION}) {
    $dwh->attrset(COLOR_PAIR( 
      select_colour(@$conf{qw(CAPTIONCOL BACKGROUND)})));
    $dwh->attron(A_BOLD) if $$conf{CAPTIONCOL} eq 'yellow';
    $dwh->addstr(0, 1, substr($$conf{CAPTION}, 0, $$conf{COLUMNS}));
    $self->_restore($dwh);
  }
}

=head2 _content

  $obj->_content($mwh);

This method should be overridden in all descendent classes, and should render
any content in the passed window.  The B<draw> method, as defined in this
class, will pass a window the exact size of the content area, so no
adjustments will need to be made to accomodate a border.

=cut

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};

  # Override this method to render widget content
}

=head2 _cursor

  $obj->_cursor

This method should be overriden in all descendent classes that display a
cursor in the content area.  The B<draw> method, as defined in this class,
calls this method after the content is rendered, and passes it a window handle
the exact size of the content area.

=cut

sub _cursor {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};

  # Override this method to render widget cursor
}

1;

=head1 HISTORY

=over

=item 2001/07/05 -- First implementation of the base class.

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

