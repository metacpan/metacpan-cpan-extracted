# NAME

Data::Trace - Trace when a data structure gets updated.

# SYNOPSIS

    use Data::Trace;

    my $data = {a => [0, {complex => 1}]};
    sub BadCall{ $data->{a}[0] = 1 }
    Trace($data);
    BadCall();  # Shows strack trace of where data was changed.

# DESCRIPTION

This module provides a convienient way to find out
when a data structure has been updated.

It is a debugging/tracing aid for complex systems to identify unintentional
alteration to data structures which should be treated as read-only.

Probably can also create a variable as read-only in Moose and see where
its been changed, but this module is without Moose support.

# SUBROUTINES/METHODS

## Trace

    Trace( \$scalar );
    Trace( \@array );
    Trace( \@hash );
    Trace( $complex_data );

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
