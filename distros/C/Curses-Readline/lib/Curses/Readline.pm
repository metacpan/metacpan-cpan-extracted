package Curses::Readline;

use 5.010;
use strict;
use warnings;
use parent 'Exporter';
use Curses;

our @EXPORT_OK = 'curses_readline';

our $VERSION = '0.9';

sub curses_readline {
    my ($prefix) = @_;
    $prefix //= ':';

    my $buffer        = '';
    my $cursor_pos    = 0;
    my $buffer_offset = 0;

    my ( $lines, $columns );
    getmaxyx( $lines, $columns );
    move( $lines + 1, $columns );
    addstring( $lines - 1, 0, ":" );

    my $half_width = int( $columns / 2 );

    while (1) {

        ## cursor_pos and buffer_offset are zero-based, columns
        ## start at one!
        if ( $cursor_pos + 1 >= $columns ) {
            $buffer_offset += $half_width - 1;
            $cursor_pos = length($buffer) - $buffer_offset;
        }
        elsif ( $cursor_pos < 0 ) {
            if ( $buffer_offset != 0 ) {
                $buffer_offset -= $half_width - 1;
                $cursor_pos = $half_width - 2;
            }
            else {
                $cursor_pos = 0;
            }
        }

        addstring( $lines - 1, 0,
            "$prefix" . substr( $buffer, $buffer_offset, $columns - 1 ) );
        clrtoeol;
        move( $lines - 1, $cursor_pos + 1 );
        refresh;

        my $c = getch;
        if ( $c eq "\cG" ) {
            $buffer = undef;
            last;
        }
        elsif ( $c eq "\n" ) {
            last;
        }
        elsif ( $c eq KEY_LEFT ) {
            $cursor_pos--;
        }
        elsif ( $c eq KEY_RIGHT ) {
            next if $cursor_pos == length($buffer) - $buffer_offset;
            $cursor_pos++;
        }
        elsif ( $c eq KEY_HOME || $c eq "\cA" ) {
            $cursor_pos    = 0;
            $buffer_offset = 0;
        }
        elsif ( $c eq "\cK" ) {
            substr( $buffer, $buffer_offset + $cursor_pos ) = '';
        }
        elsif ( $c eq KEY_END || $c eq "\cE" ) {
            my $l = length($buffer);
            if ( $l >= $columns ) {
                $buffer_offset = $l - $columns + 2;
                $cursor_pos    = $columns - 2;
            }
            else {
                $cursor_pos = $l;
            }
        }
        elsif ( $c eq KEY_BACKSPACE ) {
            next if $buffer_offset == 0 && $cursor_pos == 0;
            $cursor_pos--;
            substr( $buffer, $buffer_offset + $cursor_pos, 1 ) = '';
        }
        elsif ( $c eq "\cD" ) {
            substr( $buffer, $buffer_offset + $cursor_pos, 1 ) = '';
        }
        else {
            substr( $buffer, $buffer_offset + $cursor_pos, 0 ) = $c;
            $cursor_pos++;
        }
    }
    move( $lines - 1, 0 );
    clrtoeol;
    return $buffer;
}

1;

__END__

=pod

=head1 NAME

Curses::Readline - Readline library for curses

=head1 SYNOPSIS

	use Curses::Readline qw(curses_readline);
	use Curses;

	initscr;
	curses_readline;
	endwin;

=head1 DESCRIPTION

This library provides a way to query a user for a line with
readline-like key bindings in a curses windows. It behaves similar to
the command line in mutt or vi.

The prompt is displayed on the last line of the curses window, which
will be emptied on a call to I<curses_readline()>.

=head1 COPYRIGHT AND LICENSE

Copyright 2019 Mario Domgoergen C<< <mario@domgoergen.com> >>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
