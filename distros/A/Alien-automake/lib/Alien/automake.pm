package Alien::automake;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Build or find automake
our $VERSION = '0.15'; # VERSION






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::automake - Build or find automake

=head1 VERSION

version 0.15

=head1 SYNOPSIS

In your script or module:

 use Alien::automake;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::automake->bin_dir;

=head1 DESCRIPTION

This distribution provides automake so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of automake on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=head1 CAVEATS

This module is currently configured to I<always> do a share install.  This is because C<system> installs for this alien are not reliable.  Please see
this issue for details: L<https://github.com/plicease/Alien-autoconf/issues/2> (the issue is for autoconf, but relates to automake as well).  The good
news is that most of the time you shouldn't need this module I<unless> you are building another alien from source.  If your system provides the package
that is targeted by the upstream alien I recommend using that.  If you are packaging system packages for your platform then I recommend making sure the
upstream alien uses the system library so you won't need to install this module.

=head1 SEE ALSO

=over 4

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Build>

=item L<Alien::Autotools>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
