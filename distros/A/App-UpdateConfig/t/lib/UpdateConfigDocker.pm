package UpdateConfigDocker;

# Helper to run shell scripts in fresh Docker containers, for the extended
# tests of the installation of the program and of its modules.

use strict;
use warnings;

use English;
use Exporter 'import';
use File::Spec::Functions 'catfile';
use File::Temp 'tempdir';
use Test2::V0;

our $VERSION = 0.01;

our @EXPORT_OK = qw(skip_without_docker run_in_container);

# The modules that the program installs at run-time when they are missing.
our @MODULES = qw(Data::Section::Simple File::HomeDir File::Slurp Text::Diff File::Which);

# Skips the whole test unless the extended tests are enabled and Docker is
# available.
sub skip_without_docker {
  if (!$ENV{EXTENDED_TESTING}) {
    skip_all('Extended test. Run manually or set $ENV{EXTENDED_TESTING} to a true value to run.');
  }
  if (system('docker info > /dev/null 2>&1') != 0) {
    skip_all('Docker is required to run this test.');
  }
  return;
}

# Runs the given shell script in a fresh container of the given image (as
# root), with the given additional arguments for `docker run` (e.g. volumes).
# Checks that the container exited successfully and returns its output
# (STDOUT and STDERR).
sub run_in_container {
  my ($image, $docker_args, $script) = @_;
  my $dir = tempdir(CLEANUP => 1);
  my $script_file = catfile($dir, 'test.sh');
  open my $fh, '>', $script_file or die "Cannot write '${script_file}': ${OS_ERROR}\n";
  print {$fh} $script;
  close $fh or die "Cannot close '${script_file}': ${OS_ERROR}\n";
  # IPv6 is disabled because, on some Docker setups, the container sees IPv6
  # addresses but can't connect to them, and each download then hangs until
  # its time-out. The modules are installed by cpanm without running their
  # tests, which would make these tests much slower.
  my $docker =
      'docker run --rm --sysctl net.ipv6.conf.all.disable_ipv6=1 -e PERL_CPANM_OPT=--notest';
  my $out = `${docker} -v ${script_file}:/test.sh:ro ${docker_args} ${image} sh /test.sh 2>&1`;  ## no critic (ProhibitBacktickOperators)
  is($CHILD_ERROR, 0, 'docker run: success') or diag($out);
  return $out;
}

1;
