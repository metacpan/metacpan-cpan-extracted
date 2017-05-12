# NAME

B::Tools - Simple B operating library

# SYNOPSIS

    use B::Tools;

    op_walk {
        say $_->name;
    } $root;

    my @entersubs = op_grep { $_->name eq 'entersub' } $root;

# DESCRIPTION

B::Tools is simple B operating library.

# FUNCTIONS

- op\_walk(&$)

    Walk every op from root node.

    First argument is the callback function for walking.
    Second argument is the root op to walking.

    _Return value_: Useless.

- op\_grep(&$)

    Grep the op from op tree.

    First argument is the callback function for grepping.
    Second argument is the root op to grepping.

    _Return value_: Result of grep.

- my @descendants = op\_descendants($)

    Get the descendants from $op.

    _Return value_: @descendants

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

[B](http://search.cpan.org/perldoc?B) is a library for manage B things.

[B::Generate](http://search.cpan.org/perldoc?B::Generate) to generate OP tree in pure perl code.

[B::Utils](http://search.cpan.org/perldoc?B::Utils) provides features like this. But this module provides more simple features.
