package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use My::Utility qw(check_header check_prereqs_libs check_prereqs_tools $inc_lib_candidates);
use Config;

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
  return join(' ', @list);
}

sub can_build_binaries_from_sources {
  my $self = shift;
  return 1; # yes we can
}

sub build_binaries {
  my( $self, $build_out, $build_src ) = @_;
  my $bp = $self->notes('build_params');
  my $make = $self->_get_make;

  foreach my $pack (@{$bp->{members}}) {
    if($pack->{pack} =~ m/^tiff|png|ogg|vorbis|z$/ && check_prereqs_libs($pack->{pack})->[0]) {
      print "SKIPPING package '" . $pack->{dirname} . "' (already installed)...\n";
    }
    else {
      print "BUILDING package '" . $pack->{dirname} . "'...\n";
      my $srcdir    = catfile($build_src, $pack->{dirname});
      my $prefixdir = rel2abs($build_out);
      $self->config_data('build_prefix', $prefixdir); # save it for future Alien::SDL::ConfigData

      chdir $srcdir;

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
        unless($self->run_custom($cmd)) {
          if(-f "config.log" && open(CONFIGLOG, "<config.log")) {
            print "config.log:\n";
            print while <CONFIGLOG>;
            close(CONFIGLOG);
          }
          die "###ERROR### [$?] during ./configure for package '$pack->{pack}'...";
        }
      }

      # do 'make install'
      my @cmd = ($make, 'install');
      $self->run_custom(\@cmd) or die "###ERROR### [$?] during make ... ";

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
  my $cmd;

  # NOTE: all ugly IFs concerning ./configure params have to go here

  if($pack =~ /^SDL2_(image|mixer|ttf|gfx|net)$/) {
    $extra .= ' --disable-sdltest';
  }

  if($pack =~ /^SDL2_/) {
    $extra .= " --with-sdl-prefix=$escaped_prefixdir";
  }

  if($pack eq 'z') {
    # does not support params CFLAGS=...
    $cmd = "./configure --prefix=$escaped_prefixdir";
  }
  else {
    $cmd = "./configure --prefix=$escaped_prefixdir --enable-static=yes --enable-shared=yes $extra" .
           " CFLAGS=\"$extra_cflags\" LDFLAGS=\"$extra_ldflags\"";
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
