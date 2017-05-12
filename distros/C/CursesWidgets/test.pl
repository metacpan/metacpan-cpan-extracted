#!/usr/bin/perl -w
#
# Simple script that demonstrates the uses of Curses::Widgetss
#
# $Id: test.pl,v 1.104 2002/11/14 01:36:48 corliss Exp corliss $
#

use strict;
use Curses;
use Curses::Widgets;  # Included to import select_colour & scankey
use Curses::Widgets::TextField;
use Curses::Widgets::ButtonSet;
use Curses::Widgets::ProgressBar;
use Curses::Widgets::TextMemo;
use Curses::Widgets::ListBox;
use Curses::Widgets::Calendar;
use Curses::Widgets::ComboBox;
use Curses::Widgets::Menu;
use Curses::Widgets::Label;

#####################################################################
#
# Set up the environment
#
#####################################################################

my ($mwh, $key, $i, $p);
my (@widgets, @descriptions);

#####################################################################
#
# Program Logic starts here
#
#####################################################################

# Unless specifically noted, most functions are provided by the Curses
# package, *not* Curses::Widgets.  See the pod for Curses for more
# information on the functions.  Additional information is available
# with the (n)Curses man pages (section 3), if you have them.
$mwh = new Curses;
noecho();
halfdelay(5);
$mwh->keypad(1);
$mwh->syncok(1);
curs_set(0);
leaveok(1);

# Draw the main window, and wait for a key press (the scankey
# function is imported from the Curses::Widgets module)
main_win();
comment_box(<< '__EOF__');
Welcome to the Curses::Widgets Test Script!

Press any key to begin.
__EOF__
$key = scankey($mwh);


# Create each of the widgets beforehand
$widgets[0] = Curses::Widgets::Menu->new({
  FOREGROUND  => 'white',
  BACKGROUND  => 'green',
  BORDER      => 1,
  CURSORPOS => [qw(File)],
  MENUS       => {
    MENUORDER   => [qw(File Help)],
    File        => {
      ITEMORDER => [qw(Open Save Exit)],
      Open      => sub { 1 },
      Save      => sub { 1 },
      Exit      => sub { exit 0 },
      },
    Help        => {
      ITEMORDER => [qw(Help About)],
      Help      => sub { 1 },
      About     => sub { 1 },
      },
    },
  
  });
$descriptions[0] = << '__EOF__';
Curses::Widgets::Menu -- Menus

Use the arrow keys to navigate, and <ESC> to exit a menu without selecting anything.  Use <TAB> to move to the next widget.
__EOF__

$widgets[1] = Curses::Widgets::ButtonSet->new({
  Y           => 2,
  X           => 2,
  FOREGROUND  => 'white',
  BACKGROUND  => 'black',
  BORDER      => 0,
  LABELS      => [ qw( OK CANCEL HELP ) ],
  LENGTH      => 8,
  HORIZONTAL  => 1,
  });
$descriptions[1] = << '__EOF__';
Curses::Widgets::ButtonSet -- Horizontal set without borders.

Use the arrow keys to navigate among the buttons, and press <RETURN> or <TAB> to move to the next widget (set).
__EOF__

$widgets[2] = Curses::Widgets::ButtonSet->new({
  Y           => 3,
  X           => 1,
  FOREGROUND  => 'white',
  BACKGROUND  => 'blue',
  BORDER      => 1,
  LABELS      => [ qw( Button1 Button2 Button3 Quit ) ],
  LENGTH      => 9,
  HORIZONTAL  => 0,
  });
$descriptions[2] = << '__EOF__';
Curses::Widgets::ButtonSet -- Vertical set with borders.

Use the arrow keys to navigate among the buttons, and press <RETURN> or <TAB> to move to the next widget (set).
__EOF__

$widgets[3] = Curses::Widgets::TextField->new({
  Y           => 4,
  X           => 14,
  COLUMNS     => 20,
  MAXLENGTH   => 30,
  FOREGROUND  => 'green',
  BACKGROUND  => 'blue',
  VALUE       => 'Test Value',
  BORDERCOL   => 'black',
  BORDER      => 1,
  CAPTION     => 'Test Field',
  CAPTIONCOL  => 'yellow',
  });
$descriptions[3] = << '__EOF__';
Curses::Widgets::TextField -- Text field with a border and caption.

Press <RETURN> or <TAB> to move to the next widget (set).
__EOF__

$widgets[4] = Curses::Widgets::ProgressBar->new({
  Y           => 7,
  X           => 14,
  LENGTH      => 20,
  FOREGROUND  => 'yellow',
  BACKGROUND  => 'green',
  BORDER      => 1,
  BORDERCOL   => 'black',
  CAPTION     => 'Progress',
  CAPTIONCOL  => 'white',
  });
$descriptions[4] = << '__EOF__';
Curses::Widgets::ProgressBar -- Horizontal progress bar with border.

Please wait until the bar progresses to 100%.
__EOF__

$p = << "__EOF__";
This is an example memo that uses the Widgets class textwrap function to split
according to whitespace and column limits.
__EOF__

$widgets[5] = Curses::Widgets::TextMemo->new({
  Y           => 10,
  X           => 14,
  COLUMNS     => 20,
  FOREGROUND  => 'green',
  BACKGROUND  => 'blue',
  VALUE       => $p,
  BORDERCOL   => 'black',
  BORDER      => 1,
  CAPTION     => 'Test Memo',
  CAPTIONCOL  => 'yellow',
  });
$descriptions[5] = << '__EOF__';
Curses::Widgets::TextMemo -- Text memo with a border and caption.

Press <RETURN> or <TAB> to move to the next widget (set).
__EOF__

$widgets[6] = Curses::Widgets::ListBox->new({
  Y           => 2,
  X           => 38,
  COLUMNS     => 20,
  LISTITEMS   => ['Ham', 'Eggs', 'Cheese', 'Hash Browns', 'Toast'],
  MULTISEL    => 1,
  VALUE       => [0, 2],
  SELECTEDCOL => 'green',
  CAPTION     => 'List Box',
  CAPTIONCOL  => 'yellow',
  });
$descriptions[6] = << '__EOF__';
Curses::Widgets::ListBox -- This list box supports multiple and single selection modes.  Use <SPACE> or <RETURN> to toggle a selection.

Press <TAB> to move to the next widget (set).
__EOF__

$widgets[7] = Curses::Widgets::Calendar->new({
  Y             => 7,
  X             => 38,
  FOREGROUND    => 'black',
  BACKGROUND    => 'white',
  BORDER        => 1,
  CAPTION       => 'Appointments',
  CAPTIONCOL    => 'blue',
  HIGHLIGHT     => [1, 5, 17, 26],
  HIGHLIGHTCOL  => 'green',
  HEADERCOL     => 'red',
  });
$descriptions[7] = << '__EOF__';
Curses::Widgets::Calendar -- This calendar supports date highlighting and broad navigation capabilities.

Press <TAB> to move to the next widget (set).
__EOF__

$widgets[8] = Curses::Widgets::ComboBox->new({
  Y           => 3,
  X           => 62,
  FOREGROUND  => 'white',
  BACKGROUND  => 'red',
  LISTITEMS   => [qw(Mr. Mrs. Ms.)],
  COLUMNS     => 4,
  BORDER      => 1,
  });
$descriptions[8] = << '__EOF__';
Curses::Widgets::ComboBox -- This is a text field that also has a drop-down list to select values from.  Just press the down arrow.

Press <TAB> to move to the next widget (set).
__EOF__

# Draw each of the widgets
foreach (@widgets) { $_->draw($mwh) };
comment_box();

# Interactively demonstrate each widget
for ($i = 0; $i < scalar @widgets; $i++) { 
  comment_box($descriptions[$i]);
  if (ref($widgets[$i]) !~ /Progress/) {
    $widgets[$i]->execute($mwh);
    $widgets[$i]->draw($mwh);
  } else {
    while ($widgets[$i]->getField('VALUE') <
      $widgets[$i]->getField('MAX')) {
      $widgets[$i]->input(30);
      $widgets[$i]->draw($mwh);
      sleep 1;
    }
  }
}

# Label description
comment_box(<< '__EOF__');
This comment box has been demonstrating the use of the Curses::Widgets::Label.  Labels support left, centered, and right alignments, and with and without borders.

Press any key to continue.
__EOF__
scankey($mwh);

# Parting comments
comment_box(<< '__EOF__');
This concludes the Curses::Widgets demonstration.  Please send all comments, suggestions, criticisms, and bug reports to corliss@digitalmages.com.

Press any key to exit.
__EOF__
scankey($mwh);

exit 0;

END {
  # The END block just ensures that Curses always cleans up behind
  # itself
  endwin();
}

exit 0;

#####################################################################
#
# Subroutines follow here
#
#####################################################################

sub main_win {

  $mwh->erase();

  # This function selects a few common colours for the foreground colour
  $mwh->attrset(COLOR_PAIR(select_colour(qw(red black))));
  $mwh->box(ACS_VLINE, ACS_HLINE);
  $mwh->attrset(0);

  $mwh->standout();
  $mwh->addstr(0, 1, "Welcome to the Curses::Widgets " .
    "v${Curses::Widgets::VERSION} Demo!");
  $mwh->standend();
}

sub comment_box {
  my $message = shift;
  my ($cwh, $y, $x, @lines, $i, $line);
  my $label;

  # Get the main screen max y & X
  $mwh->getmaxyx($y, $x);

  # Render the comment box
  $label = Curses::Widgets::Label->new({
    CAPTION     => 'Comments',
    BORDER      => 1,
    LINES       => 5,
    COLUMNS     => $x - 4,
    Y           => $y - 8,
    X           => 1,
    VALUE       => $message,
    FOREGROUND  => 'white',
    BACKGROUND  => 'blue',
    });
  $label->draw($mwh);
}
