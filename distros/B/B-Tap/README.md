# NAME

B::Tap - Inject tapping node to optree

# SYNOPSIS

    use B;
    use B::Tap;
    use B::Tools;

    sub foo { 63 }

    my $code = sub { foo() + 5900 };
    my $cv = B::svref_2object($code);

    my ($entersub) = op_grep { $_->name eq 'entersub' } $cv->ROOT;
    tap($$entersub, ${$cv->ROOT}, \my @buf);

    $code->();

# DESCRIPTION

B::Tap is tapping library for B tree. `tap` function injects custom ops for fetching result of the node.

The implementation works, but it's not beautiful code. I'm newbie about the B world, Patches welcome.

**WARNINGS: This module is in a alpha state. Any API will change without notice.**

# FUNCTIONS

- tap($op, $root\_op, \\@buf)

    Tapping the result value of `$op`. You need pass the `$root_op` for rewriting tree structure. Tapped result value was stored to `\@buf`. `\@buf` must be arrayref.

    B::Tap push the current stack to `\@buf`. First element for each value is `GIMME_V`. Second element is the value of stacks.

- G\_SCALAR
- G\_ARRAY
- G\_VOID

    These functions are not exportable by default. If you want to use these functions, specify the import arguments like:

        use B::Tap ':all';

    Or

        use B::Tap qw(G_SCALAR G_ARRAY G_VOID);

# FAQ

- Why this module required 5.14+?

    Under 5.14, Perl5's custom op support is incomplete. B::Deparse can't deparse the code using custom ops.

    I seem this library without deparsing is useless.

    But if you want to use this with 5.8, it may works.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
