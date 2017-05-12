package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use My::Utility qw(check_header check_prereqs_libs check_prereqs_tools $inc_lib_candidates);
use Config;
use Capture::Tiny;

# $Config{cc} tells us to use gcc-4, but it is not there by default
if($^O eq 'cygwin') {
  $My::Utility::cc = 'gcc';
}

sub get_additional_cflags {
  my $self = shift;
  my @list = ();
  ### any platform specific -L/path/to/libs shoud go here
  for (keys %$inc_lib_candidates) {
    push @list, "-I$_" if (-d $_);
  }
  return join(' ', @list);
}

sub get_additional_libs {
  my $self = shift;
  ### any platform specific -L/path/to/libs shoud go here
  my @list = ();
  my %rv; # putting detected dir into hash to avoid duplicates
  for (keys %$inc_lib_candidates) {
    my $ld       = $inc_lib_candidates->{$_};
    if( -d $_ && -d $ld ) {
      $rv{"-L$ld"}          = 1;
      $rv{"-Wl,-rpath,$ld"} = 1 if $^O =~ /^linux|dragonfly|.+bsd$/;
    }
  }
  push @list, (keys %rv);
  if ($^O eq 'openbsd') {
    my $osver = `uname -r 2>/dev/null`;
    if ($self->notes('perl_libs')->{pthread} || ($osver && $osver < 5.0)) {
      push @list, '-lpthread'
    }
  }
  return join(' ', @list);
}

sub can_build_binaries_from_sources {
  my $self = shift;
  return 1; # yes we can
}

sub build_binaries {
  my( $self, $build_out, $build_src ) = @_;
  my $bp = $self->notes('build_params');
  foreach my $pack (@{$bp->{members}}) {
    if($pack->{pack} =~ m/^png|ogg|vorbis|z$/ && check_prereqs_libs($pack->{pack})->[0]) {
      print "SKIPPING package '" . $pack->{dirname} . "' (already installed)...\n";
    }
    elsif($pack->{pack} =~ m/^(SDL_mixer)$/ && !$self->_is_gnu_make($self->_get_make)) {
      print "SKIPPING package '" . $pack->{dirname} . "' (GNU Make needed)...\n";
    }
    elsif($pack->{pack} =~ m/^(SDL_Pango)$/ && !check_prereqs_tools('pkg-config')) {
      print "SKIPPING package '" . $pack->{dirname} . "' (pkg-config needed)...\n";
    }
    elsif($pack->{pack} =~ m/^(SDL_ttf)$/ && $^O eq 'cygwin') {
      print "SKIPPING package '" . $pack->{dirname} . "' (we cant use libfreetype)...\n";
    }
    else {
      print "BUILDING package '" . $pack->{dirname} . "'...\n";
      my $srcdir    = catfile($build_src, $pack->{dirname});
      my $prefixdir = rel2abs($build_out);
      $self->config_data('build_prefix', $prefixdir); # save it for future Alien::SDL::ConfigData

      chdir $srcdir;

      if($pack->{pack} eq 'SDL' && $^O eq 'cygwin') {
        $self->do_system('cp ../../patches/SDL-1.2.14-configure configure');
        $self->do_system('cp ../../patches/SDL-1.2.14-ltmain_sh build-scripts/ltmain.sh');
      }

      # setting environments PATH
      my $extra_PATH = "";
      if ($^O eq 'solaris') {
        # otherwise we get "false cru build/libSDLmain.a build/SDL_dummy_main.o"
        # see http://fixunix.com/ntp/245613-false-cru-libs-libopts-libopts_la-libopts-o.html#post661558
        for (qw[/usr/ccs/bin /usr/xpg4/bin /usr/sfw/bin /usr/xpg6/bin /usr/gnu/bin /opt/gnu/bin /usr/bin]) {
          $extra_PATH .= ":$_" if -d $_;
        }
      }
      $ENV{PATH} = "$prefixdir/bin:$ENV{PATH}$extra_PATH";

      # do './configure ...'
      my $run_configure = 'y';
      $run_configure    = $self->prompt("Run ./configure for '$pack->{pack}' again?", "y") if (-f "config.status");
      if (lc($run_configure) eq 'y') {
        my $cmd = $self->_get_configure_cmd($pack->{pack}, $prefixdir);
        print "Configuring package '$pack->{pack}'...\n";
        print "(cmd: $cmd)\n";
        unless($self->do_system($cmd)) {
          if(-f "config.log" && open(CONFIGLOG, "<config.log")) {
            print "config.log:\n";
            print while <CONFIGLOG>;
            close(CONFIGLOG);
          }
          die "###ERROR### [$?] during ./configure for package '$pack->{pack}'...";
        }
      }

      $self->do_system('cp ../SDL-1.2/libtool libtool') if $pack->{pack} eq 'SDL_Pango';

      # do 'make install'
      my @cmd = ($self->_get_make, 'install');
      print "Running make install $pack->{pack}...\n";
      print "(cmd: ".join(' ',@cmd).")\n";
      $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";

      chdir $self->base_dir();
    }
  }
  return 1;
}

### internal helper functions

sub _get_configure_cmd {
  my ($self, $pack, $prefixdir) = @_;
  my $extra                     = '';
  my $escaped_prefixdir         = $self->escape_path( $prefixdir );
  my $extra_cflags              = "-I$escaped_prefixdir/include " . $self->get_additional_cflags();
  my $extra_ldflags             = "-L$escaped_prefixdir/lib "     . $self->get_additional_libs();
  my $extra_PATH                = "";
  my $uname                     = $Config{archname};
  my $stdout                    = '';
  my $stderr                    = '';
  my $cmd;

  ($stdout, $stderr) = Capture::Tiny::capture { print `uname -a`; };
  $uname            .= " $stdout" if $stdout;

  # NOTE: all ugly IFs concerning ./configure params have to go here

  if($pack eq 'SDL_gfx' && $uname =~ /(powerpc|ppc|64|2level|alpha|armv[56]|sparc)/i) {
    $extra .= ' --disable-mmx';
  }

  if($pack eq 'SDL' && $uname =~ /(powerpc|ppc)/) {
    $extra .= ' --disable-video-ps3';
  }

  if($pack eq 'SDL' && $^O eq 'darwin' && !check_header($self->get_additional_cflags, 'X11/Xlib.h')) {
    $extra .= ' --without-x';
  }

  if($pack eq 'SDL' && !check_header($self->get_additional_cflags, 'X11/extensions/XShm.h')) {
    $extra        .= ' --disable-video-x11-xv';
    $extra_cflags .= ' -DNO_SHARED_MEMORY';
  }

  if($pack =~ /^SDL_(image|mixer|ttf|gfx|Pango)$/ && $^O eq 'darwin') {
    $extra .= ' --disable-sdltest';
  }

  if($pack eq 'SDL' && $^O eq 'solaris' && !check_header($extra_cflags, 'sys/audioio.h')) {
    $extra .= ' --disable-audio';
  }

  if ($pack eq 'SDL' && $^O eq 'openbsd') {
    my $osver = `uname -r 2>/dev/null`;
    if (!$self->notes('perl_libs')->{pthread} || !$osver || $osver >= 5.0) {
      $extra .= ' --disable-pthreads';
    }
  }

  if($pack =~ /^SDL_/) {
    $extra .= " --with-sdl-prefix=$escaped_prefixdir";
  }

  if($^O eq 'cygwin') {
    #$extra_cflags  .= " -I/lib/gcc/i686-pc-cygwin/3.4.4/include";
    #$extra_ldflags .= " -L/lib/gcc/i686-pc-cygwin/3.4.4";
#    $extra_cflags  .= " -I/usr/include";
#    $extra_ldflags .= " -L/lib";
#    $extra_cflags  .= " -I/lib/gcc/i686-pc-cygwin/4.3.4/include";
#    $extra_ldflags .= " -L/lib/gcc/i686-pc-cygwin/4.3.4";

    if($pack eq 'SDL') {
      # kmx experienced troubles while cygwin build when nasm was present in PATH
#      $extra .= " --disable-nasm --enable-pthreads --enable-pthread-sem --enable-sdl-dlopen --disable-arts"
#              . " --disable-esd --disable-nas --enable-oss --disable-pulseaudio --disable-dga --disable-video-aalib"
#              . " --disable-video-caca --disable-video-dga --enable-video-dummy --disable-video-ggi --enable-video-opengl"
#              . " --enable-video-x11 --disable-video-x11-dgamouse --disable-video-x11-vm --enable-video-x11-xinerama"
#              . " --disable-video-x11-xme --enable-video-x11-xrandr --disable-video-x11-xv --disable-arts-shared"
#              . " --disable-esd-shared --disable-pulseaudio-shared --enable-x11-shared";
    }
  }

  if($pack eq 'jpeg') {
    # otherwise libtiff will complain about invalid version number on dragonflybsd
    $extra .= " --disable-ld-version-script";
  }

  ### This was intended as a fix for http://www.cpantesters.org/cpan/report/7064012
  ### Unfortunately does not work.
  #
  #if(($pack eq 'SDL') && ($^O eq 'darwin')) {
  #  # fix for many MacOS CPAN tester reports saying "error: X11/Xlib.h: No such file or directory"
  #  $extra_cflags .= ' -I/usr/X11R6/include';
  #  $extra_ldflags .= ' -L/usr/X11R6/lib';
  #}

  if($pack eq 'z') {
    # does not support params CFLAGS=...
    $cmd = "./configure --prefix=$escaped_prefixdir";
  }
  else {
    $cmd = "./configure --prefix=$escaped_prefixdir --enable-static=yes --enable-shared=yes $extra" .
           " CFLAGS=\"$extra_cflags\" LDFLAGS=\"$extra_ldflags\"";
  }

  if($pack ne 'SDL' && $^O =~ /bsd$/) {
    $cmd = "LD_LIBRARY_PATH=\"$escaped_prefixdir/lib:\$LD_LIBRARY_PATH\" $cmd";
  }

  if($pack eq 'vorbis') {
    $cmd = "PKG_CONFIG_PATH=\"$escaped_prefixdir/lib/pkgconfig:\$PKG_CONFIG_PATH\" $cmd";
  }

  return $cmd;
}

sub _get_make {
  my ($self) = @_;
  my @try    = ('make', 'gmake', $Config{gmake}, $Config{make});
  my %tested;
  print "Gonna detect GNU make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    print "- testing: '$name'\n";
    if($self->_is_gnu_make($name)) {
      print "- found: '$name'\n";
      return $name
    }
  }
  print "- fallback to: 'make'\n";
  return 'make';
}

sub _is_gnu_make {
  my ($self, $name) = @_;
  my $devnull       = File::Spec->devnull();
  my $ver           = `$name --version 2> $devnull`;
  if($ver =~ /GNU Make/i) {
    return 1;
  }
  return 0;
}

sub escape_path {
  my( $self, $path ) = @_;
  my $_path          = $path;
  $_path             =~ s/([^\\]) /$1\\ /g;
  return $_path;
}

1;
