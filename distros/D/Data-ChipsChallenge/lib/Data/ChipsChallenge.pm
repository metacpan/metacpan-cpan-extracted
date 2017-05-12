package Data::ChipsChallenge;

use strict;
use warnings;

# Note: this must be on the same line. See `perldoc version`
use version; our $VERSION = version->declare('v1.0.0');

# Holds the last error message.
our $Error = '';

=head1 NAME

Data::ChipsChallenge - Perl interface to Chip's Challenge data files.

=head1 SYNOPSIS

  my $cc = new Data::ChipsChallenge("./CHIPS.DAT");

  print "This CHIPS.DAT file contains ", $cc->levels, " levels.\n\n";

  for (my $i = 1; $i <= $cc->levels; $i++) {
    my $info = $cc->getLevelInfo($i);
    print "Level $info->{level} - $info->{title}\n"
      . "Time Limit: $info->{time}\n"
      . "     Chips: $info->{chips}\n"
      . "  Password: $info->{password}\n\n";
  }

=head1 DESCRIPTION

This module provides an interface for reading and writing to Chip's Challenge
data files ("CHIPS.DAT") that is shipped with I<Best of Windows Entertainment
Pack>'s Chip's Challenge.

Chip's Challenge is a 2D tilebased maze game. The goal of each level is usually
to collect a certain number of computer chips, so that a chip socket can be
opened and the player can get to the exit and proceed to the next level.

This module is able to read and manipulate the data file that contains all these
levels. For some examples, see those in the "eg" folder shipped with this
module.

Documentation on the CHIPS.DAT file format can be found at this location:
http://www.seasip.info/ccfile.html -- in case that page no longer exists, I've
archived a copy of it in the C<doc/> directory with this source distribution.

=head1 DISCLAIMER

This module only provides the mechanism for which you can read and manipulate
a CHIPS.DAT game file. However, it cannot include a copy of the official
CHIPS.DAT, as that file is copyrighted by its creators. If you have an original
copy of the Chip's Challenge game from the I<BOWEP> collection, you can use its
CHIPS.DAT with this module.

=head1 METHODS

All of the following methods will return a value (or in the very least, 1).
If any errors occur inside any methods, the method will return undef, and the
error text can be obtained from C<$Data::ChipsChallenge::Error>.

=head2 new ([string FILE,] hash OPTIONS)

Create a new ChipsChallenge object. If you pass in an odd number of arguments,
the first argument is taken as a default "CHIPS.DAT" file to load, and the rest
is taken as a hash like 99% of the other CPAN modules. Loading the
standard Chip's Challenge file with 149 levels takes a few seconds.

Alternatively, pass options in hash form:

  bool   debug = Enable or disable debug mode
  string file  = The path to CHIPS.DAT

Ex:

  my $cc = new Data::ChipsChallenge("CHIPS.DAT");
  my $cc = new Data::ChipsChallenge("CHIPS.DAT", debug => 1);
  my $cc = new Data::ChipsChallenge(file => "CHIPS.DAT", debug => 1);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto || "Data::ChipsChallenge";

	my %args = ();
	if (scalar(@_) % 2) {
		$args{file} = shift;
	}
	my (%in) = (@_);
	foreach my $key (keys %in) {
		$args{$key} = $in{$key};
	}

	my $self = {
		debug  => 0,
		file   => undef,
		levels => {}, # Level data
		(%args),
	};

	bless ($self,$class);

	# Did they give us a file?
	if (defined $self->{file}) {
		# Load it.
		$self->load($self->{file});
	}

	return $self;
}

sub debug {
	my ($self,$line) = @_;
	if ($self->{debug}) {
		print "$line\n";
	}
}

=head2 create (int LEVELS)

Create a new, blank, CHIPS.DAT file. Pass in the number of levels you want
for your new CHIPS.DAT. This method will clear out any loaded data and
initialize blank grids for each level specified.

Additional levels can be added or destroyed via the C<addLevel> and
C<deleteLevel> functions.

=cut

sub create {
	my ($self,$levels) = @_;

	if (!defined $levels || $levels =~ /[^0-9]/) {
		$Error = "create must be given an integer number of levels!";
		return undef;
	}

	# Flush any loaded data from memory.
	$self->{file} = undef;
	$self->{levels} = {};

	# Keep track of used passwords.
	my @letters = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
	my %passes = ();

	$self->debug("Creating a new quest with $levels levels.");

	# Create all the levels.
	for (my $i = 1; $i <= $levels; $i++) {
		my $padded = sprintf("%03d", $i);

		$self->debug("Initializing level $padded");

		# Get a new password.
		my $pass = $self->random_password();
		while (exists $passes{$pass}) {
			$self->debug("\tChosen password $pass was already taken; trying another");
			$pass = $self->random_password();
		}
		$passes{$pass} = 1;

		$self->debug("\tChosen password: $pass");

		$self->{levels}->{$i} = {
			level      => $i,
			title      => "LEVEL $padded",
			password   => $pass,
			hint       => '',
			time       => 0,
			chips      => 0,
			compressed => 1,
			layer1     => [],
			layer2     => [],
			traps      => [],
			cloners    => [],
			movement   => [],
		};

		# Initialize the map layers.
		$self->debug("Initializing the map layers");
		for (my $row = 0; $row < 32; $row++) {
			for (my $col = 0; $col < 32; $col++) {
				my $sprite = '00';
				if ($row == 0 && $col == 0) {
					$sprite = '6E';
				}
				elsif ($row == 0 && $col == 1) {
					$sprite = '15';
				}
				$self->{levels}->{$i}->{layer1}->[$row]->[$col] = $sprite;
				$self->{levels}->{$i}->{layer2}->[$row]->[$col] = '00';
			}
		}
	}

	return 1;
}

=head2 load (string FILE)

Load a CHIPS.DAT file into memory. Returns undef on error, or 1 on success.

=cut

# Load the file.
sub load {
	my ($self,$file) = @_;
	$self->{file} = $file;

	# Open the file.
	if (!-f $file) {
		warn "Can't find file $file: doesn't exist!";
		return undef;
	}
	open (READ, $file);
	binmode READ;

	# Notes for unpacking the binary data:
	#  C = Unsigned word

	# Read off the headers.
	my $buffer;
	read(READ, $buffer, 4);
	my $header = $buffer;
	read(READ, $buffer, 2);
	my $levels = unpack("S",$buffer);
	$self->debug ("Number of Levels: $levels");

	# Begin loading the levels.
	for (my $parsed = 1; $parsed <= $levels; $parsed++) {
		$self->debug("Reading level $parsed");

		# See how long this level is.
		read(READ, $buffer, 2);
		my $lvl_length = unpack("s",$buffer);
		$self->debug ("\t     Length of Data: $lvl_length");

		# Slurp out the entire contents of the level.
		read(READ, $buffer, $lvl_length);

		# Get the number that THIS level claims to be.
		my $lvl_number = unpack("s",substr($buffer,0,2));
		$self->debug ("\tReported Lvl Number: $lvl_number");

		# Get the time limit here.
		my $time = unpack("s", substr($buffer,2,2));
		$self->debug ("\t         Time Limit: $time");

		# Get the number of chips required.
		my $chips = unpack("s", substr($buffer,4,2));
		$self->debug ("\t     Chips Required: $chips");

		# Get whether the level is compressed or not (it always is).
		my $compressed = unpack("s", substr($buffer,6,2));
		$self->debug ("\t   Level Compressed: $compressed");

		# Store this metadata.
		$self->{levels}->{$lvl_number} = {
			level      => $lvl_number,
			title      => '',
			password   => '',
			hint       => '',
			time       => $time,
			chips      => $chips,
			compressed => $compressed,
			layer1     => [], # Layer 1 (Top)
			layer2     => [], # Layer 2 (Bottom)
			traps      => [], # Traps
			cloners    => [], # Clone machines
			movement   => [], # Movement info
		};

		# Strip off all the header info that we don't need anymore.
		$buffer = substr($buffer, 8);

		# Begin reading the upper layer. Get how many bytes it is.
		my $upper_bytes = unpack("s", substr($buffer,0,2));
		$self->debug ("\tParsing Level Data: Upper Layer");
		$self->debug ("\t\tLength of Data: $upper_bytes");
		my $upper_layer = substr($buffer,2,$upper_bytes);

		# Process the upper layer.
		my $layer1 = $self->process_map ($lvl_number,$upper_layer);
		$self->{levels}->{$lvl_number}->{layer1} = $layer1;

		# Cut off the upper layer and begin reading the lower layer.
		$buffer = substr($buffer,$upper_bytes + 2);
		my $lower_bytes = unpack("s", substr($buffer,0,2));
		$self->debug("\tParsing Level Data: Lower Layer");
		$self->debug("\t\tLength of Data: $lower_bytes");
		my $lower_layer = substr($buffer,2,$lower_bytes);

		# Process the lower layer.
		my $layer2 = $self->process_map ($lvl_number,$lower_layer);
		$self->{levels}->{$lvl_number}->{layer2} = $layer2;

		# Cut off the lower layer and see if there are any more fields.
		$buffer = substr($buffer,$lower_bytes + 2);

		# Read any "optional" fields.
		if (length $buffer > 0) {
			# Get the bytes for optional fields.
			my $optional_bytes = unpack("s", substr($buffer,0,2));
			$self->debug("\tOptional Field Length: $optional_bytes");
			$buffer = substr($buffer,2);
		}

		while (length $buffer > 0) {
			# Get the field number.
			my $field  = unpack("C", substr($buffer,0,1));
			my $length = unpack("C", substr($buffer,1,1));
			my $data   = substr($buffer,2,$length);
			$buffer = substr($buffer,$length + 2);

			# Handle the fields.
			if ($field == 3) {
				# 3: Map Title
				my $title = substr($data,0,(length($data) - 1));
				$self->debug("\t\tMap Title: $title");
				$self->{levels}->{$lvl_number}->{title} = $title;
			}
			elsif ($field == 4) {
				# Trap Controls
				for (my $i = 0; $i < length($data); $i += 10) {
					my $buttonX = unpack("s",substr($data,$i,2));
					my $buttonY = unpack("s",substr($data,$i + 2,2));
					my $trapX   = unpack("s",substr($data,$i + 4,2));
					my $trapY   = unpack("s",substr($data,$i + 6,2));

					$self->debug("\t\tButton at ($buttonX,$buttonY) releases trap at ($trapX,$trapY)");
					push (@{$self->{levels}->{$lvl_number}->{traps}}, {
						button => [ $buttonX, $buttonY ],
						trap   => [ $trapX,   $trapY   ],
					});
				}
			}
			elsif ($field == 5) {
				# Cloning Machine Controls
				for (my $i = 0; $i < length($data); $i += 8) {
					my $buttonX = unpack("s",substr($data,$i,2));
					my $buttonY = unpack("s",substr($data,$i + 2,2));
					my $cloneX  = unpack("s",substr($data,$i + 4,2));
					my $cloneY  = unpack("s",substr($data,$i + 6,2));

					$self->debug("\t\tButton at ($buttonX,$buttonY) clones object at ($cloneX,$cloneY)");
					push (@{$self->{levels}->{$lvl_number}->{cloners}}, {
						button => [ $buttonX, $buttonY ],
						clone  => [ $cloneX,  $cloneY  ],
					});
				}
			}
			elsif ($field == 6) {
				# The password
				my $password = $self->decode_password($data);
				$self->debug("\t\tPassword: $password");
				$self->{levels}->{$lvl_number}->{password} = $password;
			}
			elsif ($field == 7) {
				# Map Hint
				my $hint = substr($data,0,(length($data) - 1));
				$self->debug("\t\tMap Hint: $hint");
				$self->{levels}->{$lvl_number}->{hint} = $hint;
			}
			elsif ($field == 10) {
				# Movement
				for (my $i = 0; $i < length($data); $i += 2) {
					my $monsterX = unpack("C",substr($data,$i,1));
					my $monsterY = unpack("C",substr($data,$i + 1,1));

					$self->debug("\t\tMonster at ($monsterX,$monsterY) moves.");
					push (@{$self->{levels}->{$lvl_number}->{movement}}, [ $monsterX,$monsterY ]);
				}
			}
		}
	}

	close (READ);
	return 1;
}

=head2 write ([string FILE])

Write the loaded data into a CHIPS.DAT file. This file should be able to be loaded
into Chip's Challenge and played. Returns undef and sets C<$Data::ChipsChallenge::Error>
on any errors.

If not given a filename, it will write to the same file that was last C<load>ed. If
no file was ever loaded then it would default to a file named "CHIPS.DAT".

=cut

sub write {
	my $self = shift;
	my $file = shift || $self->{file} || "CHIPS.DAT";

	$self->debug("Writing level data to $file");

	# Open the file for writing.
	open (WRITE, ">$file") or do {
		$Error = "Can't write to $file: $!";
		return undef;
	};
	binmode WRITE;

	# Write the magic number.
	$self->debug("Writing magic number to header: ACAA0900");
	my $magic = pack("C4", 0xAC, 0xAA, 0x02, 0x00);
	print WRITE $magic;

	# Write the number of levels in this file.
	$self->debug("Writing number of levels into header");
	my $levels = pack("S", $self->levels);
	print WRITE $levels;

	# Begin writing the level data.
	for (my $i = 1; $i <= $self->levels; $i++) {
		# Begin chucking everything into a binary string.
		my $bin = '';

		$self->debug("Writing data for level $i");

		# Get this level's meta data.
		my $meta = $self->getLevelInfo($i);

		# Encode the level number that this level claims to be.
		$self->debug("\tLevel #: $meta->{level}");
		my $alleged_level = pack("s", $meta->{level});
		$bin .= $alleged_level;

		# Encode the time limit.
		$self->debug("\tTime Limit: $meta->{time}");
		my $time = pack("s", $meta->{time});
		$bin .= $time;

		# Get the number of chips required.
		$self->debug("\tChips Required: $meta->{chips}");
		my $chips = pack("s", $meta->{chips});
		$bin .= $chips;

		# The level is always compressed.
		$self->debug("\tCompressed: 1");
		my $compressed = pack("s", 0x01);
		$bin .= $compressed;

		# Get the level grids.
		my $gridUpper = $self->getUpperLayer ($i);
		my $gridLower = $self->getLowerLayer ($i);

		# Compress and binaryify the grids.
		$self->debug("\tCompressing map layers");
		my $binUpper = $self->compress_map ($gridUpper);
		my $binLower = $self->compress_map ($gridLower);
		$self->debug("\tLength of Upper Layer: " . length($binUpper));
		$self->debug("\tLength of Lower Layer: " . length($binLower));
		return undef unless defined $binUpper;
		return undef unless defined $binLower;
		my $lenUpper = pack("s", length($binUpper));
		my $lenLower = pack("s", length($binLower));
		$bin .= $lenUpper . $binUpper;
		$bin .= $lenLower . $binLower;

		# Write the optional fields.
		my $obin = '';
		foreach my $opt (qw(3 7 6 4 5 10)) {
			my $field = pack("C", $opt);
			if ($opt == 3) {
				# 3: Map Title
				my $title = $meta->{title} . chr(0x00);
				my $len = pack("C", length($title));
				$obin .= $field . $len . $title;
				$self->debug("\tWrote title: $title (len: " . length($title) . ")");
			}
			elsif ($opt == 4) {
				# 4: Trap Controls
				my $traps = '';
				my $coords = $self->getBearTraps($i);
				if (scalar @{$coords} > 0) {
					foreach my $trap (@{$coords}) {
						my $button = $trap->{button};
						my $hole   = $trap->{trap};

						my $buttonX = pack("s", $button->[0]);
						my $buttonY = pack("s", $button->[1]);
						my $trapX = pack("s", $hole->[0]);
						my $trapY = pack("s", $hole->[1]);
						my $null  = pack("s", 0x00);
						$traps .= join("",
							$buttonX, $buttonY,
							$trapX, $trapY,
							$null,
						);
					}
					$self->debug("\tWrote bear traps - length: " . length($traps));
					my $len = pack("C", length($traps));
					$obin .= $field . $len . $traps;
				}
			}
			elsif ($opt == 5) {
				# 5: Cloning Machine Controls
				my $machines = '';
				my $coords = $self->getCloneMachines($i);
				if (scalar @{$coords} > 0) {
					foreach my $item (@{$coords}) {
						my $button = $item->{button};
						my $clone  = $item->{clone};

						my $buttonX = pack("s", $button->[0]);
						my $buttonY = pack("s", $button->[1]);
						my $cloneX  = pack("s", $clone->[0]);
						my $cloneY  = pack("s", $clone->[1]);
						$machines .= join("",
							$buttonX, $buttonY,
							$cloneX, $cloneY,
						);
					}
					$self->debug("\tWrote clone machines - length: " . length($machines));
					my $len = pack("C", length($machines));
					$obin .= $field . $len . $machines;
				}
			}
			elsif ($opt == 6) {
				# 6: Map Password
				my $len = pack("C", 5);
				my $encoded = $self->encode_password ($meta->{password});
				$self->debug("\tWrote password - length: 5");
				$obin .= $field . $len . $encoded;
			}
			elsif ($opt == 7) {
				# 7: Map Hint
				if (exists $meta->{hint}) {
					my $hint = $meta->{hint} . chr(0x00);
					my $len = pack("C", length($hint));
					$obin .= $field . $len . $hint;
					$self->debug("\tWrote map hint - length: " . length($hint));
				}
			}
			elsif ($opt == 10) {
				# 10: Movement layer
				my $movement = $self->getMovement($i);
				if (scalar(@{$movement}) > 0) {
					my $move = '';
					foreach my $coord (@{$movement}) {
						my ($x,$y) = @{$coord};
						$x = pack("C", $x);
						$y = pack("C", $y);
						$move .= join("",$x,$y);
					}
					my $len = pack("C", length($move));
					$obin .= $field . $len . $move;
					$self->debug("\tWrote movement layer - length: " . length($move));
				}
			}
		}

		# Get the length of the optionals.
		my $optlen = pack("s", length($obin));
		$self->debug("\tLength of optional data: " . length($obin));
		$bin .= $optlen . $obin;

		# Get the length of this binary.
		my $length = pack("s", length $bin);
		$self->debug("\tLength of level data: " . length($bin));
		print WRITE $length;
		print WRITE $bin;
	}

	close (WRITE);

	$self->{file} = $file;
	return 1;
}

=head2 levels

Returns the number of loaded levels. When loading the standard CHIPS.DAT, this
method will probably return C<149>.

  print "There are ", $cc->levels, " levels in this file.\n";

=cut

sub levels {
	my $self = shift;
	my $levels = scalar(keys(%{$self->{levels}}));
	return $levels;
}

=head2 getLevelInfo (int LVL_NUMBER)

Get information about a level. Returns a hashref of all the info available for
the level, which may include some or all of the following keys:

  level:    The level number of this map (3 digits, zero-padded, e.g. 001)
  title:    The name of the map
  password: The four-letter password for this level
  time:     The time limit (if 0, means there's no time limit)
  chips:    Number of chips required to open the socket on this map
  hint:     The text of the hint on this map (if no hint, this key won't exist)

Example:

  for (my $i = 1; $i <= $cc->levels; $i++) {
    my $info = $cc->getLevelInfo($i);
    print "Level: $info->{level} - $info->{title}\n"
        . " Time: $info->{time}   Chips: $info->{chips}\n"
        . " Pass: $info->{password}\n"
        . (exists $info->{hint} ? " Hint: $info->{hint}\n" : "")
        . "\n";
  }

Returns undef if the level isn't found, or if the level number wasn't given.

=cut

sub getLevelInfo {
	my ($self,$level) = @_;

	return undef unless defined $level;
	$level = int($level); # Just in case they gave us "001" instead of "1"
	return undef unless exists $self->{levels}->{$level};

	my $return = {};
	foreach my $key (qw(level title time chips hint password)) {
		if (defined $self->{levels}->{$level}->{$key} &&
		defined $self->{levels}->{$level}->{$key} &&
		length $self->{levels}->{$level}->{$key}) {
			$return->{$key} = $self->{levels}->{$level}->{$key};
		}
	}

	$return->{level} = sprintf("%03d",$return->{level})
		if exists $return->{level};

	return $return;
}

=head2 setLevelInfo (int LVL_NUMBER, hash INFO)

Set metadata about a level. The following information can be set:

  level
  title
  password
  time
  chips
  hint

See L<"getLevelInfo"> for the definition of these fields.

Note that the C<level> field should equal C<LVL_NUMBER>. It's I<possible> to
override this to be something different, but it's not recommended. If you want
to test your luck anyway, pass in the C<level> field manually any time you call
C<setLevelInfo>. When the C<level> field is not given, it defaults to the given
C<LVL_NUMBER>.

You don't need to pass in every field. For example if you only want to change
a level's time limit, you can pass only the time:

  # Level 131, "Totally Unfair", is indeed totally unfair - only 60 seconds to
  # haul butt to barely survive the level? Let's up the time limit.
  $cc->setLevelInfo (131, time => 999);

  # Or better yet, remove the time limit altogether!
  $cc->setLevelInfo (131, time => 0);

Special considerations:

  * There must be a title
  * There must be a password
  * All level passwords must be unique

If there's an error, this function returns undef and sets
C<$Data::ChipsChallenge::Error> to the text of the error message.

=cut

sub setLevelInfo {
	my ($self,$level,%info) = @_;

	if (!defined $level) {
		$Error = "setLevelInfo requires a level number as the first argument!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "That level number doesn't seem to exist!";
		return undef;
	}

	if (exists $info{title} && length $info{title} < 1) {
		$Error = "All levels must have titles!";
		return undef;
	}
	if (exists $info{password} && length $info{password} != 4) {
		$Error = "All levels must have a 4 letter password!";
		return undef;
	}
	if (exists $info{password} && $info{password} =~ /[^A-Za-z]/) {
		$Error = "Passwords can only contain letters!";
		return undef;
	}

	# Did they give us a password?
	if (exists $info{password}) {
		# Uppercase it.
		$info{password} = uc($info{password});

		# Make sure it doesn't exist.
		for (my $i = 1; $i <= $self->levels; $i++) {
			if ($self->{levels}->{$i}->{password} eq $info{password}) {
				$Error = "There is a password conflict with level $i";
				return undef;
			}
		}
	}

	# Are they overriding the level number?
	if (exists $info{level}) {
		$info{level} = int($info{level});
	}
	else {
		$info{level} = int($level);
	}

	# Store the data we were given.
	foreach my $key (keys %info) {
		$self->{levels}->{$level}->{$key} = $info{$key};
	}

	return 1;
}

=head2 getUpperLayer (int LVL_NUMBER)

Returns a 2D array of all the tiles in the "upper" (primary) layer of the map
for level C<LVL_NUMBER>. Each entry in the map is an uppercase plaintext
hexadecimal code for the object that appears in that space. The grid is referenced
by Y/X notation, not X/Y; that is, it's an array of rows (Y) and each row is an
array of columns (X).

The upper layer is where most of the stuff happens. The lower layer is primarily
for things such as: traps hidden under movable blocks, clone machines underneath
monsters, etc.

Returns undef and sets C<$Data::ChipsChallenge::Error> on error.

=cut

sub getUpperLayer {
	my ($self,$level) = @_;

	if (!defined $level) {
		$Error = "getUpperLayer requires a level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "That level number wasn't found!";
		return undef;
	}

	if (scalar(@{$self->{levels}->{$level}->{layer1}}) == 0) {
		$Error = "The upper layer data for this level wasn't found!";
		return undef;
	}

	return $self->{levels}->{$level}->{layer1};
}

=head2 getLowerLayer (int LVL_NUMBER)

Returns a 2D array of all the tiles in the "lower" layer of the map for level
C<LVL_NUMBER>. On most maps the lower layer is made up only of floor tiles.

See L<"getUpperLayer">.

=cut

sub getLowerLayer {
	my ($self,$level) = @_;

	if (!defined $level) {
		$Error = "getLowerLayer requires a level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "That level number wasn't found!";
		return undef;
	}

	if (scalar(@{$self->{levels}->{$level}->{layer2}}) == 0) {
		$Error = "The lower layer data for this level wasn't found!";
		return undef;
	}

	return $self->{levels}->{$level}->{layer2};
}

=head2 setUpperLayer (int LVL_NUMBER, grid MAP_DATA)

Sets the upper layer of a level with the 2D array in C<MAP_DATA>. The array
should be like the one given by C<getUpperLayer>. The grid must have 32 rows
and 32 columns in each row. Incomplete map data will be rejected.

=cut

sub setUpperLayer {
	my ($self,$level,$data) = @_;

	if (!defined $level || !defined $data) {
		$Error = "setUpperLayer requires a level number and map data!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "That level number wasn't found!";
		return undef;
	}

	# Validate the map data.
	my $y = 0;
	if (scalar @{$data} != 32) {
		$Error = "The map data doesn't have 32 rows (Y)";
		return undef;
	}
	foreach my $row (@{$data}) {
		if (scalar @{$row} != 32) {
			$Error = "Row $y doesn't have 32 columns (X)";
			return undef;
		}
		$y++;
	}

	# Good? Good.
	$self->{levels}->{$level}->{layer1} = $data;
	return 1;
}

=head2 setLowerLayer (int LVL_NUMBER, grid MAP_DATA)

Sets the lower layer of a level with the 2D array in C<MAP_DATA>. The array
should be like the one given by C<getLowerLayer>. The grid must have 32 rows
and 32 columns in each row. Incomplete map data will be rejected.

=cut

sub setLowerLayer {
	my ($self,$level,$data) = @_;

	if (!defined $level || !defined $data) {
		$Error = "setLowerLayer requires a level number and map data!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "That level number wasn't found!";
		return undef;
	}

	# Validate the map data.
	my $y = 0;
	if (scalar @{$data} != 32) {
		$Error = "The map data doesn't have 32 rows (Y)";
		return undef;
	}
	foreach my $row (@{$data}) {
		if (scalar @{$row} != 32) {
			$Error = "Row $y doesn't have 32 columns (X)";
			return undef;
		}
		$y++;
	}

	# Good!
	$self->{levels}->{$level}->{layer2} = $data;
	return 1;
}

=head2 getBearTraps (int LVL_NUMBER)

Get all the coordinates to bear traps and their release buttons. Returns an
arrayref of hashrefs in the following format:

  [
    {
      button => [ X, Y ],
      trap   => [ X, Y ],
    },
  ];

Where C<X, Y> are the coordinates of the tiles involved, beginning at
C<0,0> and going to C<31,31>.

=cut

sub getBearTraps {
	my ($self,$level) = @_;

	if (!defined $level) {
		$Error = "getBearTraps requires the level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "The level $level doesn't exist!";
		return undef;
	}

	return $self->{levels}->{$level}->{traps};
}

=head2 setBearTraps (int LVL_NUMBER, arrayref BEARTRAPS)

Define bear trap coordinates. You must define every bear trap with
this method; calling it overwrites the existing bear trap data with
the ones you provide.

The arrayref should be formatted the same as the one you got from
C<getBearTraps>.

  $cc->setBearTraps (5, [
    {
      button => [ 5, 6 ],
      trap   => [ 7, 8 ],
    },
    {
      button => [ 1, 2 ],
      trap   => [ 3, 4 ],
    },
  ]);

=cut

sub setBearTraps {
	my ($self,$level,$traps) = @_;

	if (!defined $level) {
		$Error = "setBearTraps requires the level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "The level $level doesn't exist!";
		return undef;
	}
	if (ref($traps) ne "ARRAY") {
		$Error = "Must pass an arrayref in for the traps!";
		return undef;
	}

	# Validate the data.
	foreach my $trap (@{$traps}) {
		if (ref($trap) ne "HASH") {
			$Error = "Beartrap array must be an array of hashes!";
			return undef;
		}
		if (!exists $trap->{button} || ref($trap->{button}) ne "ARRAY") {
			$Error = "The 'button' key in hashes must be an array!";
			return undef;
		}
		if (!exists $trap->{trap} || ref($trap->{trap}) ne "ARRAY") {
			$Error = "The 'trap' key in hashes must be an array!";
			return undef;
		}
	}

	$self->{levels}->{$level}->{traps} = $traps;
	return 1;
}

=head2 getCloneMachines (int LVL_NUMBER)

Get all the coordinates to clone machines and the buttons that activate
them. Returns an arrayref of hashrefs in the following format:

  [
    {
      button => [ X, Y ],
      clone  => [ X, Y ],
    },
  ];

Where C<X, Y> are the coordinates of the tiles involves, beginning at
C<0,0> and going to C<31,31>.

=cut

sub getCloneMachines {
	my ($self,$level) = @_;

	if (!defined $level) {
		$Error = "getCloneMachines requires the level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "The level $level doesn't exist!";
		return undef;
	}

	return $self->{levels}->{$level}->{cloners};
}

=head2 setCloneMachines (int LVL_NUMBER, arrayref CLONE_MACHINES)

Define the coordinates for the clone machines in this level. Pass in the
complete list of clone machines, as calling this function will replace
the existing clone machine data.

Give it a data structure in the same format as getCloneMachines. Ex:

  $cc->setCloneMachines (113, [
    {
      button => [ 25, 13 ],
      clone  => [ 16, 32 ],
    },
  ]);

=cut

sub setCloneMachines {
	my ($self,$level,$coords) = @_;

	if (!defined $level) {
		$Error = "setCloneMachines requires the level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "The level $level doesn't exist!";
		return undef;
	}
	if (ref($coords) ne "ARRAY") {
		$Error = "Must pass an arrayref in for the clone machines!";
		return undef;
	}

	# Validate the data.
	foreach my $link (@{$coords}) {
		if (ref($link) ne "HASH") {
			$Error = "Clone machine array must be an array of hashes!";
			return undef;
		}
		if (!exists $link->{button} || ref($link->{button}) ne "ARRAY") {
			$Error = "The 'button' key in hashes must be an array!";
			return undef;
		}
		if (!exists $link->{clone} || ref($link->{clone}) ne "ARRAY") {
			$Error = "The 'clone' key in hashes must be an array!";
			return undef;
		}
	}

	$self->{levels}->{$level}->{cloners} = $coords;
	return 1;
}

=head2 getMovement (int LVL_NUMBER)

Get all the coordinates of every creature in the level that "moves".
Returns an arrayref of coordinates in the following format:

  [
    [ X, Y ],
    [ X, Y ],
    ...
  ];

=cut

sub getMovement {
	my ($self,$level) = @_;

	if (!defined $level) {
		$Error = "getMovement requires the level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "The level $level doesn't exist!";
		return undef;
	}

	return $self->{levels}->{$level}->{movement};
}

=head2 setMovement (int LVL_NUMBER, arrayref MOVEMENT)

Define the movement coordinates. Give this method a similar data structure
to what getMovement returns: an arrayref of arrays of X/Y coordinates.

Each coordinate given should point to a tile where a creature has been placed
in order for that creature to move when the map is loaded in-game. Any creature
that doesn't have its position in the Movement list won't move at all and will
stay put. This isn't very fun.

  $cc->setMovement (133, [
    [ 25, 25 ],
    [ 25, 26 ],
    [ 25, 27 ],
  ]);

=cut

sub setMovement {
	my ($self,$level,$coords) = @_;

	if (!defined $level) {
		$Error = "setMovement requires the level number!";
		return undef;
	}
	$level = int($level);
	if (!exists $self->{levels}->{$level}) {
		$Error = "The level $level doesn't exist!";
		return undef;
	}
	if (ref($coords) ne "ARRAY") {
		$Error = "Must pass an arrayref in for the clone machines!";
		return undef;
	}

	# Validate the data.
	foreach my $link (@{$coords}) {
		if (ref($link) ne "ARRAY") {
			$Error = "Clone machine array must be an array of hashes!";
			return undef;
		}
		if (scalar(@{$link}) != 2) {
			$Error = "Each coordinate pair must have only an X and Y coordinate!";
			return undef;
		}
	}

	$self->{levels}->{$level}->{movement} = $coords;
	return 1;
}

=head1 INTERNAL METHODS

=head2 process_map (int LVL_NUMBER, bin RAW_BINARY) *Internal

Used internally to process the C<RAW_BINARY> map data, which possibly belongs to
C<LVL_NUMBER>, and returns a 2D array of the 32x32 tile grid. The grid consists
of uppercase hexadecimal bytes that represent what is on each tile.

If the length of C<RAW_BINARY> is not 1024 bytes, your program WILL crash. This
shouldn't happen on a valid CHIPS.DAT file (if Chip's Challenge won't accept it,
that's an indicator that this Perl module won't either).

=cut

sub process_map {
	my ($self,$lvl_number,$layer) = @_;

	# Prepare an arrayref to hold the raw data.
	my $raw = [];

	# Read the map data one byte at a time.
	my @bytes = split(//, $layer);
	for (my $i = 0; $i < scalar(@bytes); $i++) {
		my $byte = $bytes[$i];

		# See what number this byte corresponds to.
		my $dec = unpack("C", $byte);
		my $hex = uc(sprintf("%02x",$dec));

#		print "Byte: $hex\n";

		# If this is an FF byte, it's a compression byte, so expand it.
		if ($hex eq 'FF') {
			# Read the following 2 bytes.
			my $copies_byte = $bytes[$i + 1];
			my $object_byte = $bytes[$i + 2];
			$i += 2;

			# Unpack the bytes.
			my $copies_dec = unpack("C",$copies_byte);
			my $object_dec = unpack("C",$object_byte);
			my $object_hex = uc(sprintf("%02x",$object_dec));

			my $deb1 = uc(sprintf("%02x",$copies_dec));
#			print "This is an FF byte: copy byte $object_hex by $copies_dec times\n";

			# Add it to the array this many times.
			for (my $j = 0; $j < $copies_dec; $j++) {
				push (@{$raw}, $object_hex);
			}
		}
		else {
			# Add it to the array.
			push (@{$raw}, $hex);
		}
	}

	# We should have 1024 elements.
	if (scalar(@{$raw}) != 1024) {
		die "Data for level $lvl_number doesn't have a complete 32x32 grid! It has " . scalar(@{$raw}) . " bytes!";
	}

	# Turn it into a 2D array.
	my $grid = [];
	my $x = 0;
	my $y = 0;
	for (my $i = 0; $i < scalar(@{$raw}); $i++) {
		if ($x > scalar @{$grid}) {
			push (@{$grid}, []);
		}

	#	print "$raw->[$i] ";
		$grid->[$y]->[$x] = $raw->[$i];
		$x++;
		if ($x >= 32) {
	#		print "\n";
			$x = 0;
			$y++;
		}
	}

	#die Dumper($grid);

	return $grid;
}

=head2 compress_map (grid MAP_DATA)

Given the 2D grid C<MAP_DATA>, the map is compressed and returned in raw binary.

=cut

sub compress_map {
	my ($self,$data) = @_;

	# Turn this 2D array into a flat array of binary tiles.
	my @flat = ();
	foreach my $row (@{$data}) {
		foreach my $col (@{$row}) {
			# Turn this tile into binary.
			my $bin = pack("C", hex("0x$col"));
			push (@flat,$bin);
		}
	}

	# Invalid?
	if (scalar(@flat) != 1024) {
		$Error = "Invalid map data given to compress_map: doesn't have 1024 tiles!";
		return undef;
	}

	# Compress the map.
	my @compressed = ();
	my $ff = pack("C", 0xFF); # The compression indicator
#	my $x = 0;
#	for (my $i = 0; $i < scalar(@flat); $i++) {
#		$x++;
#		my $deb = sprintf("%02x", unpack("C", $flat[$i]));
#		print "$deb ";
#		print "\n" if $x >= 32;
#		$x = 0 if $x >= 32;
#	}
#	print "\n";

	my $i = 0;
	while ($i < 1024) {
		my $byte = $flat[$i];

		my $deb1 = sprintf("%02x", unpack("C", $byte));
#		print "Byte: $deb1\n";

		# See if the next 5 bytes are the same.
		my $copies = 0;
		for (my $j = 0; ($i + $j) < scalar(@flat); $j++) {
			my $compare = $flat[$i + $j];
			if ($byte eq $compare) {
#				print "Byte $i matches byte " . ($i+$j) . "\n";
				$copies++;
				last if $copies >= 255;
			}
			else {
				last;
			}
		}

		# Can we compress this?
		if ($copies >= 4) {
			# Yes! See how many copies there are exactly.
#			print "Compress byte $deb1 by $copies times\n";
			$i += $copies;
			my $len = pack("C", $copies);
			push (@compressed,
				$ff,
				$len,
				$byte,
			);
		}
		else {
			$i++;
			push (@compressed, $byte);
		}
	}

	# Return the compressed binary.
	my $bin = join("",@compressed);
	return $bin;
}

=head2 decode_password (bin RAW_BINARY)

Given the encoded level password in raw binary (4 bytes followed by a null byte),
this function returns the 4 ASCII byte password in clear text. This is the password
you'd type into Chip's Challenge.

Passwords are decoded by XORing the values in the raw binary by hex C<0x99>,
if you're curious.

=cut

sub decode_password {
	my ($self,$data) = @_;

	my @chars = split(//, $data, 5);

	# Decode each character.
	my $pass = '';
	for (my $i = 0; $i < 4; $i++) {
		my $dec = unpack("C",$chars[$i]);
		my $hex = uc(sprintf("%02x",$dec));

		# Decode it with XOR 0x99
		my $xor = $dec ^ 0x99;
		my $chr = chr($xor);
		$pass .= $chr;
	}

	return $pass;
}

=head2 encode_password (string PASSWORD)

Given the plain text password C<PASSWORD>, it encodes it and returns it as
a 5 byte binary string (including the trailing null byte).

=cut

sub encode_password {
	my ($self,$pass) = @_;

	my @chars = split(//, $pass, 4);

	# Encode each character.
	my $bin = '';
	for (my $i = 0; $i < 4; $i++) {
		my $dec = unpack("C", $chars[$i]);
		my $hex = sprintf("%02x",$dec);

		# XOR it with 0x99
		my $xor = hex("0x$hex") ^ 0x99;
		$bin .= pack("C",$xor);
	}
	$bin .= chr(0x00);

	# try...
	my $plain = $self->decode_password($bin);

	return $bin;
}

=head2 random_password

Returns a random 4-letter password.

=cut

sub random_password {
	my ($self) = @_;

	my @letters = qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
	my $pass = '';
	for (my $i = 0; $i < 4; $i++) {
		$pass .= $letters [ int(rand(scalar(@letters))) ];
	}

	return $pass;
}

=head1 REFERENCE

The following is some reference material relating to certain in-game data
structures.

=head2 Option Fields Max Length

If the "Option Fields" are more than 1152 bytes altogether, Chip's Challenge
will crash when loading the level. The "Option Fields" include the following:

  Map Title
  Bear Trap Controls
  Cloning Machine Controls
  Map Password
  Map Hint
  Movement

Bear Trap Controls use 10 bytes for every link. Cloning Machine Controls use
8 bytes for every link. Map passwords use 7 bytes. Movement data uses 2 bytes
per entry.

In addition, bear traps, clone machines, and movement data use 2 bytes in
their headers.

=head2 Object Hex Codes

The two map layers on each level are 2D arrays of uppercase hexadecimal codes. Each of
these codes corresponds to a certain object that is placed at that location in the map.
This table outlines what each of these hex codes translates to, object-wise:

  00 Empty Tile (Space)
  01 Wall
  02 Computer Chip
  03 Water
  04 Fire
  05 Invisible Wall (won't appear)
  06 Blocked North
  07 Blocked West
  08 Blocked South
  09 Blocked East
  0A Movable Dirt Block
  0B Dirt (mud, turns to floor)
  0C Ice
  0D Force South (S)
  0E Cloning Block North (N)
  0F Cloning Block West (W)
  10 Cloning Block South (S)
  11 Cloning Block East (E)
  12 Force North (N)
  13 Force East (E)
  14 Force West (W)
  15 Exit
  16 Blue Door
  17 Red Door
  18 Green Door
  19 Yellow Door
  1A South/East Ice Slide
  1B South/West Ice Slide
  1C North/West Ice Slide
  1D North/East Ice Slide
  1E Blue Block (becomes Tile)
  1F Blue Block (becomes Wall)
  20 NOT USED
  21 Thief
  22 Chip Socket
  23 Green Button - Switch Blocks
  24 Red Button   - Cloning
  25 Switch Block - Closed
  26 Switch Block - Open
  27 Brown Button - Bear Traps
  28 Blue Button  - Tanks
  29 Teleport
  2A Bomb
  2B Bear Trap
  2C Invisible Wall (will appear)
  2D Gravel
  2E Pass Once
  2F Hint
  30 Blocked South/East
  31 Cloning Machine
  32 Force Random Direction
  34 Burned Chip
  35 Burned Chip (2)
  36 NOT USED
  37 NOT USED
  38 NOT USED
  39 Chip in Exit - End Game
  3A Exit - End Game
  3B Exit - End Game
  3C Chip Swimming (N)
  3D Chip Swimming (W)
  3E Chip Swimming (S)
  3F Chip Swimming (E)
  40 Bug (N)
  41 Bug (W)
  42 Bug (S)
  43 Bug (E)
  44 Firebug (N)
  45 Firebug (W)
  46 Firebug (S)
  47 Firebug (E)
  48 Pink Ball (N)
  49 Pink Ball (W)
  4A Pink Ball (S)
  4B Pink Ball (E)
  4C Tank (N)
  4D Tank (W)
  4E Tank (S)
  4F Tank (E)
  50 Ghost (N)
  51 Ghost (W)
  52 Ghost (S)
  53 Ghost (E)
  54 Frog (N)
  55 Frog (W)
  56 Frog (S)
  57 Frog (E)
  58 Dumbbell (N)
  59 Dumbbell (W)
  5A Dumbbell (S)
  5B Dumbbell (E)
  5C Blob (N)
  5D Blob (W)
  5E Blob (S)
  5F Blob (E)
  60 Centipede (N)
  61 Centipede (W)
  62 Centipede (S)
  63 Centipede (E)
  64 Blue Key
  65 Red Key
  66 Green Key
  67 Yellow Key
  68 Flippers
  69 Fire Boots
  6A Ice Skates
  6B Suction Boots
  6C Chip (N)
  6D Chip (W)
  6E Chip (S) (always used)
  6F Chip (E)

=head1 BUGS

Surely.

During its development, this module was used by its author and could accomplish
the following things:

  * Load all 149 levels of the standard CHIPS.DAT, then plow through the data
    and create JavaScript files that represented the information in each map
    using JavaScript data structures (possibly for a JavaScript-based Chip's
    Challenge clone -- although I won't admit to it until it's completed!)

  * Load the original CHIPS.DAT, create a new blank CHIPS.DAT with the same
    number of levels, and randomly sort the levels into the new file. You get
    the same Chip's Challenge gameplay experience, but with completely random
    levels like ya don't remember.

  * Load the original CHIPS.DAT into memory, and write it to a different
    output file, and both files computed the exact same MD5 sum.

Your mileage may vary. If you do encounter any bugs, feel free to bother me
about them!

=head1 CHANGES

  0.02  Wed Oct  5 2016
  - Updated the documentation, added a copy of the CHIPS.DAT format docs,
    started hosting on GitHub: https://github.com/kirsle/Data-ChipsChallenge
  - Switched to semantic versioning.

  0.01  Wed Jan 28 2009
  - Initial release.

=head1 SEE ALSO

CHIPS.DAT File Format: http://www.seasip.info/ccfile.html

Chip's Challenge Corridor: http://chips.kaseorg.com/

Tile World, an Open Source Chip's Challenge Emulator:
http://www.muppetlabs.com/~breadbox/software/tworld/

=head1 LICENSE

This module was written using information freely available on the Internet and
contains no proprietary works.

  The MIT License (MIT)

  Copyright (c) 2016 Noah Petherbridge

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

=head1 AUTHOR

Noah Petherbridge, https://www.kirsle.net/

=cut

# Nothing to see down here!
1;
