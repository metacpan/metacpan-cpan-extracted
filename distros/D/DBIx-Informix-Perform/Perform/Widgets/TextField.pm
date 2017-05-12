package DBIx::Informix::Perform::Widgets::TextField;

use base 'Curses::Widgets::TextField';

use Curses;
use Curses::Widgets;

use constant 'KEY_DEL' => '330'; # dunno why not in Curses.

use 5.6.0;

our $OVERWRITE = 1;

sub input_key {
  # Process input a keystroke at a time.
  #
  # Usage:  $self->input_key($key);

  my $self = shift;
  my $in = shift;
  my $conf = $self->{CONF};
  my $mask = $$conf{MASK};
  my ($shift) = grep { $$conf{attrs}{$_} } qw(UPSHIFT DOWNSHIFT);
  my ($value, $pos, $max, $ro) = 
    @$conf{qw(VALUE CURSORPOS MAXLENGTH READONLY)};
  my @string = split(//, $value);

  # Process special keys
  if ($in eq "\cX") {		# ctrl-x = delete char forward
    return if $ro;
    if ($pos < length($value)) {
	splice(@string, $pos, 1);
	$value = join '', @string;
    } else {
      beep;
    }
  } elsif ($in eq KEY_RIGHT) {
    $pos < length($value) ? ++$pos : beep;
  } elsif ($in eq KEY_LEFT  or  $in eq KEY_BACKSPACE or $in eq "\cH") {
    $pos > 0 ? --$pos : beep;
  } elsif ($in eq KEY_HOME) {
    $pos = 0;
  } elsif ($in eq KEY_END) {
    $pos = length($value);
  } elsif ($in eq "\cD") {	# clear to end of field
      splice(@string, $pos, $#string-$pos+1);
      $value = join('', @string);
  } elsif ($in eq "\cU") {	# clear to beginning  (not part of Perform)
      $value = "";
  # Process other keys
  } else {

    return if $ro || $in !~ /^[[:print:]]$/;

    # Exit if it's a non-printing character
    return unless $in =~ /^[\w\W]$/;

    $in = uc($in)
	if $shift eq 'UPSHIFT';
    $in = lc($in)
	if $shift eq 'DOWNSHIFT';

    # Append to the end if the cursor's at the end
    if ($pos == length($value)) {
	# Reject if we're already at the max length
	if (defined $max && length($value) == $max) {
	    beep;
	    return;
	}
	$value .= $in;

    # Insert/replace the character at the cursor's position
    } elsif ($OVERWRITE) {
	splice(@string, $pos, 1, $in);
	$value = join('', @string);
    } elsif ($pos > 0) {
      @string = (@string[0..($pos - 1)], $in, @string[$pos..$#string]);
      $value = join('', @string);

    # Insert the character at the beginning of the string
    } else {
      $value = "$in$value";
    }

    # Increment the cursor's position
    ++$pos;

    # If just filled up and AUTONEXT is on, exit.
    $$conf{'EXIT'} = 1		# requires change to execute
	if (defined $max && length($value) == $max &&
	    $$conf{'AUTONEXT'});
  }

  # Save the changes
  @$conf{qw(VALUE CURSORPOS)} = ($value, $pos);
}


#  Overriding Curses::Widgets::execute
sub execute {
  my $self = shift;
  my $mwh = shift;
  my $conf = $self->{CONF};
  my $func = $$conf{'INPUTFUNC'} || \&scankey;
  my $fskeys = $$conf{'FOCUSSWITCH'};
  my $mkeys = $$conf{'FOCUSSWITCH_MACROKEYS'};
  my $key;

  $mkeys = [$mkeys] if (defined($mkeys) && ref($mkeys) ne 'ARRAY');
  my $regex = $mkeys ? ("([$fskeys]|" . join ('|', @$mkeys) . ")")
       :  "[$fskeys]";

  $self->draw($mwh, 1);

  while (1) {
    $key = &$func($mwh);
    if (defined $key) {
      if (defined $regex) {
	  return $key if ($key =~ /^$regex/ || ($fskeys =~ /\t/ &&
						$key eq KEY_STAB));
      }
      if ($key eq "\cA") {
	  $OVERWRITE = !$OVERWRITE;
	  #print STDERR "OVERWRITE = '$OVERWRITE'\n";
	  return $key;
      }
      $self->input_key($key);
    }
    $self->draw($mwh, 1);
    last if $$conf{'EXIT'};	# ADDED
  }
}


# Modify this to handle the pos-after-at-last-char case.
sub _content {
  my $self = shift;
  my $dwh = shift;
  my $cursor = shift;
  my $conf = $self->{CONF};
  my ($pos, $ts, $value, $border, $col) = 
    @$conf{qw(CURSORPOS TEXTSTART VALUE BORDER COLUMNS)};
  my $seg;

  # Trim the value if it exceeds the maximum length
  $value = substr($value, 0, $$conf{MAXLENGTH}) if $$conf{MAXLENGTH};

  # Turn on underlining (terminal-dependent) if no border is used
  $dwh->attron(A_UNDERLINE) unless $border;

  # Adjust the cursor position and text start if it's out of whack
  if ($pos > length($value)) {
    $pos = length($value);
  } elsif ($pos < 0) {
    $pos = 0;
  }
  if ($pos > $ts + $$conf{COLUMNS} - 1) {
#    $ts = $pos + 1 - $$conf{COLUMNS};
    $ts = $pos     - $$conf{COLUMNS};
  } elsif ($pos < $ts) {
    $ts = $pos;
  }
  $ts = 0 if $ts < 0;

  # Write the widget value (adjusting for horizontal scrolling)
  $seg = substr($value, $ts, $$conf{COLUMNS});
  $seg = '*' x length($seg) if $$conf{PASSWORD};
  $seg .= ' ' x ($$conf{COLUMNS} - length($seg));
  $dwh->addstr(0, 0, $seg);
  $dwh->attroff(A_BOLD);

  # Underline the field if no border is used
  $dwh->chgat(0, 0, $col, A_UNDERLINE, 
    select_colour(@$conf{qw(FOREGROUND BACKGROUND)}), 0) unless $border;

  # Save the textstart, cursorpos, and value in case it was tweaked
  @$conf{qw(TEXTSTART CURSORPOS VALUE)} = ($ts, $pos, $value);
}


sub _cursor {
  my $self = shift;
  my $dwh = shift;
  my $conf = $self->{CONF};

  
  # Display the cursor
  my $cpos = $$conf{CURSORPOS} - $$conf{TEXTSTART};
  my $attr = A_STANDOUT;
  if ($cpos >= $$conf{COLUMNS}) {
      $cpos--;
      $attr = A_REVERSE;
  }
  $dwh->chgat(0, $cpos, 1, $attr, 
    select_colour(@$conf{qw(FOREGROUND BACKGROUND)}), 0)
    unless $$conf{READONLY};

  # Restore the default settings
  $self->_restore($dwh);
}


1;

