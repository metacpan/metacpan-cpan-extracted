package Alien::gzip;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: Find or build gzip
our $VERSION = '0.03'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::gzip - Find or build gzip

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Alien::gzip;
 use Env qw( @PATH );
 
 # Add gzip to the path if it isn't there already
 push @PATH, Alien::gzip->bin_dir;

=head1 DESCRIPTION

Many environments provide the gzip command, but a few do not.
Using this module in your C<Build.PL> (or elsewhere) you can
make sure that gzip will be available.  If the system provides
it, then great, this module is a no-op.  If it does not, then
it will download and install it into a private location so that
it can be added to the C<PATH> when this module is used.

=head1 SEE ALSO

=over 4

=item L<Alien>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
