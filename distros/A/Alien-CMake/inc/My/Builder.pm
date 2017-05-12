package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use lib "inc";
use My::Utility qw(find_CMake_dir find_file sed_inplace);
use File::Spec::Functions qw(catdir catfile splitpath catpath rel2abs abs2rel);
use File::Path qw(make_path remove_tree);
use File::Copy qw(cp);
use File::Copy::Recursive qw(dircopy);
use File::Fetch;
use File::Find;
use Archive::Extract;
use Digest::SHA qw(sha1_hex);
use Config;

sub ACTION_build {
  my $self = shift;
  # as we want to wipe 'sharedir' during 'Build clean' we has
  # to recreate 'sharedir' at this point if it does not exist
  mkdir 'sharedir' unless(-d 'sharedir');
  $self->add_to_cleanup('sharedir');
  $self->SUPER::ACTION_build;
}

sub ACTION_code {
  my $self = shift;

  my $bp = $self->notes('build_params');
  die "###ERROR### Cannot continue build_params not defined" unless defined($bp);

  # check marker
  if (! $self->check_build_done_marker) {

    # important directories
    my $download     = 'download';
    my $patches      = 'patches';
    # we are deriving the subdir name from $bp->{title} as we want to
    # prevent troubles when user reinstalls the same version of
    # Alien::CMake with different build options
    my $share_subdir = $self->{properties}->{dist_version} . '_' . substr(sha1_hex($bp->{title}), 0, 8);
    my $build_out    = catfile('sharedir', $share_subdir);
    my $build_src    = 'build_src';
    $self->add_to_cleanup($build_src, $build_out);

    # save some data into future Alien::CMake::ConfigData
    $self->config_data('build_prefix', $build_out);
    $self->config_data('build_params', $bp);
    $self->config_data('build_cc', $Config{cc});
    $self->config_data('build_arch', $Config{archname});
    $self->config_data('build_os', $^O);
    $self->config_data('script', '');            # just to be sure
    $self->config_data('config', {});            # just to be sure

    if($bp->{buildtype} eq 'use_already_existing') {
      $self->config_data('script', $bp->{script});
      $self->set_config_data($bp->{prefix});
    }
    elsif($bp->{buildtype} eq 'use_prebuilt_binaries') {
      # all the following functions die on error, no need to test ret values
      $self->fetch_binaries($download);
      $self->clean_dir($build_out);
      $self->extract_binaries($download, $build_out, $build_src);
      $self->set_config_data($build_out);
    }
    elsif($bp->{buildtype} eq 'build_from_sources' ) {
      # all the following functions die on error, no need to test ret values
      $self->fetch_sources($download);
      $self->extract_sources($download, $patches, $build_src);
      $self->clean_dir($build_out);
      $self->build_binaries($build_out, $build_src);
      $self->set_config_data($build_out);
    }

    # mark sucessfully finished build
    $self->touch_build_done_marker;
  }

  $self->SUPER::ACTION_code;
}

sub fetch_file {
  my ($self, $url, $sha1sum, $download) = @_;
  die "###ERROR### _fetch_file undefined url\n" unless $url;
  die "###ERROR### _fetch_file undefined sha1sum\n" unless $sha1sum;
  my $ff = File::Fetch->new(uri => $url);
  my $fn = catfile($download, $ff->file);
  if (-e $fn) {
    print "Checking checksum for already existing '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    unlink $fn; #exists but wrong checksum
  }
  print "Fetching '$url'...\n";
  my $fullpath = $ff->fetch(to => $download);
  die "###ERROR### Unable to fetch '$url'" unless $fullpath;
  if (-e $fn) {
    print "Checking checksum for '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    die "###ERROR### Checksum failed '$fn'";
  }
  die "###ERROR### _fetch_file failed '$fn'";
}

sub fetch_binaries {
  my ($self, $download) = @_;
  my $bp = $self->notes('build_params');
  $self->fetch_file($bp->{url}, $bp->{sha1sum}, $download);
}

sub fetch_sources {
  my ($self, $download) = @_;
  my $bp = $self->notes('build_params');
  $self->fetch_file($bp->{url}, $bp->{sha1sum}, $download);
}

sub extract_binaries {
  my ($self, $download, $build_out, $build_src) = @_;

  # do extract binaries
  my $bp = $self->notes('build_params');
  my $archive = catfile($download, File::Fetch->new(uri => $bp->{url})->file);
  print "Extracting $archive...\n";
  my $ae = Archive::Extract->new( archive => $archive );
  die "###ERROR###: Cannot extract $archive ", $ae->error unless $ae->extract(to => $build_src);

  my ($prefix, $bindir, $sharedir) = find_CMake_dir(rel2abs($build_src));
  dircopy($bindir,   catdir($build_out, 'bin'));
  dircopy($sharedir, catdir($build_out, 'share'));
}

sub extract_sources {
  my ($self, $download, $patches, $build_src) = @_;
  my $bp = $self->notes('build_params');

  my $srcdir = catfile($build_src, $bp->{dirname});
  my $unpack = 'y';
  $unpack = $self->prompt("Dir '$srcdir' exists, wanna replace with clean sources?", "n") if (-d $srcdir);
  if (lc($unpack) eq 'y') {
    $self->clean_dir($srcdir);
    my $archive = catfile($download, File::Fetch->new(uri => $bp->{url})->file);
    print "Extracting sources...\n";
    my $ae = Archive::Extract->new( archive => $archive );
    die "###ERROR###: cannot extract $bp ", $ae->error unless $ae->extract(to => $build_src);
    foreach my $i (@{$bp->{patches}}) {
      chdir $srcdir;
      print "Applying patch '$i'\n";
      my $cmd = $self->patch_command($srcdir, catfile($patches, $i));
      if ($cmd) {
        print "(cmd: $cmd)\n";
        $self->do_system($cmd) or die "###ERROR### [$?] during patch ... ";
      }
      chdir $self->base_dir();
    }
  }
  return 1;
}

sub set_config_data {
  my( $self, $build_out ) = @_;

  # try to find CMake root dir
  my ($prefix, $bindir, $sharedir) = find_CMake_dir(rel2abs($build_out));
  die "###ERROR### Cannot find CMake directory in 'sharedir'" unless $prefix;
  if($self->config_data('build_params')->{buildtype} eq 'use_already_existing') {
    $self->config_data('share_subdir', rel2abs($prefix));
  }
  else {
    $self->config_data('share_subdir', abs2rel($prefix, rel2abs('sharedir')));
  }

  # set defaults
  my $cfg = {
    # defaults (used on MS Windows build)
    version => $self->notes('build_cmake_version'),
    prefix  => '@PrEfIx@',
    bin     => $self->get_path('@PrEfIx@/bin'),
    share   => $self->get_path('@PrEfIx@/share'),
  };

  if($self->config_data('build_params')->{version}) {
    $cfg->{version} = $self->config_data('build_params')->{version};
  }

  # write config
  $self->config_data('config', $cfg);
}

sub build_binaries {
  # this needs to be overriden in My::Builder::<platform>
  my ($self, $build_out, $build_src) = @_;
  die "###ERROR### My::Builder cannot build CMake from sources, use rather My::Builder::<platform>";
}

sub get_path {
  # this needs to be overriden in My::Builder::<platform>
  my ( $self, $path ) = @_;
  return $path;
}

sub clean_dir {
  my( $self, $dir ) = @_;
  if (-d $dir) {
    remove_tree($dir);
    make_path($dir);
  }
}

sub check_build_done_marker {
  my $self = shift;
  return (-e 'build_done');
}

sub touch_build_done_marker {
  my $self = shift;
  require ExtUtils::Command;
  local @ARGV = ('build_done');
  ExtUtils::Command::touch();
  $self->add_to_cleanup('build_done');
}

sub clean_build_done_marker {
  my $self = shift;
  unlink 'build_done' if (-e 'build_done');
}

sub check_sha1sum {
  my( $self, $file, $sha1sum ) = @_;
  my $sha1 = Digest::SHA->new;
  my $fh;
  open($fh, $file) or die "###ERROR## Cannot check checksum for '$file'\n";
  binmode($fh);
  $sha1->addfile($fh);
  close($fh);
  return ($sha1->hexdigest eq $sha1sum) ? 1 : 0
}

sub patch_command {
  my( $self, $base_dir, $patch_file ) = @_;

  print("patch_command: $base_dir, $patch_file\n");

  my $devnull = File::Spec->devnull();
  my $patch_rv = system("patch -v > $devnull 2>&1");
  if ($patch_rv == 0) {
    $patch_file = File::Spec->abs2rel( $patch_file, $base_dir );
    # the patches are expected with UNIX newlines
    # the following command works on both UNIX+Windows
    return qq("$^X" -pe0 -- "$patch_file" | patch -p1); # paths of files to patch should be relative to build_src
  }
  warn "###WARN### patch not available";
  return '';
}

1;
