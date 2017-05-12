
`DateTime::Moonpig` is a thin wrapper around the `DateTime` module to fix problems
with that module's design.  The main points are:

- Methods for mutating `DateTime::Moonpig` objects in place have been
overridden to throw a fatal exception.  These include `add_duration`
and `subtract_duration`, `set_`\* methods such as `set_hour`, and `truncate`.
- The addition and subtraction operators have been overridden.

    Adding a `DateTime::Moonpig` to an integer _n_ returns a new
    `DateTime::Moonpig` equal to a time _n_ seconds later than the
    original.  Similarly, subtracting _n_ returns a new `DateTime::Moonpig` equal to a
    time _n_ seconds earlier than the original.

    Subtracting two `DateTime::Moonpig`s returns the number of seconds elapsed between
    them.  It does not return an object of any kind.

- The `new` method can be called with a single argument, which is
interpreted as a Unix epoch time, such as is returned by Perl's
built-in `time()` function.
- A few convenient methods have been added

# BUGS

Please submit bug reports at
https://github.com/mjdominus/DateTime-Moonpig/issues .

Please *do not* submit bug reports at http://rt.cpan.org/ .

# LICENSE

Copyright 2010 IC Group, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

See the `LICENSE` file for a full statement of your rights under this
license.

# AUTHOR

Mark Jason DOMINUS, `mjd@cpan.org`

Ricardo SIGNES, `rjbs@cpan.org`
