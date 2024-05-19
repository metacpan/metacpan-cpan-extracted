# NAME

Data::Trace - Trace when a data structure gets updated.

# SYNOPSIS

Variable change trace:

    use Data::Trace;

    my $data = {a => [0, {complex => 1}]};

    sub BadCall{ $data->{a}[0] = 1 }

    Trace($data);

    BadCall();  # Shows stack trace of where data was changed.

Stack trace:

    use Data::Trace;
    Trace();    # 1 level.
    Trace(5);   # 5 levels.

# DESCRIPTION

This module provides a convienient way to find out
when a data structure has been updated.

It is a debugging/tracing aid for complex systems to identify unintentional
alteration to data structures which should be treated as read-only.

Probably can also create a variable as read-only in Moose and see where
its been changed, but this module is without Moose support.

# SUBROUTINES/METHODS

## Trace

Watch a reference for changes:

    Trace( \$scalar, @OPTIONS );
    Trace( \@array , @OPTIONS );
    Trace( \@hash , @OPTIONS );
    Trace( $complex_data , @OPTIONS );

Just a stack trace with no watching:

    Trace( @OPTIONS );

Options:

    -clone => 0,    # Disable auto tying after a Storable dclone.

    -var => REF,    # Variable to watch.
    REF             # Same as passing a reference.

    -levels => NUM  # How many scope levels to show.
    NUM             # Same as passing a decimal.

    -raw => 1,      # Include Internal call like Moose,
                    # and Class::MOP in a trace.
    -NUM            # Same as passing negative number.

    -message => STR # Message to use for a normal (non-
                    # tie stack trace).
    STR             # Same as passing anything else.

## \_ProcessArgs

    Allows calling Trace like:
    Trace() and Trace(-levels => 1) to
    mean the same.

# AUTHOR

Tim Potapov, `<tim.potapov at gmail.com>`

# BUGS

Please report any bugs or feature requests to [https://github.com/poti1/data-trace/issues](https://github.com/poti1/data-trace/issues).

Currently only detect `STORE` operations.
Expand this to also detect `PUSH`, `POP`, `DELETE`, etc.

# TODO

Consider adding an option to have a warn message anytime a structure is FETCHed.

# SUPPORT

You can find documentation for this module
with the perldoc command.

    perldoc Data::Trace

You can also look for information at:

[https://metacpan.org/pod/Data::Trace](https://metacpan.org/pod/Data::Trace)

[https://github.com/poti1/data-trace](https://github.com/poti1/data-trace)

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
