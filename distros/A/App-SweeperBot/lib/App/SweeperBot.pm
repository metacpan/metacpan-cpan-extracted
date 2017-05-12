package App::SweeperBot;

# minesweeper.pl
#
# Win32::Screenshot, Win32::GuiTest, and Image::Magick are needed for this
# program. Use ActivePerl's PPM to install the first two:
#   ppm> install Win32-GuiTest
#   ppm> install http://theoryx5.uwinnipeg.ca/ppms/Win32-Screenshot.ppd
#
# The version of Image-Magick used by this code can be found at
# http://www.bribes.org/perl/ppmdir.html .  Different ImageMagick
# distributions may result in different signature codes.
#
# 20050726, Matt Sparks (f0rked), http://f0rked.com

=head1 NAME

App::SweeperBot - Play windows minesweeper, automatically!

=head1 SYNOPSIS

	C:\Path\To\Distribution> SweeperBot.exe

=head1 DESCRIPTION

This is alpha code, and released for testing and demonstration
purposes only.  It is still under active development.

Using this code for playing minesweeper on a production basis is
strongly discouraged.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp;
use NEXT;

use 5.006;

our $VERSION = '0.03';

use Scalar::Util qw(looks_like_number);
use Win32::Process qw(NORMAL_PRIORITY_CLASS);

use constant DEBUG => 0;
use constant VERBOSE => 0;
use constant CHEAT => 1;
use constant UBER_CHEAT => 0;

use constant SMILEY_LENGTH => 26;

# The minimum and maximum top dressings define the range in which
# we'll look for a smiley, which we use to calibrate our board.  Different
# windows themes put them in different places.

use constant MINIMUM_TOP_DRESSING => 56;
use constant MAXIMUM_TOP_DRESSING => 75;

my $Smiley_offset = 0;

use constant CHEAT_SAFE    => "d0737abfd3abdacfeb15d559e28c2f0b3662a7aa03ac5b7a58afc422110db75a";	# Old 58
# use constant CHEAT_SAFE    => "ad95131bc0b799c0b1af477fb14fcf26a6a9f76079e48bf090acb7e8367bfd0e";	# Old 510

use constant CHEAT_UNSAFE  => "374708fff7719dd5979ec875d56cd2286f6d3cf7ec317a3b25632aab28ec37bb";	# Old 58
# use constant CHEAT_UNSAFE  => "e3820096cb82366b860b8a4e668453a7aaaf423af03bdf289fa308ea03a79332";	# Old 510

# alarm(180);	# Nuke process after three minutes, in case of run-aways.

use Win32::Screenshot;

use Win32::GuiTest qw(
    FindWindowLike
    GetWindowRect
    SendMouse
    MouseMoveAbsPix
    SendKeys
);

# Square width and height.

use constant SQUARE_W => 16;
use constant SQUARE_H => 16;

# Top-left square location (15,104)

use constant SQUARE1X => 15;

use constant MIN_SQUARE1Y => 96;
use constant MAX_SQAURE1Y => 115;

# How far left of the smiley to click to focus on the board.
use constant FOCUS_X_OFFSET => 50;

my $Square1Y;

my %char_for = (
        0            => 0,
        unpressed    => ".",
        1            => 1,
        2            => 2,
        3            => 3,
        4            => 4,
	5            => 5,
	6            => 6,
	7            => 7,
	8            => 8,
        bomb         => "x",
        bomb_hilight => "X",
	flag         => "*",
);

# 1 => Won, -1 => Lost, 0 => Still playing

my %smiley_type = (
    'd28bcc05d38fd736f6715388a12cb0b96da9852432669671ee7866135f35bbb7' =>  1,
    'efef2037072c56fb029da1dd2cd626282173d0e1b2be39eab3e955cd2bcdc856' =>  1,
    '08938969d349a6677a17a65a57f2887a85d1a7187dcd6c20d238e279a5ec3c18' => -1,
    '7cf1797ad25730136aa67c0a039b0c596f1aed9de8720999145248c72df52d1b' => -1,
    '56f7c05869d42918830e80ad5bf841109d88e17b38fc069c3e5bf19623a88711' =>  0,
    '0955e50dda3f850913392d4e654f9ef45df046f063a4b8faeff530609b37379f' =>  0,
);

# old - Bribes distro ImageMagick
# new - "Official" ImageMagick
# NB: This code is primarily tested under the bribes distribution of
# ImageMagick, because it plays nicely with PAR.  YMMV with other
# versions.

my %contents_of_square = (
        "0b6f3e019208789db304a8a8c8bd509dacf62050a962ae9a0385733d6b595427" => 0,           # old
	"cd348e1e78e4032f472c5c065c99d8289dffff7041096aa8746e29794a032698" => 0,           # new
        "35fc6aa19ab4b99bf7d4a750767ee329b773fb2709bec46204d0ffb0a2eae1e0" => "unpressed", # old
	"880113df76cbba6336d3d1c93b035e904dbce5663acb35f9494eb292bda0226c" => "unpressed", # new
        "7a66485db1fee47e7c33acff15df5b48feccbc0328ea6e68795e52ce43649e1a" => 1,	   # old
	"99a8c67265186adef6cb5d4d4b37fefc120f096fa9df6fe0b4f90d6843fcc1e1" => 1,	   # new
        "ab70100c9ac47c63edf679d838fbb10ca38a567a16132aaf42ed2fe159aa8605" => 2,	   # old
	"3bb6ebdba9eead463b427b9cc94881626275b9efc9dfd552e174a017c601d9c2" => 2,	   # new
        "799f98eb9f61f3e96def93145a6a065cf872e67647939a7e0f4c623f38f585c3" => 3,	   # old
	"bdb6e1609d57dfa5559860e9856919ba82c844043e6a294387d975bf55208133" => 3,           # new
        "b5b29ae361a9acf85ac81abb440d5a3f7525fe80738a5770df90832d0367f7d6" => 4,	   # old
	"56c72e77e03691789f10960bd4f728af2eb7a57dd04c977e6b2ab19b349e1943" => 4,	   # new
        "bff653f26af9160d66965635c8306795ca2440cd1e4eebf0f315c7abd0242fc6" => 5,           # old
	"2ce52acf436da1971ed234b8607d4928add74c5c02d8a012fce56477b52ba251" => 5,           # new
        "931b3e6a380fd85ee808fd4ac788123a0873bb3c1c30ec1737cea8e624ff866a" => 6,	   # old
	"36dc562ae36f15c7d3917e101a998736b3dc1a457872fea40e1f4bc896c3725c" => 6,	   # new
        "e5531a6de436ac50d36096b9d1b17bad2c919923650ca48063119f9868eb3943" => 7,           # old
	"2d95bf5bb506232fe283d18d3fac1ac331ddc8116c7dde83e02a3aaae7da47e6" => 7,	   # new
        "c18dd2d3747aa97a9f432993de175bd32f8e38a70a8c122c94c737f8909bc3ca" => 8,
        "ad10157084c576142c0b0e811ddf9f935c3aab5925831fe3bf9a2da226c0c6d9" => "bomb",
        "d748d75fb4fbff41cf54237a5e0fa919189a927f1776683f141a4e38feff06ab" => "bomb_hilight",
	"e4305b6c2c750ebf0869a465f5e4f7721107bf066872edbcacd15c399ae60bff" => "flag",      # old
	"645d48aa778b2ac881a3921f3044a8ed96b8029915d9b300abbe91bef3427784" => "flag",      # new
);

=head2 new

	my $sweperbot = App::SweeperBot->new;

Creates a new C<App::SweeperBot> object.  Does not use any
arguments passed, but will send them verbatim to an C<_init>
method if defined on a child class.

=cut

sub new {
	my ($class, @args) = @_;

	my $this = {};

	bless($this, $class);

	$this->EVERY::LAST::_init(@args);

	return $this;
}



=head2 spawn_minesweeper

	$sweeperbot->spawn_minesweeper;

Attempts to spawn a new minesweeper instance.  Returns the
C<Win32::Process> object on success, or throws an exception
on error.

=cut

sub spawn_minesweeper {

    Win32::Process::Create(
	    my $minesweeper,
	    "$ENV{SystemRoot}\\system32\\winmine.exe",
	    "",
	    0,
	    NORMAL_PRIORITY_CLASS,
	    "."
    ) or croak "Cannot spawn minesweeper! - ". 
        Win32::FormatError(Win32::GetLastError());

    return $minesweeper;

}

=head2 locate_minesweeper

	$sweeperbot->locate_minesweeper;

Locates the first minesweeper window that can be found, brings
it into focus, and sets relevant state so that it can be
acessed later.  Must be used before a game can be started
or played.  Should be used if the minesweeper window
changes size or position.

Returns the window ID on success.  Throws an exception on
failure.

=cut

sub locate_minesweeper {
	my ($this) = @_;

	our $id=(FindWindowLike(0, "^Minesweeper"))[0];
        our($l,$t,$r,$b)=GetWindowRect($id);
        our($w,$h)=($r-$l,$b-$t);
        # our($reset_x,$reset_y)=($l+$w/2,$t+70);
        our($reset_x,$reset_y)=($l+$w/2,$t+81);

        # Figure out our total number of squares
        # "header" of window is 96px tall
        # left side: 15px, right side: 11px
        # bottom is 11px tall

        # TODO - These constants are bogus, and depend upon the windowing
        # style used.
        # our($squares_x,$squares_y)=(($w-15-11)/SQUARE_W,($h-96-11)/SQUARE_H);
        our($squares_x,$squares_y)=(($w-15-11)/SQUARE_W,($h-104-11)/SQUARE_H);

        # Round up squares_y.  TODO: This is a kludge to deal with
	# different window decorations.
        $squares_y = int ($squares_y + 0.9);

        our $squares=$squares_x*$squares_y;

        # Display status information
        print "Width: $w, height: $h\n" if VERBOSE;
        print "$squares_x across, $squares_y down, $squares total\n" if VERBOSE;

        print "Focusing on the window\n" if VERBOSE;
        $this->focus();

	return $id;
}

=head2 click

	$sweeperbot->click($x,$y,$button);

Clicks on ($x,$y) as an I<absolute> position on the screen.
C<$button> is any button as understood by L<Win32::GuiTest>,
usually C<{LEFTCLICK}>, C<{MIDDLECLICK}> or C<{RIGHTCLICK}>.

If not specified, C<$button> defaults to a left-click.

Returns nothing.

=cut

# Click the left button of the mouse.
# Arguments: x, y as ABSOLUTE positions on the screen
sub click {
    my($this, $x,$y,$button)=@_;
    $button ||= "{LEFTCLICK}";
    MouseMoveAbsPix($x,$y);
    print "Button: $button ($x,$y)\n" if DEBUG;
    SendMouse($button);
    return;
}

=head2 new_game

	$sweeperbot->new_game;

Starts a new game of minesweeper.  C<locate_minesweeper()> must
have been called previously for this to work.

Does not return a value, nor does it check to see if a new game
has been successfully started.

=cut


# TODO: Rather than using the reset variables, we should properly
# calculate the location of our reset button.  We have calibration
# code elsewhere that essentially finds the smiley, we just have to
# click on it.

sub new_game {
    my ($this) = @_;
    our ($reset_x,$reset_y);
    $this->click($reset_x,$reset_y);
    return;
}

=head2 focus

	$sweeperbot->focus;

Focuses on t he  minesweeper window by clicking a little left of the
smiley.  Does not check for success.  Returns nothing.

=cut

# Focus on the Minesweeper window by clicking a little to the left of the game
# button.
sub focus {
    my ($this) = @_;
    our ($reset_x, $reset_y);
    $this->click($reset_x - FOCUS_X_OFFSET ,$reset_y);
    return;
}

=head2 capture_square

	my $image = $sweeperbot->capture_square($x,$y);

Captures the square ($x,$y) of the minesweeper board.  (1,1) is
the top-left of the grid.  No checking is done to see if the square
is actually on the board.  Returns the image as an L<Image::Magick>
object.

=head3 Bugs in capture_square

On failure to capture the image, this returns an empty
L<Image::Magick> object.  This is considered a bug; in the future
C<capture_square> will throw an exception on error.

C<capture_square> depends upon calibration routines that are
currently implemented in the L</value> method; calling it before
the first call to L</value> can result in incorrect or inconsistent
results.  In future releases C<capture_square> will automatically
calibrate itself if required.

=cut

# TODO GuiTest doesn't check the Image::Magick return codes, it
# just assumes everything works.  We should consider writing our
# own code that _does_ test, since these diagnostics are very
# useful when things go wrong.

sub capture_square {
    my($this, $sx,$sy)=@_;
    our($l,$t);
    my $image=CaptureRect(
        $l+SQUARE1X+($sx-1)*SQUARE_W,
        $t+$Square1Y+($sy-1)*SQUARE_H,
        SQUARE_W,
        SQUARE_H
    );
    return $image;
}

=head2 value

	my $value = $sweeperbot->value($x,$y);

Returns the value in position ($x,$y) of the board, square
(1,1) is considered the top-left of the grid.  Possible values
are given below:

	0-8		# Number of adjacent mines (0 = empty)
	bomb		# A bomb (only when game lost)
	bomb_hilight	# The bomb we hit (only when game lost)
	flag		# A flag
	unpressed	# An unpressed square

Support of question-marks is not provided, but may be included
in a future version.

Throws an exception on failure.

=cut

sub value {
    my($this, $sx,$sy)=@_;

    if (not $Square1Y) {
	# We haven't calibrated our board yet.  Let's see if we can
	# find a square we recognise.

        CALIBRATION: {
	    for (my $i = MIN_SQUARE1Y; $i <= MAX_SQAURE1Y; $i++) {
	        $Square1Y = $i;

	        warn "Trying to calibrate board $i pixels down\n" if DEBUG;

	        my $sig = $this->capture_square(1,1)->Get("signature");

	        # Known signature, break out of calibration loop.
	        last CALIBRATION if ($contents_of_square{$sig});
	    }

	# If we're here, we couldn't calibrate
	die "Board calibration failed\n";
        }
    }

    my $sig = $this-> capture_square($sx,$sy)->Get("signature");

    my $result = $contents_of_square{$sig};

    defined($result) or die "Square $sx,$sy contains a value I don't recognise\n\n$sig\n\n";

    return $result;
}

=head2 press

	$sweeperbot->press($x,$y, $button)

Clicks on the square with co-ordinates ($x,$y) using the mouse-button
C<$button>, or left-click by default.  Square (1,1)
is the top-left square.  Does not return a value.

=cut

sub press {
    my($this, $sx,$sy,$button)=@_;
    $button ||= "{LEFTCLICK}";
    our($l,$t);
    $this->click(
        $l+SQUARE1X+($sx-1)*SQUARE_W+SQUARE_W/2,
        $t+$Square1Y+($sy-1)*SQUARE_H+SQUARE_W/2,
	$button
    );

    return;
}

=head2 stomp

	$sweeperbot->stomp($x,$y);

Stomps (middle-clicks) on the square at ($x,$y), normally used to
stand on all squares adjacent to the square specified.  Square (1,1)
is the top-left of the grid.  Does not return a value.

=cut

# Stomp on a square (left+right click)
sub stomp {
	my ($this, $x, $y) = @_;
	$this->press($x,$y,"{MIDDLECLICK}");

	return;
}

=head2 flag_mines

	$sweeperbot->flag_mines($game_state,
		[2,3], [7,1], [8,3]
	);

Takes a game state, and a list of location tuples (array-refs),
and marks all of those locations with flags.

The requirement to pass C<$game_state> may be removed in a
future version.

=cut

sub flag_mines {
	my ($this, $game_state, @flag_these) = @_;

	foreach my $square (@flag_these) {
		my ($x,$y) = @$square;

		# Skip to the next square if we have record that this
		# has already been flagged (earlier this iteration).
		next if $game_state->[$x][$y] eq "flag";

		$this->press($x,$y,"{RIGHTCLICK}");
		$game_state->[$x][$y] = "flag";
	}

	return;
}

=begin deprecated

# This code is left here as a mathom, but isn't used anymore.
# Generally we want to call flag_mines() to flag mines, or
# stomp() to stomp on a square.

sub mark_adjacent {
	my ($this, $x, $y) = @_;
	$this->press($x-1,$y-1,"{RIGHTCLICK}");
	$this->press($x  ,$y-1,"{RIGHTCLICK}");
	$this->press($x+1,$y-1,"{RIGHTCLICK}");

	$this->press($x-1,$y  ,"{RIGHTCLICK}");
	$this->press($x+1,$y  ,"{RIGHTCLICK}");

	$this->press($x-1,$y+1,"{RIGHTCLICK}");
	$this->press($x  ,$y+1,"{RIGHTCLICK}");
	$this->press($x+1,$y+1,"{RIGHTCLICK}");

}

=end deprecated

=head2 game_over

	if (my $state = $sweeperbot->game_over) {
		print $state > 0 ? "We won!\n" : "We lost!\n";
	}

Checks to see if the game is over by looking at the minesweeper smiley.
Returns C<1> for game over due to a win, C<-1> for game over due to
a loss, and false if the game has not finished.

=cut

# Is the game over (we hit a mine)? 
# Returns -1 if game is over and we lost, 0 if not over, 1 if over and we won
sub game_over {
    # Capture game button and determine its sig
    # Game button is always at (x,56). X-value must be determined by 
    # calculation using formula: x=w/2-11
    # Size is 26x26
    our($l,$t,$w);

    # If we don't know where our smiley lives, then go find it.
    if (not $Smiley_offset) {
        for (my $i = MINIMUM_TOP_DRESSING; $i <= MAXIMUM_TOP_DRESSING; $i++) {

	    $Smiley_offset = $i;

            warn "Searching $Smiley_offset pixels down for smiley\n" if DEBUG;

	    my $smiley = CaptureRect(
		$l+$w/2 - 11,
		$Smiley_offset + $t,
		SMILEY_LENGTH,
		SMILEY_LENGTH,
	    );

            my $sig = $smiley->Get('signature');

	    if (exists $smiley_type{$sig}) {
		return $smiley_type{$sig};
	    }
	}

	# Oh no!  We couldn't find our smiley!

	die "Smiley not found on gameboard!\n";
    }

    # my $smiley=CaptureRect($l+$w/2-11,$t+56,26,26);
    # my $smiley=CaptureRect($l+$w/2-11, $t+64, SMILEY_LENGTH, SMILEY_LENGTH);
    # my $smiley=CaptureRect($l+$w/2-11,$t+75,26,26);

    my $smiley = CaptureRect(
	$l+$w/2 - 11,
	$Smiley_offset + $t,
	SMILEY_LENGTH,
	SMILEY_LENGTH,
    );


    my $sig = $smiley->Get("signature");

    if (exists $smiley_type{$sig}) {
	return $smiley_type{$sig};
    }

    die "I don't know what the smiley means\n$sig\n";

}

=head2 make_move


	$sweeperbot->make_move($game_state);

Given a game state, determines the next move(s) that should be made,
and makes them.  By default this uses a very simple process:

=over

=item *

If C<UBER_CHEAT> is set, then cheat.

=item *

If we find a square where the number of adjacent mines matches the
number on the square, L</stomp> on it.

=item *

If the number of adjacent unpressed squares matches the number of 
unknown adjacent mines, then flag them as mines.

=item * 

If all else fails, pick a square at random.  If C<CHEAT> is defined,
and we would have picked a square with a mine, then pick another.

=back

If you want to inherit from this class to change the AI, overriding
this method is the place to do it.

=cut

sub make_move {
	my ($this, $game_state) = @_;
	our ($squares_x, $squares_y);
	my $altered_board = 0;
	foreach my $y (1..$squares_y) {
		SQUARE: foreach my $x (1..$squares_x) {

			if (UBER_CHEAT) {
				if (cheat_is_square_safe([$x,$y])) {
					$this->press($x,$y);
				}
				else {
					$this->flag_mines($game_state,[$x,$y]);
				}
				$altered_board = 1;
			}

			# Empty squares are dull.
			next SQUARE if ($game_state->[$x][$y] eq 0);

			# Unpressed/flag squares don't give us any information.
			next SQUARE if (not looks_like_number($game_state->[$x][$y]));

			my @adjacent_unpressed = $this->adjacent_unpressed_for($game_state,$x,$y);
			# If there are no adjacent unpressed squares, then
			# this square is boring.
			next SQUARE if not @adjacent_unpressed;

			my $adjacent_mines = $this->adjacent_mines_for($game_state,$x,$y);

			# If the number of mines is equal to the number
			# on this square, then stomp on it.
			
			if ($adjacent_mines == $game_state->[$x][$y]) {
				print "Stomping on $x,$y\n" if DEBUG;
				$this->stomp($x,$y);
				$altered_board = 1;
			}

			# If the number of mines plus unpressed squares is
			# equal to the number on this square, then mark all
			# adjacent squares as having mines.
			if ($adjacent_mines + @adjacent_unpressed == $game_state->[$x][$y]) {
				print "Marking mines next to $x,$y\n" if DEBUG;
				$this->flag_mines($game_state,@adjacent_unpressed);
				$altered_board = 1;
			}
			
		}
	}
	if (not $altered_board) {
		# Drat!  Can't find a good move.  Pick a square at
		# random.
		
		my @unpressed = ();

		foreach my $x (1..$squares_x) {
			foreach my $y (1..$squares_y) {
				push(@unpressed,[$x,$y]) if $game_state->[$x][$y] eq "unpressed";
			}
		}

		my $square = $unpressed[rand @unpressed];

		if (CHEAT) {
			while (not $this->cheat_is_square_safe($square)) {
				$square = $unpressed[rand @unpressed];
			}
		}

		print "Guessing square ",join(",",@$square),"\n" if DEBUG;
		$this->press(@$square);

	}
	return;
}

=head2 capture_game_state

	my $game_state = $sweeperbot->capture_game_state;

Walks over the entire board, capturing the value in each location and
adding it to an array-of-arrays (game-state) structure.  The value
in a particular square can be accessed with:

	$value = $game_state->[$x][$y];

Where (1,1) is considered the top-left of the game board.

=cut

sub capture_game_state {

	my ($this) = @_;

	my $game_state = [];
	our ($squares_x, $squares_y);

	for my $y (1..$squares_y) {
    		for my $x (1..$squares_x) {
			my $square_value = $this->value($x,$y);
			$game_state->[$x][$y] = $square_value;
			print $char_for{$square_value} if DEBUG;
		}
		print "\n" if DEBUG;
	}
	print "---------------\n" if DEBUG;

	# To make things easier later on, we provide a one square "padding"
	# of virtual squares that are always empty.
	
	for my $x (0..$squares_x+1) {
		$game_state->[$x][0] = 0;
		$game_state->[$x][$squares_y+1] = 0;
	}

	for my $y (0..$squares_y+1) {
		$game_state->[0][$y] = 0;
		$game_state->[$squares_x+1][$y] = 0;
	}

	return $game_state;
}

=head2 adjacent_mines_for

	my $mines = $sweeperbot->adjacent_mines_for($game_state, $x, $y);

Examines all the squares adjacent to ($x,$y) and returns an
array-ref of tuples for those that have already been flagged
as a mine.

=cut

sub adjacent_mines_for {
	my ($this, $game_state, $x, $y) = @_;
	return $this->mines_at($game_state,
		[$x-1, $y-1],   [$x, $y-1],   [$x+1, $y-1],
		[$x-1, $y  ],                 [$x+1, $y  ],
		[$x-1, $y+1],   [$x, $y+1],   [$x+1, $y+1],
	);
}

=head2 adjacent_unpressed_for

	my $squares = $sweeperbot->adjacent_unpressed_for($game_state, $x, $y);

Examines all the squares adjacent to ($x,$y) and returns an array-ref
of tuples for those that have not been pressed (and not flagged as a
mine).

=cut

sub adjacent_unpressed_for {
	my ($this, $game_state, $x, $y) = @_;
	return $this->unpressed_list($game_state,
		[$x-1, $y-1],   [$x, $y-1],   [$x+1, $y-1],
		[$x-1, $y  ],                 [$x+1, $y  ],
		[$x-1, $y+1],   [$x, $y+1],   [$x+1, $y+1],
	);
}

=head2 mines_at

	my $mines = $sweeperbot->mines_at($game_state, @locations);

Takes a game state and a list of locations, and returns an array-ref
containing those locations from the list that have been flagged as
a mine.

=cut


sub mines_at {
	my ($this, $game_state, @locations) = @_;

	my $mines = 0;

	foreach my $square (@locations) {
		if ($game_state->[ $square->[0] ][ $square->[1] ] eq "flag") {
			$mines++;
		}
	}
	return $mines;
}

=head2 unpressed_list

	my $unpressed = $this->unpressed-list($game_state, @locations);

Identical to L</mines_at> above, but returns any locations that have
not been pressed (and not flagged as a mine).

=cut

sub unpressed_list {
	my ($this, $game_state, @locations) = @_;

	my @unpressed = grep { ($game_state->[ $_->[0] ][ $_->[1] ] eq "unpressed") } @locations;

	return @unpressed;
}

=head2 enable_cheats

	$sweeperbot->enable_cheats;

Sends the magic C<xyzzy> cheat to minesweeper, which allows us to
determine the contents of a square by examining the top-left pixel
of the entire display.

For this cheat to be used in the default AI, the C<CHEAT> constant
must be set to a true value in the C<App::SweeperBot> source.

=cut

sub enable_cheats {
	SendKeys("xyzzy{ENTER}+ ");

	return;
}

=head2 cheat_is_square_safe

	if ($sweeperbot->cheat_is_square_safe($x,$y) {
		print "($x,$y) looks safe!\n";
	} else {
		print "($x,$y) has a mine underneath.\n";
	}

If cheats are enabled, returns true if the given square looks
safe to step on, or false if it appears to contain a mine.

Note that especially on fast, multi-core systems, it's possible
for this to move the mouse and capture the required pixel before
minesweeper has had a chance to update it.  So if you cheat,
you may sometimes be surprised.

=cut

sub cheat_is_square_safe {
	my ($this, $square) = @_;
	our($l,$t);
	
	MouseMoveAbsPix(
		$l+SQUARE1X+($square->[0]-1)*SQUARE_W+SQUARE_W/2,
		$t+$Square1Y+($square->[1]-1)*SQUARE_H+SQUARE_W/2,
	);

	# Capture our pixel.
	my $pixel =  CaptureRect(0,0,1,1);

	my $signature = $pixel->Get("signature");

	print "Square at @$square has sig of $signature\n" if DEBUG;

	if ($signature eq CHEAT_SAFE) {
		print "This square (@$square) looks safe\n" if DEBUG;
		return 1;
	} elsif ($signature eq CHEAT_UNSAFE) {
		print "This square (@$square) looks dangerous!\n" if DEBUG;
		return;
	} 
	die "Square @$square has unknown cheat-signature\n$signature\n";
}

__END__

=head1 BUGS

Plenty.  The code is pretty awful right now.  Anything that could go
wrong probably will.

Use of this program may cause sweeperbot to take control of our
mouse and keyboard, playing minesweeper endlessly for days on end,
and forcing the user to go and do something productive instead.

All methods that require a game-state to be passed will be modified
in the future to be usable without the game-state.  The
C<App::SweeperBot> object itself should be able to retain state.

=head1 AUTHOR

Paul Fenwick E<lt>pjf@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Paul Fenwick, E<lt>pjf@cpan.orgE<gt>

Based upon original code Copyright (C) 2005 by 
Matt Sparks E<lt>root@f0rked.comE<gt>

This application is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either Perl version 5.6.0
or, at your option, any later version of Perl 5 you may have available.

=cut

