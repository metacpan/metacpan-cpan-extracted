# Curses::Forms::Dialog::Input.pm -- Curses Forms Input Dialog
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Input.pm,v 0.4 2002/11/04 01:06:35 corliss Exp corliss $
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

Curses::Forms::Dialog::Input - Curses Forms Input Dialog

=head1 MODULE VERSION

$Id: Input.pm,v 0.4 2002/11/04 01:06:35 corliss Exp corliss $

=head1 SYNOPSIS

	use Curses::Forms::Dialog::Input;

  ($rv, $text) = input('Input Parameter!', BTN_OK | BTN_CANCEL, 
    'Search String', 20, qw(white red yellow));

=head1 REQUIREMENTS

Curses
Curses::Widgets
Curses::Forms
Curses::Forms::Dialog

=head1 DESCRIPTION

Provides a single function to displaying single field input dialogs.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Forms::Dialog::Input;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Curses;
use Curses::Forms;
use Curses::Forms::Dialog;
use Exporter;
use Carp;

$VERSION = (q$Revision: 0.4 $ =~ /(\d+(?:\.(\d+))+)/)[0] || '0.1';
@ISA = qw(Curses::Forms Curses::Forms::Dialog Exporter);
@EXPORT = qw(input BTN_OK BTN_CANCEL BTN_HELP);

########################################################################
#
# Module code follows. . .
#
########################################################################

=head1 FUNCTIONS

=head2 input

  ($rv, $text) = input('Input Parameter!', BTN_OK | BTN_CANCEL, 
    'Search String', 20, qw(white red yellow));

This function displays an input dialog with the specified title, buttons, and
field caption.  The following constants are defined for specifying buttons, 
and can be or'ed to provide multiple choices:

  BTN_OK
  BTN_CANCEL
  BTN_HELP

The remaining arguments is the max string length and the desired colours
(foreground, background, and caption colour).

The return value of the dialog will be the index value of the chosen button,
as one would normally recieve from the Curses::Widgets::ButtonSet widget, and
the string value of the TextField widget.

=cut

sub input {
  my $title = shift;
  my $buttons = shift;
  my $caption = shift;
  my $limit = shift || 20;
  my ($fg, $bg, $cfg) = @_;
  my ($form, @buttons, $rv, $max);
  my ($cols, $lines, $bx, $fx);

  # Build array of buttons to display
  push(@buttons, 'OK') if $buttons & BTN_OK;
  push(@buttons, 'Cancel') if $buttons & BTN_CANCEL;
  push(@buttons, 'Help') if $buttons & BTN_HELP;

  unless (@buttons) {
    carp "dialog:  No buttons specified for dialog!";
    return 0;
  }

  # Calculate the necessary dimensions of the message box, based
  # on both the button(s) and the length of the TextField.
  $max = 10 * @buttons + 2 * $#buttons;
  $max = $max > 23 ? $max : 23;

  # Calculate cols and lines
  $cols = $max + 2;
  $lines = 6;

  # Exit if the geometry exceeds the display
  unless ($cols + 2 < $COLS && $lines + 2 < $LINES) {
    carp "dialog:  Calculated geometry exceeds display geometry!";
    return 0;
  }

  # Calculate upper-left corners
  $bx = 10 * @buttons + 2 * $#buttons;
  $bx = int(($cols - $bx) / 2);
  $fx  = int(($cols - 23) / 2);

  local *btnexit = sub {
    my $f = shift;
    my $key = shift;

    if ($key eq "\e") {
      $key = chop $key;
      if ($key =~ /^f$/i) {
        $f->setField(FOCUSED => 'Buttons');
      } elsif ($key =~ /^b$/i) {
        $f->setField(FOCUSED => 'TextField');
      }
      return;
    }

    return unless $key eq "\n";
    $f->setField(EXIT => 1);
  };

  $form = Curses::Forms::Dialog::Input->new({
    AUTOCENTER    => 1,
    DERIVED       => 0,
    COLUMNS       => $cols,
    LINES         => $lines,
    CAPTION       => $title,
    CAPTIONCOL    => $cfg,
    BORDER        => 1,
    FOREGROUND    => $fg,
    BACKGROUND    => $bg,
    FOCUSED       => 'TextField',
    TABORDER      => [qw(TextField Buttons)],
    WIDGETS       => {
      TextField   => {
        TYPE      => 'TextField',
        CAPTION   => $caption,
        CAPTIONCOL=> $cfg,
        Y         => 0,
        X         => $fx,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        COLUMNS   => 21,
        MAXLENGTH => $limit,
        },
      Buttons     => {
        TYPE      => 'ButtonSet',
        LABELS    => [@buttons],
        Y         => 3,
        X         => $bx,
        BORDER    => 1,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        OnExit    => *btnexit,
        },
      },
    });
  $form->execute;

  return ($form->getWidget('Buttons')->getField('VALUE'),
    $form->getWidget('TextField')->getField('VALUE'));
}

1;

=head1 HISTORY

2002/10/10 -- Rewritten in OO form.

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

