package Alien::patch;

use strict;
use warnings;
use base qw( Alien::Base );
use Env qw( @PATH );

# ABSTRACT: Find or build patch
our $VERSION = '0.11'; # VERSION


my $in_path;

sub import
{
  require Carp;
  Carp::carp "Alien::patch with implicit path modification is deprecated ( see https://metacpan.org/pod/Alien::patch#CAVEATS )";
  return if __PACKAGE__->install_type('system');
  return if $in_path;
  my $dir = File::Spec->catdir(__PACKAGE__->dist_dir, 'bin');
  Carp::carp "adding $dir to PATH";
  unshift @PATH, $dir;
  # only do it once.
  $in_path = 1;
}

sub exe
{
  $^O eq 'MSWin32' ? 'patch --binary' : 'patch';
}

sub _vendor
{
  shift->runtime_prop->{my_vendor};
}


sub alien_helper
{
  return {
    patch => sub {
      Alien::patch->exe;
    },
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::patch - Find or build patch

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use Alien::patch ();
 use Env qw( @PATH );
 
 unshift @ENV, Alien::patch->bin_dir;
 my $patch = Alien::patch->exe;
 system "$patch -p1 < foo.patch";

Or with L<Alien::Build::ModuleBuild>:

 use Alien::Base::ModuleBuild;
 Alien::Base::ModuleBuild->new(
   ...
   alien_bin_requires => {
     'Alien::patch' => '0.08',
   },
   alien_build_commands => {
     '%{patch} -p1 < foo.patch',
   },
   ...
 )->create_build_script;

=head1 DESCRIPTION

Many environments provide the patch command, but a few do not.
Using this module in your C<Build.PL> (or elsewhere) you can
make sure that patch will be available.  If the system provides
it, then great, this module is a no-op.  If it does not, then
it will download and install it into a private location so that
it can be added to the C<PATH> when this module is used.

This class is a subclass of L<Alien::Base>, so all of the methods documented there
should work with this class.

=head1 METHODS

=head2 exe

 my $exe = Alien::patch->exe;

Returns the command to run patch on your system.  For now it simply
adds the C<--binary> option on Windows (C<MSWin32> but not C<cygwin>)
which is usually what you want.

=head1 HELPERS

=head2 patch

 %{patch}

When used with L<Alien::Base::ModuleBuild> in a C<alien_build_commands> or C<alien_install_commands>,
this helper will be replaced by either C<patch> (Unix and cygwin) or C<patch --binary> (MSWin32).

=head1 CAVEATS

This version of L<Alien::patch> adds patch to your path, if it isn't
already there when you use it, like this:

 use Alien::patch;  # deprecated, issues a warning

This was a design mistake, and now B<deprecated>.  When L<Alien::patch> was
originally written, it was one of the first Alien tool style modules on
CPAN.  As such, the author and the L<Alien::Base> team hadn't yet come up
with the best practices for this sort of module.  The author, and the
L<Alien::Base> team feel that for consistency and for readability it is
better use L<Alien::patch> without the automatic import:

 use Alien::patch ();

and explicitly modify the C<PATH> yourself (examples are above in the
synopsis).  The old style will issue a warning.  The old behavior will be
removed, but not before 31 January 2018.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
