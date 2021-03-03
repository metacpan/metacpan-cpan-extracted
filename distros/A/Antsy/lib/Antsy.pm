use v5.32;

package Antsy;
use strict;
use warnings;
use utf8;
use experimental qw(signatures);

use Carp     qw(carp);
use Exporter qw(import);

our( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

our $VERSION = '0.901';

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

=head1 SEE ALSO

=over 4

=item * Everything you never wanted to know about ANSI escape codes https://notes.burke.libbey.me/ansi-escape-codes/

=item * https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797

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

sub _256 ( $i, $n ) {
	carp "Bad 256 $n" unless( int($n) == $n and $n >= 0 and $n <= 255 );
	_seq( 'm', $i, 5, $n );
	}

sub _bg () { 48 }  # a magic number that applies the SGR to the background

sub _erase ( $n, $command ) {
	carp "Bad value <$n>. Should be 0,1, or 2"
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

	my @templates = ( 'clear_%s', 'clear_to_%s_end', 'clear_to_%s_start' );

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

1;
