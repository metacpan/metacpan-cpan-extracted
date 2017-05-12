# Curses::Application.pm -- Curses Application Framework
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Application.pm,v 0.2 2002/11/14 19:40:42 corliss Exp corliss $
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

Curses::Application - Curses Application Framework

=head1 MODULE VERSION

$Id: Application.pm,v 0.2 2002/11/14 19:40:42 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Application;

  $app = Curses::Application->new({
      FOREGROUND  => 'white',
      BACKGROUND  => 'blue',
      TITLEBAR    => 1,
      STATUSBAR   => 1,
      CAPTION     => 'My Application',
      MAINFORM    => { name => defname },
      MINY        => 20,
      MINX        => 60,
      ALTFBASE    => 'MyCompany::Forms',
      ALTBASE     => 'MyCompany::Widgets',
    });

  ($y, $x) = $app->maxyx;
  $mwh = $app->mwh;

  $app->titlebar($caption);
  $app->statusbar($message);

  $app->draw;
  $app->redraw;

  $app->addFormDef('MyForm', { %formopts });
  $app->createForm($name, $def);
  $form = $app->getForm('MainFrm');
  $app->delForm('Main');
  $app->execForm('Main');

  $app->execute;

=head1 REQUIREMENTS

Curses
Curses::Widgets
Curses::Forms

=head1 DESCRIPTION

Curses::Application attempts to relieve the programmer of having to deal
directly with Curses at all.  Based upon Curses::Widgets and Curses::Forms,
all one should have to do is define the application forms and contents in the
DATA block of a script.  Curses::Application will take care of the rest.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Application;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use Carp;
use Curses;
use Curses::Widgets;
use Curses::Forms;
use Curses::Forms::Dialog;
use Curses::Forms::Dialog::Input;
use Curses::Forms::Dialog::Logon;

($VERSION) = (q$Revision: 0.2 $ =~ /(\d+(?:\.(\d+))+)/);

@ISA = qw(Curses::Widgets);
@EXPORT = qw(dialog input logon BTN_OK BTN_YES BTN_NO BTN_CANCEL
  BTN_HELP scankey);

my @events = qw(OnEnter OnExit);
my @colitems = qw(FOREGROUND BACKGROUND BORDERCOL CAPTIONCOL);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 INTRODUCTION

This module follows many of the conventions established by the Curses::Widgets
and Curses::Forms modules, being built upon that framework.  One area of
special note, however, is the declaration of forms used within the
application.

B<Curses::Application> differentiates between forms and form definitions.
A form is an instance of any particular form definition.  Keeping that line of
separation simplifies the development of MDI (Multiple Document Interface) 
applications.

Form definitions can be provided in two ways:  as a list of definitions in the
main::DATA block, or individually by using the B<addFormDef> method.  The
former would normally be the simplest way to do so.

At the end of your script, declare a DATA block using Perl's B<__DATA__>
token.  In that DATA block place a hash declaration (%forms) which contains
a key/value pair for each form definition.  The key being the name of the
definition, and the value being a hash reference to the form declarations
(see the B<Curses::Forms> pod for directives available to that module).  The
only extra key that should be in each form's hash reference should be a
B<TYPE> directive, which would point to a module name relative to the base
Curses::Forms class.  If you omit this key, then it will be assumed that the
form is a Curses::Forms object, or some custom derivative as specified in
B<ALTPATH>.

  Example:
  ========

  __DATA__
  
  %forms = (
    Main    => {
      TYPE      => 'Custom',
      ALTBASE   => 'MyCompany::Forms',
      LINES     => 10,
      COLUMNS   => 80,
      DERIVED   => 0,
      WIDGETS   => {
        ...
        },
      ...
      },
    );

Just as Curses::Forms allows you to use custom derivatives of Curses::Widgets,
this module also allows you to use custom derivatives of Curses::Forms using
the B<ALTBASE> directive.  Similarly, the OnEnter and OnExit events are also
supported on per-form basis.  Instead of passing the form reference as an
argument to the call it passes the application object reference.

B<NOTE>:  The main form (as declared with B<MAINFORM>) will always be a
derived form and the size of the screen minus any title or status bars used.
This is overridden in the object constructor, so expect those options to be
set as such.

=head1 FUNCTIONS

This module exports the functions and constants provided by
Curses::Forms::Dialog and child modules:

  Functions
  ---------
  dialog, input, logon, scankey

  Constants
  ---------
  BTN_OK, BTN_YES, BTN_NO, BTN_CANCEL, BTN_HELP

This should provide all of the functionality needed within your main
application code.  The intent of this module is to prevent you from having to
know and/or use the entire Curses family of modules directly.  The only thing
you will need to be aware of is the appropriate configuration syntax for both
forms and widgets.

If you need access to the B<pushwh>, etc., functions, you'll need to add:

  use Curses::Forms;

to your main script body, and they'll be imported directly.

=head1 METHODS

=head2 new

  $app = Curses::Application->new({
      FOREGROUND  => 'white',
      BACKGROUND  => 'blue',
      TITLEBAR    => 1,
      STATUSBAR   => 1,
      CAPTION     => 'My Application',
      MAINFORM    => { name => defname },
      MINY        => 20,
      MINX        => 60,
      ALTFBASE    => 'MyCompany::Forms',
      ALTBASE     => 'MyCompany::Widgets',
    });

The B<new> class method returns a Curses::Application object. All 
arguments are optional, provided you're happy with the defaults, with the
exception of B<MAINFORM>.  That directive is a key/value pair consisting of
the form name and the name of the form definition.

  Argument    Default  Description
  ============================================================
  FOREGROUND    undef  Default foreground colour
  BACKGROUND    undef  Default background colour
  CAPTIONCOL    undef  Default caption colour
  TITLEBAR          0  Whether or not to show a title bar
  STATUSBAR         0  Whether or not to show a status bar
  CAPTION          $0  Default caption to show in the titlebar
  MINY             24  Minimum lines needed for application
  MINX             80  Minimum columns needed for application
  ALTFBASE      undef  Alternate namespace to search for forms
  ALTBASE       undef  Alternate namespace to search for widgets
  FORMDEFS         {}  Form definitions
  INPUTFUNC \&scankey  Default input routine

B<MAINFORM> is the form first display by the application when executed.

If either B<MINY> or B<MINX> is not satisfied, this method will return undef
instead of an object reference to Curses::Application.

Like Curses::Forms, all colour choices are passed to each form that doesn't
explicitly declare their own.  Alternate namespaces are also passed.

=cut

sub _conf {
  # This method creates the initial curses object and initialises
  # both the curses and application configurable space.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = ( 
    TITLEBAR    => 0,
    STATUSBAR   => 0,
    FORMDEFS    => {},
    CAPTION     => $0,
    MINY        => 24,
    MINX        => 80,
    @_ );
  my $mwh = new Curses;
  my @required = qw(MAINFORM);
  my ($y, $x, %forms, $code);
  my ($my, $ml) = (0, 0);
  my $err = 0;
  my $main;

  # Set some defaults
  $self->{CONF} = {%conf};
  $self->{FORMS} = {};
  $self->{FORMDEFS} = {};

	# Check for required arguments
	foreach (@required) { $err = 1 unless exists $conf{$_} };
  unless ($err == 0) {
    carp ref($self), ":  Required fields not passed";
    return 0;
  }

  # Save the handle to stdscr
  $self->{MWH} = $mwh;
  pushwh($mwh);

  # Get and store the max X and Y
  $mwh->getmaxyx($y, $x);
  $self->{MAX} = [$y, $x];

  # Return an error if MINY and MINX aren't met
  unless ($y >= $conf{MINY} && $x >= $conf{MINX}) {
    carp ref($self), ":  Minimum screen size not satisfied!";
    return 0;
  }

  # Set up the session
  noecho();         # Turn off input echoing
  halfdelay(1);     # Turn on partial blocking uncooked input
  curs_set(0);      # Turn off visible cursor
  $mwh->keypad(1);  # Turn on keypad support for special keys
  $mwh->syncok(1);  # Sync sub/derwins up to mainwin

  # Read the forms from main
  $code = join('', <main::DATA>);
  close(main::DATA);
  unless (eval $code) {
    carp ref($self), ":  Eval of main::DATA failed!";
    return 0;
  }

  # Get geometry for the main form
  $ml = $y;
  $my = 0;
  if ($conf{TITLEBAR}) {
    --$ml;
    ++$my;
  }
  --$ml if $conf{STATUSBAR};

  # Set size of MAINFORM
  $main = (keys %{$conf{MAINFORM}})[0];
  $forms{$conf{MAINFORM}{$main}} = {
    %{$forms{$conf{MAINFORM}{$main}}},
    Y       => $my,
    X       => 0,
    LINES   => $ml,
    COLUMNS => $x,
    DERIVED => 1,
    };

  # Save the form defs, adjusting the colours, if neccessary
  foreach (keys %forms) { $self->addFormDef($_, $forms{$_}) };

  # Set the window foreground/background colours if specified
  if ($conf{FOREGROUND} && $conf{BACKGROUND}) {
    $mwh->bkgdset(COLOR_PAIR(
      select_colour($conf{FOREGROUND}, $conf{BACKGROUND})));
  }

  # Make sure no errors are returned by the parent method
  $err = 1 unless $self->SUPER::_conf(%conf);

  # Initialise window
  $self->_init($mwh);

  return $err == 1 ? 0 : 1;
}

=head2 maxyx

  ($y, $x) = $app->maxyx;

Returns the maximum Y and X coordinates for the screen.

=cut

sub maxyx {
  my $self = shift;

  return @{$self->{MAX}};
}

=head2 mwh

  $mwh = $app->mwh;

Returns a handle to the curses window handle.

=cut

sub mwh {
  my $self = shift;

  return $self->{MWH};
}

=head2 titlebar

  $app->titlebar($newcaption);

This method updates the application caption used in the titlebar and
immediately updates screen with a refresh.  If you'd prefer to have it updated
at the next application refresh (such as the next B<draw> method call) you
should use the B<setField> method instead, and update the B<CAPTION> field.

=cut

sub titlebar {
  my $self = shift;
  my $caption = shift;
  my $conf = $self->{CONF};

  $$conf{CAPTION} = $caption;
  $self->_titlebar;
  $self->{MWH}->refresh;
}

sub _titlebar {
  my $self = shift;
  my $mwh = $self->{MWH};
  my $enabled = $self->{CONF}->{TITLEBAR};
  my $caption = $self->{CONF}->{CAPTION};

  if ($enabled) {
    $mwh->standout;
    $mwh->addstr(0, 0, $caption . ' ' x ($COLS - length($caption)));
    $mwh->standend;
  }
}

=head2 statusbar

  $app->statusbar($message);

This method updates the statusbar message and immediately updates screen with 
a refresh.  If you'd prefer to have it updated at the next application 
refresh (such as the next B<draw> method call) you should use the 
B<setField> method instead, and update the B<MESSAGE> field.

=cut

sub statusbar {
  my $self = shift;
  my $message = shift;
  my $conf = $self->{CONF};

  $$conf{MESSAGE} = $message;
  $self->_statusbar;
  $self->{MWH}->refresh;
}

sub _statusbar {
  my $self = shift;
  my $mwh = $self->{MWH};
  my $enabled = $self->{CONF}->{STATUSBAR};
  my $message = $self->{CONF}->{MESSAGE};
  my ($y, $x);

  if ($enabled) {
    $mwh->getmaxyx($y, $x);
    $mwh->standout;
    $mwh->addstr($y - 1, 0, $message . ' ' x ($COLS - length($message)));
    $mwh->standend;
  }
}

=head2 draw

  $app->draw;

Flushes all screen changes to the terminal.

=cut

sub draw {
  my $self = shift;
  my $mwh = $self->{MWH};
  my $conf = $self->{CONF};

  $self->_titlebar;
  $self->_statusbar;
  $mwh->refresh;
}

=head2 redraw

  $app->redraw;

Redraws the entire screen.

=cut

sub redraw {
  my $self = shift;
  my $mwh = $self->{MWH};

  $mwh->touchwin;
  $mwh->refresh;
}

=head2 addFormDef

  $app->addFormDef('MyForm', { %formopts });

Adds another form definition to the current library.  Returns a true if
successful, and a false if not (such as if the form type requested is provided
by an unavailable module).

=cut

sub addFormDef {
  my $self = shift;
  my $name = shift;
  my $options = shift;
  my $type = $$options{TYPE} || '';
  my $forms = $self->{FORMDEFS};
  my @try = ('Curses::Forms');
  my $conf = $self->{CONF};
  my ($altf, $altw) = @$conf{qw(ALTFBASE ALTBASE)};
  my $success = 0;
  my ($base, $mod);

  # Get the alt forms base class, if specified
  if (defined $altf) {
    if (ref($altf) eq 'ARRAY') {
      unshift @try, @$altf;
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
  if (exists $$forms{$name}) {
    carp ref($_), ":  A form def named $name is already in the hash!";
    return 0;
  }

  # Store the form def after updating few options
  $$options{INPUTFUNC} = $$conf{INPUTFUNC};
  $$options{MODULE} = $mod;
  foreach (@colitems) {
    $$options{$_} = $$conf{$_} if
      (exists $$conf{$_} && ! exists $$options{$_});
  }
  $$forms{$name} = { ALTFBASE => $altf, ALTBASE => $altw, %$options };

  return 1;
}

=head2 createForm

  $app->createForm($name, $def);

Creates a form object based on the named definition.  Returns a handle to the
form if successful, and a false if not.

=cut

sub createForm {
  my $self = shift;
  my $name = shift;
  my $def = shift;
  my $forms = $self->{FORMS};
  my $defs = $self->{FORMDEFS};
  my ($type, $options);

  # Saftey checks
  unless (exists $$defs{$def}) {
    carp ref($self), ":  No form def exists by that name ($name)!";
    return 0;
  }
  if (exists $$forms{$name}) {
    carp ref($self), ":  A form by the name of $name already exists!";
    return 0;
  }

  # Create and store the form
  {
    no strict 'refs';
    $type = $$defs{$def}{MODULE};
    $options = $$defs{$def};
    unless ($$forms{$name} = "$type"->new($options)) {
      carp ref($self), ":  $type creation failed!";
      return 0;
    }

    # Reference event subs under form space
    foreach (@events) {
      $$forms{$name}->{$_} = $$options{$_} if exists $$options{$_};
    }
  }

  return $$forms{$name};
}

=head2 getForm

  $form = $app->getForm('MainFrm');

Returns a handle to the specified form.  If that form does not exist, the
object generates a warning and returns undef.

=cut

sub getForm {
  my $self = shift;
  my $name = shift;
  my $forms = $self->{FORMS};

  if (exists $$forms{$name}) {
    return $$forms{$name};
  } else {
    carp ref($self), ":  No form by the name $name exists!";
    return undef;
  }
}

=head2 delForm

  $app->delForm('Main');

Deletes the form object by that name.

=cut

sub delForm {
  my $self = shift;
  my $name = shift;
  my $forms = $self->{FORMS};

  unless (exists $$forms{$name}) {
    carp ref($self), ":  No form by that name ($name) exists to be deleted!";
    return 0;
  }

  delete $$forms{$name};
  return 1;
}

=head2 execForm

  $app->execForm('Main');

Executes the form specified by name.  This form must be created beforehand via
the B<createForm> method.  Returns the return value of the form's B<execute>
method.

=cut

sub execForm {
  my $self = shift;
  my $name = shift;
  my $forms = $self->{FORMS};
  my ($f, $rv);

  unless (exists $$forms{$name}) {
    carp ref($self), ":  No form ($name) available to execute!";
    return 0;
  }

  $f = $$forms{$name};

  # Call the OnEnter routine if present
  &{$f->{OnEnter}}($self) if defined $f->{OnEnter};

  # Execute the form
  $rv = $f->execute($self->mwh);

  # Call the OnExit routine if present
  &{$f->{OnExit}}($self) if defined $f->{OnExit};

  return $rv;
}

=head2 execute

  $app->execute;

Causes the main form to execute.  Once the main form exits, this call will
exit as well.

=cut

sub execute {
  my $self = shift;
  my $conf = $self->{CONF};
  my $forms = $self->{FORMS};
  my $main;

  # Get the main form name
  $main = (keys %{$$conf{MAINFORM}})[0];

  # Create it if necessary
  unless (exists $$forms{$main}) {
    $self->createForm($main, $$conf{MAINFORM}{$main});
  }

  # Execute it
  $self->execForm($main);
}

sub DESTROY {
  # This routines resets the console to the previous sane state
  # before the application began.
  #
  # Internal use only.

  my $self = shift;

  popwh();
  endwin();
}

1;

=head1 HISTORY

=over

=item 2002/11/12 - Initial release.

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

