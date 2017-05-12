# My::Builder
#  A local Module::Build subclass for installing libjio
#
# $Id$

package My::Builder;

use strict;
use warnings;

use base 'Module::Build';

use Cwd ();
use Carp ();

my $ORIG_DIR = Cwd::cwd();

# These are utility commands for getting into and out of our build directory
sub _chdir_or_die {
  use File::Spec ();
  my $dir = File::Spec->catfile(@_);
  chdir $dir or Carp::croak("Failed to chdir to $dir: $!");
}
sub _chdir_back {
  chdir $ORIG_DIR or Carp::croak("Failed to chdir to $ORIG_DIR: $!");
}

sub ACTION_code {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_code;
  if ($self->notes('build_libjio')) {
    # Get into our build directory; either libjio (all) or libjio/libjio
    # (bindings only)
    if ($self->notes('extra')) {
      _chdir_or_die('libjio');
    }
    else {
      _chdir_or_die('libjio', 'libjio');
    }

    # Run the make system to do the rest, but save the return code
    system($self->notes('make'));
    $rc = $? >> 8;

    # Make sure we change the directory back before adding notes, or they
    # won't persist (in _build state)
    _chdir_back();
    $self->notes(build_result => $rc);
  }

  return $rc;
}

sub ACTION_install {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_install;
  if ($self->notes('build_libjio')) {
    # Get into our build directory
    if ($self->notes('extra')) {
      _chdir_or_die('libjio');
    }
    else {
      _chdir_or_die('libjio', 'libjio');
    }

    # Run the make system to do the rest
    $rc = (system($self->notes('make'), 'install') == 0) ? 1 : 0;
    _chdir_back();
  }

  return $rc;
}

sub ACTION_clean {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_clean;
  _chdir_or_die('libjio');
  $rc = (system($self->notes('make'), 'clean') == 0) ? 1 : 0;
  _chdir_back();

  return $rc;
}

1;
