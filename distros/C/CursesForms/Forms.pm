# Curses::Forms.pm -- Curses Forms Framework
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Forms.pm,v 1.997 2002/11/14 18:22:59 corliss Exp corliss $
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
########################################################################

=head1 NAME

Curses::Forms - Curses Forms Framework

=head1 MODULE VERSION

$Id: Forms.pm,v 1.997 2002/11/14 18:22:59 corliss Exp corliss $

=head1 SYNOPSIS

	use Curses::Forms;

  $obj = Curses::Forms->new({
    ALTBASE     => 'MyCompany::Widgets',
    ALTFBASE    => 'MyCompany::Forms',
    COLUMNS     => 40,
    LINES       => 20,
    BORDER      => 1,
    BORDERCOL   => 'white',
    CAPTION     => 'New Record',
    CAPTIONCOL  => 'yellow',
    FOREGROUND  => 'black',
    BACKGROUND  => 'white',
    Y           => 1,
    X           => 1,
    INPUTFUNC   => \&scankey,
    DERIVED     => 0,
    AUTOCENTER  => 1,
    TABORDER    => [qw(btnOKCancel edtLogon edtPsswd)],
    FOCUSED     => 'edtLogon',
    WIDGETS     => {
      btnOKCancel   => {
        TYPE        => 'ButtonSet',
        LABELS      => [qw(OK Cancel)],
        Y           => 8,
        X           => 3,
        FOREGROUND  => 'white',
        BACKGROUND  => 'green',
        OnExit      => \&btns,
        },
      edtLogon      => {
        TYPE        => 'TextField',
        FOREGROUND  => 'white',
        BACKGROUND  => 'blue',
        CAPTION     => 'Logon',
        CAPTIONCOL  => 'yellow',
        LENGTH      => 21,
        Y           => 2,
        X           => 8,
        },
      edtPsswd      => {
        TYPE        => 'TextField',
        FOREGROUND  => 'white',
        BACKGROUND  => 'blue',
        CAPTION     => 'Password',
        CAPTIONCOL  => 'yellow',
        LENGTH      => 21,
        Y           => 5,
        X           => 8,
        PASSWORD    => 1,
      },
    });

  $form->setField(BORDER => 1);
  @taborder = @{$form->getField('TABORDER')};

  $form->addWidget('btnClose', { %options });
  $widget = $form->getWidget('btnClose');

  $form->addSubform('MainSubFrm', { %options });
  $subform = $form->getSubform('MainSubFrm');

  $form->execute($mwh);

  pushwh($mwh);
  popwh();
  refreshwh();
  lowerwh($wh);
  raisewh($wh);

=head1 REQUIREMENTS

Curses
Curses::Widgets

=head1 DESCRIPTION

Curses::Forms provide a simple framework for OO forms.  The Forms module
itself provides a basic class from which extended forms can be derived, or, it
can be used as-is to control forms populated with widgets.  More specialised 
forms are also available under B<Curses::Forms::Dialog>.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Forms;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Curses;
use Curses::Widgets 1.9;
use Exporter;
use Carp;

$VERSION = (q$Revision: 1.997 $ =~ /(\d+(?:\.(\d+))+)/)[0] || '0.1';
@ISA = qw(Curses::Widgets);
@EXPORT = qw(select_colour select_color scankey textwrap pushwh 
  popwh refreshwh lowerwh raisewh);

my @events = qw(OnEnter OnExit);
my @colitems = qw(FOREGROUND BACKGROUND BORDERCOL CAPTIONCOL);

########################################################################
#
# Module code follows. . .
#
########################################################################

=head1 INTRODUCTION

This module is partially derived from the B<Curses::Widgets> module, and so
has much of the same syntax and APIs.  One area of special note, however, is
populating a form with widgets.

=head2 ADDING WIDGETS

There are two ways to add widgets to a form:  interactively (i.e., one at a
time, at any time), or predeclared (i.e., all at once during object
instantiation).  Both methods require passing hashes containing all the
standard arguments normally used when creating the widgets directly via the
Curses::Widgets::* modules.  There are a few new keys to be aware of, though:

   Key      Description
   ====================================================
   TYPE     Type of widget, relative to Curses::Widgets
   OnEnter  Subroutine reference to be called when the
            widget first gains focus
   OnExit   Subroutine reference to be called when the 
            widget loses focus

Only B<TYPE> is mandatory.  The value is a string relative to the
Curses::Widgets hierarchy.  In other words, if you want a TextField widget,
that's all you need to put in, not the full Curses::Widgets::TextField module
name.  This allows you to use new widgets with no special modifications needed
in this module, as long as it's found within the Curses::Widgets namespace.

If you want to use custom widgets not in the Curses::Widgets namespace you
must set the B<ALTBASE> key to whatever the base class is called (i.e.,
'MyCompany::Widgets', if all the widgets are within that heirarchy).  The
B<TYPE> will use B<ALTBASE> first, then, and if that fails, try 
Curses::Widgets.  You can set B<ALTBASE> to an array ref with multiple
namespaces to search, if desired.

B<OnEnter> and B<OnExit> can be considered rudimentary event handlers.  These
subroutines are called when the widget gains and/or loses focus.  These
subroutines are always called with two arguments:  a reference to the
Curses::Forms object, and the last key stroke:

  @$sub($form, $key)

This allows you to use these handlers to update other widgets on the form, or
take appropriate action as needed.  For instance, suppose you had a database
record form open, with two buttons:  Commit, and Cancel.  The former would
save the database changes, while the latter would just close the form.  You
would accomplish this as so:

  # During widget declaration
  $form->new({
    ...
    WIDGETS => {
      ...
      btnCommitCancel => {
        ...
        OnExit  => \&CancelOrCommit,
        },
      },
    });

  # Subroutine somewhere else in your program code
  sub CancelOrCommit {
    my $form = shift;
    my $key = shift;
    my $btns = $form->getWidget('btnCommitCancel');

    # Make sure they user pressed <ENTER> to push a button
    return unless $key eq "\n";

    # The user pressed 'Commit'
    if ($btn->getField('VALUE') == 0) {
      # Save your record updates
      ...

    # The user pressed 'Cancel'
    } else {
      $form->setField(EXIT => 1);
    }
  }

As you can see, this example also explains a special field used by the
Curses::Forms object:  B<EXIT>.  Whenever you want the form to be closed due
to some condition or user input just set B<EXIT> to some true value.  Once
your subroutine exits this field will be checked, and if true, will cause the
form to break out of the execute loop.

Another special field is the B<DONTSWITCH> field, which tells the form to keep
the focus where it is.

A point of clarification:  if you use the B<getField/setField> operations to
retrieve and modify the WIDGETS key, this will have no affect on the current
set of widgets in the form.  This key is only used during object
instantiation, with all object references to the widgets stored internally,
but outside of the configuration hash.  Therefore, you can modify widget
parameters only by retrieving the object reference via the B<getWidget>
method.  Also, you can add widgets via the B<addWidget> but there is no
method to delete them.

The form content area is always a derived window, so widgets should always
place themselves relative to (0, 0), regardless of whether or not the form has
a border.

=head2 ADDING SUBFORMS

Adding subforms within a form is done in the same manner as widgets, either by
passing the subform options via the B<SUBFORMS> field, or by calling the
B<addSubform> method.  Like the widgets implementation, subforms can be custom
derivatives of Curses::Forms, all you need to do is declare the alternate
Forms namespace(s) to search via the B<ALTFBASE> key.

The only change in subform behaviour versus form behaviour is that once the
focus leaves the last widget in the tab order, focus switches back to the
parent form tab order, instead of looping within that subform.

=head2 MANAGING OVERLAPPING FORMS

Every time a non-derived form is displayed Curses::Forms pushes the active
window handle onto an internal ordinal array.  This array is used each time a
window is released to refresh each window from the bottom up to make sure all
the regions overlapped by the now-deleted form are redrawn.  This is done by
calling touchwin and noutrefresh on each window handle, and then a single
doupdate at the end.  The deleted form's window handle is popped off the array
just prior to this refresh.

From time to time you may create windows that need to be redrawn with the
other overlapping windows.  Two functions are provided to handle this:  
B<pushwh> and B<popwh>.  As you create the window you should use pushwh to put
it in the array, and use popwh as soon as you delete it.  If you'd like to
manually refresh the screen, you may do so via the B<refreshwh> subroutine.

To other functions are provided for lowering or raising the windows in the
array:  B<lowerwh> and B<raisewh>.

=head1 FUNCTIONS

Using this module will import the same set of functions provided by
Curses::Widgets.  Please consult the Curses::Widgets pod for a complete
reference of these functions.

New functions provided by this module are documented below.

=cut

{
  my @wh;

  sub pushwh {
    push(@wh, shift @_);
  }

  sub popwh {
    pop @wh;
  }

  sub refreshwh {
    foreach (@wh) {
      next unless defined $_;
      $_->touchwin;
      $_->noutrefresh;
    }
    doupdate();
  }

  sub lowerwh {
    my $pwh = shift;
    my $i;

    for ($i = 0; $i < @wh; $i++) {
      if ($wh[$i] == $pwh) {
        @wh[$i - 1, $i] = @wh[$i, $i - 1] if ($i > 0);
        last;
      }
    }
  }

  sub raisewh {
    my $pwh = shift;
    my $i;

    for ($i = 0; $i < @wh; $i++) {
      if ($wh[$i] == $pwh) {
        @wh[$i, $i + 1] = @wh[$i + 1, $i] if ($i < $#wh);
        last;
      }
    }
  }
}

=head2 pushwh

  pushwh($mwh);

Pushes an external window handle onto the Curses::Forms-managed refresh array.

=head2 popwh

  popwh();

Pops a window handle off the Curses::Forms-managed refresh array.

=head2 refreshwh

  refreshwh();

Refreshes each window in order of the ordinal array.

=head2 raisewh

  raisewh($wh);

Raises the passed window in the array.

=head2 lowerwh

  lowerwh($wh);

Lowers the passed window in the array.

=head1 METHODS

=head2 new

  $obj = Curses::Forms->new({
    ALTBASE     => 'MyCompany::Widgets',
    ALTFBASE    => 'MyCompany::Forms',
    COLUMNS     => 40,
    LINES       => 20,
    BORDER      => 1,
    BORDERCOL   => 'white',
    CAPTION     => 'New Record',
    CAPTIONCOL  => 'yellow',
    FOREGROUND  => 'black',
    BACKGROUND  => 'white',
    Y           => 1,
    X           => 1,
    INPUTFUNC   => \&scankey,
    DERIVED     => 0,
    AUTOCENTER  => 1,
    TABORDER    => [qw(btnOKCancel edtLogon edtPsswd)],
    FOCUSED     => 'edtLogon',
    WIDGETS     => {
      btnOKCancel   => {
        TYPE        => 'ButtonSet',
        LABELS      => [qw(OK Cancel)],
        Y           => 8,
        X           => 3,
        FOREGROUND  => 'white',
        BACKGROUND  => 'green',
        OnExit      => \&btns,
        },
      edtLogon      => {
        TYPE        => 'TextField',
        FOREGROUND  => 'white',
        BACKGROUND  => 'blue',
        CAPTION     => 'Logon',
        CAPTIONCOL  => 'yellow',
        LENGTH      => 21,
        Y           => 2,
        X           => 8,
        },
      edtPsswd      => {
        TYPE        => 'TextField',
        FOREGROUND  => 'white',
        BACKGROUND  => 'blue',
        CAPTION     => 'Password',
        CAPTIONCOL  => 'yellow',
        LENGTH      => 21,
        Y           => 5,
        X           => 8,
        PASSWORD    => 1,
      },
    });

This method instantiates a new instance of a Curses::Form object.  All
configuration directives, with the exception of B<COLUMNS> and B<LINES> are
optional.  The defaults for the rest are described below:

  Key         Default     Description
  ==============================================================
  BORDER            0     Display a border around the form
  BORDERCOL     undef     Foreground colour for border
  CAPTION       undef     Caption superimposed on border
  CAPTIONCOL    undef     Foreground colour for caption text
  FOREGROUND    undef     Foreground colour for form
  BACKGROUND    undef     Background colour for form
  Y                 0     Y coordinate for upper left corner
  X                 0     X coordinate for upper left corner
  INPUTFUNC \&scankey     Function to use to scan for keystrokes
  DERIVED           1     Whether to create the form as a derived
                          or new window
  TABORDER         []     Order in which widgets will get the 
                          focus
  FOCUSED       undef     Currently focused widget
  WIDGETS          {}     Widgets used on the form
  ALTBASE       undef     Alternate namespace to search for 
                          loadable widgets
  ALTFBASE      undef     Alternate namespace to search for 
                          loadable forms
  AUTOCENTER        0     Whether or not to center the form in the
                          display (only for non-derived windows)

The CAPTION is only valid when the BORDER is enabled.  B<INPUTFUNC> will be
passed to each widget explicitly.   B<FOREGROUND>, B<BACKGROUND>, and
B<CAPTIONCOL> will be passed to each widget if that widget's declaration 
doesn't specify it directly.

Please see the B<Introduction> section on special handling of the declaration
of widgets.

=cut

sub _conf {
  my $self = shift;
  my %conf = (
    BORDER      => 0,
    Y           => 0,
    X           => 0,
    INPUTFUNC   => \&scankey,
    DERIVED     => 1,
    TABORDER    => [],
    FOCUSED     => undef,
    WIDGETS     => {},
    SUBFORMS    => {},
    EXIT        => 0,
    DONTSWITCH  => 0,
    DESTROY     => 1,
    SUBFORM     => 0,
    @_
    );
	my @required = qw(COLUMNS LINES);
	my $err = 0;
  my ($subform, $widget, $y, $x, $cols, $lines);

  # Set some defaults
  $self->{FWH} = undef;
  $self->{LEVEL} = 0;

	# Check for required arguments
	foreach (@required) { $err = 1 unless exists $conf{$_} };

  # Quick archive of configuration directives (needed for
  # widget creation)
  $self->{CONF} = {%conf};
  $self->{WIDGETS} = {};
  $self->{SUBFORMS} = {};

  # Create all the passed widgets
  foreach (keys %{$conf{WIDGETS}}) {
    $widget = $conf{WIDGETS}{$_};
    $$widget{INPUTFUNC} = $conf{INPUTFUNC};
    unless ($self->addWidget($_, $widget)) { $err = 1 };
  }

  # Create all the passed subforms
  foreach (keys %{$conf{SUBFORMS}}) {
    $subform = $conf{SUBFORMS}{$_};
    $$subform{INPUTFUNC} = $conf{INPUTFUNC};
    $$subform{SUBFORM} = 1;
    unless ($self->addSubform($_, $subform)) { $err = 1 };
  }

  # Calculate Y & X for nonderived, centered forms
  if ($conf{AUTOCENTER} && ! $conf{DERIVED}) {
    ($cols, $lines) = @conf{qw(COLUMNS LINES)};
    ($x, $y) = (0, 0);
    $x = int(($COLS - $cols) / 2) if $COLS > $cols;
    $y = int(($LINES - $lines) / 2) if $LINES > $lines;
    @conf{qw(Y X)} = ($y, $x);
  }

	# Make sure no errors are returned by the parent method
	$err = 1 unless $self->SUPER::_conf(%conf);

	return $err == 0 ? 1 : 0;
}

=head2 draw

  $form->draw($mwh);

This methods renders and displays the form in its current state. An optional
second argument designates whether or not the focused widget should be drawn
in active mode or not.

=cut

sub draw {
  my $self = shift;
  my $mwh = shift;
  my $active = shift;
  my $conf = $self->{CONF};
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

  # Print the contents
  $self->_content($cwh);

  # Flush the changes to the screen and release the window handles
  $cwh->refresh;
  $cwh->delwin;
  $dwh->refresh;
  $dwh->delwin;

  return 1;
}

sub _formwin {
  my $self = shift;
  my $conf = $self->{CONF};
  my $fwh = $self->{FWH};
  my @geom = @$conf{qw(LINES COLUMNS Y X)};

  # Create the window handle if it hasn't been already
  unless (defined $fwh) {

    # Adjust dimensions for the border
    if ($$conf{BORDER}) {
      $geom[0] += 2;
      $geom[1] += 2;
    }
    unless ($fwh = newwin(@geom)) {
      carp ref($self), ":  Window creation failed, possible geometry problem";
      return 0;
    }
    $fwh->syncok(1);
    $self->_init($fwh);
    pushwh($fwh);
  }

  # Store the handles
  $self->{FWH} = $fwh;

  return $fwh;
}

sub _relwin {
  my $self = shift;
  my $fwh = $self->{FWH};

  $fwh->delwin if defined $fwh;
  popwh();
  refreshwh();

  $self->{FWH} = undef;
}

sub _geometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv = @$conf{qw(LINES COLUMNS Y X)};

  if ($$conf{BORDER}) {
    $rv[0] += 2;
    $rv[1] += 2;
  }
  @rv[2,3] = (0, 0) if ($self->{LEVEL});

  return @rv;
}

sub _cgeometry {
  my $self = shift;
  my $conf = $self->{CONF};
  my @rv;

  @rv = (@$conf{qw(LINES COLUMNS)}, 0, 0);
  @rv[2,3] = (1, 1) if $$conf{BORDER};

  return @rv;
}

sub _content {
	my $self = shift;
	my $fwh = shift;
	my $active = shift;
  my $conf = $self->{CONF};
  my @taborder = @{$$conf{TABORDER}};
  my $widgets = $self->{WIDGETS};
  my $subforms = $self->{SUBFORMS};
  my $focused = $$conf{FOCUSED} || $taborder[0] || undef;

  # Draw any subforms
  foreach (keys %$subforms) {
    ($active && $_ eq $focused) ? $$subforms{$_}->draw($fwh, 1) : 
      $$subforms{$_}->draw($fwh);
  }

  # Draw the widgets
  foreach (keys %$widgets) {
    ($active && $_ eq $focused) ? $$widgets{$_}->draw($fwh, 1) : 
      $$widgets{$_}->draw($fwh);
  }
}

sub _cursor {
  # Forms don't have cursors, per-se
}

=head2 setField/getField

  $form->setField(BORDER => 1);
  @taborder = @{$form->getField('TABORDER')};

These methods are inherited from the Curses::Widgets module, and hence are
syntactically the same.  For more specifics please see that module.

=head2 addWidget

  $form->addWidget('btnClose', { %options });

This method allows you to add a widget to the form.  Please see the
B<INTRODUCTION> for a more indepth explanation of this call.  Returns a true
if successful, or a false if not (if, for instance, you're trying to use a
widget that module can be found for, or a widget by that name already exists).

=cut

sub addWidget {
  my $self = shift;
  my $name = shift;
  my $options = shift;
  my $type = $$options{TYPE};
  my $widgets = $self->{WIDGETS};
  my $conf = $self->{CONF};
  my @try = ('Curses::Widgets');
  my $alt = $self->{CONF}->{ALTBASE};
  my $success = 0;
  my $base;

  unless ($type) {
    carp ref($self), ":  No widget type specified to add!";
    return 0;
  }

  # Get the alt widget base class, if specified
  if (defined $alt) {
    if (ref($alt) eq 'ARRAY') {
      unshift @try, @$alt;
    } else {
      unshift @try, $self->{CONF}->{ALTBASE};
    }
  }

  # Load the applicable module
  foreach $base (@try) {
    if (eval "require ${base}::$type") {
      $success = 1;
      $type = "${base}::$type";
      last;
    }
  }
  unless ($success) {
    carp ref($self), ":  Loading module $type (in @try) failed!";
    return 0;
  }

  # Avoid name collisions
  if (exists $$widgets{$name}) {
    carp ref($_), ":  A widget named $name is already in the hash!";
    return 0;
  }

  # Set the colours
  foreach (@colitems) {
    $$options{$_} = $$conf{$_} if
      (exists $$conf{$_} && ! exists $$options{$_});
  }

  # Create and store the widget
  {
    no strict 'refs';
    unless ($$widgets{$name} = "$type"->new($options)) {
      carp ref($self), ":  $type creation failed!";
      return 0;
    }

    # Reference event subs under widget space
    foreach (@events) {
      $$widgets{$name}->{$_} = $$options{$_} if exists
        $$options{$_};
    }
  }

  return 1;
}

=head2 getWidget

  $widget = $form->getWidget('btnClose');

Retrieves a reference to a widget object.  Returns an undef if the widget does
not exist under the passed name.

=cut

sub getWidget {
  my $self = shift;
  my $name = shift;
  my $widgets = $self->{WIDGETS};
  my $w = $$widgets{$name} if exists $$widgets{$name};

  return $w;
}

=head2 addSubform

  $form->addSubform('MainSubFrm', { %options });

This method allows you to add a subform to the form.  Please see the
B<INTRODUCTION> for a more indepth explanation of this call.  Returns a true
if successful, or a false if not (if, for instance, you're trying to use a
form that module can't be found for, or a widget by that name already exists).

=cut

sub addSubform {
  my $self = shift;
  my $name = shift;
  my $options = shift;
  my $type = $$options{TYPE} || '';
  my $subforms = $self->{SUBFORMS};
  my $conf = $self->{CONF};
  my @try = ('Curses::Forms');
  my $alt = $self->{CONF}->{ALTFBASE};
  my $success = 0;
  my ($base, $mod);

  # Get the alt widget base class, if specified
  if (defined $alt) {
    if (ref($alt) eq 'ARRAY') {
      unshift @try, @$alt;
    } else {
      unshift @try, $self->{CONF}->{ALTBASE};
    }
  }

  # Load the applicable module
  foreach $base (@try) {
    $mod = $type eq '' ? $base : "${base}::$type";
    if (eval "require $mod") {
      $success = 1;
      $type = $mod;
      last;
    }
  }
  unless ($success) {
    carp ref($self), ":  Loading module $type (in @try) failed!";
    return 0;
  }

  # Avoid name collisions
  if (exists $$subforms{$name}) {
    carp ref($_), ":  A widget named $name is already in the hash!";
    return 0;
  }

  # Set the colours
  foreach (@colitems) {
    $$options{$_} = $$conf{$_} if
      (exists $$conf{$_} && ! exists $$options{$_});
  }

  # Subforms are always derived
  $$options{DERIVED} = 1;

  # Create and store the widget
  {
    no strict 'refs';
    unless ($$subforms{$name} = "$mod"->new($options)) {
      carp ref($self), ":  $type creation failed!";
      return 0;
    }

    # Reference event subs under widget space
    foreach (@events) {
      $$subforms{$name}->{$_} = $$options{$_} if exists
        $$options{$_};
    }
  }

  return 1;
}

=head2 getSubform

  $subform = $form->getSubform('MainSubFrm');

Retrieves a reference to a subform object.  Returns an undef if the form does
not exist under the passed name.

=cut

sub getSubform {
  my $self = shift;
  my $name = shift;
  my $subforms = $self->{SUBFORMS};
  my $f = $$subforms{$name} if exists $$subforms{$name};

  return $f;
}

=head2 execute

  $form->execute($mwh);

This method starts the form loop to scan input and cycle through the widgets
that can get focus.  A valid window handle must be passed for any form using
B<DERIVED> mode.

=cut

sub execute {
  my $self = shift;
	my $mwh = shift;
  my $conf = $self->{CONF};
  my @taborder = @{$$conf{TABORDER}};
  my $widgets = $self->{WIDGETS};
  my $subforms = $self->{SUBFORMS};
  my $focused = $$conf{FOCUSED} || $taborder[0] || undef;
  my ($i, $obj, $key, $oderived, $dwh, $cwh);

  # Create the window if this is not a derived window
  unless ($$conf{DERIVED}) {
    $mwh = $self->_formwin;
    $self->{LEVEL} = 1;

    # Save the old value of DESTORY and temporarily set it to false
    $oderived = $$conf{DERIVED};
    $$conf{DERIVED} = 1;

    # Call ourself again
    $key = $self->execute($mwh);
    $self->_relwin();

    # Restore the DERIVED value and exit
    $$conf{DERIVED} = $oderived;
    $self->{LEVEL} = 0;
    return $key;
  }

  # Take an early exit if there's nothing listed in the tab order
  unless ($#taborder > -1) {
    carp ref($self), ":  Must have a widget to give focus to!";
    return 0;
  }

  # Set the EXIT flag to false
  $$conf{EXIT} = 0;

  # Find the index of the focused widget
  $i = 0;
  until ($i > $#taborder || $focused eq $taborder[$i]) {
    ++$i;
  }
  $i = 0 if $i > $#taborder;

  $self->{MWH} = $mwh;
  $dwh = $self->_canvas($mwh, $self->_geometry);
  $self->_init($dwh);
  $cwh = $self->_canvas($dwh, $self->_cgeometry);
  $cwh->keypad(1);

  # Start the loop
  while (1) {

    $obj = exists $$widgets{$taborder[$i]} ?  $$widgets{$taborder[$i]} :
      $$subforms{$taborder[$i]};
    $focused = $$conf{FOCUSED} = $taborder[$i];

    unless (defined $obj) {
      carp ref($self), ":  No such form or widget to focus!";
      return 0;
    }

    # Draw the form
    $self->draw($mwh, 1);

    # Call the OnEnter routine if present
    &{$obj->{OnEnter}}($self) if defined $obj->{OnEnter};

    # Execute
    $key = $obj->execute($cwh);
    $self->draw($mwh);

    # Call the OnExit routine if present
    &{$obj->{OnExit}}($self, $key) if defined $obj->{OnExit};

    # Exit if specified
    last if $$conf{EXIT};

    # Move the focus where appropriate
    unless ($$conf{DONTSWITCH} == 1) {
      $i += $key eq KEY_STAB ? -1 : 1;
    }
    $$conf{DONTSWITCH} = 0;
    $i = 0 if $i > $#taborder;
    $i = $#taborder if $i < 0;

    # Exit if this is the last widget on a subform
    last if ($$conf{SUBFORM} && $focused eq $taborder[$#taborder]);
  }

  $cwh->delwin;
  $dwh->delwin;

  # Reset the EXIT and DESTROY flags
  $$conf{EXIT} = 0;
  $$conf{FOCUSED} = $taborder[$i];

  return $key;
}

1;

=head1 HISTORY

=over

=item 2000/02/29 -- Original functional version

=item 2002/10/10 -- Rewritten in OO form

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

