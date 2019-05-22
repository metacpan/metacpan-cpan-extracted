package Alien::hiredis;

use strict;
use warnings;

our $VERSION = '0.008';

use parent 'Alien::Base';

1;

=head1 NAME

Alien::hiredis - Alien wrapper for hiredis

=head1 DESCRIPTION

This module provides the L<hiredis|https://github.com/redis/hiredis>
minimalistic C client library for the L<Redis|https://redis.io> database. See
L<Alien::Build::Manual::AlienUser> for usage.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Redis::hiredis>, L<Protocol::Redis::XS>
