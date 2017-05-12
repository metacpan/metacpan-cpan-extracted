package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use lib "inc";
use My::Utility qw(find_SDL2_dir find_file sed_inplace get_dlext);
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
use IPC::Run3;

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

 $sharedir = eval {File::ShareDir::dist_dir('Alien-SDL2')} || '';

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
    # Alien::SDL2 with different build options
    my $share_subdir = $self->{properties}->{dist_version} . '_' . substr(sha1_hex($bp->{title}), 0, 8);
    my $build_out    = catfile('sharedir', $share_subdir);
    my $build_src    = 'build_src';
    $self->add_to_cleanup($build_src, $build_out);

    # save some data into future Alien::SDL2::ConfigData
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
    elsif ( $bp->{buildtype} eq 'build_from_sources' ) {

        my $m = '';
        if ( $self->notes('travis') && $self->notes('travis') == 1 ) {
            # always select option '1'
            $m = 1;
        }
        else {
            $m = $self->prompt(
"\nDo you want to see all messages during configure/make (y/n)?",
                'n'
            );
        }

      $self->notes('build_msgs', lc($m) eq 'y' ? 1 : 0);
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

  # fix hardcoded prefix path in bin/sdl2-config
  my ($version, $prefix, $incdir, $libdir) = find_SDL2_dir(rel2abs($build_out));
  sed_inplace("$prefix/bin/sdl2-config", 's/^prefix=.*/prefix=\''.quotemeta($prefix).'\'/');
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
      $self->apply_patch($srcdir, "$patches/$_") for (@{$pack->{patches}});
    }
  }
  return 1;
}

sub set_config_data {
  my( $self, $build_out ) = @_;

  # try to find SDL2 root dir
  my ($version, $prefix, $incdir, $libdir) = find_SDL2_dir(rel2abs($build_out));
  die "###ERROR### Cannot find SDL2 directory in 'sharedir'" unless $version;
  $self->config_data('share_subdir', abs2rel($prefix, rel2abs('sharedir')));

  # set defaults
  my $L   = $My::Utility::cc eq 'cl'
          ? '/LIBPATH:'
          : '-L';
  my $cfg = $self->config_data('config') || {};

  # defaults
  $cfg->{version}        = $version;
  $cfg->{prefix}         = '@PrEfIx@';
  $cfg->{libs}           = $L . $self->get_path('@PrEfIx@/lib') . ' -lSDL2main -lSDL2';
  $cfg->{cflags}         = '-I' . $self->get_path('@PrEfIx@/include/SDL2') . ' -D_GNU_SOURCE=1 -Dmain=SDL2_main';
  $cfg->{ld_shared_libs} = [ ];

  # overwrite values available via sdl2-config
  my $bp      = $self->config_data('build_prefix') || $prefix;
  my $devnull = File::Spec->devnull();
  my $script  = $self->escape_path( rel2abs("$prefix/bin/sdl2-config") );
  foreach my $p (qw(version prefix libs cflags)) {
    my $o=`$script --$p 2>$devnull`;
    if ($o) {
      $o =~ s/[\r\n]*$//;
      $o =~ s/\Q$prefix\E/\@PrEfIx\@/g;
      $cfg->{$p} = $o;
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
  my ($version, $prefix, $incdir, $libdir) = find_SDL2_dir(rel2abs($build_out));
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
    elsif ($f =~ /^(lib)?(SDL2_[a-zA-Z]{2,8})[^a-zA-Z0-9]/) {
      # sort of dark magic how to detect SDL2_<something> related shlib
      $shlib_map{$2} = $full unless $shlib_map{$2};
    }
    elsif ($f =~ /^(lib)?(SDL2)/) {
      # '*SDL2*' that did not pass previous test is probably core 'SDL2'
      $shlib_map{SDL2} = $full unless $shlib_map{SDL2};
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
      push @{ $cfg->{ld_shared_libs} }, $have_libs->{$_}->[1];
      $shlib_map{$_} = $have_libs->{$_}->[1];
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
  die "###ERROR### My::Builder cannot build SDL2 from sources, use rather My::Builder::<platform>";
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

# pure perl implementation of patch functionality
sub apply_patch {
  my ($self, $dir_to_be_patched, $patch_file) = @_;
  my ($src, $diff);

  undef local $/;
  open(DAT, $patch_file) or die "###ERROR### Cannot open file: '$patch_file'\n";
  $diff = <DAT>;
  close(DAT);
  $diff =~ s/\r\n/\n/g; #normalise newlines
  $diff =~ s/\ndiff /\nSpLiTmArKeRdiff /g;
  my @patches = split('SpLiTmArKeR', $diff);

  print STDERR "Applying patch file: '$patch_file'\n";
  foreach my $p (@patches) {
    my ($k) = $p =~ /^---\s*([\S]+)/;
    # doing the same like -p1 for 'patch'
    $k =~ s|\\|/|g;
    $k =~ s|^[^/]*/(.*)$|$1|;
    $k = catfile($dir_to_be_patched, $k);
    print STDERR "- gonna patch '$k'\n";

    if (-f $k) {
      open(SRC, "<", $k) or die "###ERROR### Cannot open file: '$k'\n";
      $src  = <SRC>;
      close(SRC);
      $src =~ s/\r\n/\n/g; #normalise newlines
    }
    else {
      $src = "";
    }

    my $out = eval { Text::Patch::patch( $src, $p, { STYLE => "Unified" } ) };
    if ($out) {
      open(OUT, ">", $k) or die "###ERROR### Cannot open file for writing: '$k'\n";
      print(OUT $out);
      close(OUT);
    }
    else {
      warn "###WARN### Patching '$k' failed: $@";
    }
  }
}

sub run_output_on_error {
  my ($self, $limit, $cmd) = @_;
  my $output;
  my $c = ref($cmd) eq 'ARRAY' ? join(' ',@$cmd) : $cmd;
  print STDERR "CMD: $c\n";
  print STDERR "- running (stdout+stderr redirected)...\n";
  my $rv = run3($cmd, \undef, \$output, \$output, { return_if_system_error => 1 } );
  my $success = ($rv == 1 && $? == 0) ? 1 : 0;
  if ($success) {
    print STDERR "- finished successfully (output suppressed)\n";
  }
  else {
    $output = substr $output, -$limit if defined $limit; # we want just last N chars
    if (!defined($limit)) {
      print STDERR "OUTPUT:\n", $output, "\n";
    }
    elsif ($limit>0) {
      print STDERR "OUTPUT: (only last $limit chars)\n", $output, "\n";
    }
  }
  return $success;
}

sub run_output_std {
  my ($self, $cmd) = @_;
  my $c = ref($cmd) eq 'ARRAY' ? join(' ',@$cmd) : $cmd;
  print STDERR "CMD: $c\n";
  my $rv = run3($cmd, undef, undef, undef, { return_if_system_error => 1 } );
  my $success = ($rv == 1 && $? == 0) ? 1 : 0;
  print STDERR "- finished successfully\n" if ($success);
  return $success;
}

sub run_custom {
  my ($self, $cmd) = @_;
  my $rv;
  if ($self->notes('build_msgs')) {
    $rv = $self->run_output_std($cmd);
  }
  else {
    $rv = $self->run_output_on_error(undef, $cmd);
  }
  #warn "###WARN### error during run_custom()" unless $rv;
  return $rv;
}

sub run_stdout2str {
  my ($self, $cmd) = @_;
  my $output;
  my $rv = run3($cmd, \undef, \$output, \undef, { return_if_system_error => 1 } );
  $output =~ s/[\r\n]*$//;
  return $output;
}

1;
