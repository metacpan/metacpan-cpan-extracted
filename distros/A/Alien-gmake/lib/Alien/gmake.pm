package Alien::gmake;

use strict;
use warnings;
use base qw( Alien::Base );
use Env qw( @PATH );
use File::Spec;

# ABSTRACT: Find or build GNU Make
our $VERSION = '0.24'; # VERSION


sub exe
{
  my($class) = @_;
  $class->runtime_prop->{command};
}


sub alien_helper
{
  return {
    gmake => sub {
      # return the executable name for GNU make,
      # usually either make or gmake depending on
      # the platform and environment
      Alien::gmake->exe;
    },
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::gmake - Find or build GNU Make

=head1 VERSION

version 0.24

=head1 SYNOPSIS

From your Perl script:

 use Alien::gmake ();
 use Env qw( @PATH );
 
 unshift @ENV, Alien::gmake->bin_dir;
 my $gmake = Alien::gmake->exe;
 system $gmake, 'all';
 system $gmake, 'install';

Or L<alienfile>:

 use alienfile;

 share {
   ...
   requires 'Alien::gmake' => '0.09';
   build [ '%{gmake}', '%{gmake} install' ];
 };

Or Build.PL with L<Alien::Build::ModuleBuild>:

 use Alien::Base::ModuleBuild;
 Alien::Base::ModuleBuild->new(
   ...
   alien_bin_requires => {
     'Alien::gmake' => '0.09',
   },
   alien_build_commands => {
     "%{gmake}",
   },
   alien_install_commands => {
     "%{gmake} install",
   },
   ...
 )->create_build_script;

=head1 DESCRIPTION

Some packages insist on using GNU Make.  Some platforms refuse to come with GNU Make.
Sometimes you just want to be able to build packages that require GNU Make without
having to check the version of Make each time.  This module is for that.  It uses the
system provided GNU Make if it can be found.  Otherwise it will download and install
it into a directory not normally in your path so that it can be used when you
C<use Alien::gmake>.  This way you can use it when you need it, but not muck up your
environment when you don't.

If possible, it is better to fix the package so that it doesn't require GNU make
extensions, making it more portable.  Unfortunately, sometimes this isn't an option.

This class is a subclass of L<Alien::Base>, so all of the methods documented there
should work with this class.

=head1 METHODS

=head2 exe

 my $gmake = Alien::gmake->exe;

Return the "name" of GNU make.  Normally this is either C<make> or C<gmake>.  On
Windows (and possibly other platforms), it I<may> be the full path to the GNU make
executable.

To be usable on all platforms you will have to first add directories returned
from C<bin_dir> to your C<PATH>, for example:

 use Alien::gmake ();
 use Env qw( @PATH );
 
 unshift @PATH, Alien::gmake->bin_dir;
 system "@{[ Alien::gmake->exe ]}";
 system "@{[ Alien::gmake->exe ]} install";

=head2 bin_dir

 my @dir = Alien::gmake->bin_dir;

Returns the list of directories that should be added to C<PATH> in order for the
shell to find GNU make.  If GNU make is already in the C<PATH>, this will return
the empty list.  For example:

 use Alien::gmake ();
 use Env qw( @PATH );
 
 unshift @PATH, Alien::gmake->bin_dir;

=head1 HELPERS

=head2 gmake

 %{gmake}

Returns either make or gmake depending on how GNU make is called on your
system.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
