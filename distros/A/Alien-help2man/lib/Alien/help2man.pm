package Alien::help2man;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Build or find help2man
our $VERSION = '0.01'; # VERSION







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::help2man - Build or find help2man

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your script or module:

 use Alien::help2man;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::help2man->bin_dir;

=head1 DESCRIPTION

This distribution provides help2man so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of help2man on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
