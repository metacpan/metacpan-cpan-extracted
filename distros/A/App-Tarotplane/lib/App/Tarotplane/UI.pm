package App::Tarotplane::UI;
use 5.016;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%KEY_BINDINGS);

use Carp;
use Text::Wrap qw(wrap $columns);

use Curses;

# Tells whether Curses is running or not, so that multiple objects don't try to
# run Curses.
my $CURSED = 0;

our %KEY_BINDINGS = (
	Next  => [ 'l', KEY_RIGHT, ],
	Prev  => [ 'h', KEY_LEFT, ],
	Flip  => [ 'j', 'k', ' ', KEY_UP, KEY_DOWN, ],
	First => [ KEY_NPAGE, KEY_END, ],
	Last  => [ KEY_PPAGE, KEY_HOME, ],
	Quit  => [ 'q', ],
	Help  => [ '?', ],
);

my $CONTROLS_HELP = <<END;
Next:      right, l
Previous:  left, h
Flip:      up/down, j/k, space
First      card: page up, home
Last card: page down, end
Quit:      q
Help:      ?
END

sub init {

	my $class = shift;
	my $self = {
		MainWin => undef,
		CardWin => undef,
		InfoWin => undef,
		CardStr => '',
		InfoStr => '',
	};

	if ($CURSED) {
		croak "Curses is already running";
	}

	initscr();

	curs_set(0);
	cbreak();
	noecho();
	keypad(1);

	$self->{MainWin} = $stdscr;

	$self->{InfoWin} = newwin(1, $COLS, $LINES - 1, 0);
	$self->{CardWin} = newwin($LINES - 3, $COLS - 2, 1, 1);

	$CURSED = 1;

	bless $self, $class;
	return $self;

}

sub wipe {

	my $self = shift;

	erase($self->{MainWin});
	noutrefresh($self->{MainWin});

}

sub update {

	my $self = shift;

	doupdate();

}

sub draw_card {

	my $self = shift;
	my $str  = shift;
	my $bold = shift;

	# Make room for the box borders and a single whitespace on each side.
	my $linemax = getmaxx($self->{CardWin}) - 4;

	$self->{CardStr} = $str if defined $str;

	$columns = $linemax;
	my $text = wrap('', '', $self->{CardStr});

	if (defined $bold) {
		attrset($self->{CardWin}, $bold ? A_BOLD : A_NORMAL);
	}

	erase($self->{CardWin});
	box($self->{CardWin}, 0, 0);

	my $ypos = (getmaxy($self->{CardWin}) / 2) - (($text =~ tr/\n//) / 2);

	foreach my $l (split /\n/, $text) {
		$l =~ s/^\s+|\s+$//; # Trim leading/trailing whitespace.
		$l =~ s/\s+/ /g;     # Truncate space.
		addstr($self->{CardWin}, $ypos++, (($linemax + 4) - length($l)) / 2, $l);
	}

	noutrefresh($self->{CardWin});

}

sub draw_info {

	my $self = shift;
	my $info = shift;

	$self->{InfoStr} = $info if defined $info;

	erase($self->{InfoWin});

	addstr($self->{InfoWin}, $self->{InfoStr});

	noutrefresh($self->{InfoWin});

}

sub draw_help {

	my $self = shift;

	my $y = 0;
	foreach my $l (split /\n/, $CONTROLS_HELP) {
		addstr($self->{MainWin}, $y++, 0, $l);
	}

	noutrefresh($self->{MainWin});

}

sub update_size {

	my $self = shift;

	$self->wipe();

	resize($self->{InfoWin}, 1, $COLS);
	mvwin($self->{InfoWin}, $LINES - 1, 0);

	resize($self->{CardWin}, $LINES - 3, $COLS - 2);
	mvwin($self->{CardWin}, 1, 1);

	$self->draw_card();
	$self->draw_info();

	$self->update();

}

sub poll {

	my $self = shift;

	while (my $in = getch()) {

		if ($in eq KEY_RESIZE) {
			$self->update_size();
			next;
		}

		foreach my $k (keys %KEY_BINDINGS) {
			return $k if grep { $in eq $_ } @{$KEY_BINDINGS{$k}};
		}

		return undef;

	}

}

sub end {

	my $self = shift;

	endwin();

	foreach my $win (grep { /Win$/ } keys %{$self}) {
		$self->{$win} = undef;
	}

	$CURSED = 0;

}

DESTROY {

	my $self = shift;

	$self->end();

}

1;



=head1 NAME

App::Tarotplane::UI - tarotplane TUI

=head1 SYNOPSIS

  $ui = App::Tarotplane::UI->init();

  $ui->draw_card($cardstr);
  $ui->draw_info($infostr);
  $ui->update();

  $cmd = $ui->poll();

  $ui->wipe();
  $ui->update();

  $ui->end();

=head1 DESCRIPTION

App::Tarotplane::UI is the component of L<tarotplane> that handles the TUI
(text-user interface). It accomplishes this through the L<Curses> module. If
you're looking for documentation for L<tarotplane>, consult its manual page.

=head1 Object Methods

=head2 App::Tarotplane::UI->init()

Initializes L<Curses> and returns an App::Tarotplane::UI object. Only one
App::Tarotplane::UI object can be initialized at a single time.

=head2 $ui->wipe()

Wipes screen. Should be called before any re-drawing occurs.

=head2 $ui->update()

Updates screen with any new drawings. Should be called to display the results
of any draw method.

=head2 $ui->draw_card([$str, $bold])

Draws a new card displaying $str, automatically performing any text wrapping
necessary to fit in the card. If $bold is supplied and true, the drawn card
will be bold.

update() needs to be called to push the drawing to the screen.

If $str and/or $bold are not supplied, will use whatever was used on a previous
call to draw_card().

=head2 $ui->draw_info([$str])

Draws an info bar at the bottom of the screen containing $str.

update() needs to be calleed to push the drawing to the screen.

If $str is not supplied, uses the last string supplied by a previous
draw_info() call.

=head2 $ui->draw_help()

Wipes screen and draws help message.

update() needs to be called to push the drawing to the screen.

=head2 $ui->update_size()

Resizes drawings to fit screen, automatically performing necessary wiping and
updating.

=head2 $ui->poll()

Returns command from user input, or undef if the command does not exist. See
the documentation for %KEY_BINDINGS for a list of valid commands.

=head2 $ui->end()

Ends L<Curses>.

=head1 Global Variables

=over 4

=item %KEY_BINDINGS

Hash map of commands and their respective key bindings.

=back

=head1 AUTHOR

Written by Samuel Young E<lt>L<samyoung12788@gmail.com>E<gt>.

=head1 COPYRIGHT

Copyright 2024, Samuel Young

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<tarotplane>, L<Curses>

=cut
