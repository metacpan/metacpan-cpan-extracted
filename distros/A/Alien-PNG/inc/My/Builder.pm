package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use lib "inc";
use My::Utility qw(find_PNG_dir find_file sed_inplace);
use File::Spec::Functions qw(catdir catfile splitpath catpath rel2abs abs2rel);
use File::Path qw(make_path remove_tree);
use File::Copy qw(cp);
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
    # Alien::PNG with different build options
    my $share_subdir = $self->{properties}->{dist_version} . '_' . substr(sha1_hex($bp->{title}), 0, 8);
    my $build_out    = catfile('sharedir', $share_subdir);
    my $build_src    = 'build_src';
    $self->add_to_cleanup($build_src, $build_out);

    # save some data into future Alien::PNG::ConfigData
    $self->config_data('build_prefix', $build_out);
    $self->config_data('build_params', $bp);
    $self->config_data('build_cc', $Config{cc});
    $self->config_data('build_arch', $Config{archname});
    $self->config_data('build_os', $^O);
    $self->config_data('script', '');            # just to be sure
    $self->config_data('config', {});            # just to be sure
    $self->config_data('additional_cflags', ''); # just to be sure
    $self->config_data('additional_libs', '');   # just to be sure

    if($bp->{buildtype} eq 'use_config_script') {
      $self->config_data('script', $bp->{script});
      # include path trick - adding couple of addititonal locations
      $self->config_data('additional_cflags', '-I' . get_path($bp->{prefix} . '/include/smpeg') . ' '.
                                              '-I' . get_path($bp->{prefix} . '/include') . ' ' .
                                              $self->get_additional_cflags);
      $self->config_data('additional_libs', $self->get_additional_libs);
    }
    elsif($bp->{buildtype} eq 'use_prebuilt_binaries') {
      # all the following functions die on error, no need to test ret values
      $self->fetch_binaries($download);
      $self->clean_dir($build_out);
      $self->extract_binaries($download, $build_out);
      $self->set_config_data($build_out);
    }
    elsif($bp->{buildtype} eq 'build_from_sources' ) {
      # all the following functions die on error, no need to test ret values
      $self->check_prereqs();
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

sub check_prereqs {
  my ($self) = @_;
  my $bp = $self->notes('build_params');
  #print "-l$_\n" foreach (@{$_->{libs}) foreach (@{$bp->{prereqs}});
}

sub fetch_sources {
  my ($self, $download) = @_;
  my $bp = $self->notes('build_params');
  $self->fetch_file($_->{url}, $_->{sha1sum}, $download) foreach (@{$bp->{members}});
}

sub extract_binaries {
  my ($self, $download, $build_out) = @_;

  # do extract binaries
  my $bp = $self->notes('build_params');
  my $archive = catfile($download, File::Fetch->new(uri => $bp->{url})->file);
  print "Extracting $archive...\n";
  my $ae = Archive::Extract->new( archive => $archive );
  die "###ERROR###: Cannot extract $archive ", $ae->error unless $ae->extract(to => $build_out);

  # fix hardcoded prefix path in bin/libpng-config
  my ($version, $prefix, $incdir, $libdir) = find_PNG_dir(rel2abs($build_out));
  sed_inplace("$prefix/bin/libpng-config", 's/^prefix=.*/prefix=\''.quotemeta($prefix).'\'/');
}

sub extract_sources {
  my ($self, $download, $patches, $build_src) = @_;
  my $bp = $self->notes('build_params');
  foreach my $pack (@{$bp->{members}}) {
    my $srcdir = catfile($build_src, $pack->{dirname});
    my $unpack = 'y';
    $unpack = $self->prompt("Dir '$srcdir' exists, wanna replace with clean sources?", "n") if (-d $srcdir);
    if (lc($unpack) eq 'y') {
      my $archive = catfile($download, File::Fetch->new(uri => $pack->{url})->file);
      print "Extracting $pack->{pack}...\n";
      my $ae = Archive::Extract->new( archive => $archive );
      die "###ERROR###: cannot extract $pack ", $ae->error unless $ae->extract(to => $build_src);
      foreach my $i (@{$pack->{patches}}) {
        chdir $srcdir;
        print "Checking affected files for patch '$i'\n";
        foreach my $k ($self->patch_get_affected_files($srcdir, catfile($patches, $i))) {
		  # doing the same like -p1 for 'patch'
		  $k =~ s/^[^\/]*\/(.*)$/$1/;
          if(-e $k) {
			print "Preparing file '$k'\n";
            sed_inplace( $k, 's/\r\n/\n/gm' ); # converting to UNIX newlines
          }
		  else {
		    print "###WARN### file '$k' for patch '$i' not found\n";
		  }
        }
        print "Applying patch '$i'\n";
        my $cmd = $self->patch_command($srcdir, catfile($patches, $i));
        if ($cmd) {
          print "(cmd: $cmd)\n";
          $self->do_system($cmd) or die "###ERROR### [$?] during patch ... ";
        }
        chdir $self->base_dir();
      }
    }
  }
  return 1;
}

sub set_config_data {
  my( $self, $build_out ) = @_;

  # try to find PNG root dir
  my ($version, $prefix, $incdir, $libdir) = find_PNG_dir(rel2abs($build_out));
  die "###ERROR### Cannot find PNG directory in 'sharedir'" unless $version;
  $self->config_data('share_subdir', abs2rel($prefix, rel2abs('sharedir')));

  # set defaults
  my $cfg = {
    # defaults
    version     => $version,
    prefix      => '@PrEfIx@',
    libs        => '-L' . $self->get_path('@PrEfIx@/lib') . ' -lpng',
    cflags      => '-I' . $self->get_path('@PrEfIx@/include') . ' -D_GNU_SOURCE=1', # -Dmain=SDL_main
    shared_libs => [ ],
  };

  # overwrite values available via libpng-config
  my $bp = $self->config_data('build_prefix') || $prefix;
  my $devnull = File::Spec->devnull();
  my $script = rel2abs("$prefix/bin/libpng-config");
  foreach my $p (qw(version prefix L_opts libs I_opts cflags)) {
    my $o=`$script --$p 2>$devnull`;
    if ($o) {
      $o =~ s/[\r\n]*$//;
      $o =~ s/\Q$prefix\E/\@PrEfIx\@/g;
      $cfg->{$p} = $o;
      
      if($p eq 'libs') {
        $cfg->{$p} = $cfg->{L_opts} . ' ' . $cfg->{$p};
        delete $cfg->{L_opts};
      }
      
      if($p eq 'cflags') {
        $cfg->{$p} = $cfg->{I_opts} . ' ' . $cfg->{$p};
        delete $cfg->{I_opts};
      }
    }
  }

  # find ld_shared_libs and create symlinks if necessary
  my $symlink_exists = eval { symlink("",""); 1 };
  if($symlink_exists)
  {
    my @shlibs_ = find_file($build_out, qr/\.\Q$Config{dlext}\E[\d\.]+$/);
    foreach my $full (@shlibs_){
      $full =~ qr/(.*\.\Q$Config{dlext}\E)[\d\.]+$/;
      my ($v, $d, $f) = splitpath($full);
      symlink("./$f", $1) unless -e $1;
    }
  }

  # find and set ld_shared_libs
  my @shlibs = find_file($build_out, qr/\.\Q$Config{dlext}\E$/);
  my $p = rel2abs($prefix);
  $_ =~ s/^\Q$prefix\E/\@PrEfIx\@/ foreach (@shlibs);
  $cfg->{ld_shared_libs} = [ @shlibs ];

  # set ld_paths and ld_shlib_map
  my %tmp = ();
  my %shlib_map = ();
  foreach my $full (@shlibs) {
    my ($v, $d, $f) = splitpath($full);
    $tmp{ catpath($v, $d, '') } = 1;
    # available shared libs detection
    if ($f =~ /^(lib)?(png12)/) {
      $shlib_map{png12} = $full unless $shlib_map{png12};
    }
    elsif ($f =~ /^(lib)?(tiff|jpeg|png)[^a-zA-Z]/) {
      $shlib_map{$2} = $full unless $shlib_map{$2};
    }
  };
  $cfg->{ld_paths} = [ keys %tmp ];
  $cfg->{ld_shlib_map} = \%shlib_map;

  # write config
  $self->config_data('additional_cflags', '-I' . $self->get_path('@PrEfIx@/include') . ' ' .
                                          $self->get_additional_cflags);
  $self->config_data('additional_libs', $self->get_additional_libs);
  $self->config_data('config', $cfg);
}

sub can_build_binaries_from_sources {
  # this needs to be overriden in My::Builder::<platform>
  my $self = shift;
  return 0; # no
}

sub build_binaries {
  # this needs to be overriden in My::Builder::<platform>
  my ($self, $build_out, $build_src) = @_;
  die "###ERROR### My::Builder cannot build PNG from sources, use rather My::Builder::<platform>";
}

sub get_additional_cflags {
  # this needs to be overriden in My::Builder::<platform>
  my $self = shift;
  return '';
}

sub get_additional_libs {
  # this needs to be overriden in My::Builder::<platform>
  my $self = shift;
  return '';
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

sub patch_get_affected_files {
  my( $self, $base_dir, $patch_file ) = @_;
  $patch_file = File::Spec->abs2rel( $patch_file, $base_dir );
  open(DAT, $patch_file) or die "###ERROR### Cannot open file: '$patch_file'\n";
  my @affected_files = map{$_ =~ /^---\s*([\S]+)/} <DAT>;
  close(DAT);
  return @affected_files;
}

1;
