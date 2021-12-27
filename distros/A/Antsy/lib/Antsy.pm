use v5.32;

package Antsy;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);

use Carp     qw(carp);
use Exporter qw(import);

our( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

our $VERSION = '0.903';

=encoding utf8

=head1 NAME

Antsy - Streaming ANSI escape sequences

=head1 SYNOPSIS

	use Antsy qw(:all);

	print bold, underline, text_red, "Hello", reset;

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

=item * blink

Make the text blink (however your terminal does that).

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

Make the text invisible (if your terminal handles that).

=item * cursor_back( N )

Move the cursor back N positions.

=item * cursor_column( N )

Move the cursor to column N.

=item * cursor_down( N )

Move the cursor down N positions.

=item * cursor_forward( N )

Move the cursor forward N positions.

=item * cursor_next_line( N )

Move the cursor down N lines, to the start of the line

=item * cursor_previous_line( N )

Move the cursor up N lines, to the start of the line

=item * cursor_row_column( N, M )

Move the cursor to row N and column M.

=item * cursor_up

TK: Fill in details

=item * dark

Make the text dark (however your terminal does that).

=item * erase_in_display( [ 0, 1, 2, 3 ] )

TK: Fill in details

=item * erase_in_line( [ 0, 1, 2, 3 ] )

TK: Fill in details

=item * hide_cursor

Hide the cursor. See also C<show_cursor>.

=item * italic

Turn on italic.

=item * reset

Turn off all attributes

=item * restore_cursor

Put the cursor back to where you saved it. See also C<save_cursor>.

=item * reverse

Use the background color for the text color, and the text color
for the background.

=item * save_cursor

Save the current location of the cursor. See also C<save_cursor>.

=item * scroll_down( N )

Scroll down N lines.

=item * scroll_up( N )

Scroll up N lines.

=item * show_cursor

Show the cursor. See also C<hide_cursor>.

=item * text_256( N )

Make the foreground the color N in the xterm 256 color chart.

This dies if N is not a positive number between 0 and 255 (inclusive).

=item * text_black

=item * text_blue

=item * text_cyan

=item * text_green

=item * text_magenta

=item * text_red

=item * text_rgb

=item * text_white

=item * text_yellow

Make foreground text the named color.

=item * text_blink

Make the text blink.

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

=item * text_concealed

Conceal the text.

=item * underline

Turn on underlining.

=back

=cut

sub _256 ( $i, $n ) {
	carp "Bad 256 $n" unless( int($n) == $n and $n >= 0 and $n <= 255 );
	_seq( 'm', $i, 5, $n );
	}

sub _bg () { 48 }  # a magic number that applies the SGR to the background

sub _erase ( $n, $command ) {
	carp "Bad value <$n>. Should be 0, 1, or 2"
		unless grep { $_ == $n } qw(0 1 2);
	carp "Bad erase command <$command>. Should be J or K"
		unless grep { $_ == $n } qw(0 1 2);
	_seq( $command, $n );
	}

sub _export ( $name, $tag ) {
	push @EXPORT_OK,             $name;
	push $EXPORT_TAGS{all }->@*, $name;
	push $EXPORT_TAGS{$tag}->@*, $name;
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

sub text_256 ( $n         ) { _256( _text(), $n ) }
sub text_rgb ( $r, $g, $b ) { _rgb( _text(), $r, $g, $b ) }


# This section takes the subroutines that we've already defined to
# adds them to the export lists.
BEGIN {
	my @subs = qw( bg_256 bg_rgb text_256 text_rgb
		erase_in_display erase_in_line cursor_row_column
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
	my @groups = (
		[ qw( cursor back           D ) ],
		[ qw( cursor column         G ) ],
		[ qw( cursor down           B ) ],
		[ qw( cursor forward        C ) ],
		[ qw( cursor next_line      E ) ],
		[ qw( cursor previous_line  F ) ],
		[ qw( cursor up             A ) ],
		[ qw( scroll down           T ) ],
		[ qw( scroll up             S ) ],
		);

	foreach my $group ( @groups ) {
		no strict 'refs';

		my( $export_tag, $fragment, $command ) = @$group;
		my $name = join '_', $export_tag, $fragment;

		*{$name} = sub ( $n ) {
			$n = $n =~ /\A([0-9]+)\z/ ? $1 : 0;
			_seq( $command, $n );
			};

		_export( $name, $export_tag );
		}
	}

BEGIN {
	my @groups = (
		# EXPORT_TAG  SUB_NAME  COMMAND ARGS
		[ qw( control reset          m    0 ) ],
		[ qw( text    bold           m    1 ) ],
		[ qw( text    dark           m    2 ) ],
		[ qw( text    italic         m    3 ) ],
		[ qw( text    underline      m    4 ) ],
		[ qw( text    blink          m    5 ) ],
		[ qw( text    reverse        m    7 ) ],
		[ qw( text    conceal        m    8 ) ],
		[ qw( cursor  save_cursor    s      ) ],
		[ qw( cursor  restore_cursor u      ) ],
		[ qw( cursor  hide_cursor    h  ?25 ) ],
		[ qw( cursor  show_cursor    l  ?25 ) ],
		);

	foreach my $group ( @groups ) {
		no strict 'refs';

		my( $export_tag, $name, $command, $n ) =  @$group;
		$n //= '';
		my $value = _seq( $command, $n );

		*{$name} = sub () { $value };

		_export( $name, $export_tag );
		}
	}

BEGIN {
	my @colors = qw( black red green yellow blue magenta cyan white );
	my %colors = map { state $n = 0; $_ => $n++ } @colors;

	my @groups = (
		[   (   0, '',       '%s' ) ],
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
			_export( $name, $group->[1] );
			}
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
	$ENV{TERM_PROGRAM} =~ m/\A\Q$id\E\z/;
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
	$id = defined $id ? 'id=$id' : '';
	OSC() . 8 . ';' . $id . ';' . $url . ST();
	}

sub iterm_end_link () { OSC() . 8 . ';;' . ST() }

sub iterm_linked_text ( $text, $url, $id ) {
	iterm_start_link( $url, $id ) .
	$text .
	iterm_end_link();
	}

=item * set_cursor_shape( N )

=over 4

=item * 0 Block

=item * 1 Vertical bar

=item * 2 Underline

=back

=item * iterm_set_block_cursor

=item * iterm_set_bar_cursor

=item * iterm_set_underline_cursor

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

	OSC() . 1337 . ';' . "CursorShape=$n" . 'ST'
	}

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

	my $r = _osc_1337( "RequestAttention=$value" );
	say _encode_seq( $r );
	$r;
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

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2021, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
