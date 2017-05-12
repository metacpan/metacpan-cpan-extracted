#!/usr/bin/perl -w
#
# test.pl -- Curses::Application test script
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: test.pl,v 0.1 2002/11/14 19:40:15 corliss Exp corliss $
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

use strict;
use vars qw($VERSION);
use Curses::Application;

#####################################################################
#
# Set up the environment
#
#####################################################################

($VERSION) = (q$Revision: 0.1 $ =~ /(\d+(?:\.(\d+))+)/) || '0.1';

my $app = Curses::Application->new({
  FOREGROUND    => 'white',
  BACKGROUND    => 'blue',
  CAPTIONCOL    => 'yellow',
  TITLEBAR      => 1,
  CAPTION       => "Curses::Application Test Application v$VERSION",
  MAINFORM      => { Main  => 'MainFrm' },
  INPUTFUNC     => \&myscankey,
  });
my ($rv, $user, $psswd, $f, $w);

# E-mail database:  each record is key ("Last, First") and hash ref
# (keys Last First E-mail City State)
my %records = (
  'Doe, John'         => {
    Last      => 'Doe',
    First     => 'John',
    'E-mail'  => 'john.doe@foo.com',
    City      => 'Somewhere',
    State     => 'NJ',
    },
  'Blow, Joe'         => {
    Last      => 'Blow',
    First     => 'Joe',
    'E-mail'  => 'joe.blow@bar.com',
    City      => 'New York City',
    State     => 'NY',
    },
  'Corliss, Arthur'   => {
    Last      => 'Corliss',
    First     => 'Arthur',
    'E-mail'  => 'corliss@digitalmages.com',
    City      => 'Anchorage',
    State     => 'AK',
    },
  );

#####################################################################
#
# Program Logic starts here
#
#####################################################################

# Draw the main screen
$app->draw;

# Present the logon screen
($rv, $user, $psswd) = logon('User Logon', BTN_OK | BTN_CANCEL,
  20, qw(white red yellow));

# Exit if the logon was canceled
if ($rv) {
  dialog('Canceled!', BTN_OK, 'Exiting application!', qw(white red yellow));
  exit 0;
}

# Welcome the user
dialog('Welcome!', BTN_OK, "Welcome to the test application, $user!  " .
  "Let's pretend you actually logged in.  ;-)", qw(white green yellow));

# Create the MainFrm early, since we need to adjust a few parameters
# of the ListBox and Label
$app->createForm(qw(Main MainFrm));
$w = $app->getForm('Main')->getWidget('People');
$w->setField(
  LINES       => ($app->maxyx)[0] - 7,
  LISTITEMS   => [map { [split(', ', $_)] } sort keys %records],
  );
$w = $app->getForm('Main')->getWidget('Message');
$w->setField(VALUE => << '__EOF__');
Use <ESC> to cancel the drop-down menu, <TAB> to move among the widgets, and <ENTER> to select a person's record from the list.  Arrow keys are used to select different buttons and/or menus.
__EOF__

# Start the input loop
$app->execute;

exit 0;

#####################################################################
#
# Subroutines follow here
#
#####################################################################

sub myscankey {
  my $mwh = shift;
  my $key = -1;

  while ($key eq -1) {
    clock();
    $key = $mwh->getch
  };

  return $key;

}

sub clock {
  my $time = scalar localtime;
  my $x = ($app->maxyx)[1] - length($time);
  my $caption = substr($app->getField('CAPTION'), 0, $x);

  $caption .= ' ' x ($x - length($caption)) . $time;
  $app->setField(CAPTION => $caption);
  $app->draw;
}

sub save {
  dialog('Save Database', BTN_OK, 'I would, but that\'s really a lot ' .
    'more work than I want to do for a demo.  ;-)', qw(white green yellow));
}

sub quit {
  $rv = dialog('Quit Application?', BTN_YES | BTN_NO, 
    'Are you sure you want to quit?', qw(white red yellow));
  exit 0 unless ($rv);
}

sub displayrec {
  my $f = shift;
  my $key = shift;
  my ($w, $list, $rec, @items);

  return unless $key =~ /[\n ]/;

  # Get the list box widget to retrieve the select record
  $w = $f->getWidget('People');
  @items = @{$w->getField('LISTITEMS')};
  $rec = $items[$w->getField('CURSORPOS')];
  $rec = join(', ', @$rec[0,1]);

  # Update the form's record fields
  foreach (keys %{$records{$rec}}) {
    $w = $f->getWidget($_);
    $w->setField(VALUE => $records{$rec}{$_});
  }

  # Set the form's DONTSWITCH directive to keep the focus where it is
  $f->setField(DONTSWITCH => 1);
}

sub delrec {
  my $f = $app->getForm('Main');
  my $w = $f->getWidget('People');
  my $rec = ${$w->getField('LISTITEMS')}[$w->getField('CURSORPOS')];

  # Delete the record from the hash and list box
  delete $records{join(', ', @$rec[0,1])};
  $w->setField(
    LISTITEMS => [map { [split(', ', $_)] } sort keys %records]);

  # Reset the form fields
  resetfields($f);
}

sub showaddrec {
  $app->createForm('AddRec', 'AddRecFrm');
  $app->execForm('AddRec');
  $app->delForm('AddRec');
}

sub resetfields {
  my $f = shift;

  # Reset the displayed record field
  foreach (qw(Last First E-mail City State)) {
    $f->getWidget($_)->setField(VALUE => '') };
}

sub addbtns {
  my $f = shift;
  my $key = shift;
  my @fields = qw(Last First E-mail City State);
  my %rec;

  return unless $key =~ /[\n ]/;

  # Close the dialog if the user canceled
  if ($f->getWidget('Buttons')->getField('VALUE') == 1) {
    $f->setField(EXIT => 1);
    return;
  }

  # Get the field values
  foreach (@fields) { $rec{$_} = $f->getWidget($_)->getField('VALUE') };

  # Make sure there's a first and last name
  unless ($rec{Last} && $rec{First}) {
    dialog('Error!', BTN_OK, 'The First & Last Names are required fields!',
      qw(white red yellow));
    return;
  }

  # Save the record and set the dialog to close
  $records{join(', ', @rec{qw(Last First)})} = { %rec };
  $f->setField(EXIT => 1);

  # Update the list box on the main form
  $f = $app->getForm('Main');
  $f->getWidget('People')->setField(
    LISTITEMS => [map { [split(', ', $_)] } sort keys %records]);

  # Reset the form fields
  resetfields($f);
}

__DATA__

%forms = (
  MainFrm     => {
    TABORDER        => [qw(Menu People)],
    FOCUSED         => 'People',
    WIDGETS         => {
      Menu            => {
        TYPE            => 'Menu',
        MENUS           => {
          MENUORDER       => [qw(File Record)],
          File            => {
            ITEMORDER       => [qw(Save Exit)],
            Exit            => \&main::quit,
            Save            => \&main::save,
            },
          Record            => {
            ITEMORDER       => ['Add Record', 'Delete Record'],
            'Add Record'    => \&main::showaddrec,
            'Delete Record' => \&main::delrec,
            },
          },
        },
      People          => {
        TYPE            => 'ListBox::MultiColumn',
        LISTITEMS       => [],
        COLUMNS         => 20,
        LINES           => 10,
        Y               => 2,
        X               => 1,
        COLWIDTHS       => [10, 10],
        HEADERS         => [qw(Last First)],
        BIGHEADER       => 1,
        CAPTION         => 'People',
        FOCUSSWITCH     => "\t\n ",
        OnExit          => \&main::displayrec,
        },
      Last            => {
        TYPE            => 'TextField',
        Y               => 2,
        X               => 24,
        CAPTION         => 'Last Name',
        COLUMNS         => 20,
        },
      First            => {
        TYPE            => 'TextField',
        Y               => 2,
        X               => 46,
        CAPTION         => 'First Name',
        COLUMNS         => 20,
        },
      'E-mail'        => {
        TYPE            => 'TextField',
        Y               => 5,
        X               => 24,
        CAPTION         => 'E-mail',
        COLUMNS         => 42,
        },
      City            => {
        TYPE            => 'TextField',
        Y               => 8,
        X               => 24,
        CAPTION         => 'City',
        COLUMNS         => 38,
        },
      State           => {
        TYPE            => 'TextField',
        Y               => 8,
        X               => 64,
        CAPTION         => 'State',
        COLUMNS         => 2,
        },
      Message         => {
        TYPE            => 'Label',
        CENTER          => 1,
        Y               => 11,
        X               => 26,
        COLUMNS         => 42,
        LINES           => 6,
        ALIGNMENT       => 'C',
        },
      },
    },
  AddRecFrm   => {
    DERIVED         => 0,
    FOREGROUND      => 'white',
    BACKGROUND      => 'green',
    AUTOCENTER      => 1,
    BORDER          => 1,
    LINES           => 12,
    COLUMNS         => 46,
    CAPTION         => 'New Record',
    TABORDER        => [qw(Last First E-mail City State Buttons)],
    FOCUSED         => 'Last',
    WIDGETS         => {
      Buttons         => {
        TYPE            => 'ButtonSet',
        Y               => 9,
        X               => 11,
        LABELS          => [qw(OK Cancel)],
        OnExit          => \&main::addbtns,
        },
      Last            => {
        TYPE            => 'TextField',
        Y               => 0,
        X               => 1,
        CAPTION         => 'Last Name',
        CAPTIONCOL      => 'yellow',
        COLUMNS         => 20,
        },
      First            => {
        TYPE            => 'TextField',
        Y               => 0,
        X               => 23,
        CAPTION         => 'First Name',
        COLUMNS         => 20,
        },
      'E-mail'        => {
        TYPE            => 'TextField',
        Y               => 3,
        X               => 1,
        CAPTION         => 'E-mail',
        COLUMNS         => 42,
        },
      City            => {
        TYPE            => 'TextField',
        Y               => 6,
        X               => 1,
        CAPTION         => 'City',
        COLUMNS         => 38,
        },
      State           => {
        TYPE            => 'TextField',
        Y               => 6,
        X               => 41,
        CAPTION         => 'State',
        COLUMNS         => 2,
        },
      },
    },
  );

