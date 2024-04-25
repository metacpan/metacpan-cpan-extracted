# NAME

Call::Context - Sanity-check calling context

# SYNOPSIS

    use Call::Context;

    sub gives_a_list {

        # Will die() if the context is not list.
        Call::Context::must_be_list();

        return (1, 2, 3);
    }

    gives_a_list();             # die()s: incorrect context (void)

    my $v = gives_a_list();     # die()s: incorrect context (scalar)

    my @list = gives_a_list();  # lives

    #----------------------------------------------------------------------

    sub scalar_is_bad {

        # Will die() if the context is scalar.
        Call::Context::must_not_be_scalar();

        return (1, 2, 3);
    }

    scalar_is_bad();            # die()s: incorrect context (void)

    my $v = scalar_is_bad();    # die()s: incorrect context (scalar)

    my @list = scalar_is_bad(); # lives

# DESCRIPTION

If your function only expects to return a list, then a call in some other
context is, by definition, an error. The problem is that, depending on how
the function is written, it may actually do something expected in testing, but
then in production act differently.

# FUNCTIONS

## must\_be\_list()

`die()`s if the calling function is itself called outside list context.
(See the SYNOPSIS for examples.)

## must\_not\_be\_scalar()

`die()`s if the calling function is itself called in scalar context.
(See the SYNOPSIS for examples.)

# EXCEPTIONS

This module throws instances of `Call::Context::X`. `Call::Context::X` is
overloaded to stringify; however, to keep memory usage low, `overload` is not
loaded until instantiation.

# REPOSITORY

https://github.com/FGasper/p5-Call-Context

# LICENSE

This module is licensed under the MIT License.
