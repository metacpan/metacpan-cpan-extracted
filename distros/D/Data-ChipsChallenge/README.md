# NAME

Data::ChipsChallenge - Perl interface to Chip's Challenge data files.

# SYNOPSIS

```perl
my $cc = new Data::ChipsChallenge("./CHIPS.DAT");

print "This CHIPS.DAT file contains ", $cc->levels, " levels.\n\n";

for (my $i = 1; $i <= $cc->levels; $i++) {
  my $info = $cc->getLevelInfo($i);
  print "Level $info->{level} - $info->{title}\n"
    . "Time Limit: $info->{time}\n"
    . "     Chips: $info->{chips}\n"
    . "  Password: $info->{password}\n\n";
}
```

# DESCRIPTION

This module provides an interface for reading and writing to Chip's Challenge
data files ("CHIPS.DAT") that is shipped with _Best of Windows Entertainment
Pack_'s Chip's Challenge.

Chip's Challenge is a 2D tilebased maze game. The goal of each level is usually
to collect a certain number of computer chips, so that a chip socket can be
opened and the player can get to the exit and proceed to the next level.

This module is able to read and manipulate the data file that contains all these
levels. For some examples, see those in the "eg" folder shipped with this
module.

Documentation on the CHIPS.DAT file format can be found at this location:
http://www.seasip.info/ccfile.html -- in case that page no longer exists, I've
archived a copy of it in the `doc/` directory with this source distribution.

# DISCLAIMER

This module only provides the mechanism for which you can read and manipulate
a CHIPS.DAT game file. However, it cannot include a copy of the official
CHIPS.DAT, as that file is copyrighted by its creators. If you have an original
copy of the Chip's Challenge game from the _BOWEP_ collection, you can use its
CHIPS.DAT with this module.

# METHODS

All of the following methods will return a value (or in the very least, 1).
If any errors occur inside any methods, the method will return undef, and the
error text can be obtained from `$Data::ChipsChallenge::Error`.

## new (\[string FILE,\] hash OPTIONS)

Create a new ChipsChallenge object. If you pass in an odd number of arguments,
the first argument is taken as a default "CHIPS.DAT" file to load, and the rest
is taken as a hash like 99% of the other CPAN modules. Loading the
standard Chip's Challenge file with 149 levels takes a few seconds.

Alternatively, pass options in hash form:

    bool   debug = Enable or disable debug mode
    string file  = The path to CHIPS.DAT

Ex:

```perl
my $cc = new Data::ChipsChallenge("CHIPS.DAT");
my $cc = new Data::ChipsChallenge("CHIPS.DAT", debug => 1);
my $cc = new Data::ChipsChallenge(file => "CHIPS.DAT", debug => 1);
```

## create (int LEVELS)

Create a new, blank, CHIPS.DAT file. Pass in the number of levels you want
for your new CHIPS.DAT. This method will clear out any loaded data and
initialize blank grids for each level specified.

Additional levels can be added or destroyed via the `addLevel` and
`deleteLevel` functions.

## load (string FILE)

Load a CHIPS.DAT file into memory. Returns undef on error, or 1 on success.

## write (\[string FILE\])

Write the loaded data into a CHIPS.DAT file. This file should be able to be loaded
into Chip's Challenge and played. Returns undef and sets `$Data::ChipsChallenge::Error`
on any errors.

If not given a filename, it will write to the same file that was last `load`ed. If
no file was ever loaded then it would default to a file named "CHIPS.DAT".

## levels

Returns the number of loaded levels. When loading the standard CHIPS.DAT, this
method will probably return `149`.

```perl
print "There are ", $cc->levels, " levels in this file.\n";
```

## getLevelInfo (int LVL\_NUMBER)

Get information about a level. Returns a hashref of all the info available for
the level, which may include some or all of the following keys:

    level:    The level number of this map (3 digits, zero-padded, e.g. 001)
    title:    The name of the map
    password: The four-letter password for this level
    time:     The time limit (if 0, means there's no time limit)
    chips:    Number of chips required to open the socket on this map
    hint:     The text of the hint on this map (if no hint, this key won't exist)

Example:

```perl
for (my $i = 1; $i <= $cc->levels; $i++) {
  my $info = $cc->getLevelInfo($i);
  print "Level: $info->{level} - $info->{title}\n"
      . " Time: $info->{time}   Chips: $info->{chips}\n"
      . " Pass: $info->{password}\n"
      . (exists $info->{hint} ? " Hint: $info->{hint}\n" : "")
      . "\n";
}
```

Returns undef if the level isn't found, or if the level number wasn't given.

## setLevelInfo (int LVL\_NUMBER, hash INFO)

Set metadata about a level. The following information can be set:

    level
    title
    password
    time
    chips
    hint

See ["getLevelInfo"](#getlevelinfo) for the definition of these fields.

Note that the `level` field should equal `LVL_NUMBER`. It's _possible_ to
override this to be something different, but it's not recommended. If you want
to test your luck anyway, pass in the `level` field manually any time you call
`setLevelInfo`. When the `level` field is not given, it defaults to the given
`LVL_NUMBER`.

You don't need to pass in every field. For example if you only want to change
a level's time limit, you can pass only the time:

```perl
# Level 131, "Totally Unfair", is indeed totally unfair - only 60 seconds to
# haul butt to barely survive the level? Let's up the time limit.
$cc->setLevelInfo (131, time => 999);

# Or better yet, remove the time limit altogether!
$cc->setLevelInfo (131, time => 0);
```

Special considerations:

    * There must be a title
    * There must be a password
    * All level passwords must be unique

If there's an error, this function returns undef and sets
`$Data::ChipsChallenge::Error` to the text of the error message.

## getUpperLayer (int LVL\_NUMBER)

Returns a 2D array of all the tiles in the "upper" (primary) layer of the map
for level `LVL_NUMBER`. Each entry in the map is an uppercase plaintext
hexadecimal code for the object that appears in that space. The grid is referenced
by Y/X notation, not X/Y; that is, it's an array of rows (Y) and each row is an
array of columns (X).

The upper layer is where most of the stuff happens. The lower layer is primarily
for things such as: traps hidden under movable blocks, clone machines underneath
monsters, etc.

Returns undef and sets `$Data::ChipsChallenge::Error` on error.

## getLowerLayer (int LVL\_NUMBER)

Returns a 2D array of all the tiles in the "lower" layer of the map for level
`LVL_NUMBER`. On most maps the lower layer is made up only of floor tiles.

See ["getUpperLayer"](#getupperlayer).

## setUpperLayer (int LVL\_NUMBER, grid MAP\_DATA)

Sets the upper layer of a level with the 2D array in `MAP_DATA`. The array
should be like the one given by `getUpperLayer`. The grid must have 32 rows
and 32 columns in each row. Incomplete map data will be rejected.

## setLowerLayer (int LVL\_NUMBER, grid MAP\_DATA)

Sets the lower layer of a level with the 2D array in `MAP_DATA`. The array
should be like the one given by `getLowerLayer`. The grid must have 32 rows
and 32 columns in each row. Incomplete map data will be rejected.

## getBearTraps (int LVL\_NUMBER)

Get all the coordinates to bear traps and their release buttons. Returns an
arrayref of hashrefs in the following format:

    [
      {
        button => [ X, Y ],
        trap   => [ X, Y ],
      },
    ];

Where `X, Y` are the coordinates of the tiles involved, beginning at
`0,0` and going to `31,31`.

## setBearTraps (int LVL\_NUMBER, arrayref BEARTRAPS)

Define bear trap coordinates. You must define every bear trap with
this method; calling it overwrites the existing bear trap data with
the ones you provide.

The arrayref should be formatted the same as the one you got from
`getBearTraps`.

```perl
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
```

## getCloneMachines (int LVL\_NUMBER)

Get all the coordinates to clone machines and the buttons that activate
them. Returns an arrayref of hashrefs in the following format:

    [
      {
        button => [ X, Y ],
        clone  => [ X, Y ],
      },
    ];

Where `X, Y` are the coordinates of the tiles involves, beginning at
`0,0` and going to `31,31`.

## setCloneMachines (int LVL\_NUMBER, arrayref CLONE\_MACHINES)

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

## getMovement (int LVL\_NUMBER)

Get all the coordinates of every creature in the level that "moves".
Returns an arrayref of coordinates in the following format:

    [
      [ X, Y ],
      [ X, Y ],
      ...
    ];

## setMovement (int LVL\_NUMBER, arrayref MOVEMENT)

Define the movement coordinates. Give this method a similar data structure
to what getMovement returns: an arrayref of arrays of X/Y coordinates.

Each coordinate given should point to a tile where a creature has been placed
in order for that creature to move when the map is loaded in-game. Any creature
that doesn't have its position in the Movement list won't move at all and will
stay put. This isn't very fun.

```
$cc->setMovement (133, [
  [ 25, 25 ],
  [ 25, 26 ],
  [ 25, 27 ],
]);
```

# INTERNAL METHODS

## process\_map (int LVL\_NUMBER, bin RAW\_BINARY) \*Internal

Used internally to process the `RAW_BINARY` map data, which possibly belongs to
`LVL_NUMBER`, and returns a 2D array of the 32x32 tile grid. The grid consists
of uppercase hexadecimal bytes that represent what is on each tile.

If the length of `RAW_BINARY` is not 1024 bytes, your program WILL crash. This
shouldn't happen on a valid CHIPS.DAT file (if Chip's Challenge won't accept it,
that's an indicator that this Perl module won't either).

## compress\_map (grid MAP\_DATA)

Given the 2D grid `MAP_DATA`, the map is compressed and returned in raw binary.

## decode\_password (bin RAW\_BINARY)

Given the encoded level password in raw binary (4 bytes followed by a null byte),
this function returns the 4 ASCII byte password in clear text. This is the password
you'd type into Chip's Challenge.

Passwords are decoded by XORing the values in the raw binary by hex `0x99`,
if you're curious.

## encode\_password (string PASSWORD)

Given the plain text password `PASSWORD`, it encodes it and returns it as
a 5 byte binary string (including the trailing null byte).

## random\_password

Returns a random 4-letter password.

# REFERENCE

The following is some reference material relating to certain in-game data
structures.

## Option Fields Max Length

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

## Object Hex Codes

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

# BUGS

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

# CHANGES

  1.0.0  Wed Oct  5 2016
  - Updated the documentation, added a copy of the CHIPS.DAT format docs,
    started hosting on GitHub: https://github.com/kirsle/Data-ChipsChallenge
  - Switched to semantic versioning.

  0.01  Wed Jan 28 2009
  - Initial release.

# SEE ALSO

CHIPS.DAT File Format: http://www.seasip.info/ccfile.html

Chip's Challenge Corridor: http://chips.kaseorg.com/

Tile World, an Open Source Chip's Challenge Emulator:
http://www.muppetlabs.com/~breadbox/software/tworld/

# LICENSE

This module was written using information freely available on the Internet and
contains no proprietary works.

```
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
```

# AUTHOR

Noah Petherbridge, https://www.kirsle.net/
