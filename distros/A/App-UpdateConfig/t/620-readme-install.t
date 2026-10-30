#!/usr/bin/perl

# Tests the installation command given in the README, in a fresh Docker
# container, using the current distribution instead of the one from CPAN. The
# optional modules used by MERGE must be installed and the installed program
# must work.

use strict;
use warnings;

use Test2::V0;

use File::Spec::Functions 'catdir';
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigDocker qw(skip_without_docker run_in_container);
use UpdateConfigTest;

our $VERSION = 0.01;

BEGIN { skip_without_docker() }

my $image = 'perl:5.24';
my $root = catdir($FindBin::Bin, '..');

my $readme = UpdateConfigTest::read_file(catdir($root, 'README.md'))
    // die "Cannot read README.md\n";
my ($command) = $readme =~ m/^(cpanm[ ].*)$/mx or die "No cpanm command in README.md\n";
like($command, qr/[ ]App::UpdateConfig\b/x, 'the command installs the distribution');
$command =~ s{[ ]App::UpdateConfig\b}{ /tmp/dist.tar.gz}x;

my $modules = 'Config::Tiny JSON::PP TOML::Tiny YAML::PP';

my $t = UpdateConfigTest->new;
$t->add_fragment('app', qq{FILENAME app.toml\nMERGE toml\n\n[ui]\ntheme = "dark"\n});
my $config_dir = $t->config_dir;

# The distribution tarball is built in the container, as cpanm needs its
# META.json file to find the configure dependencies.
my $container_script = <<"EOS";
cp -r /opt/src /tmp/src && cd /tmp/src && rm -rf blib Makefile MYMETA.* pm_to_blib App-UpdateConfig-*
build="cpanm -n ExtUtils::MakeMaker::CPANfile && perl Makefile.PL && make manifest && make dist"
sh -c "\$build" > /tmp/dist.log 2>&1 || { echo "Build failed"; cat /tmp/dist.log; }
mv App-UpdateConfig-*.tar.gz /tmp/dist.tar.gz && cd /
${command} > /tmp/cpanm.log 2>&1 || { echo "Install failed"; cat /tmp/cpanm.log; }
for m in ${modules}; do perl -M\$m -e1 2>/dev/null || echo "Absent: \$m"; done
update_config || echo "Script failed"
echo "--- app.toml"; cat ~/app.toml
echo "--- end"
EOS

my $out =
    run_in_container($image,
      "-v ${root}:/opt/src:ro -v ${config_dir}:/root/.config/update_config:ro",
      $container_script);
unlike($out, qr/^Build[ ]failed$/mx, 'distribution built') or diag($out);
unlike($out, qr/^Install[ ]failed$/mx, 'installation success') or diag($out);
unlike($out, qr/^Absent:/mx, 'optional modules installed') or diag($out);
unlike($out, qr/^Installing[ ]module/mx, 'no module installed by the program');
unlike($out, qr/^Script[ ]failed$/mx, 'script success') or diag($out);
my ($toml) = $out =~ m/^---[ ]app[.]toml\n(.*?)^---[ ]end\n/msx;
# The exact formatting depends on the version of TOML::Tiny.
like($toml, qr/^\[ui\]\ntheme[ ]?=[ ]?"dark"$/mx, 'MERGE fragment applied');

done_testing;
