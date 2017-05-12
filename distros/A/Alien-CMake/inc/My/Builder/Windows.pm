package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use Config;

sub build_binaries {
  my( $self, $build_out, $build_src ) = @_;
  my $bp = $self->notes('build_params');

  print "BUILDING '" . $bp->{dirname} . "'...\n";
  my $srcdir = catfile($build_src, $bp->{dirname});
  my $prefixdir = rel2abs($build_out);
  $self->config_data('build_prefix', $prefixdir); # save it for future Alien::CMake::ConfigData

  print "Gonna read version info from $srcdir/Common/b2Settings.cpp\n";
  open(DAT, "$srcdir/Common/b2Settings.cpp") || die;
  my @raw=<DAT>;
  close(DAT);
  my ($version) = grep(/version\s?=\s?\{[\d\s,]+\}/, @raw);
  if ($version =~ /version\s?=\s?\{(\d+)[^\d]+(\d+)[^\d]+(\d+)\}/) {
    print STDERR "Got version=$1.$2.$3\n";
    $self->notes('build_cmake_version', "$1.$2.$3");
  }

  chdir $srcdir;

  # do 'cmake ...'
  print "CMaking ...\n";
  $self->do_system('cmake', '-GMinGW Makefiles', '-DCMAKE_INSTALL_PREFIX=' . $self->config_data('build_prefix'),
                            '-DCMAKE_C_COMPILER=mingw32-gcc', '-DCMAKE_CXX_COMPILER=mingw32-g++',
                            '-DCMAKE_MAKE_PROGRAM=mingw32-make',
                            '-DBOX2D_INSTALL=ON', '-DBOX2D_BUILD_SHARED=OFF', '-DBOX2D_BUILD_STATIC=ON',
                            '-DBOX2D_BUILD_EXAMPLES=OFF', '..')
  or die "###ERROR### [$?] during cmake ... ";

  # do 'make install'
  my @cmd = ($self->get_make, 'install');
  print "Running make install ...\n";
  print "(cmd: ".join(' ',@cmd).")\n";
  $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";

  chdir $self->base_dir();
  return 1;
}

sub get_make {
  my ($self) = @_;
  my $devnull = File::Spec->devnull();
  my @try = ($Config{gmake}, 'gmake', 'make', $Config{make});
  my %tested;
  print "Gonna detect GNU make:\n";

  #return 'mingw32-make';

  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    print "- testing: '$name'\n";
    my $ver = `$name --version 2> $devnull`;
    if ($ver =~ /GNU Make/i) {
      print "- found: '$name'\n";
      return $name
    }
  }
  print "- fallback to: 'make'\n";
  return 'make';
}

1;
