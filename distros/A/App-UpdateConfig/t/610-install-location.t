#!/usr/bin/perl

# Tests where the missing modules are installed, depending on where the program
# itself is installed, in a fresh Docker container where the program is run by
# a non-root user. When the program is installed in the directories of the Perl
# installation, the modules are installed there too, through sudo. Otherwise,
# they are installed with local::lib, and nothing is written outside of its
# directory. With --no-root, sudo is never used.

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
useradd -m test
mkdir -p /home/test/.config
cp -r /opt/config /home/test/.config/update_config
chown -R test /home/test
EOS

my $t = UpdateConfigTest->new;
$t->add_fragment('testrc', "FILENAME .testrc\nsome content\n");
my $config_dir = $t->config_dir;

# Runs the program in a fresh container and returns the output of the
# container, which also reports where the modules are installed and the files
# written outside of the home directory of the user. The arguments are:
# `install_path`, where the program is installed; `program`, the script that
# is installed (the source script by default); `command`, run by the user
# (`perl` and the installed program by default); `pre`, optional shell
# commands run before it; and `local_lib`, false to not install local::lib.
sub run_test {
  my (%args) = @_;
  my $install_path = $args{install_path};
  my $command = $args{command} // "perl ${install_path}";
  my $pre = $args{pre} // q{};
  my $program = $args{program} // $script;
  my $local_lib = ($args{local_lib} // 1) ? 'cpanm -q -n local::lib' : q{};
  my $container_script = <<"EOS";
${setup}
${local_lib}
cp /opt/update_config ${install_path}
chmod 755 ${install_path}
${pre}
touch /tmp/stamp
su - test -c '${command}' || echo "Script failed"
echo "--- outside"
find / -xdev \\( -path /proc -o -path /sys -o -path /tmp -o -path /home/test \\) -prune -o -type f -newer /tmp/stamp -print
echo "--- man"; ls /home/test/perl5/man/man3
[ -s /tmp/sudo.log ] && echo "Sudo was invoked"
echo "--- sudo"; cat /tmp/sudo.log
for m in ${modules}; do perl -M\$m -e1 2>/dev/null && echo "Global: \$m"; done
for m in ${modules}; do perl -I/home/test/perl5/lib/perl5 -M\$m -e1 2>/dev/null && echo "Local: \$m"; done
echo "--- .testrc"; cat /home/test/.testrc
echo "--- end"
EOS
  return run_in_container($image,
    "-v ${program}:/opt/update_config:ro -v ${config_dir}:/opt/config:ro",
    $container_script);
}

# Returns the files written outside of the home directory of the user, as
# reported by run_test.
sub files_outside {
  my ($out) = @_;
  my ($files) = $out =~ m/^---[ ]outside\n(.*?)^---[ ]man\n/msx;
  return $files;
}

subtest 'installed globally' => sub {
  my $out = run_test(install_path => '/usr/local/bin/update_config');
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
  my $out = run_test(install_path => '/home/test/update_config');
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  like($out, qr/^Successfully[ ]loaded[ ]local::lib$/mx, 'local::lib loaded');
  like(
    $out,
    qr/^Installing[ ]module[ ]'File::Slurp'[ ]with[ ]cpanm$/mx,
    'modules installed without sudo');
  like($out, qr/^---[ ]sudo\n^Local:/mx, 'sudo not invoked');
  unlike($out, qr/^Global:/mx, 'modules not installed globally');
  like($out, qr/^Local:[ ]File::Slurp$/mx, 'module installed with local::lib');
  is(files_outside($out), q{}, 'nothing written outside of the home directory');
  like($out, qr/^File::Slurp[.]/mx, 'man pages installed with local::lib');
  my ($testrc) = $out =~ m/^---[ ][.]testrc\n(.*?)^---[ ]end\n/msx;
  is($testrc, guarded("some content\n"), 'fragment applied');
};

subtest 'standalone copy, with cpan' => sub {
  my $out =
      run_test(install_path => '/home/test/update_config', pre => 'rm /usr/local/bin/cpanm');
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  like(
    $out,
    qr/^Installing[ ]module[ ]'File::Slurp'[ ]with[ ]cpan$/mx,
    'modules installed with cpan');
  unlike($out, qr/^Sudo[ ]was[ ]invoked$/mx, 'sudo not invoked');
  unlike($out, qr/^Global:/mx, 'modules not installed globally');
  like($out, qr/^Local:[ ]File::Slurp$/mx, 'module installed with local::lib');
  is(files_outside($out), q{}, 'nothing written outside of the home directory');
  like($out, qr/^File::Slurp[.]/mx, 'man pages installed with local::lib');
};

my $r = $t->run('--pack');
is($r->{exit}, 0, '--pack: success');
my $packed = catfile($t->root, 'packed.pl');
UpdateConfigTest::write_file($packed, $r->{stdout});
my %packed_args = (install_path => '/home/test/packed.pl', program => $packed);

subtest 'packed script with --no-root' => sub {
  # As with `ssh host perl -- - --no-root`.
  my $out = run_test(%packed_args, command => 'perl - --no-root < /home/test/packed.pl');
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  like($out, qr/^Successfully[ ]loaded[ ]local::lib$/mx, 'local::lib loaded');
  unlike($out, qr/^Sudo[ ]was[ ]invoked$/mx, 'sudo not invoked');
  like($out, qr/^Local:[ ]File::Slurp$/mx, 'module installed with local::lib');
  is(files_outside($out), q{}, 'nothing written outside of the home directory');
  my ($testrc) = $out =~ m/^---[ ][.]testrc\n(.*?)^---[ ]end\n/msx;
  is($testrc, guarded("some content\n"), 'fragment applied');
};

subtest 'failed installation with --no-root' => sub {
  # The modules can't be found by cpanm.
  my $out = run_test(%packed_args,
    command =>
        'PERL_CPANM_OPT="--mirror file:///none --mirror-only" perl - --no-root < /home/test/packed.pl'
  );
  like($out, qr/^Script[ ]failed$/mx, 'script failure');
  like(
    $out,
    qr/^Cannot[ ]install[ ]module[ ]'Data::Section::Simple'[ ]with[ ]cpanm[ ][(]not[ ]retried[ ]with[ ]sudo/mx,
    'failure reported');
  unlike($out, qr/^Installing[ ].*[ ]with[ ]sudo/mx, 'no installation with sudo');
  unlike($out, qr/^Sudo[ ]was[ ]invoked$/mx, 'sudo not invoked');
};

subtest 'installed globally, with --no-root' => sub {
  my $out = run_test(
    install_path => '/usr/local/bin/update_config',
    command => 'perl /usr/local/bin/update_config --no-root');
  like($out, qr/^Script[ ]failed$/mx, 'script failure');
  like(
    $out,
    qr/^Cannot[ ]install[ ]module[ ]'Data::Section::Simple'[ ]without[ ]sudo,[ ]which[ ]is[ ]disabled[ ]by[ ]--no-root/mx,
    'failure reported');
  unlike($out, qr/^Sudo[ ]was[ ]invoked$/mx, 'sudo not invoked');
};

subtest 'packed script with --no-root, on a host without local::lib' => sub {
  # cpan bootstraps local::lib in ~/perl5 during the first run, the second run
  # must find it there.
  my $run = 'perl - --no-root < /home/test/packed.pl';
  my $out = run_test(
    %packed_args,
    local_lib => 0,
    pre => 'rm /usr/local/bin/cpanm',
    command => "${run} && echo \"--- second run\" && ${run}");
  unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
  my ($first, $second) = $out =~ m/\A(.*)^---[ ]second[ ]run\n(.*?)^---[ ]outside\n/msx;
  like(
    $first,
    qr/^Installing[ ]module[ ]'File::Slurp'[ ]with[ ]cpan$/mx,
    'first run: modules installed');
  like(
    $first,
    qr/^Successfully[ ]loaded[ ]local::lib$/mx,
    'first run: bootstrapped local::lib loaded');
  like($second, qr/^Successfully[ ]loaded[ ]local::lib$/mx, 'second run: local::lib loaded');
  unlike($second, qr/^Installing[ ]module/mx, 'second run: nothing installed');
  unlike($out, qr/^Sudo[ ]was[ ]invoked$/mx, 'sudo not invoked');
  like($out, qr/^Local:[ ]File::Slurp$/mx, 'module installed with local::lib');
  is(files_outside($out), q{}, 'nothing written outside of the home directory');
  my ($testrc) = $out =~ m/^---[ ][.]testrc\n(.*?)^---[ ]end\n/msx;
  is($testrc, guarded("some content\n"), 'fragment applied');
};

done_testing;
