#!/usr/bin/perl -w
#
# test.pl -- Curses::Forms test script
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: test.pl,v 0.4 2002/11/14 18:26:22 corliss Exp corliss $
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
use Curses;
use Curses::Forms;
use Curses::Forms::Dialog;
use Curses::Forms::Dialog::Input;
use Curses::Forms::Dialog::Logon;

use vars qw($VERSION);

#####################################################################
#
# Set up the environment
#
#####################################################################

($VERSION) = (q$Revision: 0.4 $ =~ /(\d+(?:\.(\d+))+)/) || '0.1';

my $mwh = new Curses;
my %widgets = (
  btnOKCancel   => {
    TYPE        => 'ButtonSet',
    LABELS      => [qw(OK Cancel Quit)],
    Y           => 3,
    X           => 1,
    FOREGROUND  => 'white',
    BACKGROUND  => 'green',
    OnExit      => \&btns,
    },
  edtStatus     => {
    TYPE        => 'TextField',
    FOREGROUND  => 'white',
    BACKGROUND  => 'blue',
    CAPTION     => 'Event Triggered',
    CAPTIONCOL  => 'yellow',
    COLUMNS     => 21,
    Y           => 0,
    X           => 6,
    },
  );
my $form = Curses::Forms->new({
  COLUMNS     => 36,
  LINES       => 6,
  BORDER      => 1,
  BORDERCOL   => 'white',
  FOREGROUND  => 'white',
  BACKGROUND  => 'blue',
  CAPTION     => 'Derived Test Form',
  CAPTIONCOL  => 'yellow',
  WIDGETS     => \%widgets,
  TABORDER    => [qw(btnOKCancel)],
  FOCUSED     => 'btnOKCancel',
  DERIVED     => 1,
  X           => 2,
  Y           => 2,
  });
my $form2 = Curses::Forms->new({
  COLUMNS     => 36,
  LINES       => 6,
  BORDER      => 1,
  BORDERCOL   => 'white',
  FOREGROUND  => 'white',
  BACKGROUND  => 'blue',
  CAPTION     => 'Newwin Test Form 2',
  CAPTIONCOL  => 'yellow',
  WIDGETS     => \%widgets,
  TABORDER    => [qw(btnOKCancel)],
  FOCUSED     => 'btnOKCancel',
  Y           => 5,
  X           => 10,
  DERIVED     => 0,
  });
my ($message, $rv);

#####################################################################
#
# Program Logic starts here
#
#####################################################################

noecho();
halfdelay(5);
$mwh->keypad(1);
curs_set(0);

pushwh($mwh);

$form->execute($mwh);
$form2->execute($mwh);

$message = << '__EOF__';
This is a really long test of the dialog's ability to split lines and calculate geometry appropriately.  Hopefully, if there's bugs in the routines, we'll find them here.

In any event, it was fun trying.  ;-)
__EOF__

dialog('Return Value', BTN_OK, 
  "Return value was:  " . 
  dialog('Test Dialog', BTN_OK | BTN_CANCEL | BTN_YES | BTN_NO, $message, 
  qw(white red yellow)), qw(white green yellow));

($rv, $message) = input('Input Value', BTN_OK | BTN_CANCEL, 'Name', 20,
  qw(white blue yellow));
dialog('Return Value', BTN_OK, "You type '$message', and hit button $rv!",
  qw(white green yellow));

logon('System Logon', BTN_OK | BTN_CANCEL, 20, qw(black yellow red));

popwh();

exit 0;

#####################################################################
#
# Subroutines follow here
#
#####################################################################

END {
  endwin();
}

sub btns {
  my $form = shift;
  my $key = shift;
  my $w = $form->getWidget('btnOKCancel');

  if ($w->getField('VALUE') == 0) {
    $form->getWidget('edtStatus')->setField(VALUE => "Pushed OK button!");
  } elsif ($w->getField('VALUE') == 1) {
    $form->getWidget('edtStatus')->setField(VALUE => 
      "Pushed Cancel button!");
  } else {
    $form->setField(EXIT => 1);
  }
}
