#!/usr/bin/perl

# Tests where the missing modules are installed, depending on where the program
# itself is installed, in a fresh Docker container where the program is run by
# a non-root user. When the program is installed in the directories of the Perl
# installation, the modules are installed there too, through sudo. Otherwise,
# they are installed with local::lib.

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

my $image = 'perl:5.24';

my $script = catfile($FindBin::Bin, '..', 'script', 'update_config');
my $modules = join ' ', @UpdateConfigDocker::MODULES;

# The image does not have sudo, so we use a minimal replacement, which logs its
# invocations.
my $setup = <<'EOS';
cat > /tmp/sudo.c <<'EOC'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char **argv) {
  FILE *log = fopen("/tmp/sudo.log", "a");
  for (int i = 1; i < argc; ++i) fprintf(log, "%s ", argv[i]);
  fprintf(log, "\n");
  fclose(log);
  if (setgid(0) || setuid(0)) return 126;
  setenv("HOME", "/root", 1);
  execvp(argv[1], argv + 1);
  return 127;
}
EOC
gcc -std=c99 -o /usr/local/bin/sudo /tmp/sudo.c && chmod 4755 /usr/local/bin/sudo
touch /tmp/sudo.log && chmod 666 /tmp/sudo.log
# The program runs through `su -`, which resets the environment, so the option
# of cpanm set by run_in_container is also set in the login profile.
echo 'export PERL_CPANM_OPT=--notest' >> /etc/profile
cpanm -q -n local::lib
useradd -m test
mkdir -p /home/test/.config
cp -r /opt/config /home/test/.config/update_config
chown -R test /home/test
EOS

my $t = UpdateConfigTest->new;
$t->add_fragment('testrc', "FILENAME .testrc\nsome content\n");
my $config_dir = $t->config_dir;

# Runs the program, installed at the given path, in a fresh container. Returns
# the output of the container, which also reports where the modules are
# installed.
sub run_test {
  my ($install_path) = @_;
  my $container_script = <<"EOS";
${setup}
cp /opt/update_config ${install_path}
chmod 755 ${install_path}
su - test -c 'perl ${install_path}' || echo "Script failed"
echo "--- sudo"; cat /tmp/sudo.log
for m in ${modules}; do perl -M\$m -e1 2>/dev/null && echo "Global: \$m"; done
for m in ${modules}; do perl -I/home/test/perl5/lib/perl5 -M\$m -e1 2>/dev/null && echo "Local: \$m"; done
echo "--- .testrc"; cat /home/test/.testrc
echo "--- end"
EOS
  return run_in_container($image,
    "-v ${script}:/opt/update_config:ro -v ${config_dir}:/opt/config:ro",
    $container_script);
}

subtest 'installed globally' => sub {
  my $out = run_test('/usr/local/bin/update_config');
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  like($out, qr/^Installing[ ]modules[ ]globally/mx, 'global installation reported');
  unlike($out, qr/local::lib/x, 'local::lib not loaded');
  like(
    $out,
    qr/^Installing[ ]module[ ]'File::Slurp'[ ]with[ ]sudo[ ]cpanm$/mx,
    'modules installed through sudo');
  unlike($out, qr/^Installing[ ]module[ ].*[ ]with[ ]cpanm$/mx, 'no installation without sudo');
  like($out, qr{^/usr/local/bin/cpanm[ ]File::Slurp[ ]$}mx, 'sudo invoked');
  like($out, qr/^Global:[ ]File::Slurp$/mx, 'module installed globally');
  my ($testrc) = $out =~ m/^---[ ][.]testrc\n(.*?)^---[ ]end\n/msx;
  is($testrc, guarded("some content\n"), 'fragment applied');
};

subtest 'standalone copy' => sub {
  my $out = run_test('/home/test/update_config');
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  like($out, qr/^Successfully[ ]loaded[ ]local::lib$/mx, 'local::lib loaded');
  like(
    $out,
    qr/^Installing[ ]module[ ]'File::Slurp'[ ]with[ ]cpanm$/mx,
    'modules installed without sudo');
  like($out, qr/^---[ ]sudo\n^Local:/mx, 'sudo not invoked');
  unlike($out, qr/^Global:/mx, 'modules not installed globally');
  like($out, qr/^Local:[ ]File::Slurp$/mx, 'module installed with local::lib');
  my ($testrc) = $out =~ m/^---[ ][.]testrc\n(.*?)^---[ ]end\n/msx;
  is($testrc, guarded("some content\n"), 'fragment applied');
};

done_testing;
