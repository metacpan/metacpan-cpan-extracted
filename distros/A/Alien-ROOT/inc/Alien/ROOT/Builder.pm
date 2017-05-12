package Alien::ROOT::Builder;

use strict;
use warnings;

use base 'Module::Build';
use Alien::ROOT::Builder::Utility qw(aroot_touch aroot_install_arch_auto_dir aroot_install_arch_auto_file);

use Cwd ();
use Carp ();

my $ORIG_DIR = Cwd::cwd();

# use the system version of a module if present; in theory this could lead to
# compatibility problems (if the latest version of one of the dependencies,
# installed in @INC is incompatible with the bundled version of a module)
sub _load_bundled_modules {
  # the load order is important: all dependencies must be loaded
  # before trying to load a module
  require inc::latest;

  inc::latest->import( $_ )
    foreach qw(version
               Locale::Maketext::Simple
               Params::Check
               Module::Load
               Module::Load::Conditional
               IPC::Cmd
               Archive::Extract
               File::Fetch);
}

sub ACTION_build {
  my $self = shift;
  # try to make "perl Makefile.PL && make test" work
  # but avoid doubly building ROOT when doing
  # "perl Makefile.PL && make && make test"
  unlink 'configured' if -f 'configured';
  $self->SUPER::ACTION_build;
}


sub ACTION_code {
  my $self = shift;

  $self->SUPER::ACTION_code;
  return if not $self->notes( 'build_ROOT' );

  # see comment in ACTION_build for why 'configured' is used
  return if -f 'configured';
  $self->depends_on( 'build_ROOT' );
  aroot_touch( 'configured' );
  $self->add_to_cleanup( 'configured' );
}


sub ACTION_build_ROOT {
  my $self = shift;
  return if not $self->notes( 'build_ROOT' );
  $self->fetch_ROOT;
  $self->extract_ROOT;
  $self->build_ROOT;
}


sub ACTION_install {
  my $self = shift;
  $self->depends_on('build');
  $self->depends_on('code');
  if ($self->notes('build_ROOT')) {
    $self->depends_on('build_ROOT');
    $self->install_ROOT;
  }

  require ExtUtils::Install;
  my %install_map = %{$self->install_map};
  if ($self->notes('build_ROOT')
      and exists $install_map{'read'}
      and defined $install_map{'read'}) {
    # so that EU::Install::install picks up the files installed by ROOT
    $install_map{'read'} = $self->get_root_packlist_file;
  }
  
  ExtUtils::Install::install(\%install_map, $self->verbose, 0, $self->{args}{uninst}||0);
}

sub ACTION_clean {
  my ($self) = @_;

  my $rc = $self->SUPER::ACTION_clean;
  if ($self->notes('build_ROOT')) {
    chdir($self->notes('build_data')->{directory});
    $rc = (system($self->notes('make'), 'clean') == 0) ? 1 : 0;
    chdir($ORIG_DIR);
  }

  return $rc;
}


sub fetch_ROOT {
  my $self = shift;

  return if defined $self->notes('build_data')->{archive}
         and -f $self->notes('build_data')->{archive};

  $self->_load_bundled_modules;
  print "Fetching ROOT...\n";
  print "fetching from: ", $self->notes('build_data')->{url}, "\n";

  my $ff = File::Fetch->new( uri => $self->notes('build_data')->{url} );
  my $path = $ff->fetch(to => File::Spec->curdir);
  die 'Unable to fetch archive' unless $path;
  $self->notes('build_data')->{archive} = $path;
}

sub extract_ROOT {
  my $self = shift;

  return if -d $self->notes( 'build_data' )->{directory};
  my $archive = $self->notes( 'build_data' )->{archive};
  if (not $archive or not -e $archive) {
    $self->fetch_ROOT;
    $archive = $self->notes( 'build_data' )->{archive};
  }

  print "Extracting ROOT...\n";

  $self->_load_bundled_modules;
  $Archive::Extract::PREFER_BIN = 1;
  my $ae = Archive::Extract->new( archive => $archive );

  die 'Error: ', $ae->error unless $ae->extract;

  #$self->patch_ROOT;
}

sub build_ROOT {
  my $self = shift;

  my $prefix = $self->aroot_install_arch_auto_dir('root');
  my @cmd = (
    qw(sh configure),
    '--prefix='.$prefix,
    '--etcdir='.File::Spec->catfile($prefix, 'etc'),
    '--enable-explicitlink', # needed for SOOT
  );

  my $dir = $self->notes('build_data')->{directory};
  chdir $dir;
  $ENV{PWD} = Cwd::cwd();

  # do not reconfigure unless necessary
  if (not -f 'config.status') {
    system(@cmd) and die "Build failed while running '@cmd': $?";
  }
  my $make = $self->notes('make');
  
  my $parallel_procs = $self->notes('build_data')->{parallel_processes};
  if (defined $parallel_procs and $parallel_procs > 1) {
    system($make, "-j$parallel_procs")
      and die "Build failed while running '$make -j$parallel_procs': $?";
  }
  else {
    system($make) and die "Build failed while running '$make': $?";
  }
  chdir $ORIG_DIR;
}


sub install_ROOT {
  my $self = shift;

  require File::Path;
  File::Path::mkpath($self->aroot_install_arch_auto_dir('root'));

  my $dir = $self->notes('build_data')->{directory};
  chdir $dir;

  my $make = $self->notes('make');
  system($make, 'install') and die "Build failed while running '$make install': $?";
  $self->write_packlist_ROOT;

  chdir $ORIG_DIR;
}


sub write_packlist_ROOT {
  my $self = shift;
  my $root_dir = $self->aroot_install_arch_auto_dir('root');
  my $root_plist = $self->get_root_packlist_file;

  open my $fh, '>', $root_plist
    or die "Could not open file '$root_plist' for writing the ROOT packlist: $!";

  # merge the previous source for .packlist
  my $from_to = $self->install_map;
  if (exists $from_to->{'read'}
      and defined $from_to->{'read'})
  {
    my $ih;
    if (open $ih, '<', $from_to->{'read'}) {
      print $fh $_ for <$ih>;
    }
  }
  require File::Find;
  File::Find::find(
    sub {
      print $fh $File::Find::name, "\n";
    },
    $root_dir
  );
  close $fh;
}


sub get_root_packlist_file {
  my $self = shift;
  my $root_dir = $self->aroot_install_arch_auto_dir('root');
  my $root_plist = File::Spec->catdir($root_dir, '.merged_root_packlist');
  return $root_plist;
}

1;
