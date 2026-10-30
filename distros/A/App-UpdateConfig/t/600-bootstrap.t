#!/usr/bin/perl

# Tests the bootstrapping of a new host, in a fresh Docker container that has
# Perl but none of the modules required by the script. The script must install
# the modules (with cpanm, or with cpan when cpanm is not available) and then
# apply the fragments. This is tested both with a copy of the script and with a
# packed script executed through `perl -` (as with ssh).

use strict;
use warnings;

use Test2::V0;

use File::Spec::Functions 'catfile';
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigDocker qw(skip_without_docker run_in_container);
use UpdateConfigTest 'guarded';

our $VERSION = 0.01;

BEGIN { skip_without_docker() }

# The oldest supported Perl version. This image does not have any of the
# non-core modules used by the script, but it has `make`, which is needed to
# install them, as well as cpanm.
my $image = 'perl:5.24';

my $script = catfile($FindBin::Bin, '..', 'script', 'update_config');
my $modules = join ' ', @UpdateConfigDocker::MODULES;

# Runs the given command in a fresh container, after the given setup command,
# and between a check that the modules are not installed and a check that they
# are installed. Then prints the content of the files that should have been
# written by the script. Returns the output of the container.
sub run_test {
  my ($docker_args, $setup, $command) = @_;
  my $container_script = <<"EOS";
${setup}
for m in ${modules}; do perl -M\$m -e1 2>/dev/null && echo "Before: \$m present"; done
${command} || echo "Script failed"
for m in ${modules}; do perl -M\$m -e1 2>/dev/null || echo "After: \$m absent"; done
echo "--- .testrc"; cat ~/.testrc
echo "--- .which"; cat ~/.which
echo "--- end"
EOS
  return run_in_container($image, $docker_args, $container_script);
}

# Checks the output of run_test, where the modules should have been installed
# by the given installer.
sub check_output {
  my ($out, $installer) = @_;
  unlike($out, qr/^Before:/mx, 'modules not present in the initial image');
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  unlike($out, qr/^After:/mx, 'modules installed') or diag($out);
  like(
    $out,
    qr/^Installing[ ]module[ ]'File::Slurp'[ ]with[ ]\Q${installer}\E$/mx,
    "modules installed with ${installer}");
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
my $config_dir = $t->config_dir;
my $mounts = "-v ${script}:/opt/update_config:ro -v ${config_dir}:/root/.config/update_config:ro";

subtest 'copy of the script, with cpanm' => sub {
  my $out = run_test($mounts, q{}, 'perl /opt/update_config');
  check_output($out, 'cpanm');
};

subtest 'copy of the script, with cpan' => sub {
  my $out = run_test($mounts, 'rm /usr/local/bin/cpanm', 'perl /opt/update_config');
  check_output($out, 'cpan');
};

subtest 'packed script' => sub {
  my $r = $t->run('--pack');
  is($r->{exit}, 0, '--pack: success');
  my $packed = catfile($t->root, 'packed.pl');
  UpdateConfigTest::write_file($packed, $r->{stdout});
  # The script reads the whole standard input, so the other commands of the
  # container don't receive anything.
  my $out = run_test("-v ${packed}:/opt/packed.pl:ro", q{}, 'perl - < /opt/packed.pl');
  check_output($out, 'cpanm');
};

done_testing;
