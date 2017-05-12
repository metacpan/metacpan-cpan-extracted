package Alien::ROOT;
use 5.008;
use strict;
use warnings;
use Carp ();

=head1 NAME

Alien::ROOT - Utility package to install and locate CERN's ROOT library

=cut

our $VERSION = '5.34.36.1';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use Alien::ROOT;

  my $aroot = Alien::ROOT->new;

=head1 DESCRIPTION

Installs or detects CERN's ROOT library.

This version of C<Alien::ROOT> will download and install
C<ROOT v5.30.0> B<if necessary>. If an existing (and
compatible) installation of ROOT was detected, the
module will not download/compile/install a new version
of ROOT.

=head1 METHODS

=head2 Alien::ROOT->new

Creates a new C<Alien::ROOT> object, which essentially just has a few
convenience methods providing useful information like the path
to the ROOT installation (C<ROOTSYS> environment variable)
and the path to the F<root-config> utility.

=cut

sub new {
  my $class = shift;

  Carp::croak('You must call this as a class method') if ref($class);

  my $self = {
    installed    => 0,
    root_config  => undef,
    version      => undef,
    cflags       => undef,
    ldflags      => undef,
    features     => undef,
    libdir       => undef,
    bindir       => undef,
    incdir       => undef,
    etcdir       => undef,
    archdir      => undef, # internal
    private_root => undef,
  };

  bless($self, $class);

  $self->_load_modules();
  $self->_configure();

  return $self;
}

sub _load_modules {
  require File::Spec;
  require Config;
  require ExtUtils::MakeMaker;
  require IPC::Open3;
}

=head2 $aroot->installed

Determine if a valid installation of ROOT has been detected in the system.
This method will return a true value if it is, or undef otherwise.

Example code:

  print "okay\n" if $aroot->installed;

=cut

sub installed {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->{installed};
}

=head2 $aroot->run

Sets up the ROOT environment (see C<setup_environment>) and then invokes
the ROOT shell by simply calling C<root>.

=cut

sub run {
  my $self = shift;
  $self->setup_environment;
  system {'root'} 'root', @_;
}

=head2 $aroot->setup_environment

Sets up the C<PATH> and C<LD_LIBRARY_PATH> environment
variables to point at the correct paths for ROOT.

Throws an exception if ROOT was not found, so wrap this in an C<eval>
or check C<$aroot-E<gt>installed> before using this.

=cut

sub setup_environment {
  my $self = shift;
  Carp::croak('You must call this method as an object') unless ref($self);
  die "ROOT was not found. Make the 'root-config' utility accessible or set the ROOTSYS variable"
    if not $self->installed;
 
  my $bindir = $self->bindir;
  my $libdir = $self->libdir;

  if ($^O =~ /win32/i) {
    $ENV{PATH} = $self->_add_to_path($ENV{PATH}, $bindir, $libdir);
  }
  else {
    $ENV{PATH} = $self->_add_to_path($ENV{PATH}, $bindir);
  }
  $ENV{LD_LIBRARY_PATH} = $self->_add_to_path($ENV{LD_LIBRARY_PATH}, $libdir);
  #require DynaLoader;
  #unshift @DynaLoader::dl_library_path, $libdir; # doesn't help
}

sub _add_to_path {
  my $self = shift;
  my $string = shift;
  my @paths = @_;

  my $sep = $Config::Config{path_sep};
  my @split = (defined($string) ? split /\Q$sep\E/, $string : ());

  my %exists;
  $exists{$_}++ for @split;

  foreach my $path (@paths) {
    unshift @split, $path if not exists $exists{$path};
  }
  return join $sep, @split;
}


=head2 $aroot->version

Determine the installed version of ROOT, as a string.

Example code:

  my $version = $aroot->version;

=cut

sub version {
  my ($self) = @_;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('version', '--version');
}


=head2 $aroot->ldflags

=head2 $aroot->linker_flags

This returns the flags required to link C code with the local installation of
ROOT.

Example code:

  my $ldflags = $aroot->ldflags;

=cut

sub ldflags {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('ldflags', qw(--ldflags --glibs --auxlibs));
}

# Glob to create an alias to ldflags
*linker_flags = *ldflags;


=head2 $aroot->cflags

=head2 $aroot->compiler_flags

This method returns the compiler option flags to compile C++ code which uses
the ROOT library (typically in the CFLAGS variable).

Example code:

  my $cflags = $aroot->cflags;

=cut

sub cflags {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('cflags', qw(--cflags --auxcflags));
}
*compiler_flags = *cflags;


=head2 $aroot->features

This method returns a string of ROOT features that were enabled when ROOT
was compiled.

Example code:

  my $features = $aroot->features;
  if ($features !~ /\bexplicitlink\b/) {
    warn "ROOT was built without the --explicitlink option";
  }

=cut

sub features {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('features', qw(--features));
}


=head2 $aroot->bindir

This method returns the path to the executable directory of ROOT.

Example code:

  my $dir = $aroot->bindir;
  system(File::Spec->catfile($dir, 'root'));

=cut

sub bindir {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('bindir', qw(--bindir));
}


=head2 $aroot->libdir

This method returns the path to the library (F<lib/>) directory of ROOT.

Example code:

  my $dir = $aroot->libdir;

=cut

sub libdir {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('libdir', qw(--libdir));
}


=head2 $aroot->incdir

This method returns the path to the include directory of ROOT.

Example code:

  my $dir = $aroot->incdir;

=cut

sub incdir {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('incdir', qw(--incdir));
}


=head2 $aroot->etcdir

This method returns the path to the 'etc' directory of ROOT.

Example code:

  my $dir = $aroot->etcdir;

=cut

sub etcdir {
  my $self = shift;

  Carp::croak('You must call this method as an object') unless ref($self);

  return $self->_config_get_one_line_param('etcdir', qw(--etcdir));
}


=head2 $aroot->private_root

This method returns true if the copy of ROOT that is being used
was installed by C<Alien::ROOT> and is considered private.

Example code:

  my $is_private = $aroot->private_root;

=cut

sub private_root {
  my $self = shift;
  return 1 if $self->{private_root};
  return 0;
}


########################################
# Private methods to find & fill out information

sub _archdir {
  my $self = shift;
  
  if (not defined $self->{archdir}) {
    my $path = File::Spec->catdir(
      'auto', split(/::/, __PACKAGE__),
    );

    # Find the full dir withing @INC
    foreach my $inc ( @INC ) {
      next unless defined $inc and not ref $inc;
      my $dir = File::Spec->catdir( $inc, $path );
      next unless -d $dir;
      unless ( -r $dir ) {
        croak("Found directory '$dir', but no read permissions");
      }
      $self->{archdir} = $dir;
      last;
    }
  }

  return $self->{archdir};
}


sub _configure {
  my $self = shift;

  my $root_config;
  # try to get it from our arch dir
  my $archdir = $self->_archdir();
  if (defined $archdir and -d $archdir) {
    $root_config = File::Spec->catdir($archdir, 'root', 'bin', 'root-config');
    $root_config = undef if not -x $root_config;
  }

  if (defined $root_config) {
    $self->{private_root} = 1;
  }

  # try ROOTSYS 
  if (not defined $root_config and defined $ENV{ROOTSYS}) {
    $root_config = File::Spec->catfile($ENV{ROOTSYS}, 'bin', 'root-config');
    $root_config = undef if not -x $root_config;
  }

  # try to access root-config
  if (not defined $root_config) {
    $root_config = $self->_can_run('root-config');
  }

  if (not defined $root_config) {
    return();
  }
  $self->{root_config} = $root_config;
  $self->{installed} = 1;
}

# From Module::Install::Can
# check if we can run some command
sub _can_run {
  my ($self, $cmd) = @_;

  my $_cmd = $cmd;
  return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    my $abs = File::Spec->catfile($dir, $_[1]);
    return $abs if (-x $abs or $abs = MM->maybe_command($abs));
  }

  return;
}

sub _config_run_stdio {
  my $self = shift;
  my @args = @_;
  return() if not defined $self->{root_config};
  my $read;
  my $pid = IPC::Open3::open3(undef, $read, undef, $self->{root_config}, @args);
  waitpid($pid, 0);
  #if (($? >> 8) == 0)
  return join '', <$read>;
}

sub _config_get_one_line_param {
  my $self = shift;
  my $param = shift;
  my @opts = @_;

  return() if not $self->installed;
  return $self->{$param} if defined $self->{$param};

  my $out = $self->_config_run_stdio(@opts) || '';
  $self->{$param} = (split /\n/, $out, 2)[0];
  return $self->{$param};
}

1;

__END__

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

This package is based upon Jonathan Yu's L<Alien::libjio>
and Mattia Barbon's L<Alien::wxWidgets>.
They kindly allowed me to use their work as a starting point.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::ROOT

You can also look for information at:

=over

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-ROOT>

=item * CPAN Request Tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-ROOT>

=item * CPAN Testers Platform Compatibility Matrix

L<http://cpantesters.org/show/Alien-ROOT.html>

=back

=head1 REPOSITORY

You can access the most recent development version of this module at:

L<git://github.com/tsee/ROOT.git>

=head1 SEE ALSO

L<SOOT>, the Perl-ROOT wrapper.

L<SOOT::App>, the SOOT shell.

L<Alien>, the Alien manifesto.

=head1 LICENSE

This module is licensed under the GNU General Public License 2.0
or at your discretion, any newer version of the GPL. You can
find a copy of the license in the F<LICENSE> file of this package
or at L<http://www.opensource.org/licenses/gpl-2.0.php>

=cut

