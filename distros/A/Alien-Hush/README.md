# Alien::Hush

Alien::Hush is an interface to the [Hush](https://myhush.org) privacy coin.

Please come join our [Discord](https://discord.io/hush/)

# Dependencies

This module requires Alien::Base.

## CPAN distribution dependencies

Currently Alien::Hush requires at least Perl 5.8.1, and a Linux-based operating
system with at least 4GB of RAM, to fully compile the underlying Hush daemon,
which is based on Zcash.

For Hush to work correctly, it will need to make inbound+outbound connections
on the Peer-to-Peer port 8888.

# Installation

To install this module from source code, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install clean

If you just want to install this module with your favorite CPAN client:

    cpan  Alien::Hush
OR
    cpanm Alien::Hush

to use the beauty of Perl CPAN infrastructure via your local mirror, to
install Hush.

# Support

After installing, you can find documentation for this module with the
perldoc command:

    perldoc Alien::Hush

# Copyright and Licence

Copyright (C) 2017 Jonathan "Duke" Leto

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. Fuck Yeah.
