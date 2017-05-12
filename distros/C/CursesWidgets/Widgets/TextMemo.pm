# Curses::Widgets::TextMemo.pm -- Text Memo Widgets
#
# (c) 2001, Arthur Corliss <corliss@digitalmages.com>
#
# $Id: TextMemo.pm,v 1.104 2002/11/14 01:27:31 corliss Exp corliss $
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

Curses::Widgets::TextMemo - Text Memo Widgets

=head1 MODULE VERSION

$Id: TextMemo.pm,v 1.104 2002/11/14 01:27:31 corliss Exp corliss $

=head1 SYNOPSIS

  use Curses::Widgets::TextMemo;

  $tm = Curses::Widgets::TextMemo->new({
    CAPTION       => 'Memo',
    CAPTIONCOL    => 'blue',
    COLUMNS       => 10,
    MAXLENGTH     => undef,
    LINES         => 3,
    MASK          => undef,
    VALUE         => '',
    INPUTFUNC     => \&scankey,
    FOREGROUND    => 'white',
    BACKGROUND    => 'black',
    BORDER        => 1,
    BORDERCOL     => 'red',
    FOCUSSWITCH   => "\t",
    CURSORPOS     => 0,
    TEXTSTART     => 0,
    PASSWORD      => 0,
    X             => 1,
    Y             => 1,
    READONLY      => 0,
    });

  $tm->draw($mwh, 1);

  See the Curses::Widgets pod for other methods.

=head1 REQUIREMENTS

=over

=item Curses

=item Curses::Widgets

=back

=head1 DESCRIPTION

Curses::Widgets::TextMemo provides simplified OO access to Curses-based
single line text fields.  Each object maintains its own state information.

=cut

#####################################################################
#
# Environment definitions
#
#####################################################################

package Curses::Widgets::TextMemo;

use strict;
use vars qw($VERSION @ISA);
use Carp;
use Curses;
use Curses::Widgets;

($VERSION) = (q$Revision: 1.104 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets);

#####################################################################
#
# Module code follows
#
#####################################################################

=head1 METHODS

=head2 new (inherited from Curses::Widgets)

  $tm = Curses::Widgets::TextMemo->new({
    CAPTION       => 'Memo',
    CAPTIONCOL    => 'blue',
    COLUMNS       => 10,
    MAXLENGTH     => undef,
    LINES         => 3,
    MASK          => undef,
    VALUE         => '',
    INPUTFUNC     => \&scankey,
    FOREGROUND    => 'white',
    BACKGROUND    => 'black',
    BORDER        => 1,
    BORDERCOL     => 'red',
    FOCUSSWITCH   => "\t",
    CURSORPOS     => 0,
    TEXTSTART     => 0,
    PASSWORD      => 0,
    X             => 1,
    Y             => 1,
    READONLY      => 0,
    });

The new method instantiates a new TextMemo object.  The only mandatory
key/value pairs in the configuration hash are B<X> and B<Y>.  All others
have the following defaults:

  Key           Default   Description
  ============================================================
  CAPTION         undef   Caption superimposed on border
  CAPTIONCOL      undef   Foreground colour for caption text
  COLUMNS            10   Number of columns displayed
  MAXLENGTH       undef   Maximum string length allowed
  LINES               3   Number of lines in the window
  VALUE              ''   Current field text
  INPUTFUNC   \&scankey   Function to use to scan for keystrokes
  FOREGROUND      undef   Default foreground colour
  BACKGROUND      undef   Default background colour
  BORDER              1   Display a border around the field
  BORDERCOL       undef   Foreground colour for border
  FOCUSSWITCH      "\t"   Characters which signify end of input
  CURSORPOS           0   Starting position of the cursor
  TEXTSTART           0   Line number of string to start 
                          displaying
  PASSWORD            0   Subsitutes '*' instead of characters
  READONLY            0   Prevents alteration to content

The B<CAPTION> is only valid when the B<BORDER> is enabled.  If the border
is disabled, the field will be underlined, provided the terminal supports it.
The B<MAXLENGTH> has no effect if left undefined.

=cut

sub _conf {
  # Validates and initialises the new TextMemo object.
  #
  # Usage:  $self->_conf(%conf);

  my $self = shift;
  my %conf = ( 
    COLUMNS       => 10,
    MAXLENGTH     => undef,
    LINES         => 3,
    VALUE         => '',
    INPUTFUNC     => \&scankey,
    BORDER        => 1,
    UNDERLINE     => 1,
    FOCUSSWITCH   => "\t",
    CURSORPOS     => 0,
    TEXTSTART     => 0,
    PASSWORD      => 0,
    READONLY      => 0,
    @_ 
    );
  my @required = qw(X Y);
  my $err = 0;

  # Check for required arguments
  foreach (@required) { $err = 1 unless exists $conf{$_} };

  # Make sure no errors are returned by the parent method
  $err = 1 unless $self->SUPER::_conf(%conf);

  return $err == 0 ? 1 : 0;
}

=head2 draw

  $tm->draw($mwh, 1);

The draw method renders the text memo in its current state.  This
requires a valid handle to a curses window in which it will render
itself.  The optional second argument, if true, will cause the field's
text cursor to be rendered as well.

=cut

sub _border {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($border, $ts, $pos, $value, $lines) = 
    @$conf{qw(BORDER TEXTSTART CURSORPOS VALUE LINES)};
  my (@lines, $v, $i, $y, $x);

  # Massage the value as needed, and split the result
  $value = '' unless defined $value;
  $value = substr($value, 0, $$conf{MAXLENGTH}) if
    defined $$conf{MAXLENGTH};
  @lines = textwrap($value, $$conf{COLUMNS} - 1);

  # Adjust the cursor position and text start line if they're out of whack
  $pos = $pos < 0 ? 0 : ($pos > length($value) ? $pos = length($value) :
    $pos);
  $ts = $#lines if $ts > $#lines;
  $ts = 0 if $ts < 0;
  if ($ts > 0 && $pos < length(join('', @lines[0..($ts - 1)]))) {
    $v = length(join('', @lines[0..($ts - 1)]));
    $i = $ts - 1;
    until ($v <= $pos) {
      $v -= length($lines[$i]);
      --$i;
    }
    $ts = $i > 0 ? $i : 0;
    ++$ts unless $pos < length($lines[0]);
  } elsif ($ts + $lines - 1 < $#lines && 
    $pos >= length(join('', @lines[0..($ts + $lines - 1)]))) {
    $v = length(join('', @lines[0..($ts + $lines - 1)]));
    $i = $ts + $lines;
    until ($v >= $pos) {
      $v += length($lines[$i]);
      ++$i;
    }
    $ts = $i - $lines;
    ++$ts if $pos == $v;
  }
  ++$ts if $pos == length($value) and $ts + $lines == @lines;

  # Save the adjust values
  @$conf{qw(TEXTSTART CURSORPOS VALUE)} = ($ts, $pos, $value);
  $self->{SPLIT} = [@lines];

  # Render the border
  if ($border) {

    # Call the parent method
    $self->SUPER::_border($dwh);

    # Place the arrows
    $dwh->getmaxyx($y, $x);
    $dwh->addch(0, $x - 2, ACS_UARROW) if $ts > 0;
    $dwh->addch($y - 1, $x - 2, ACS_DARROW)
      if $#lines - $ts > $lines;
  }
}

sub _content {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($border, $ts, $pos, $lines, $cols) = 
    @$conf{qw(BORDER TEXTSTART CURSORPOS LINES COLUMNS)};
  my @lines = @{$self->{SPLIT}};
  my ($i, $j);

  # Print the lines
  $j = 0;
  for ($i = $ts; $i < $ts + $lines; $i++) {
    unless ($i > $#lines) {
      $$conf{PASSWORD} ? 
        $dwh->addstr($j, 0, '*' x length($lines[$i])) :
        $dwh->addstr($j, 0, $lines[$i]) ;
    }

    # Underline each line if there's no border
    $dwh->chgat($j, 0, $cols, A_UNDERLINE, 
      select_colour(@$conf{qw(FOREGROUND BACKGROUND)}), 0) unless $border;

    $j++;
  }
}

sub _cursor {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};
  my ($pos, $ts) = @$conf{qw(CURSORPOS TEXTSTART)};
  my @lines = @{$self->{SPLIT}};
  my $i = 0;
  my $v = 0;
  my $seg;

  $v = length(join('', @lines[0..($ts - 1)])) if $ts > 0;
  while ($ts + $i < $#lines && $v + length($lines[$ts + $i]) <= $pos) {
    $v += length($lines[$ts + $i]);
    ++$i;
  }
  $v = $pos - $v;
  #$i-- if $i > 0 and substr($$conf{VALUE}, $pos - 1, 1) eq "\n";
  if ($pos == length($$conf{VALUE}) && substr($$conf{VALUE}, $pos - 1, 1) eq
    "\n") {
    ++$i;
    $v = 0;
  }

  $dwh->chgat($i, $v, 1, A_STANDOUT, 
    select_colour(@$conf{qw(FOREGROUND BACKGROUND)}), 0);

  $self->_restore($dwh);
}

sub input_key {
  # Process input a keystroke at a time.
  #
  # Usage:  $self->input_key($key);

  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my ($value, $pos, $max, $ro, $ts) = 
    @$conf{qw(VALUE CURSORPOS MAXLENGTH READONLY TEXTSTART)};
  my @string = split(//, $value);
  my @lines = @{$self->{SPLIT}};
  my ($snippet, $i, $lpos, $l);

  # Process special keys
  if ($in eq KEY_BACKSPACE) {
    return if $ro;
    if ($pos > 0) {
      splice(@string, $pos - 1, 1);
      $value = join('', @string);
      --$pos;
    } else {
      beep;
    }
  } elsif ($in eq KEY_RIGHT) {
    $pos < length($value) ? ++$pos : beep;
  } elsif ($in eq KEY_LEFT) {
    $pos > 0 ? --$pos : beep;
  } elsif ($in eq KEY_UP || $in eq KEY_DOWN ||
    $in eq KEY_NPAGE || $in eq KEY_PPAGE) {

    # Exit early if there's no text
    unless (length($value) > 0) {
      beep;
      return;
    }

    # Get the text length up to the displayed window
    $snippet = $ts == 0 ? 0 : length(join('', @lines[0..($ts - 1)]));

    # Get the position of the cursor relative to the line it's on,
    # as well as the line index
    if ($pos == length($value)) {
      $l = $#lines;
      $lpos = length($lines[$#lines]);
    } else {
      $i = 0;
      while ($snippet + length($lines[$ts + $i]) <= $pos) {
        $snippet += length($lines[$ts + $i]);
        ++$i;
      }
      $l = $ts + $i;
      $lpos = $pos - $snippet;
    }

    # Process according to the key
    if ($in eq KEY_UP) {
      if ($l > 0) {
        if (length($lines[$l - 1]) >= $lpos) {
          $pos -= length($lines[$l - 1]);
        } else {
          $pos -= ($lpos + 1);
        }
      } else {
        beep;
      }
    } elsif ($in eq KEY_DOWN) {
      if ($l < $#lines) {
        if (length($lines[$l + 1]) >= $lpos) {
          $pos += length($lines[$l]);
        } else {
          $pos += ((length($lines[$l]) - $lpos) + 
            length($lines[$l + 1]) - 1);
        }
      } else {
        beep;
      }
    } elsif ($in eq KEY_PPAGE) {
      if ($l >= $$conf{LINES}) {
        $pos -= length(join('', 
          @lines[(1 + $l - $$conf{LINES})..($l - 1)]));
        if (length($lines[$l - $$conf{LINES}]) > $lpos) {
          $pos -= length($lines[$l - $$conf{LINES}]);
        } else {
          $pos -= ($lpos + 1);
        }
      } elsif ($l > 0) {
        if ($lpos > length($lines[0])) {
          $pos = length($lines[0]) - 1;
        } else {
          $pos = $lpos;
        }
      } else {
        beep;
      }
    } elsif ($in eq KEY_NPAGE) {
      if ($l <= $#lines - $$conf{LINES}) {
        $pos += length(join('', 
          @lines[($l + 1) ..($l + $$conf{LINES} - 1)]));
        if (length($lines[$l + $$conf{LINES}]) >= $lpos) {
          $pos += (length($lines[$l + $$conf{LINES}]) + 1);
        } else {
          $pos += ((length($lines[$l]) - $lpos) + 
            length($lines[$l + $$conf{LINES}]) - 1);
        }
      } elsif ($l < $#lines) {
        if (length($lines[$#lines]) > $lpos) {
          $pos = length($value) - (length($lines[$#lines]) -
            $lpos);
        } else {
          $pos = length($value);
        }
      } else {
        beep;
      }
    }

  } elsif ($in eq KEY_HOME) {
    $pos = 0;
  } elsif ($in eq KEY_END) {
    $pos = length($value);

  # Process other keys
  } else {

    return if $ro || $in !~ /^[[:print:]]$/;

    # Exit if it's a non-printing character
    return unless $in =~ /^[\w\W]$/;

    # Reject if we're already at the max length
    if (defined $max && length($value) == $max) {
      beep;
      return;

    # Append to the end if the cursor's at the end
    } elsif ($pos == length($value)) {
      $value .= $in;

    # Insert the character at the cursor's position
    } elsif ($pos > 0) {
      @string = (@string[0..($pos - 1)], $in, @string[$pos..$#string]);
      $value = join('', @string);

    # Insert the character at the beginning of the string
    } else {
      $value = "$in$value";
    }

    # Increment the cursor's position
    ++$pos;
  }

  # Save the changes
  @$conf{qw(VALUE CURSORPOS TEXTSTART)} = ($value, $pos, $ts);
}

1;

=head1 HISTORY

=over

=item 1999/12/29 -- Original text field widget in functional model

=item 2001/07/05 -- First incarnation in OO architecture

=back

=head1 AUTHOR/COPYRIGHT

(c) 2001 Arthur Corliss (corliss@digitalmages.com) 

=cut

