package Alien::libtool24;

use strict;
use warnings;
use base qw( Alien::Base );

# ABSTRACT: (Deprecated) Built or find libtool 2.4.x
our $VERSION = '0.06'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::libtool24 - (Deprecated) Built or find libtool 2.4.x

=head1 VERSION

version 0.06

=head1 SYNOPSIS

From your L<Alien::Base> based Build.PL:

 Alien::Base::ModuleBuild->new(
   ...
   alien_bin_requires => {
     'Alien::libtool24' => 0,
   },
   alien_build_commands => [
     ...
     'libtool ...',
     ...
   ],
   ...
 );

From regular Perl:

 use Alien::libtool24;
 use env qw( @PATH );
 
 # puts libtook in the PATH if it isn't already there
 unshift @PATH, Alien::libtool24->bin_dir;
 system 'libtool ...';

=head1 DESCRIPTION

B<This module is deprecated>.  Use L<Alien::libtool> instead, it uses newer
better Alien tech.

This module will download and install libtool 2.4.x if it is not already
available on your system.  As with other L<Alien::Base> based distributions
it will install into a distribution based share directory which will not
override or otherwise malign your system software.

=head1 METHODS

=head2 bin_dir

 my $dir = Alien::libtool24->bin_dir;

Returns the directory which contains the C<libtool> and C<libtoolize> scripts.
Adding this to the C<PATH> usually means that you can run these commands without
fully qualifying them.  Returns empty list if libtool is I<already> in the C<PATH>.

=head2 dist_dir

 my $dir = Alien::libtool24->dist_dir;

Returns the base install directory of C<libtool> if it was installed by building
it from source, rather than using your system's version of libtool.

=head1 CAVEATS

This works(ish) on Windows, in that it installs, but C<libtool> installs itself
as a shell script which can be used with L<Alien::MSYS>, but is not very useful
by itself.  L<Alien::Hunspell> uses this module successfully, but somewhat
hackishly on Windows.

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<Alien::libtool>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
