# NAME

Data::IEEE754 - Pack and unpack big-endian IEEE754 floats and doubles

# VERSION

version 0.02

# SYNOPSIS

    use Data::IEEE754 qw( pack_double_be unpack_double_be );

    my $packed = pack_double_be(3.14);
    my $double = unpack_double_be($packed);

# DESCRIPTION

This module provides some simple convenience functions for packing and
unpacking IEEE 754 floats and doubles.

If you can require Perl 5.10 or greater then this module is pointless. Just
use the `d>` and `f>` pack formats instead!

Currently this module only implements big-endian order. Patches to add
little-endian order subroutines are welcome.

# EXPORTS

This module optionally exports the following four functions:

- pack\_float\_be($number)
- pack\_double\_be($number)
- unpack\_float\_be($binary)
- unpack\_double\_be($binary)

# CREDITS

The code in this module is more or less copied and pasted from
[Data::MessagePack](https://metacpan.org/pod/Data::MessagePack)'s `Data::MessagePack::PP` module. That module was
written by Makamaka Hannyaharamitu. The code was then tweaked by Dave Rolsky,
so blame him for the bugs.

# SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-IEEE754 or via email at
bug-data-ieee754@rt.cpan.org.

Bugs may be submitted through [https://github.com/maxmind/Data-IEEE754/issues](https://github.com/maxmind/Data-IEEE754/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
