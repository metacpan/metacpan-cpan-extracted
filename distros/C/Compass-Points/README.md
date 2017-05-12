# NAME

Compass::Points - Convert between compass point names, abbreviations and values

# SYNOPSIS

    use Compass::Points;
    my $points = Compass::Points->new();
    my $deg = $points->abbr2deg( "NNE" );

# DESCRIPTION

This module converts compass point names and abbreviations to degrees
and vice versa.
It supports four different compass point systems: 4, 8, 16 and 32.
The default is 16 and can be used for wind compass usage.

# METHODS

## new( \[ $points \] )

Returns a Compass::Points object for the number of points (defaults to 16).

## deg2abbr( $degree )

Takes a degree value and returns the corresponding abbreviation for the
matching wind name.

## deg2name( $degree )

Same as deg2abbr() but returns the full wind name.

## abbr2deg( $abbreviation )

Given a wind name abbreviation returns the degree of the points object.

## name2deg( $name )

Same as abbr2deg() but takes full wind names.

# SEE ALSO

[http://en.wikipedia.org/wiki/Points\_of\_the\_compass](http://en.wikipedia.org/wiki/Points_of_the_compass)

# AUTHOR

Simon Bertrang, <janus@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2014 by Simon Bertrang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
