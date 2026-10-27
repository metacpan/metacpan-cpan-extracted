#!/usr/bin/perl

# Tests the bootstrapping of a new host, in a fresh Docker container that has
# Perl but none of the modules required by the script. The script must install
# the modules and then apply the fragments. This is tested both with a copy of
# the script and with a packed script executed through `perl -` (as with ssh).

use strict;
use warnings;

use Test2::V0;

use English;
use File::Spec::Functions 'catfile';
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest 'guarded';

our $VERSION = 0.01;

BEGIN {
  if (!$ENV{EXTENDED_TESTING}) {
    skip_all('Extended test. Run manually or set $ENV{EXTENDED_TESTING} to a true value to run.');
  }
  if (system('docker info > /dev/null 2>&1') != 0) {
    skip_all('Docker is required to run this test.');
  }
}

# The oldest supported Perl version. This image does not have any of the
# non-core modules used by the script, but it has `make`, which is needed by
# `cpan` to install them.
my $image = 'perl:5.24';

my $script = catfile($FindBin::Bin, '..', 'script', 'update_config');
my $modules = 'Data::Section::Simple File::HomeDir File::Slurp Text::Diff File::Which';

# Runs the given command in a fresh container, between a check that the
# modules are not installed and a check that they are installed. Then prints
# the content of the files that should have been written by the script.
# Returns the output of the container.
sub run_in_container {
  my ($docker_args, $command) = @_;
  my $container_script = <<"EOF";
for m in ${modules}; do perl -M\$m -e1 2>/dev/null && echo "Before: \$m present"; done
${command} || echo "Script failed"
for m in ${modules}; do perl -M\$m -e1 2>/dev/null || echo "After: \$m absent"; done
echo "--- .testrc"; cat ~/.testrc
echo "--- .which"; cat ~/.which
echo "--- end"
EOF
  # IPv6 is disabled because, on some Docker setups, the container sees IPv6
  # addresses but can't connect to them, and each download then hangs until
  # its time-out.
  my $docker = 'docker run --rm --sysctl net.ipv6.conf.all.disable_ipv6=1';
  my $out = `${docker} ${docker_args} ${image} sh -c '${container_script}' 2>&1`;  ## no critic (ProhibitBacktickOperators)
  is($CHILD_ERROR, 0, 'docker run: success') or diag($out);
  return $out;
}

sub check_output {
  my ($out) = @_;
  unlike($out, qr/^Before:/mx, 'modules not present in the initial image');
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  unlike($out, qr/^After:/mx, 'modules installed') or diag($out);
  like($out, qr/^Updated:[ ][.]testrc$/mx, 'fragment reported as updated');
  my ($testrc) = $out =~ m/^---[ ][.]testrc\n(.*?)^---[ ][.]which\n/msx;
  is($testrc, guarded("some content\n"), 'fragment applied');
  my ($which) = $out =~ m/^---[ ][.]which\n(.*?)^---[ ]end\n/msx;
  is($which, guarded("has sh\n"), 'fragment with a REQUIRE guard applied');
  return;
}

my $t = UpdateConfigTest->new;
$t->add_fragment('testrc', "FILENAME .testrc\nsome content\n");
$t->add_fragment('which', "REQUIRE which('sh') # sh not found\nFILENAME .which\nhas sh\n");

subtest 'copy of the script' => sub {
  my $config_dir = $t->config_dir;
  my $out = run_in_container(
    "-v ${script}:/opt/update_config:ro -v ${config_dir}:/root/.config/update_config:ro",
    'perl /opt/update_config');
  check_output($out);
};

subtest 'packed script' => sub {
  my $r = $t->run('--pack');
  is($r->{exit}, 0, '--pack: success');
  my $packed = catfile($t->root, 'packed.pl');
  UpdateConfigTest::write_file($packed, $r->{stdout});
  # The script reads the whole standard input, so the other commands of the
  # container don't receive anything.
  my $out = run_in_container("-i < ${packed}", 'perl -');
  check_output($out);
};

done_testing;
