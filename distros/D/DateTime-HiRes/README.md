# NAME

DateTime::HiRes - Create DateTime objects with sub-second current time resolution

# VERSION

version 0.04

# SYNOPSIS

    use DateTime::HiRes;

    my $dt = DateTime::HiRes->now;

# DESCRIPTION

This module enables you to generate DateTime objects that represent the current
time with sub-second resolution.

# METHODS

This class provides the following methods:

## DateTime::HiRes->now( ... )

Similar to `DateTime->now` but uses `Time::HiRes::time()` instead of
Perl's `CORE::time()` to determine the current time. The returned object will
have fractional second information stored as nanoseconds. The sub-second
precision of `Time::HiRes` is highly system dependent and will vary from one
platform to the next.

Just like `DateTime->now` it accepts "time\_zone" and "locale" parameters.

# CREDITS

Everyone at the DateTime `Asylum`.

# SEE ALSO

[DateTime](https://metacpan.org/pod/DateTime), [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes)

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/DateTime-HiRes/issues](https://github.com/houseabsolute/DateTime-HiRes/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for DateTime-HiRes can be found at [https://github.com/houseabsolute/DateTime-HiRes](https://github.com/houseabsolute/DateTime-HiRes).

# AUTHORS

- Joshua Hoblitt <jhoblitt@cpan.org>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Roy Ivy III <rivy.dev@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Joshua Hoblitt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
`LICENSE` file included with this distribution.
