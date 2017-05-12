# Curses::Forms::Dialog.pm -- Curses Forms Dialog
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: Dialog.pm,v 0.4 2002/11/14 19:09:08 corliss Exp corliss $
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

Curses::Forms::Dialog - Curses Forms Dialog

=head1 MODULE VERSION

$Id: Dialog.pm,v 0.4 2002/11/14 19:09:08 corliss Exp corliss $

=head1 SYNOPSIS

	use Curses::Forms::Dialog;

  $rv = dialog('Warning!', BTN_OK, 'You generated and error!', 
    qw(white red yellow));

=head1 REQUIREMENTS

Curses
Curses::Widgets
Curses::Forms

=head1 DESCRIPTION

Provides a single function to displaying flexible dialogs.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Forms::Dialog;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Curses;
use Curses::Forms;
use Exporter;
use Carp;

$VERSION = (q$Revision: 0.4 $ =~ /(\d+(?:\.(\d+))+)/)[0] || '0.1';
@ISA = qw(Curses::Forms);
@EXPORT = qw(dialog BTN_OK BTN_CANCEL BTN_YES BTN_NO BTN_HELP);

use constant BTN_OK     => 1;
use constant BTN_YES    => 2;
use constant BTN_NO     => 4;
use constant BTN_CANCEL => 8;
use constant BTN_HELP   => 16;

########################################################################
#
# Module code follows. . .
#
########################################################################

=head1 FUNCTIONS

=head2 dialog

  $rv = dialog('Warning!', BTN_OK, 'You generated and error!', 
    qw(white red yellow));

This function displays a dialog with the specified title, buttons, and
message.  The following constants are defined for specifying buttons, and can
be or'ed to provide multiple choices:

  BTN_OK
  BTN_YES
  BTN_NO
  BTN_CANCEL
  BTN_HELP

The buttons will always be displayed in the order shown above, and is not
modifiable.  The remaining optional arguments are the desired colours for the
foreground, background, and caption colour, respectively.

The return value of the dialog will be the index value of the chosen button,
as one would normally recieve from the Curses::Widgets::ButtonSet widget.

This function can handle multi-line messages with embedded newlines, as long
as the number of lines doesn't cause the dialog to be too large to display as
a whole on the screen.  It uses the textwrap function from Curses::Widgets to
split lines longer than the screen according to whitespace.

=cut

sub dialog {
  my $title = shift;
  my $buttons = shift;
  my $message = shift;
  my ($fg, $bg, $cfg) = @_;
  my ($form, @lines, @buttons, $max);
  my ($cols, $lines, $bx, $by);

  # Build array of buttons to display
  push(@buttons, 'OK') if $buttons & BTN_OK;
  push(@buttons, 'Yes') if $buttons & BTN_YES;
  push(@buttons, 'No') if $buttons & BTN_NO;
  push(@buttons, 'Cancel') if $buttons & BTN_CANCEL;
  push(@buttons, 'Help') if $buttons & BTN_HELP;

  unless (@buttons) {
    carp "dialog:  No buttons specified for dialog!";
    return 0;
  }

  # Calculate the necessary dimensions of the message box, based
  # on both the button(s) and the length of the message.
  $max = 10 * @buttons + 2 * $#buttons;
  @lines = textwrap($message, $COLS - 4);
  foreach (@lines) { $max = length($_) if length($_) > $max };

  # Calculate cols and lines
  $cols = $max;
  $lines = @lines + 3;

  # Exit if the geometry exceeds the display
  unless ($cols + 2 < $COLS && $lines + 2 < $LINES) {
    carp "dialog:  Calculated geometry exceeds display geometry!";
    return 0;
  }

  # Calculate upper-left corner of the buttons
  $bx = 10 * @buttons + 2 * $#buttons;
  $bx = int(($cols - $bx) / 2);
  $by = $lines - 3;

  local *btnexit = sub {
    my $f = shift;
    my $key = shift;

    return unless $key eq "\n";
    $f->setField(EXIT => 1);
  };

  $form = Curses::Forms->new({
    AUTOCENTER    => 1,
    DERIVED       => 0,
    COLUMNS       => $cols,
    LINES         => $lines,
    CAPTION       => $title,
    CAPTIONCOL    => $cfg,
    BORDER        => 1,
    FOREGROUND    => $fg,
    BACKGROUND    => $bg,
    FOCUSED       => 'Buttons',
    TABORDER      => ['Buttons'],
    WIDGETS       => {
      Buttons     => {
        TYPE      => 'ButtonSet',
        LABELS    => [@buttons],
        Y         => $by,
        X         => $bx,
        FOREGROUND    => $fg,
        BACKGROUND    => $bg,
        BORDER    => 1,
        OnExit    => *btnexit,
        },
      Label       => {
        TYPE      => 'Label',
        Y         => 0,
        X         => 0,
        COLUMNS   => $max,
        LINES     => scalar @lines,
        VALUE     => $message,
        FOREGROUND    => $fg,
        BACKGROUND    => $bg,
        },
      },
    });
  $form->execute;

  return $form->getWidget('Buttons')->getField('VALUE');
}

1;

=head1 HISTORY

=over

=item 2002/10/10 -- Rewritten in OO form.

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com)

=cut

