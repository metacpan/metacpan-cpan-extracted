package Alien::Meson;
$Alien::Meson::VERSION = '0.06';
use strict;
use warnings;
use base qw( Alien::Base );
use 5.008004;

use Path::Tiny;
use Alien::Build::Util qw( _destdir_prefix );

=head1 NAME

Alien::Meson - Find or build meson build tool

=head1 SYNOPSIS

Command line tool:

 use Alien::Meson;
 use Env qw( @PATH );

 unshift @PATH, Alien::Meson->bin_dir;
 system "@{[ Alien::Meson->exe ]}";

Use in L<alienfile>:

  share {
    requires 'Alien::Meson';
    requires 'Alien::Ninja';
    # ...
    my $build_dir = '_build';
    build [
      sub {
        my $build = shift;
        Alien::Build::CommandSequence->new([
          Alien::Meson->exe, 'setup',
            '--prefix=%{.install.prefix}',
            $build_dir,
        ])->execute($build);
      },
      [ '%{ninja}', qw(-C), $build_dir, "test" ],
      [ '%{ninja}', qw(-C), $build_dir, 'install' ],
    ];
  }

=head1 DESCRIPTION

This distribution provides meson so that it can be used by other
Perl distributions that are on CPAN.  It does this by first trying to
detect an existing install of meson on your system.  If found it
will use that.  If it cannot be found, the source code will be downloaded
from the internet and it will be installed in a private share location
for the use of other modules.

=cut

=head1 METHODS

=head2 exe

 Alien::Meson->exe

Returns the command name for running meson.

=cut

sub exe {
  my($class) = @_;
  if( $class->install_type('share')
    && $class->runtime_prop->{'python-source'}
    ) {
    return (
      $class->runtime_prop->{python_bin},
      Path::Tiny->new( $class->bin_dir, $class->runtime_prop->{command} ) );
  }
  $class->runtime_prop->{command};
}

sub bin_dir {
  my ($class) = @_;
  if($class->install_type('share')) {
    my $dir = Path::Tiny->new($class->dist_dir);
    my $bin_dir = $dir->child('bin');
    if( -d $bin_dir ) {
      return ("$bin_dir");
    }
    return -d $dir ? ("$dir") : ();
  } else {
    return $class->SUPER::bin_dir(@_);
  }
}

=head2 _apply_destdir_prefix_hack

  use alienfile;

  eval {
    require Alien::Meson;
    Alien::Meson->_apply_destdir_prefix_hack;
  };

  share { ... }

Applies a hack to fix how the C<DESTDIR> and prefix are joined to follow the
approach that Meson takes. See issue at L<https://github.com/PerlAlien/Alien-Build/issues/407>
for more information.

B<WARNING>: This is a hack. It is not expected to work long-term and if a
better solution is possible, it will be deprecated then removed.

=cut

sub _apply_destdir_prefix_hack {
  my ($class) = @_;
  no warnings "redefine";
  # Work around for Meson's `destdir_join` which drops the first part of
  # the path when joining (this is the drive letter).
  # See <https://github.com/mesonbuild/meson/blob/1.2.3/mesonbuild/scripts/__init__.py>.
  *Alien::Build::Util::_destdir_prefix = \&_meson_destdir_prefix;
}

sub _meson_destdir_prefix {
  my($destdir, $prefix) = @_;
  $prefix =~ s{^/?([a-z]):}{}i if $^O eq 'MSWin32';
  path($destdir)->child($prefix)->stringify;
}

=head1 HELPERS

=head2 meson

 %{meson}

B<WARNING>: This interpolation is deprecated. This will be removed in a future
version as some share installs of Meson are not callable as a single executable
(they need to be prefixed with the Python interpreter). Instead use
C<< Alien::Meson->exe >> directly.

Returns 'meson', 'meson.py', or appropriate command for
platform.

=cut

sub alien_helper {
  return +{
    meson => sub {
      warn "Interpolation of %{meson} is deprecated. See POD for Alien::Meson.";
      join " ", Alien::Meson->exe;
    },
  };
}

=head1 SEE ALSO

=over 4

=item L<Meson|https://mesonbuild.com/>

The Meson Build system home page.

=item L<Alien>

Documentation on the Alien concept itself.

=item L<Alien::Base>

The base class for this Alien.

=item L<Alien::Build::Manual::AlienUser>

Detailed manual for users of Alien classes.

=back

=cut

1;
