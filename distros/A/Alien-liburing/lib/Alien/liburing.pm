package Alien::liburing;

use strict;
use warnings;

our $VERSION = '0.101';

use parent 'Alien::Base';

1;

=head1 NAME

Alien::liburing - Alien wrapper for liburing

=head1 DESCRIPTION

This module provides library building and detectiong support for the
C<libuing> C library, for working with the io_uring Linux kernel subsystem.
This library is only available or relavent for Linux, and will fail
to install on any other operating systems.

This library also requires a resonably modern version of the Linux kernel.
I'd recommend at a minimum a 5.3 versioned kernel or newer, 
due to features and support.

For the eventual IO::Async::Loop::IOUring module, a minimum kernel
version of 5.4 (likely 5.5) will also be needed and detected at install
time of that module.

See the L<github|https://github.com/axboe/liburing> project for liburing,
and the kernel L<documentation (pdf)|https://kernel.dk/io_uring.pdf> for io_uring documentation 
Also see L<Alien::Build::Manual::AlienUser> for usage.

=head1 BUGS

Report any issues on the public github bugtracker.

=head1 AUTHOR

Ryan Voots <simcop@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Ryan Voots.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<IO::Uring> - A library to actually using IO::Uring from within perl
