package App::ArduinoBuilder::System;

use strict;
use warnings;
use utf8;

use Cwd;
use Exporter 'import';
use File::Spec::Functions;
use List::Util 'first';

our @EXPORT_OK = qw(find_arduino_dir system_cwd);

sub find_arduino_dir {
  my @tests;
  if ($^O eq 'MSWin32' || $^O eq 'cygwin' || $^O eq 'msys') {
    if (exists $ENV{LOCALAPPDATA}) {
      push @tests, catdir($ENV{LOCALAPPDATA}, 'Arduino15');
    }
  }
  if ($^O ne 'MSWin32') {
    push @tests, '/usr/share/arduino', '/usr/local/share/arduino';
    if (`which arduino 2>/dev/null` =~ m{^(.*)/bin/arduino}) {
      push @tests, catdir($1, 'share/arduino');
    }
  }
  return first { -d } @tests;
}

sub system_cwd {
  my $cwd = getcwd();
  # Todo: we could have a "use_native_cygwin" option somewhere in the improbable
  # case of a native toolchain to deactivate this logic (as well as using
  # /dev/null instal of nul in the builder).
  if ($^O eq 'cygwin') {
    $cwd = `cygpath -w '${cwd}'`;
    chomp($cwd);
  }
  return $cwd;
}
