# Code to select XS or Pure Perl version inspired by Scalar::List::Utils

use strict;
use warnings;
use Config;
use inc::Module::Install;

# Automatically select XS or PP version in case neither argument is given
my $got_libFLAC = defined(search_lib('-lFLAC'));
my $do_xs = can_cc() && $got_libFLAC;

# Select XS or PP version if argument is given
for (@ARGV) {
  /^-pp/ and $do_xs = 0;
  /^-xs/ and $do_xs = 1;
}

if ($do_xs && !$got_libFLAC) {
  warn "* libFLAC is not installed or not in the default lib path. Cannot build XS version.\n";
  die  "* Try building pure perl version by using -pp argument.\n";
}

name('Audio-FLAC-Header');
license('perl');
perl_version('5.005');
all_from('Header.pm');
requires_external_cc() if $do_xs;

if ($do_xs) {
  requires_external_cc();

  print "Building XS version.\n";

  if ($^O =~ /win32/i) {
    cc_lib_links('FLAC_static');
  } else {
    cc_lib_links('FLAC');
    cc_optimize_flags('-Wall') if $Config::Config{'archname'} =~ /gnu/i;
  }

} else {
  print "Not building XS version.\n";
  makemaker_args ( XS => {}, C => [] );
}

auto_install();
WriteAll();

sub search_lib {
  my ($lib) = @_;

  unless ($lib =~ /^-l/) {
    warn "search_lib: illegal arguments, \`$lib\'.\n";
    return undef;
  }

  my $libbase = 'lib' . substr($lib, 2) . $Config{lib_ext};
  my $libbase_so = 'lib' . substr($lib, 2) . "." . $Config{so};

  for my $path (split(' ', $Config{libpth})) {
    if (-f $path . '/' . $libbase) {
      print "$path/$libbase\n";
      print "Found '$path/$libbase'.\n";
      return $lib;
    } elsif (-f $path . '/' . $libbase_so) {
      print "$path/$libbase_so\n";
      print "Found `$_/$libbase_so'.\n";
      return $lib;
    }
  }

  return undef;
}
