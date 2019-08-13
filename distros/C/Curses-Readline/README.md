# NAME

Curses::Readline - Readline library for curses

# SYNOPSIS

        use Curses::Readline qw(curses_readline);
        use Curses;

        initscr;
        curses_readline;
        endwin;

# DESCRIPTION

This library provides a way to query a user for a line with
readline-like key bindings in a curses windows. It behaves similar to
the command line in mutt or vi.

The prompt is displayed on the last line of the curses window, which
will be emptied on a call to _curses\_readline()_.

# COPYRIGHT AND LICENSE

Copyright 2019 Mario Domgoergen `<mario@domgoergen.com>`

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see &lt;http://www.gnu.org/licenses/>.
