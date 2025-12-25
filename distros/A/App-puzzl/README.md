
# NAME

App::puzzl - A CLI for writing running Advent of Code solutions written in Perl

# SYNOPSIS

    puzzl --new=<day number(s)> --run=<day number(s)>
    puzzl --run=3
    puzzl --new=4

# DESCRIPTION

App::puzzl is a CLI for running Advent of Code solutions. `puzzl --new` will create a file in `days/`,
and `puzzl --run` will run a day, passing an input file descriptor for the file `input/day(day number).txt`.

# LICENSE

Copyright (C) Aleks Rutins.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Aleks Rutins <keeper@farthergate.com>
