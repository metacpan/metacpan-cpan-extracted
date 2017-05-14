# NAME

Acme::Sort::Sleep - IO::Async timer based sorting algorithm

# SYNOPSIS

    use Acme::Sort::Sleep qw( sleepsort );

    my @sorted = sleepsort( qw( 3 1 3.37 0 ) );

# DISCUSSION

[https://www.reddit.com/r/programming/comments/2qeg28/4chan\_sleep\_sort/](https://www.reddit.com/r/programming/comments/2qeg28/4chan_sleep_sort/)

    If it's dumb but it works, it's not dumb.
    Except this. This works, but it's still dumb. :D

      -- Asmor

Except this won't always work.

# AUTHOR

Mitch McCracken <mrmccrac@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Mitch McCracken.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
