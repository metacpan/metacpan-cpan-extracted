![CI](https://github.com/BlueSquare23/Acme-Shotgun/actions/workflows/ci.yml/badge.svg)

# NAME

Acme::Shotgun - Shoots holes in files

# SYNOPSIS

    use Acme::Shotgun;

    my $gun = Acme::Shotgun->new(
        type  => 'double',   # double | pump
        load  => 'bird',     # bird | buck | slug
        quiet => 0,
        debug => 0,
    );

    $gun->reload();
    $gun->check();
    $gun->fire(target => '/path/to/file.txt');

# DESCRIPTION

Acme::Shotgun is an object-oriented Perl module that shoots holes in plain
text files. Supports double-barrel and pump-action shotgun types, with
birdshot, buckshot, and slug ammunition - each producing a distinct damage
pattern in the target file.

Magazine state is kept in the object itself, so rounds are tracked for the
lifetime of the object.

# METHODS

## new(%args)

Constructs and returns a new Acme::Shotgun object. The gun is automatically
reloaded on construction.

    my $gun = Acme::Shotgun->new(
        type    => 'double',  # 'double' (default) or 'pump'
        load    => 'bird',    # 'bird' (default), 'buck', or 'slug'
        shots   => undef,     # optional: cap the number of rounds loaded
        quiet   => 0,         # suppress all output
        debug   => 0,         # dry-run mode, no file modifications
        verbose => 1,         # verbose output (disabled automatically if quiet)
    );

Dies with an error if an invalid `type` or `load` value is given.

## reload()

Loads the magazine for the current shotgun type and ammunition. Default
capacity is 2 rounds for `double` and 5 rounds for `pump`. If `shots`
was set in the constructor and is less than the default capacity, it is
used instead.

Prints a loading message and the resulting mag state when `verbose` is on.
Returns the object for chaining.

## check()

Prints the current magazine state - shotgun type, ammunition type, and
remaining round count. Returns the object for chaining.

## fire(target => $path)

Fires all remaining rounds at the given target file, shooting holes into
it with each shot. The file must be an existing plain text file under 1 GB.
Each shot prints `POW!` unless `quiet` is set.

In `debug` mode, `POW!` is still printed but no file modifications are
made. Returns the object for chaining.

# REFERENCE

## Shotgun Types

- **double**

    Double-barrel. Holds 2 rounds by default. This is the default type.

- **pump**

    Pump-action. Holds 5 rounds by default.

## Ammunition Types

- **bird**

    Birdshot. Sparse, scattered pellet holes spread across the target area.
    This is the default ammunition type.

- **buck**

    Buckshot. Denser, clustered hole patterns - more destructive than birdshot.

- **slug**

    Slug. A tight, concentrated blast with minimal spread.

# AUTHOR

John R.

# LICENSE

Same terms as Perl itself.

