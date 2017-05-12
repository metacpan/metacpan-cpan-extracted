package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use lib "inc";
use My::Utility qw(find_SDL_dir find_file sed_inplace get_dlext);
use File::Spec::Functions qw(catdir catfile splitpath catpath rel2abs abs2rel);
use File::Path qw(make_path remove_tree);
use File::Copy qw(cp);
use File::Fetch;
use File::Find;
use File::ShareDir;
use Archive::Extract;
use Digest::SHA qw(sha1_hex);
use Text::Patch;
use Config;

$SIG{__WARN__} = sub {
	my $thing =  join('', @_);
	$thing    =~ s|(://.+:).+(\@.+)|$1******$2|;
	warn $thing;
	return 1;
};

sub ACTION_build {
  my $self = shift;
  # as we want to wipe 'sharedir' during 'Build clean' we has
  # to recreate 'sharedir' at this point if it does not exist

  my $bp = $self->notes('build_params');
  die "###ERROR### Cannot continue build_params not defined" unless defined($bp);

  printf("Build option used:\n\t%s\n", $bp->{title} || 'n.a.');

  mkdir 'sharedir' unless(-d 'sharedir');
  $self->add_to_cleanup('sharedir');
  $self->SUPER::ACTION_build;
}


sub ACTION_install
{
 my $self = shift;
 my $sharedir = '';

 $sharedir = eval {File::ShareDir::dist_dir('Alien-SDL')} || '';

 if ( -d $sharedir )
 {
   print "Removing the old $sharedir \n";
   remove_tree($sharedir);
   make_path($sharedir);
 }

 $self->SUPER::ACTION_install;
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
    # Alien::SDL with different build options
    my $share_subdir = $self->{properties}->{dist_version} . '_' . substr(sha1_hex($bp->{title}), 0, 8);
    my $build_out    = catfile('sharedir', $share_subdir);
    my $build_src    = 'build_src';
    $self->add_to_cleanup($build_src, $build_out);

    # save some data into future Alien::SDL::ConfigData
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
      $self->set_ld_config($build_out);
      $self->config_data('additional_cflags', '-I' . $self->get_path($bp->{prefix} . '/include/smpeg') . ' '.
                                              '-I' . $self->get_path($bp->{prefix} . '/include') . ' ' .
                                              $self->get_additional_cflags);
      $self->config_data('additional_libs', $self->get_additional_libs);
    }
    elsif($bp->{buildtype} eq 'use_prebuilt_binaries') {
      # all the following functions die on error, no need to test ret values
      $self->fetch_binaries($download);
      $self->clean_dir($build_out);
      $self->extract_binaries($download, $build_out);
      $self->set_config_data($build_out);
      $self->set_ld_config($build_out);
    }
    elsif($bp->{buildtype} eq 'build_from_sources' ) {
      # all the following functions die on error, no need to test ret values
      $self->fetch_sources($download);
      $self->extract_sources($download, $patches, $build_src);
      $self->clean_dir($build_out);
      $self->build_binaries($build_out, $build_src);
      $self->set_config_data($build_out);
      $self->set_ld_config($build_out);
    }

    # mark sucessfully finished build
    $self->touch_build_done_marker;
  }

  $self->SUPER::ACTION_code;
}

sub fetch_file {
  my ($self, $url, $sha1sum, $download) = @_;
  die "###ERROR### _fetch_file undefined url\n"     unless @{$url}[0];
  die "###ERROR### _fetch_file undefined sha1sum\n" unless $sha1sum;

  # setting http_proxy environment var if we are within CPAN and this information is available
  if(!$ENV{http_proxy} && $ENV{PERL5_CPAN_IS_RUNNING}) {
    if(eval('require CPAN::Config; 1') && $CPAN::Config->{http_proxy}) {
      $ENV{http_proxy} = $CPAN::Config->{http_proxy};
      if($CPAN::Config->{proxy_user} && $CPAN::Config->{proxy_pass} && $CPAN::Config->{http_proxy} !~ m|//.+:.+@|) {
        $ENV{http_proxy} =~ s|://|://\Q$CPAN::Config->{proxy_user}\E:\Q$CPAN::Config->{proxy_pass}\E@|;
      }
    }
  }

  my $ff = File::Fetch->new(uri => @{$url}[0]);
  my $fn = catfile($download, $ff->file);
  if (-e $fn) {
    print "Checking checksum for already existing '$fn'...\n";
    return 1 if $self->check_sha1sum($fn, $sha1sum);
    unlink $fn; #exists but wrong checksum
  }

  my $fullpath;
  foreach my $current_url (@{$url})
  {
    die "###ERROR### _fetch_file undefined url\n" unless $current_url;
    print "Fetching '$current_url'...\n";
    $ff = File::Fetch->new(uri => $current_url);
    $fullpath = $ff->fetch(to => $download);
    last if $fullpath;
  }
  die "###ERROR### Unable to fetch '$ff->file'" unless $fullpath;
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
  $self->fetch_file($_->{url}, $_->{sha1sum}, $download) foreach (@{$bp->{members}});
}

sub extract_binaries {
  my ($self, $download, $build_out) = @_;

  # do extract binaries
  my $bp = $self->notes('build_params');
  my $archive = catfile($download, File::Fetch->new(uri => @{$bp->{url}}[0])->file);
  print "Extracting $archive...\n";
  my $ae = Archive::Extract->new( archive => $archive );
  die "###ERROR###: Cannot extract $archive ", $ae->error unless $ae->extract(to => $build_out);

  # fix hardcoded prefix path in bin/sdl-config
  my ($version, $prefix, $incdir, $libdir) = find_SDL_dir(rel2abs($build_out));
  sed_inplace("$prefix/bin/sdl-config", 's/^prefix=.*/prefix=\''.quotemeta($prefix).'\'/');
  if( $^O eq 'MSWin32' && $My::Utility::cc eq 'cl' ) {
    cp( catfile('patches', 'SDL_config_win32.h'), catfile($incdir, 'SDL', 'SDL_config.h') );
  }
}

sub extract_sources {
  my ($self, $download, $patches, $build_src) = @_;
  my $bp = $self->notes('build_params');
  foreach my $pack (@{$bp->{members}}) {
    my $srcdir = catfile($build_src, $pack->{dirname});
    my $unpack = 'y';
    $unpack = $self->prompt("Dir '$srcdir' exists, wanna replace with clean sources?", "y") if (-d $srcdir);
    if (lc($unpack) eq 'y') {
      my $archive = catfile($download, File::Fetch->new(uri => @{$pack->{url}}[0])->file);
      print "Extracting $pack->{pack}...\n";
      my $ae = Archive::Extract->new( archive => $archive );
      die "###ERROR###: cannot extract $pack ", $ae->error unless $ae->extract(to => $build_src);
      foreach my $i (@{$pack->{patches}}) {
        chdir $srcdir;
        my $patch_file = File::Spec->abs2rel( catfile($patches, $i), $srcdir );
        print "Applying patch '$i'\n";
        foreach my $k ($self->patch_get_affected_files($patch_file)) {
          # doing the same like -p1 for 'patch'
          $k =~ s/^[^\/]*\/(.*)$/$1/;
          open(SRC, $k) or die "###ERROR### Cannot open file: '$k'\n";
          my @src = <SRC>;
          close(SRC);
          open(DIFF, $patch_file) or die "###ERROR### Cannot open file: '$patch_file'\n";
          my @diff = <DIFF>;
          close(DIFF);
          foreach(@src)  { $_=~ s/[\r\n]+$//; }
          foreach(@diff) { $_=~ s/[\r\n]+$//; }
          my $out = Text::Patch::patch( join("\n", @src) . "\n", join("\n", @diff) . "\n", { STYLE => "Unified" } );
          open(OUT, ">$k") or die "###ERROR### Cannot open file for writing: '$k'\n";
          print(OUT $out);
          close(OUT);
        }
        chdir $self->base_dir();
      }
    }
  }
  return 1;
}

sub set_config_data {
  my( $self, $build_out ) = @_;

  # try to find SDL root dir
  my ($version, $prefix, $incdir, $libdir) = find_SDL_dir(rel2abs($build_out));
  die "###ERROR### Cannot find SDL directory in 'sharedir'" unless $version;
  $self->config_data('share_subdir', abs2rel($prefix, rel2abs('sharedir')));

  # set defaults
  my $L   = $My::Utility::cc eq 'cl'
          ? '/LIBPATH:'
          : '-L';
  my $cfg = $self->config_data('config') || {};

  # defaults
  $cfg->{version}        = $version;
  $cfg->{prefix}         = '@PrEfIx@';
  $cfg->{libs}           = $L . $self->get_path('@PrEfIx@/lib') . ' -lSDLmain -lSDL';
  $cfg->{cflags}         = '-I' . $self->get_path('@PrEfIx@/include/SDL') . ' -D_GNU_SOURCE=1 -Dmain=SDL_main';
  $cfg->{ld_shared_libs} = [ ];

  # overwrite values available via sdl-config
  my $bp      = $self->config_data('build_prefix') || $prefix;
  my $devnull = File::Spec->devnull();
  my $script  = $self->escape_path( rel2abs("$prefix/bin/sdl-config") );
  foreach my $p (qw(version prefix libs cflags)) {
    my $o=`$script --$p 2>$devnull`;
    if ($o) {
      $o =~ s/[\r\n]*$//;
      $o =~ s/\Q$prefix\E/\@PrEfIx\@/g;
      $cfg->{$p} = $o;
    }
  }

  if ($^O eq 'openbsd') {
    my $osver = `uname -r 2>/dev/null`;
    if (!$self->notes('perl_libs')->{pthread} || !$osver || $osver >= 5.0) {
      $cfg->{libs} =~ s/\s*-l?pthread//g;
    }
  }

  # write config
  $self->config_data('additional_cflags', '-I' . $self->get_path('@PrEfIx@/include') . ' ' .
                                          '-I' . $self->get_path('@PrEfIx@/include/smpeg') . ' ' .
                                          $self->get_additional_cflags);
  $self->config_data('additional_libs', $self->get_additional_libs);
  $self->config_data('config', $cfg);
}

sub set_ld_config {
  my( $self, $build_out ) = @_;
  my ($version, $prefix, $incdir, $libdir) = find_SDL_dir(rel2abs($build_out));
  my $cfg   = $self->config_data('config') || {};
  my $dlext = get_dlext();
  # find ld_shared_libs and create symlinks if necessary
  my $symlink_exists = eval { symlink("",""); 1 };
  if($symlink_exists) {
    my @shlibs_ = find_file($build_out, qr/\.$dlext[\d\.]+$/);
    foreach my $full (@shlibs_){
      $full =~ qr/(.*\.$dlext)[\d\.]+$/;
      my ($v, $d, $f) = splitpath($full);
      symlink("./$f", $1) unless -e $1;
    }
  }

  # find and set ld_shared_libs
  my @shlibs = find_file($build_out, qr/\.$dlext$/);
#  my $p      = rel2abs($prefix);
  $_         =~ s/^\Q$prefix\E/\@PrEfIx\@/ foreach (@shlibs);

  # set ld_paths and ld_shlib_map
  my %tmp = ();
  my %shlib_map = ();
  foreach my $full (@shlibs) {
    my ($v, $d, $f) = splitpath($full);
    $tmp{ catpath($v, $d, '') } = 1;
    # available shared libs detection
    if ($f =~ /smpeg/) {
      $shlib_map{smpeg} = $full unless $shlib_map{smpeg};
    }
    elsif ($f =~ /^(lib)?(png12)/) {
      $shlib_map{png12} = $full unless $shlib_map{png12}; # what if it isnt png12?
    }
    elsif ($f =~ /^(lib)?(intl|z|tiff|jpeg|png|ogg|vorbis|vorbisfile|freetype|FLAC|mikmod)[^a-zA-Z]/) {
      $shlib_map{$2} = $full unless $shlib_map{$2};
    }
    elsif ($f =~ /^(lib)?(SDL_[a-zA-Z]{2,8})[^a-zA-Z0-9]/) {
      # sort of dark magic how to detect SDL_<something> related shlib
      $shlib_map{$2} = $full unless $shlib_map{$2};
    }
    elsif ($f =~ /^(lib)?(SDL)/) {
      # '*SDL*' that did not pass previous test is probably core 'SDL'
      $shlib_map{SDL} = $full unless $shlib_map{SDL};
    }
  };

  $cfg->{ld_shared_libs} = [ @shlibs ];
  $cfg->{ld_paths}       = [ keys %tmp ];
  $cfg->{ld_shlib_map}   = \%shlib_map;

  my $have_libs = $self->notes('have_libs');
  for(qw(pthread  z jpeg tiff png ogg vorbis vorbisfile freetype
         pangoft2 pango gobject gmodule glib fontconfig expat )) {
    if( !$shlib_map{$_} && $have_libs->{$_}->[0] ) {
      next unless defined $have_libs->{$_}->[1];
      if ($_ eq 'pthread' && $^O eq 'openbsd') {
        my $osver = `uname -r 2>/dev/null`;
        if ($self->notes('perl_libs')->{pthread} || ($osver && $osver < 5.0)) {
          push @{ $cfg->{ld_shared_libs} }, $have_libs->{$_}->[1];
          $shlib_map{$_} = $have_libs->{$_}->[1];
        }
      }
      else {
        push @{ $cfg->{ld_shared_libs} }, $have_libs->{$_}->[1];
        $shlib_map{$_} = $have_libs->{$_}->[1];
      }
    }
  }

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
  die "###ERROR### My::Builder cannot build SDL from sources, use rather My::Builder::<platform>";
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

sub escape_path {
  # this needs to be overriden in My::Builder::<platform>
  my( $self, $path ) = @_;
  return $path;
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
  my $_sha1sum = $sha1->hexdigest;
  warn "###WARN## checksum for file $file is $_sha1sum but we expect $sha1sum\n" if $_sha1sum ne $sha1sum;
  return ($_sha1sum eq $sha1sum) ? 1 : 0
}

sub patch_get_affected_files {
  my( $self, $patch_file ) = @_;
  open(DAT, $patch_file) or die "###ERROR### Cannot open file: '$patch_file'\n";
  my @affected_files = map{$_ =~ /^---\s*([\S]+)/} <DAT>;
  close(DAT);
  return @affected_files;
}

1;
