use v5.26;

package Antsy;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);

use Carp     qw(carp);
use Exporter qw(import);

our( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

our $VERSION = '0.908';

=encoding utf8

=head1 NAME

Antsy - Streaming ANSI escape sequences

=head1 SYNOPSIS

	use Antsy qw(:all);

	print bold, underline, text_red, "Hello", reset_all;

=head1 DESCRIPTION

Subroutines to deal with ANSI terminal sequences. You can emit these
without knowing what's coming up.

=head2 Yet another module?

There are several modules that come close to this, but so far
everything is incomplete or requires you to know all of the upcoming
text ahead of time so you can use of it as an argument to a function.
I want to emit the sequence in a stream without knowing what's coming
up.

=over 4

=item * L<Term::ANSIColor>

Wraps ANSI color stuff around text. This comes with Perl v5.10 and
later.

=item * L<Text::ANSI::Util>

Routines for dealing with text that contains ANSI code. For example,
ignore the ANSI sequences in computing length.

=item * L<Text::ANSI::Printf>

I don't really know what this does.

=item * L<Term::ANSIScreen>

=back

=head2 Methods

=over 4

=item * bg_256( N )

=item * bg_rgb

=item * bg_black

=item * bg_blue

=item * bg_cyan

=item * bg_green

=item * bg_magenta

=item * bg_orange

=item * bg_red

=item * bg_white

=item * bg_yellow

Make the background the named color

=item * bg_bright_black

=item * bg_bright_blue

=item * bg_bright_cyan

=item * bg_bright_green

=item * bg_bright_magenta

=item * bg_bright_red

=item * bg_bright_white

=item * bg_bright_yellow

Make the background the named color and bright (however your terminal
does that).

=item * bg_gray

=item * bg_grey

The same as C<bg_bright_black>, which most people call gray.

=item * bg_default

Go back to the terminal's default background color (SGR 49). Unlike
C<reset_all>, this leaves the text color and attributes alone.

=item * blink

Make the text blink (however your terminal does that).

=item * rapid_blink

Make the text blink quickly (SGR 6). Few terminals support this; most
treat it like C<blink> or ignore it. C<no_blink> turns off both.

=item * bold

Turn on bold

=item * clear_line

=item * clear_screen

=item * clear_to_line_end

=item * clear_to_line_start

=item * clear_to_screen_end

=item * clear_to_screen_start

Clear the part of the screen as indicated. Each of these start at the
current cursor position.

=item * conceal

=item * hidden

Make the text invisible (if your terminal handles that). Show it again
with C<reveal>.

=item * cursor_back( [ N ] )

=item * cursor_left( [ N ] )

Move the cursor back (left) N positions.

=item * cursor_column( [ N ] )

Move the cursor to column N.

=item * cursor_down( [ N ] )

Move the cursor down N positions.

=item * cursor_forward( [ N ] )

=item * cursor_right( [ N ] )

Move the cursor forward (right) N positions.

=item * cursor_row( [ N ] )

Move the cursor to row N, staying in the same column (VPA, C<CSI N d>).
This is the vertical version of C<cursor_column>.

=item * cursor_home

Move the cursor to the top left corner of the screen. This is the same
as C<cursor_row_column()> with no arguments.

=item * cursor_line_start

Move the cursor to the start of the current line. This is the same as
C<cursor_column(1)>.

=item * cursor_next_line( [ N ] )

Move the cursor down N lines, to the start of the line

=item * cursor_previous_line( [ N ] )

=item * cursor_prev_line( [ N ] )

Move the cursor up N lines, to the start of the line

=item * cursor_row_column( [ N, M ] )

=item * cursor_position( [ N, M ] )

Move the cursor to row N and column M. Both default to 1.

=item * cursor_tab_back( [ N ] )

Move the cursor back N tab stops (CBT, C<CSI N Z>).

=item * cursor_tab_forward( [ N ] )

Move the cursor forward N tab stops (CHT, C<CSI N I>).

=item * cursor_up( [ N ] )

Move the cursor up N lines.

For these and for C<scroll_down> and C<scroll_up>, N defaults to 1.
Terminals treat a count of 0 as 1, so these never put a 0 in the
sequence. Instead, an N of 0 returns the empty string, except that
C<cursor_next_line(0)> and C<cursor_previous_line(0)> move to the start
of the current line, C<cursor_column(0)> moves to column 1, and
C<cursor_row(0)> moves to row 1. An N that isn't a non-negative integer
counts as 0.

=item * cursor_hide

Hide the cursor. See also C<cursor_show>.

=item * cursor_show

Show the cursor. See also C<cursor_hide>.

=item * cursor_position_request

The sequence that asks the terminal where the cursor is (DSR 6,
C<CSI 6n>). The terminal answers on its input, not its output, with
C<CSI ROW ; COLUMN R>. Use this if you read the terminal yourself;
otherwise use C<cursor_get_position>.

=item * cursor_get_position( [ TIMEOUT ] )

Ask the terminal where the cursor is, and return the row and column
(both starting at 1):

	my( $row, $column ) = cursor_get_position();

This opens F</dev/tty>, puts it in raw mode, sends
C<cursor_position_request>, and reads the answer, so it works only on
Unix-like systems with a terminal. It waits up to TIMEOUT seconds
(default 0.5) for each character, since some terminals never answer.
It returns the empty list if it can't open the terminal, gets no
answer, or can't understand it. It needs L<Term::ReadKey>, which it
loads only when you call it.

=item * dark

Make the text dark (however your terminal does that).

=item * erase_in_display( [ N ] )

Erase part of the screen (ED, C<CSI N J>). The cursor doesn't move.
N defaults to 0:

=over 4

=item * 0 - from the cursor to the end of the screen

=item * 1 - from the start of the screen to the cursor

=item * 2 - the whole screen

=item * 3 - the whole screen and the scrollback buffer (an xterm
extension that most terminals support)

=back

Any other value carps and returns the empty string.

=item * erase_in_line( [ N ] )

Erase part of the current line (EL, C<CSI N K>). The cursor doesn't
move. N defaults to 0:

=over 4

=item * 0 - from the cursor to the end of the line

=item * 1 - from the start of the line to the cursor

=item * 2 - the whole line

=back

Any other value carps and returns the empty string.

=item * erase_line

=item * erase_screen

=item * erase_screen_and_scrollback

=item * erase_to_end_of_line

=item * erase_to_end_of_screen

=item * erase_to_start_of_line

=item * erase_to_start_of_screen

Shortcuts for C<erase_in_display> and C<erase_in_line> with each of
their arguments, so you don't have to remember the numbers. For
example, C<erase_to_end_of_screen> is C<erase_in_display(0)> and
C<erase_line> is C<erase_in_line(2)>.

=item * dim

=item * faint

The same as C<dark> (SGR 2). The standard calls this "faint" (decreased
intensity), and terminfo and many other tools call it "dim".

=item * hide_cursor

Deprecated. Use C<cursor_hide> instead.

=item * inverse

=item * reverse_video

Use the background color for the text color, and the text color
for the background (SGR 7). Use these instead of C<reverse>, which
Antsy can't export.

=item * italic

Turn on italic.

=item * no_blink

Turn off blinking (SGR 25).

=item * no_bold

=item * no_dark

=item * no_dim

=item * no_faint

=item * normal_intensity

Turn off bold and dark (or faint) (SGR 22). These are all the same:
terminals have no way to turn off just one of bold and dark, so each
of these turns off both.

Some terminals treat SGR 21 as "bold off", but the standard says SGR 21
is double underline, so Antsy doesn't use it.

=item * no_italic

Turn off italic (SGR 23).

=item * no_inverse

=item * no_reverse

=item * no_reverse_video

Turn off reverse video (SGR 27).

=item * no_strikethrough

Turn off strikethrough (SGR 29).

=item * no_underline

Turn off underlining (SGR 24).

=item * normal

=item * reset_all

Turn off all attributes and go back to the default colors (SGR 0).
C<normal> is not the same as C<normal_intensity>, which only turns off
bold and dark.

=item * reset

The same as C<reset_all>, but Antsy can't export it. Importing a sub
named C<reset> would replace Perl's built-in C<reset> in your program,
so it isn't in C<@EXPORT_OK> or any export tag. Use C<reset_all> or
C<normal>, or call it with its full name, C<Antsy::reset()>.

=item * reveal

Show text hidden by C<conceal> (SGR 28).

=item * reverse

The same as C<inverse>, but Antsy can't export it. Importing a sub
named C<reverse> would replace Perl's built-in C<reverse> in your
program, so C<reverse @list> would stop working. It isn't in
C<@EXPORT_OK> or any export tag. Use C<inverse> or C<reverse_video>,
or call it with its full name, C<Antsy::reverse()>.

=item * scroll_down( [ N ] )

Scroll down N lines. See C<cursor_up> for how N works.

=item * scroll_up( [ N ] )

Scroll up N lines. See C<cursor_up> for how N works.

=item * show_cursor

Deprecated. Use C<cursor_show> instead.

=item * strikethrough

Draw a line through the text (SGR 9), which the standard calls
"crossed-out".

=item * text_256( N )

Make the foreground the color N in the xterm 256 color chart.

This dies if N is not a positive number between 0 and 255 (inclusive).

=item * text_black

=item * text_blue

=item * text_cyan

=item * text_green

=item * text_magenta

=item * text_orange

=item * text_red

=item * text_rgb

=item * text_white

=item * text_yellow

Make foreground text the named color.

=item * text_bright_black

=item * text_bright_blue

=item * text_bright_cyan

=item * text_bright_green

=item * text_bright_magenta

=item * text_bright_red

=item * text_bright_white

=item * text_bright_yellow

Make foreground text the named color and bright (however your terminal
does that).

=item * text_gray

=item * text_grey

The same as C<text_bright_black>, which most people call gray.

=item * text_default

Go back to the terminal's default text color (SGR 39). Unlike
C<reset_all>, this leaves the background color and attributes alone.

=item * underline

Turn on underlining.

=back

=head2 Saving and restoring the cursor

Terminals have two ways to save the cursor and come back to it later:
the DEC way and the SCO way. Each has only one save slot, so saving
again replaces whatever you saved before; you can't nest them.

The DEC versions are the ones to use. They work in essentially every
terminal, and they're what terminfo's C<sc> and C<rc> capabilities
(C<tput sc>) send for most terminals. The SCO versions are less
predictable: some terminals save only the position, others (such as
xterm and the VT510) save the same things as the DEC versions, some
terminals ignore them, and in terminals with left and right margins
turned on, C<CSI s> sets the margins instead.

For the details, see the VT510 reference pages for
L<DECSC|https://vt100.net/docs/vt510-rm/DECSC.html>,
L<DECRC|https://vt100.net/docs/vt510-rm/DECRC.html>,
L<SCOSC|https://vt100.net/docs/vt510-rm/SCOSC.html>, and
L<SCORC|https://vt100.net/docs/vt510-rm/SCORC.html>, and
L<XTerm Control Sequences|https://invisible-island.net/xterm/ctlseqs/ctlseqs.html>,
which also covers the conflict between C<CSI s> and setting the left
and right margins.

The saved position is a screen position. If the screen scrolls between
saving and restoring, the cursor comes back to the same row of the
screen, which may now show a different line.

=over 4

=item * cursor_save_state

=item * cursor_save_dec

=item * cursor_save_all

=item * decsc

Save the cursor position, along with the current text attributes,
character sets, origin mode, and a few other settings
(L<DECSC|https://vt100.net/docs/vt510-rm/DECSC.html>, C<ESC 7>).
Restore it with C<cursor_restore_state> or any of its other names.

=item * cursor_restore_state

=item * cursor_restore_dec

=item * cursor_restore_all

=item * decrc

Put the cursor back where C<cursor_save_state> saved it, and restore
the attributes saved with it
(L<DECRC|https://vt100.net/docs/vt510-rm/DECRC.html>, C<ESC 8>).

=item * cursor_save

=item * cursor_save_position

Save the cursor position the SCO way
(L<SCOSC|https://vt100.net/docs/vt510-rm/SCOSC.html>, C<CSI s>). What
else gets saved depends on the terminal. Prefer C<cursor_save_state>.

=item * cursor_restore

=item * cursor_restore_position

Put the cursor back where C<cursor_save> saved it, the SCO way
(L<SCORC|https://vt100.net/docs/vt510-rm/SCORC.html>, C<CSI u>).
Prefer C<cursor_restore_state>.

=item * save_cursor

Deprecated. Use C<cursor_save> (the same SCO sequence) or, better,
C<cursor_save_state>.

=item * restore_cursor

Deprecated. Use C<cursor_restore> (the same SCO sequence) or, better,
C<cursor_restore_state>.

=back

=head2 Changing the cursor shape

These use the standard DECSCUSR sequence (C<CSI N SP q>), which works
in xterm, iTerm2, kitty, Windows Terminal, the VTE terminals, tmux, and
most others. iTerm2 also has its own way, C<iterm_set_cursor_shape>,
which numbers the shapes differently.

See the VT510 reference page for
L<DECSCUSR|https://vt100.net/docs/vt510-rm/DECSCUSR.html>, which defines
shapes 0 through 4, and
L<XTerm Control Sequences|https://invisible-island.net/xterm/ctlseqs/ctlseqs.html>,
which adds the bar shapes, 5 and 6.

=over 4

=item * cursor_shape( [ N ] )

Set the cursor shape. N defaults to 0:

=over 4

=item * 0 - the terminal's default shape (usually a blinking block)

=item * 1 - blinking block

=item * 2 - steady block

=item * 3 - blinking underline

=item * 4 - steady underline

=item * 5 - blinking bar

=item * 6 - steady bar

=back

Any other value carps and returns the empty string.

=item * cursor_shape_default

=item * cursor_block_blinking

=item * cursor_block

=item * cursor_underline_blinking

=item * cursor_underline

=item * cursor_bar_blinking

=item * cursor_bar

Shortcuts for C<cursor_shape> with each argument, so you don't have to
remember the numbers. For example, C<cursor_bar> is C<cursor_shape(6)>.

=back

=cut

sub _256 ( $i, $n ) {
	carp "Bad 256 $n" unless( int($n) == $n and $n >= 0 and $n <= 255 );
	_seq( 'm', $i, 5, $n );
	}

sub _bg () { 48 }  # a magic number that applies the SGR to the background

# _erase forms an erase sequence (J for the display, K for the line).
# An argument that isn't allowed carps and returns the empty string,
# since erasing nothing is safer than erasing the wrong part.
sub _erase ( $command, $n, @allowed ) {
	unless( grep { $n eq $_ } @allowed ) {
		carp "Bad erase value <$n>. Should be one of <@allowed>";
		return '';
		}
	_seq( $command, $n );
	}

sub _export ( $name, $tag ) {
	push @EXPORT_OK,              $name;
	push $EXPORT_TAGS{'all'}->@*, $name;
	push $EXPORT_TAGS{$tag}->@*,  $name;
	}

sub _rgb ( $i, $r, $g, $b ) {
	carp "Bad RGB $r;$b;$g" unless
		3 == grep { int($_) == $_ and $_ >= 0 and $_ <= 255 }
			( $r, $b, $g );

	_seq( 'm', $i, 2, $r, $g, $b );
	}

# _seq forms the ANSI escape sequence. There's the start, some arguments
# separated by `;`, then a string for the argument
sub _seq ( $command, @args ) { join '', "\x1b[", join( ';', @args ), $command }

sub _encode_seq ( $string ) {
	local $_ = $string;

	s/(.)/sprintf '%02X ', ord($1) /ge;

	s/1b /ESC /ig;
	s/07 /BEL /ig;
	s/31 33 33 37 /1337 /;

	s/([2-7A-F][0-9A-F])\x20/ chr( hex($1) ) . ' ' /ge;
	$_;
	}

sub _start () { "\x1b[" }

sub _text () { 38 }  # a magic number that applies the SGR to the text

sub bg_256   ( $n         ) { _256( _bg(), $n ) }
sub bg_rgb   ( $r, $g, $b ) { _rgb( _bg(), $r, $g, $b ) }

sub cursor_row_column ( $n = 1, $m = 1 ) { _seq( 'H', $n, $m ) }
sub cursor_position   ( $n = 1, $m = 1 ) { cursor_row_column( $n, $m ) }
sub cursor_home       ()                 { cursor_row_column() }
sub cursor_line_start ()                 { _seq( 'G', 1 ) }

# Device Status Report 6 asks the terminal where the cursor is. The
# terminal answers on its input with CSI ROW ; COLUMN R.
sub cursor_position_request ()           { _seq( 'n', 6 ) }

sub cursor_get_position ( $timeout = 0.5 ) {
	state $have_readkey = eval { require Term::ReadKey };
	unless( $have_readkey ) {
		carp "cursor_get_position needs Term::ReadKey";
		return;
		}

	open my $tty, '+<', '/dev/tty' or do {
		carp "cursor_get_position couldn't open /dev/tty: $!";
		return;
		};
	my $old = select $tty; $| = 1; select $old;

	# Raw mode, so the reply isn't echoed and arrives without a newline.
	# Some terminals never answer, so give up after $timeout seconds
	# without a character.
	Term::ReadKey::ReadMode( 'raw', $tty );
	print { $tty } cursor_position_request();
	my $reply = '';
	while( defined( my $char = Term::ReadKey::ReadKey( $timeout, $tty ) ) ) {
		$reply .= $char;
		last if $char eq 'R';
		}
	Term::ReadKey::ReadMode( 'restore', $tty );

	_parse_cursor_position_report( $reply );
	}

sub _parse_cursor_position_report ( $reply ) {
	my( $row, $column ) = $reply =~ /\e\[(\d+);(\d+)R/ or return;
	( $row, $column );
	}

sub erase_in_display ( $n = 0 ) { _erase( 'J', $n, 0 .. 3 ) }
sub erase_in_line    ( $n = 0 ) { _erase( 'K', $n, 0 .. 2 ) }

# Named shortcuts for each erase_in_display and erase_in_line argument,
# so nobody has to remember the numbers.
BEGIN {
	my @helpers = (
		# NAME                              SUB               ARG
		[ qw( erase_to_end_of_screen        erase_in_display  0 ) ],
		[ qw( erase_to_start_of_screen      erase_in_display  1 ) ],
		[ qw( erase_screen                  erase_in_display  2 ) ],
		[ qw( erase_screen_and_scrollback   erase_in_display  3 ) ],
		[ qw( erase_to_end_of_line          erase_in_line     0 ) ],
		[ qw( erase_to_start_of_line        erase_in_line     1 ) ],
		[ qw( erase_line                    erase_in_line     2 ) ],
		);

	foreach my $helper ( @helpers ) {
		no strict 'refs';
		my( $name, $sub, $n ) = @$helper;
		my $value = __PACKAGE__->can( $sub )->( $n );
		*{$name} = sub () { $value };
		_export( $name, 'erase' );
		}
	}

sub text_256 ( $n         ) { _256( _text(), $n ) }
sub text_rgb ( $r, $g, $b ) { _rgb( _text(), $r, $g, $b ) }


# This section takes the subroutines that we've already defined to
# adds them to the export lists.
BEGIN {
	my @subs = qw( bg_256 bg_rgb text_256 text_rgb
		erase_in_display erase_in_line cursor_row_column
		cursor_position cursor_home cursor_line_start
		cursor_position_request cursor_get_position
		cursor_shape
		);

	push @EXPORT_OK, @subs;
	push $EXPORT_TAGS{all   }->@*,                      @subs;
	push $EXPORT_TAGS{bg    }->@*, grep { /\Abg_/     } @subs;
	push $EXPORT_TAGS{text  }->@*, grep { /\Atext_/   } @subs;
	push $EXPORT_TAGS{erase }->@*, grep { /\Aerase_/  } @subs;
	push $EXPORT_TAGS{cursor}->@*, grep { /\Acursor_/ } @subs;
	}

BEGIN {
	my @groups = (
		[ qw( J screen) ],
		[ qw( K line  ) ],
		);

	my @templates = ( 'clear_to_%s_end', 'clear_to_%s_start', 'clear_%s' );

	foreach my $group ( @groups ) {
		no strict 'refs';
		foreach my $i ( 0 .. 2 ) {
			my $name = sprintf $templates[$i], $group->[1];
			my $value = _seq( $group->[0], $i );
			*{$name} = sub () { $value };
			_export( $name, 'clear' );
			}
		}
	}

BEGIN {
	# Terminals treat a count of 0 as 1, so a 0 can't go into the
	# sequence. ZERO is what to return instead: nothing for the relative
	# moves, column 1 for the moves that also go to the start of a line,
	# and row 1 for the move to a row.
	my $start_of_line = _seq( 'G', 1 );
	my $first_row     = _seq( 'd', 1 );

	my @groups = (
		# EXPORT_TAG  FRAGMENT         COMMAND  ZERO
		[ 'cursor',   'back',          'D',     ''             ],
		[ 'cursor',   'column',        'G',     $start_of_line ],
		[ 'cursor',   'down',          'B',     ''             ],
		[ 'cursor',   'forward',       'C',     ''             ],
		[ 'cursor',   'next_line',     'E',     $start_of_line ],
		[ 'cursor',   'previous_line', 'F',     $start_of_line ],
		[ 'cursor',   'row',           'd',     $first_row     ],
		[ 'cursor',   'tab_back',      'Z',     ''             ],
		[ 'cursor',   'tab_forward',   'I',     ''             ],
		[ 'cursor',   'up',            'A',     ''             ],
		[ 'scroll',   'down',          'T',     ''             ],
		[ 'scroll',   'up',            'S',     ''             ],
		# aliases
		[ 'cursor',   'left',          'D',     ''             ],
		[ 'cursor',   'right',         'C',     ''             ],
		[ 'cursor',   'prev_line',     'F',     $start_of_line ],
		);

	foreach my $group ( @groups ) {
		no strict 'refs';

		my( $export_tag, $fragment, $command, $zero ) = @$group;
		my $name = join '_', $export_tag, $fragment;

		*{$name} = sub ( $n = 1 ) {
			$n = $n =~ /\A([0-9]+)\z/ ? $1 : 0;
			return $zero if $n == 0;
			_seq( $command, $n );
			};

		_export( $name, $export_tag );
		}
	}

BEGIN {
	# Importing a sub with the same name as a Perl builtin replaces that
	# builtin in the importing package (for example, reverse @list would
	# call Antsy::reverse). Define these, but never export them.
	my %shadows_builtin = map { $_ => 1 } qw( reset reverse );

	my @groups = (
		# EXPORT_TAG  SUB_NAME  COMMAND ARGS
		[ qw( control reset          m    0 ) ],
		[ qw( control reset_all      m    0 ) ],
		[ qw( control normal         m    0 ) ],
		[ qw( text    bold           m    1 ) ],
		[ qw( text    dark           m    2 ) ],
		[ qw( text    dim            m    2 ) ],
		[ qw( text    faint          m    2 ) ],
		[ qw( text    italic         m    3 ) ],
		[ qw( text    underline      m    4 ) ],
		[ qw( text    blink          m    5 ) ],
		[ qw( text    rapid_blink    m    6 ) ],
		[ qw( text    reverse        m    7 ) ],
		[ qw( text    inverse        m    7 ) ],
		[ qw( text    reverse_video  m    7 ) ],
		[ qw( text    conceal        m    8 ) ],
		[ qw( text    hidden         m    8 ) ],
		[ qw( text    strikethrough  m    9 ) ],
		[ qw( text    normal_intensity m 22 ) ],
		[ qw( text    no_bold        m   22 ) ],
		[ qw( text    no_dark        m   22 ) ],
		[ qw( text    no_dim         m   22 ) ],
		[ qw( text    no_faint       m   22 ) ],
		[ qw( text    no_italic      m   23 ) ],
		[ qw( text    no_underline   m   24 ) ],
		[ qw( text    no_blink       m   25 ) ],
		[ qw( text    no_reverse     m   27 ) ],
		[ qw( text    no_inverse     m   27 ) ],
		[ qw( text    no_reverse_video m 27 ) ],
		[ qw( text    reveal         m   28 ) ],
		[ qw( text    no_strikethrough m 29 ) ],
		[ qw( text    text_default   m   39 ) ],
		[ qw( bg      bg_default     m   49 ) ],
		[ qw( cursor  hide_cursor    l  ?25 ) ],
		[ qw( cursor  show_cursor    h  ?25 ) ],
		[ qw( cursor  cursor_hide    l  ?25 ) ],
		[ qw( cursor  cursor_show    h  ?25 ) ],
		);

	foreach my $group ( @groups ) {
		no strict 'refs';

		my( $export_tag, $name, $command, $n ) =  @$group;
		$n //= '';
		my $value = _seq( $command, $n );

		*{$name} = sub () { $value };

		_export( $name, $export_tag ) unless $shadows_builtin{$name};
		}
	}

# Saving and restoring the cursor. See "Saving and restoring the
# cursor" in the docs for the difference between the DEC and SCO
# versions.
BEGIN {
	my @groups = (
		# SEQUENCE                     NAMES
		[ "\x1b7",       qw( cursor_save_state    cursor_save_dec    cursor_save_all    decsc ) ], # DECSC
		[ "\x1b8",       qw( cursor_restore_state cursor_restore_dec cursor_restore_all decrc ) ], # DECRC
		[ _seq( 's' ),   qw( cursor_save    cursor_save_position    save_cursor    ) ],         # SCOSC
		[ _seq( 'u' ),   qw( cursor_restore cursor_restore_position restore_cursor ) ],         # SCORC
		);

	foreach my $group ( @groups ) {
		no strict 'refs';
		my( $value, @names ) = @$group;
		foreach my $name ( @names ) {
			*{$name} = sub () { $value };
			_export( $name, 'cursor' );
			}
		}
	}

# Changing the cursor shape with DECSCUSR (CSI N SP q). See "Changing
# the cursor shape" in the docs.
sub cursor_shape ( $n = 0 ) {
	unless( grep { $n eq $_ } 0 .. 6 ) {
		carp "Bad cursor shape <$n>. Should be one of <0 1 2 3 4 5 6>";
		return '';
		}
	_seq( ' q', $n );
	}

# Named shortcuts for each cursor_shape argument.
BEGIN {
	my @helpers = (
		# NAME                            SHAPE
		[ qw( cursor_shape_default        0 ) ],
		[ qw( cursor_block_blinking       1 ) ],
		[ qw( cursor_block                2 ) ],
		[ qw( cursor_underline_blinking   3 ) ],
		[ qw( cursor_underline            4 ) ],
		[ qw( cursor_bar_blinking         5 ) ],
		[ qw( cursor_bar                  6 ) ],
		);

	foreach my $helper ( @helpers ) {
		no strict 'refs';
		my( $name, $n ) = @$helper;
		my $value = cursor_shape( $n );
		*{$name} = sub () { $value };
		_export( $name, 'cursor' );
		}
	}

BEGIN {
	my @colors = qw( black red green yellow blue magenta cyan white );
	my %colors = map { state $n = 0; $_ => $n++ } @colors;

	my @groups = (
		[ qw(  30 text        %s  ) ],
		[ qw(  90 text bright %s  ) ],
		[ qw(  40 bg          %s  ) ],
		[ qw( 100 bg   bright %s  ) ],
		);

	foreach my $group ( @groups ) {
		my $offset  = shift @$group;
		my $template = join "_", @$group;

		foreach my $i ( 0 .. $#colors ) {
			no strict 'refs';
			my $name = sprintf $template, $colors[$i];
			my $value = _seq( 'm', $offset + $i );
			*{$name} = sub () { $value };

			# The tag is text or bg. The bright colors also go in their
			# own bright tag.
			_export( $name, $group->[0] );
			push $EXPORT_TAGS{bright}->@*, $name if $group->[1] eq 'bright';
			}
		}

	# Most people call bright black gray (or grey), so give it those
	# names too. Copy the value from the bright_black sub so they can't
	# drift apart.
	foreach my $prefix ( qw( text bg ) ) {
		no strict 'refs';
		my $value = __PACKAGE__->can( "${prefix}_bright_black" )->();
		foreach my $spelling ( qw( gray grey ) ) {
			my $name = "${prefix}_$spelling";
			*{$name} = sub () { $value };
			_export( $name, $prefix );
			push $EXPORT_TAGS{bright}->@*, $name;
			}
		}

	my @secondary_colors = (
		[ 'orange', [ 0xFF, 0x8C, 0x00 ] ],
		);

	foreach my $tuple ( @secondary_colors ) {
		no strict 'refs';
		my( $color, $rgb ) = $tuple->@*;

		# Each sub needs its own variable to close over. If they shared
		# one, reassigning it would change what the other returns.
		my $text_name  = "text_$color";
		my $text_value = text_rgb( $rgb->@* );
		*{$text_name} = sub () { $text_value };
		_export( $text_name, 'text' );

		my $bg_name  = "bg_$color";
		my $bg_value = bg_rgb( $rgb->@* );
		*{$bg_name} = sub () { $bg_value };
		_export( $bg_name, 'bg' );
		}
	}

=head2 Character shortcuts

=over 4

=item * BELL - \007

=item * CSI - ESC [

=item * ESC - \x1b

=item * OSC - ESC ]

=item * ST - BELL or ESC \

=item * SP - literal space

=back

=cut

sub BELL () { "\007" }
sub CSI  () { ESC() . '[' }
sub ESC  () { "\x1b" }
sub OSC  () { ESC() . ']' }
sub SP   () { ' ' }
sub ST   () { BELL() }

=head2 Editor-specific codes

=head3 iTerm2

iTerm2 supports proprietary

=over 4

=item * iterm_bg_color()

=item * iterm_fg_color() OSC 4 ; -1; ? ST

Returns an array reference of the decimal values for the Red, Green
and Blue components of the background or foreground. These triplets
may be 2 or 4 digits in each component.

=cut

sub _iterm_id { 'iTerm.app' }

sub _is_term_type ( $id ) {
	( $ENV{TERM_PROGRAM} // '' ) =~ m/\A\Q$id\E\z/;
	}

sub _is_iterm { _is_term_type( _iterm_id() ) }

sub _iterm_seq ( $command, @args ) {
	unless( _is_iterm() ) {
		my $sub = ( caller(1) )[3];
		carp( "$sub only works in iTerm2" );
		return;
		}

	OSC() . join( ';', @args, '' ) . $command . ST();
	}

sub _iterm_query ( $command, @args ) {
	my $terminal = do {
		state $rc = require Term::ReadKey;
		chomp( my $tty = `/usr/bin/tty` );
		# say "Term: ", $tty;
		open my $terminal, '+<', $tty;
		my $old = select( $terminal );
		$|++;
		select( $old );
		$terminal;
		};

	print { $terminal } _iterm_seq( $command, @args );;
	Term::ReadKey::ReadMode('raw');
	my $response;
	my $key;
	while( defined ($key = Term::ReadKey::ReadKey(0)) ) {
		$response .= $key;
		last if ord( $key ) == 3; # Control-C
		last if ord( $key ) == 7;
	}
	Term::ReadKey::ReadMode('normal');

	$response;
	}

sub _iterm_rgb_query ( $type ) {
	state $OSC = qr/ ( \007 | \x1b \\ ) /xn;
	my $response = _iterm_query( '?', 4, $type );
	my( $r, $g, $b ) = $response =~ m|rgb:(.+?)/(.+?)/(.+?)$OSC|;
	[ $r, $g, $b ]
	}

sub iterm_bg_color () { _iterm_rgb_query( -2 ) } # OSC 4 ; -2; ? ST
sub iterm_fg_color () { _iterm_rgb_query( -1 ) } # OSC 4 ; -1; ? ST

=item * iterm_start_link( URL [, ID] )

=item * iterm_end_link()

Mark some text as a clickable URL.
OSC 8 ; [params] ; [url] ST id is only param

=item * iterm_linked_text( TEXT, URL, [, ID] )

=cut

sub iterm_start_link ( $url, $id = undef ) {
	$id = defined $id ? "id=$id" : '';
	OSC() . 8 . ';' . $id . ';' . $url . ST();
	}

sub iterm_end_link () { OSC() . 8 . ';;' . ST() }

sub iterm_linked_text ( $text, $url, $id = undef ) {
	iterm_start_link( $url, $id ) .
	$text .
	iterm_end_link();
	}

=item * iterm_set_cursor_shape( N )

Change the cursor shape the iTerm2 way (C<OSC 1337 ; CursorShape=N ST>):

=over 4

=item * 0 Block

=item * 1 Vertical bar

=item * 2 Underline

=back

Any other N carps and returns nothing. These numbers aren't the same as
the standard ones that C<cursor_shape> uses, which work in iTerm2 and
most other terminals; see "Changing the cursor shape".

=item * iterm_set_block_cursor

=item * iterm_set_bar_cursor

=item * iterm_set_underline_cursor

Change the cursor to a block, a vertical bar, or an underline. Like the
other iTerm2 functions, these work only in iTerm2; anywhere else, they
carp and return nothing.

=cut

sub _osc_1337 ( $content ) {
	unless( _is_iterm() ) {
		my $sub = ( caller(1) )[3];
		carp( "$sub only works in iTerm2" );
		return;
		}

	OSC() . 1337 . ';' . $content . ST()
	}

# OSC 1337 ; CursorShape=[N] ST
sub _iterm_set_cursor ( $n ) {
	unless( $n == 0 or $n == 1 or $n == 2 ) {
		carp "The cursor type can be 0, 1, or 2, but you specified <$n>";
		return;
		}

	# Check here rather than leaving it to _osc_1337 so the warning
	# names the public function (such as iterm_set_bar_cursor) instead
	# of this one.
	unless( _is_iterm() ) {
		my $sub = ( caller(1) )[3];
		carp( "$sub only works in iTerm2" );
		return;
		}

	_osc_1337( "CursorShape=$n" );
	}

sub iterm_set_cursor_shape ( $n ) { _iterm_set_cursor( $n ) }

sub iterm_set_block_cursor ()     { state $s = _iterm_set_cursor(0); $s }
sub iterm_set_bar_cursor ()       { state $s = _iterm_set_cursor(1); $s }
sub iterm_set_underline_cursor () { state $s = _iterm_set_cursor(2); $s }

=item * set_mark

Same as Command-Shift-M. Mark the current location and jump back to it
with Command-Shift-J.

=cut

# OSC 1337 ; SetMark ST
sub set_mark () { state $s = _osc_1337( 'SetMark' ); $s }

=item * steal_focus

Bring the window to the foreground.

=cut

# OSC 1337 ; StealFocus ST
sub steal_focus () { state $s = _osc_1337( 'StealFocus' ); $s }

=item * clear_scrollback_history

Erase the scrollback history.

=cut

# OSC 1337 ; ClearScrollback ST
sub clear_scrollback_history () { state $s = _osc_1337( 'ClearScrollback' ); $s }

=item * post_notification

=cut

# OSC 9 ; [Message content goes here] ST

=item * set_current_directory

=cut

# OSC 1337 ; CurrentDir=[current directory] ST

=item * change_profile

=cut

# OSC 1337 SetProfile=[new profile name] ST

=item * start_copy_to_clipboard

=item * end_copy_to_clipboard

=cut

# OSC 1337 ; CopyToClipboard=[clipboard name] ST
# OSC 1337 ; EndCopy ST

=item * change_color_palette

[key] gives the color to change. The accepted values are: fg bg bold link selbg selfg curbg curfg underline tab" black red green yellow blue magenta cyan white br_black br_red br_green br_yellow br_blue br_magenta br_cyan br_white

[value] gives the new color. The following formats are accepted:

RGB (three hex digits, like fff)
RRGGBB (six hex digits, like f0f0f0)
cs:RGB (like RGB but cs gives a color space)
cs:RRGGBB (like RRGGBB but cs gives a color space)
If a color space is given, it should be one of:

srgb (the standard sRGB color space)
rgb (the device-specific color space)
p3 (the standard P3 color space, whose gamut is supported on some newer hardware)

=cut

# OSC 1337 ; SetColors=[key]=[value] ST


=item * add_annotation

OSC 1337 ; AddAnnotation=[message] ST
OSC 1337 ; AddAnnotation=[length] | [message] ST
OSC 1337 ; AddAnnotation=[message] | [length] | [x-coord] | [y-coord] ST
OSC 1337 ; AddHiddenAnnotation=[message] ST
OSC 1337 ; AddHiddenAnnotation=[length] | [message] ST
OSC 1337 ; AddHiddenAnnotation=[message] | [length] | [x-coord] | [y-coord] ST
`[message]`: The message to attach to the annotation.
`[length]`: The number of cells to annotate. Defaults to the rest of the line beginning at the start of the annotation.
`[x-coord]` and `[y-coord]`: The starting coordinate for the annotation. Defaults to the cursor's coordinate.

=cut

sub add_annotation () {}

=item * hide_cursor_guide

=item * show_cursor_guide

=cut

# OSC 1337 ; HighlightCursorLine=[boolean] ST
sub hide_cursor_guide () { state $s = _osc_1337( 'HighlightCursorLine=no'  ); $s }
sub show_cursor_guide () { state $s = _osc_1337( 'HighlightCursorLine=yes' ); $s }

=item * iterm_attention

Play with the dock icon.

=over 4

=item * fireworks - animation at the cursor

=item * no - stop bouncing the dock icon

=item * once - bounce the dock icon once

=item * yes - bounce the dock indefinitely

=back

=cut

=item * iterm_bounce_dock_icon

Bounce the Dock icon, continuously

=item * iterm_bounce_dock_icon_once

Bounce the Dock icon, only once

=item * iterm_unbounce_dock_icon

Stop bouncing the Dock icon

=item * iterm_fireworks

Show animated fireworks.

=cut


# OSC 1337 ; RequestAttention=[value] ST
sub iterm_attention ( $value ) {
	state $allowed = do {
		my %hash = map { $_, 1 } qw( fireworks no once yes );
		\%hash;
		};
	unless( exists $allowed->{$value} ) {
		carp "iterm_attention argument can be one of <@{[ join ',', sort keys %$allowed ]}>, but you specified <$value>";
		return;
		}

	_osc_1337( "RequestAttention=$value" );
	}
sub iterm_bounce_dock_icon      { iterm_attention( 'yes' )  }
sub iterm_bounce_dock_icon_once { iterm_attention( 'once' ) }
sub iterm_unbounce_dock_icon    { iterm_attention( 'no' )   }
sub iterm_fireworks             { iterm_attention( 'fireworks' )  }

=item * background_image_file

OSC 1337 ; SetBackgroundImageFile=[base64] ST
The value of [base64] is a base64-encoded filename to display as a background image. If it is an empty string then the background image will be removed. User confirmation is required as a security measure.

=item * report_cell_cell

OSC 1337 ; ReportCellSize ST
The terminal responds with either:

OSC 1337 ; ReportCellSize=[height];[width] ST
Or, in newer versions:

OSC 1337 ; ReportCellSize=[height];[width];[scale] ST
[scale] gives the number of pixels (physical units) to points (logical units). 1.0 means non-retina, 2.0 means retina. It could take other values in the future.

[height] and [width] are floating point values giving the size in points of a single character cell. For example:

OSC 1337 ; ReportCellSize=17.50;8.00;2.0 ST

=item * copy_to_pasteboard

You can place a string in the system's pasteboard with this sequence:

OSC 1337 ; Copy=:[base64] ST
Where [base64] is the base64-encoded string to copy to the pasteboard.

=item * report_variable

Each iTerm2 session has internal variables (as described in Scripting Fundamentals). This escape sequence reports a variable's value:

OSC 1337 ; ReportVariable=[base64] ST
Where [base64] is a base64-encoded variable name, like session.name. It responds with:

OSC 1337 ; ReportVariable=[base64] ST
Where [base64] is a base64-encoded value.

https://iterm2.com/documentation-scripting-fundamentals.html

=item * badge

The badge may be set with the following control sequence:

https://iterm2.com/documentation-badges.html

OSC 1337 ; SetBadgeFormat=Base-64 encoded badge format ST
Here's an example that works in bash:

# Set badge to show the current session name and git branch, if any is set.
printf "\e]1337;SetBadgeFormat=%s\a" \
  $(echo -n "\(session.name) \(user.gitBranch)" | base64)

=item * downloads

https://iterm2.com/documentation-images.html

The width and height are given as a number followed by a unit, or the word "auto".

iTerm2 extends the xterm protocol with a set of proprietary escape sequences. In general, the pattern is:

ESC ] 1337 ; key = value ^G
Whitespace is shown here for ease of reading: in practice, no spaces should be used.

For file transfer and inline images, the code is:

ESC ] 1337 ; File = [arguments] : base-64 encoded file contents ^G
The arguments are formatted as key=value with a semicolon between each key-value pair. They are described below:

Key		Description of value
name	  	base-64 encoded filename. Defaults to "Unnamed file".
size	  	File size in bytes. The file transfer will be canceled if this size is exceeded.
width	  	Optional. Width to render. See notes below.
height	  	Optional. Height to render. See notes below.
preserveAspectRatio	  	Optional. If set to 0, then the image's inherent aspect ratio will not be respected; otherwise, it will fill the specified width and height as much as possible without stretching. Defaults to 1.
inline	  	Optional. If set to 1, the file will be displayed inline. Otherwise, it will be downloaded with no visual representation in the terminal session. Defaults to 0.
N: N character cells.
Npx: N pixels.
N%: N percent of the session's width or height.
auto: The image's inherent size will be used to determine an appropriate dimension.
More on File Transfers
By omitting the inline argument (or setting its value to 0), files will be downloaded and saved in the Downloads folder instead of being displayed inline. Any kind of file may be downloaded, but only images will display inline. Any image format that macOS supports will display inline, including PDF, PICT, EPS, or any number of bitmap data formats (PNG, GIF, etc.). A new menu item titled Downloads will be added to the menu bar after a download begins, where progress can be monitored and the file can be located, opened, or removed.

If the file's size exceeds the declared size, the transfer may be canceled. This is a security measure to prevent a download gone wrong from using unbounded memory.

=item * uploads

To request the user select one or more files to upload, send:

OSC 1337 ; RequestUpload=format=[type] ST
In the future the [type] may be configurable, but for now it must always be tgz, which is a tar and gzipped file.

When iTerm2 receives this it will respond with a status of ok or abort followed by a newline. If the status is ok then it will be followed by a base-64 encoded tar.gz file.

If the user selects multiple files they will be placed in a directory within the tar file.

=item * set_touchbar_key_levels

You can configure touch bar key labels for function keys and for the "status" button. The code used is:

OSC 1337 ; SetKeyLabel=[key]=[value] ST
Where [key] is one of F1, F2, ..., F24, to adjust a function key label; or it can be status to adjust the touch bar status button. You can also save and restore sets of key labels using a stack. To push the current key labels on the stack use:

OSC 1337 ; PushKeyLabels ST
To pop them:

OSC 1337 ; PopKeyLabels ST
You can optionally label the entry in the stack when you push so that pop will pop multiple sets of key labels if needed. This is useful if a program crashes or an ssh session exits unexpectedly. The corresponding codes with labels are:

OSC 1337 ; PushKeyLabels=[label] ST
OSC 1337 ; PopKeyLabels=[label] ST
Where [label] is an ASCII string that works best if it is unique in the stack.

=item * unicode_version

iTerm2 by default uses Unicode 9's width tables. The user can opt to use Unicode 8's tables with a preference (for backward compatibility with older locale databases). Since not all apps will be updated at the same time, you can tell iTerm2 to use a particular set of width tables with:

OSC 1337 ; UnicodeVersion=[n] ST
Where [n] is 8 or 9

You can push the current value on a stack and pop it off to return to the previous value by setting n to push or pop. Optionally, you may affix a label after push by setting n to something like push mylabel. This attaches a label to that stack entry. When you pop the same label, entries will be popped until that one is found. Set n to pop mylabel to effect this. This is useful if a program crashes or an ssh session ends unexpectedly.

=back

=head1 SEE ALSO

=over 4

=item * Everything you never wanted to know about ANSI escape codes https://notes.burke.libbey.me/ansi-escape-codes/

=item * https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797

=item * iTerm2 ANSI codes https://iterm2.com/documentation-escape-codes.html

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/antsy

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2021-2026, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
