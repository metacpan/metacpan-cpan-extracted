package Alien::Alien;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Find or use alien package conversion tool
our $VERSION = '0.02'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Alien - Find or use alien package conversion tool

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Alien::Alien;
 use Env qw( @PATH );
 
 unshift @ENV, Alien::Alien->bin_dir;
 
 system "alien --to-rpm --scripts ./mkpkg.deb";

=head1 DESCRIPTION

This L<Alien> module provides the C<alien> tool that converts between different
Linux package formats.  Reading this documentation, and seeing the name, you may
feel as though you are glancing through the looking glass.  This distribution is
not I<entirely> a joke, though it is somewhat to tongue in cheek.  One of the useful
things that this module provides is some interesting challenges in the L<Alien>
space.  That includes

=over 4

=item Tool is implemented as Perl

C<alien> is implemented in Perl, and distributed as a standard CPAN style distribution,
but isn't available ON CPAN.

=item Project is hosted on SourceForge

This module drove development of L<Alien::Build::Plugin::Decode::SourceForge>, which I
expect will be useful for other Aliens.

=item Tool is architecture independent

Aliens using L<Alien::Build> are usually installed in the architecture specific library
location, because they I<usually> are architecture specific.  Since this tool is Perl,
it is architecture independent, so we install it in the regular architecture independent
library location.

=item Project is distributed as a tar.xz file.

This is an added complication and sort of a hassle for a few bytes saved.  Thanks!

=back

=head1 METHODS

=head2 bin_dir

 my @dirs = Alien::Alien->bin_dir;

Returns the list of directories that need to be added to the PATH in order for C<alien>
to work.  This may be an empty list (as for a system install).

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Base>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
