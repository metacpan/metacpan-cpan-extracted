package Alien::unzip;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Find or build Info-ZIP unzip
our $VERSION = '0.03'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::unzip - Find or build Info-ZIP unzip

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Alien::unzip
 use Env qw( @PATH );

 # Add unzip to the PATH if it isn't there already
 push @PATH, Alien::unzip->bin_dir;

=head1 DESCRIPTION

This is an alien that provides Info-ZIP unzip.  It is useful for building
other aliens in C<share> mode.  Another option is to use L<Archive::Zip>,
but that module seems to be quite unreliable in practice.

=head1 SEE ALSO

=over

=item L<Alien>

=item L<Alien::Build>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
