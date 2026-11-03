#!/usr/bin/perl

# Tests that the ENTIRE FILE fragments don't overwrite the modifications made
# to their target since they were last applied, unless --force is used.

use strict;
use warnings;

use Test2::V0;

use File::Spec::Functions 'catfile';
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest 'guarded';

our $VERSION = 0.01;

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "ENTIRE FILE\nv1\n");
  $t->add_fragment('other', "other\n");
  $t->write_home_file('file', "existing\n");
  my $r = $t->run();
  is($t->read_home_file('file'), "v1\n", 'without a saved state: target overwritten');

  $t->add_fragment('file', "ENTIRE FILE\nv2\n");
  $r = $t->run();
  is($t->read_home_file('file'), "v2\n", 'unmodified target: updated');

  $t->write_home_file('file', "v2\nlocal change\n");
  $t->add_fragment('file', "ENTIRE FILE\nv3\n");
  $t->add_fragment('other', "other 2\n");
  $r = $t->run();
  is($r->{exit}, 0, 'modified target: success');
  is($t->read_home_file('file'), "v2\nlocal change\n", 'modified target: not overwritten');
  like(
    $r->{stderr},
    qr/^Skipping[ ]file,[ ]which[ ]was[ ]modified[ ]since[ ]its[ ]last[ ]update[ ][(]use[ ]--force/mx,
    'modified target: reported');
  like($r->{stderr}, qr/^\+local[ ]change$/mx, 'modified target: modifications printed');
  unlike($r->{stdout}, qr/^Updated:[ ]file$/mx, 'modified target: not reported as updated');
  is($t->read_home_file('other'), guarded("other 2\n"), 'modified target: others applied');

  $r = $t->run('--silent');
  like($r->{stderr}, qr/^Skipping[ ]file/mx, 'modified target: reported with --silent');

  $r = $t->run('--test');
  like($r->{stderr}, qr/^Skipping[ ]file/mx, 'modified target: reported with --test');

  $t->add_fragment('other', "other 3\n");
  $r = $t->run('--force');
  is($r->{exit}, 0, '--force: success');
  is($t->read_home_file('file'), "v3\n", '--force: overwritten');
  is($r->{stderr}, '', '--force: no warning');
  like($r->{stdout}, qr/^Updated:[ ]file[ ][(]forced[)]$/mx, '--force: reported as forced');
  like($r->{stdout}, qr/^Updated:[ ]other$/mx, '--force: other fragments not forced');

  $t->add_fragment('file', "ENTIRE FILE\nv3 bis\n");
  $r = $t->run('--force');
  is($t->read_home_file('file'), "v3 bis\n", '--force on an unmodified target: updated');
  like($r->{stdout}, qr/^Updated:[ ]file$/mx, '--force on an unmodified target: not forced');

  $t->write_home_file('file', "local change\n");
  $t->add_fragment('file', "ENTIRE FILE\nv3 ter\n");
  $r = $t->run('--force', '--test');
  like($r->{stdout}, qr/^Updated:[ ]file[ ][(]forced[)]$/mx, '--force with --test: reported');
  is($t->read_home_file('file'), "local change\n", '--force with --test: not overwritten');
  $r = $t->run('--force', '--silent');
  is($r->{stdout}, '', '--force with --silent: nothing reported');
  is($t->read_home_file('file'), "v3 ter\n", '--force with --silent: overwritten');

  $t->write_home_file('file', "local change\n");
  $t->add_fragment('file', "ENTIRE FILE\nlocal change\n");
  $r = $t->run();
  like($r->{stdout}, qr/^Nothing[ ]to[ ]do[ ]for:[ ]file$/mx, 'same content: nothing to do');
  $t->add_fragment('file', "ENTIRE FILE\nv4\n");
  $r = $t->run();
  is($t->read_home_file('file'), "v4\n", 'state saved when there is nothing to do');

  unlink $t->home_path('file');
  $t->add_fragment('file', "ENTIRE FILE\nv5\n");
  $r = $t->run();
  is($t->read_home_file('file'), "v5\n", 'deleted target: written again');
  is($r->{stderr}, '', 'deleted target: no warning');
}

{
  my $t = UpdateConfigTest->new;
  my $state_dir = catfile($t->root, 'root_state');
  my $env = {env => {UPDATE_CONFIG_ROOT_STATE_DIR => $state_dir}};
  $t->add_fragment('file', "NEED ROOT\nENTIRE FILE\nv1\n");
  $t->run($env, '--root');
  is($t->read_home_file('file'), "v1\n", 'NEED ROOT: written');
  ok(-d $state_dir, 'NEED ROOT: state saved in the root state directory');

  $t->write_home_file('file', "changed\n");
  $t->add_fragment('file', "NEED ROOT\nENTIRE FILE\nv2\n");
  my $r = $t->run($env, '--no-root');
  is($r->{stderr}, '', 'NEED ROOT: not checked by the user run');
  $r = $t->run($env, '--root');
  like($r->{stderr}, qr/^Skipping[ ]file/mx, 'NEED ROOT: modified target reported');
  is($t->read_home_file('file'), "changed\n", 'NEED ROOT: not overwritten');
}

done_testing;
