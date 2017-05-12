package Acme::POE::Tree;

use warnings;
use strict;

use Curses;
use POE qw(Wheel::Curses);
use IO::Tty;

use constant CYCLE_TYPE => "random"; # "random" or "cycle"
use constant LIGHT_TYPE => "strand"; # "random" or "strand"
use constant DIM_BULBS => 0; # enable dim bulbs

our $VERSION = '1.022';

sub new {
	my ($class, $arg) = @_;

	my $self = bless { %{$arg || {}} }, $class;

	$self->{light_delay} ||= 1;
	$self->{star_delay}  ||= 1.33;

	POE::Session->create(
		object_states => [
			$self => {
				_start        => "_setup_tree",
				got_keystroke => "_handle_keystroke",
				got_sigwinch  => "_handle_sigwinch",
				paint_tree    => "_paint_tree",
				light_cycle   => "_cycle_lights",
				star_cycle    => "_cycle_star",
				shut_down     => "_handle_shut_down",
			},
		],
	);

	return $self;
}

sub run {
	my $self = shift;
	POE::Kernel->run();
}

sub _setup_tree {
	my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

	# Tell this session about terminal size changes.
	$kernel->sig(WINCH => "got_sigwinch");

	# Set up Curses, and notify this session when there's input.
	$heap->{console} = POE::Wheel::Curses->new(
		InputEvent => 'got_keystroke',
	);

	# Initialize the tree's color palette.
	my @light_colors = (
		COLOR_BLUE, COLOR_YELLOW, COLOR_RED, COLOR_GREEN, COLOR_MAGENTA
	);

	init_pair($_, $light_colors[$_-1], COLOR_BLACK) for 1..@light_colors;
	$heap->{light_colors} = [ map { COLOR_PAIR($_) } (1..@light_colors) ];

	init_pair(@light_colors + 2, COLOR_GREEN, COLOR_BLACK);
	$heap->{color_tree} = COLOR_PAIR(@light_colors + 2) | A_DIM;

	init_pair(@light_colors + 3, COLOR_WHITE, COLOR_BLACK);
	$heap->{color_bg} = COLOR_PAIR(@light_colors + 3);

	init_pair(@light_colors + 4, COLOR_YELLOW, COLOR_BLACK);
	$heap->{color_star} = COLOR_PAIR(@light_colors + 4);

	# Start the star cycle.
	$heap->{star_cycle} = 0;

	# Start the star and light timers.
	$kernel->delay("light_cycle", $self->{light_delay});
	$kernel->delay("star_cycle", $self->{star_delay});

	# Run until an automatic cutoff time has elapsed.
	$kernel->delay("shut_down", $self->{run_for}) if $self->{run_for};

	# Cause the tree to be painted.
	$kernel->yield("paint_tree");
}

# Some window managers send a lot of window-change signals during a
# window resize.  This waits for the user to let go before finally
# painting the new tree.

sub _handle_sigwinch {
	$_[KERNEL]->delay(paint_tree => 0.5);
}

# Handle keystrokes.  Quit if the user presses "q".

sub _handle_keystroke {
	my $keystroke = $_[ARG0];

	# Make control and extended keystrokes printable.
	if ($keystroke lt ' ') {
		$keystroke = '<' . uc(unctrl($keystroke)) . '>';
	}
	elsif ($keystroke =~ /^\d{2,}$/) {
		$keystroke = '<' . uc(keyname($keystroke)) . '>';
	}

	if ( $keystroke eq '<^C>' or $keystroke eq 'q') {
		$_[KERNEL]->yield("shut_down");
	}
}

# Repaint the tree.  This happens after every terminal resize.

sub _paint_tree {
	my $heap = $_[HEAP];
	$heap->{lights} = grow_tree($heap);
}

# Periodically change which lights are lit.

sub _cycle_lights {
	my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

	if (CYCLE_TYPE eq "random") {
		foreach my $light (@{$heap->{lights}}) {
			next unless rand() < 0.25;

			$light->{lit} = !$light->{lit};
			$light->{c_paint} = $light->{c_main} | ($light->{lit} ? A_BOLD : A_DIM);

			if ($light->{lit} or DIM_BULBS) {
				attrset($light->{c_paint});
				addstr($light->{y}, $light->{x}, "o");
			}
			else {
				addstr($light->{y}, $light->{x}, " ");
			}
		}
	}
	elsif (CYCLE_TYPE eq "cycle") {
		foreach my $light (@{$heap->{lights}}) {
			$light->{lit} = (
				$light->{c_main} == $heap->{light_colors}[$heap->{light_cycle} || 0]
			) || 0;
			$light->{c_paint} = $light->{c_main} | ($light->{lit} ? A_BOLD : A_DIM);

			if ($light->{lit} or DIM_BULBS) {
				attrset($light->{c_paint});
				addstr($light->{y}, $light->{x}, "o");
			}
			else {
				addstr($light->{y}, $light->{x}, " ");
			}
		}

		$heap->{light_cycle}++;
		$heap->{light_cycle} = 0 if (
			$heap->{light_cycle} >= @{$heap->{light_colors}}
		);
	}

	do_refresh($heap);

	$kernel->delay("light_cycle", $self->{light_delay});
}

# The star periodically shimmers.

sub _cycle_star {
	my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

	$heap->{star_cycle}++;
	draw_star($heap);

	do_refresh($heap);

	$kernel->delay("star_cycle", $self->{star_delay});
}

# Grow a new tree.  Returns a list of lights to be cycled by timers
# later.

sub grow_tree {
	my $heap = shift;

	# Make sure Curses knows the current terminal size.

	my ($lines, $cols) = ($LINES, $COLS);
	eval {
		my $winsize = " " x 64;
		ioctl(STDOUT, &IO::Tty::Constant::TIOCGWINSZ, $winsize) or die $!;
		($lines, $cols) = unpack("S2", $winsize);
	};

	# TODO - How to do this portably?
	eval { resizeterm($lines, $cols) };

	# Clear the screen in the default color.  Add vertical bars to
	# either side of the screen, as this sometimes ensures erasure.

	attrset($heap->{color_bg});
	clear();
	addstr($_-1, 0, "|" . (" " x ($cols-2)) . "|") for 1..$lines;

	# Draw the tree.

	my $tier_width = 2;
	my $tier_height = 4;
	my $tier_width_increment = 8;
	my $light_density = 0.05;

	my $center = int($cols / 2);

	my $tier_pos = 4;

	my @tiers;

	TIER: while ($tier_pos < $lines - $tier_height) {
		for my $subtier (0..$tier_height-1) {
			last TIER if $tier_width >= $cols - 5;

			my $y = $tier_pos + $subtier;
			my $x = $center - int($tier_width / 2);
			my $w = $tier_width - 1;

			push @tiers, { y => $y, x => $x + 1, w => $w } if $w > 0;

			attrset($heap->{color_tree});
			addstr($y, $center - int($tier_width / 2), "/");
			addstr($y, $center + int($tier_width / 2), "\\");

			$tier_width += 2 * ($tier_width_increment / $tier_height);
		}

		$tier_pos += $tier_height;
		$tier_width -= $tier_width_increment;
	}

	# Distribute lights throughout the tree's area.

	my $area = 0;
	$area += $_->{w} foreach @tiers;

	my @lights;
	if (LIGHT_TYPE eq "random") {
		for my $light_i (1..$area / 10) {

			my $light_pos = int(rand $area);
			my ($x, $y);
			TIER: foreach my $tier (@tiers) {
				if ($light_pos < $tier->{w}) {
					$x = $tier->{x} + $light_pos;
					$y = $tier->{y};
					last TIER;
				}
				$light_pos -= $tier->{w};
			}

			next unless defined $x and defined $y;
			push @lights, { y => $y, x => $x };
			addstr($y, $x, "o");
		}
	}
	elsif (LIGHT_TYPE eq "strand") {
		LIGHT: for my $light_i (0..($area/10)) {

			my $light_pos = $light_i * 10 + int(rand 5) - 2;

			my ($x, $y);
			TIER: foreach my $tier (@tiers) {
				if ($light_pos < $tier->{w}) {
					$x = $tier->{x} + $light_pos;
					$y = $tier->{y};
					next LIGHT if $y < $tiers[2]{y}; # avoid collision with star
					last TIER;
				}
				$light_pos -= $tier->{w};
			}

			next LIGHT unless defined $y and defined $x;
			push @lights, { y => $y, x => $x };
		}
	}

	# Assign colors to each light.

	for (0..$#lights) {
		my $light = $lights[$_];

		my $color_index = $_ % @{$heap->{light_colors}};
		my $color = $heap->{light_colors}[$color_index];

		$light->{c_main} = $color;
		$light->{lit} = 0;
		$light->{c_paint} = $color | ($light->{lit} ? A_BOLD : A_DIM);

		if ($light->{lit} or DIM_BULBS) {
			attrset($light->{c_paint});
			addstr($light->{y}, $light->{x}, "o");
		}
		else {
			addstr($light->{y}, $light->{x}, " ");
		}
	}

	# Put the star on top of the tree.

	$heap->{star_center_y} = $tiers[0]{y} - 1;
	$heap->{star_center_x} = $center;
	draw_star($heap);

	do_refresh($heap);

	return \@lights;
}

# Draw the star.  Also used to shimmer the star based on a moving
# "star cycle".

sub draw_star {
	my $heap = shift;

	my $center_y = $heap->{star_center_y};
	my $center_x = $heap->{star_center_x};
	my $cycle = $heap->{star_cycle};

	my $color_inner = $heap->{color_bg} | ($cycle % 2 ? A_DIM : A_BOLD);
	my $color_outer = $heap->{color_bg} | ($cycle % 2 ? A_BOLD : A_DIM);
	my $color_star  = $heap->{color_star} | ($cycle % 2 ? A_DIM : A_BOLD);

	attrset($color_star);
	addstr($center_y, $center_x, "O");

	attrset($color_inner);
	addstr($center_y - 1, $center_x - 1, "\\");
	addstr($center_y + 1, $center_x + 1, "\\");
	addstr($center_y - 1, $center_x + 1, "/");
	addstr($center_y + 1, $center_x - 1, "/");

	attrset($color_outer);
	addstr($center_y, $center_x - 1, "=");
	addstr($center_y, $center_x + 1, "=");
	addstr($center_y - 1, $center_x, "|");
	addstr($center_y + 1, $center_x, "|");

	attrset($color_inner);
	addstr($center_y, $center_x - 2, "-");
	addstr($center_y, $center_x + 2, "-");
	addstr($center_y - 2, $center_x, "|");
	addstr($center_y + 2, $center_x, "|");

	attrset($color_outer);
	addstr($center_y, $center_x - 3, "-");
	addstr($center_y, $center_x + 3, "-");
}

# Common refresh code.

sub do_refresh {
	my $heap = shift;

	attrset($heap->{color_bg});
	addstr(0, 0, "Press q to quit.");
	refresh();
}

# Common shutdown code.

sub _handle_shut_down {
	delete $_[HEAP]{console};
	$_[KERNEL]->delay("light_cycle", undef);
	$_[KERNEL]->delay("star_cycle", undef);
}

1;

__END__

=head1 NAME

Acme::POE::Tree - an animated christmas tree

=head1 SYNOPSIS

	perl -MAcme::POE::Tree -e 'Acme::POE::Tree->new()->run()'

=head1 DESCRIPTION

Acme::POE::Tree uses IO::Tty to learn the current terminal size,
Curses to fill the terminal with a colorful Christmas tree, and POE to
animate the lights.

=head1 PUBLIC METHODS

=head2 new

Create a new Acme::POE::Tree application.  The light and star
animation delays may be set here.  The tree may also be set to exit
automatically after a short amount of time:

	use Acme::POE::Tree;
	my $tree = Acme::POE::Tree->new(
		{
			star_delay => 1.5,  # shimmer star every 1.5 sec
			light_delay => 2,   # twinkle lights every 2 sec
			run_for => 10,      # automatically exit after 10 sec
		}
	);
	$tree->run();

=head2 run

Run the tree until the user decides they've had enough.

=head1 AUTHOR

Rocco Caputo <rcaputo@cpan.org> with debugging and feedback from
irc.perl.org channel #poe.

=head1 BUG TRACKER

https://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Acme-POE-Tree

=head1 REPOSITORY

http://github.com/rcaputo/acme-poe-tree

=head1 OTHER RESOURCES

http://search.cpan.org/dist/Acme-POE-Tree/

=head1 COPYRIGHT

Copyright (c) 2008-2010, Rocco Caputo.  All Rights Reserved.  This
module is free software.  It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
