package Alien::autoconf;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Base );

# ABSTRACT: Build or find autoconf
our $VERSION = '0.17'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::autoconf - Build or find autoconf

=head1 VERSION

version 0.17

=head1 SYNOPSIS

From your script or module:

 use Alien::autoconf;
 use Env qw( @PATH );
 
 unshift @PATH, Alien::autoconf->bin_dir;

From your alienfile:

 use alienfile;
 
 share {
   # Alien::Autotools will pull in:
   #  - Alien::autoconf
   #  - Alien::automake
   #  - Alien::m4
   #  - Alien::libtool
   # all of which you will likely need.
   requires 'Alien::Autotools';
   plugin 'Build::Autoconf';
   build [
     'autoreconf -vfi',
     '%{configure}',
     '%{make}',
     '%{make} install',
   ];
 };

=head1 DESCRIPTION

This distribution provides autoconf so that it can be used by other Perl distributions that are on CPAN.  This is most commonly necessary when creating
other L<Alien>s that target a autoconf project that does not ship with a C<configure> script.  Ideally you should complain to the upstream developers,
but if you are not able to convince them then you have this option.  There are currently two such Aliens: L<Alien::libuv> and L<Alien::Hunspell>.

=head1 METHODS

=head2 bin_dir

 my @dirs = Alien::autoconf->bin_dir;

Returns a list of directories that need to be added to the C<PATH> in order to use C<autoconf>.

=head1 CAVEATS

This module is currently configured to I<always> do a share install.  This is because C<system> installs for this alien are not reliable.  Please see
this issue for details: L<https://github.com/plicease/Alien-autoconf/issues/2>.  The good news is that most of the time you shouldn't need this module
I<unless> you are building another alien from source.  If your system provides the package that is targeted by the upstream alien I recommend using
that.  If you are packaging system packages for your platform then I recommend making sure the upstream alien uses the system library so you won't need
to install this module.

=head1 SEE ALSO

=over 4

=item L<alienfile>

=item L<Alien::Build>

=item L<Alien::Build>

=item L<Alien::Autotools>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Mark Jensen (MAJENSEN)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
