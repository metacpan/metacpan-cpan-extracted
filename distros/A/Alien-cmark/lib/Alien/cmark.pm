package Alien::cmark;

use strict;
use warnings;

our $VERSION = '0.004';

use parent 'Alien::Base';

1;

=head1 NAME

Alien::cmark - Alien wrapper for cmark

=head1 DESCRIPTION

This module provides the C<cmark> reference implementation of
L<CommonMark|http://commonmark.org/>, consisting of the C<libcmark> library and
C<cmark> command-line tool. See L<Alien::Build::Manual::AlienUser> for usage.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<CommonMark>
