#!/usr/bin/perl

# Tests the directory from which the configuration fragments are read.

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
  $t->add_fragment('file', "content\n");
  my $r = $t->run();
  my $dir = $t->config_dir;
  like(
    $r->{stdout},
    qr/\AReading[ ]configuration[ ]from:[ ]\Q${dir}\E$/mx,
    'default directory printed first');
  is($t->read_home_file('file'),
    guarded("content\n"), 'fragment from ~/.config/update_config applied');
}

{
  my $t = UpdateConfigTest->new;
  my $xdg = catfile($t->root, 'xdg');
  my $dir = catfile($xdg, 'update_config');
  UpdateConfigTest::write_file(catfile($dir, 'file'), "content\n");
  $t->add_fragment('ignored', "content\n");
  my $r = $t->run({env => {XDG_CONFIG_HOME => $xdg}});
  like(
    $r->{stdout},
    qr/\AReading[ ]configuration[ ]from:[ ]\Q${dir}\E$/mx,
    'XDG_CONFIG_HOME: directory printed');
  is($t->read_home_file('file'), guarded("content\n"), 'XDG_CONFIG_HOME: fragment applied');
  is($t->read_home_file('ignored'), undef, 'XDG_CONFIG_HOME: ~/.config/update_config ignored');
}

{
  my $t = UpdateConfigTest->new;
  my $xdg = catfile($t->root, 'xdg');
  my $dir = $t->home_path('.update_config');
  $t->write_home_file('.update_config/file', "content\n");
  $t->add_fragment('ignored', "content\n");
  UpdateConfigTest::write_file(catfile($xdg, 'update_config', 'ignored_xdg'), "content\n");
  my $r = $t->run({env => {XDG_CONFIG_HOME => $xdg}});
  like(
    $r->{stdout},
    qr/\AReading[ ]configuration[ ]from:[ ]\Q${dir}\E$/mx,
    '~/.update_config: directory printed');
  is($t->read_home_file('file'), guarded("content\n"), '~/.update_config: fragment applied');
  is($t->read_home_file('ignored'), undef, '~/.update_config: ~/.config/update_config ignored');
  is($t->read_home_file('ignored_xdg'), undef, '~/.update_config: XDG_CONFIG_HOME ignored');

  my $other = catfile($t->root, 'other_dir');
  UpdateConfigTest::write_file(catfile($other, 'other'), "content\n");
  $r = $t->run('--dir', $other);
  like(
    $r->{stdout},
    qr/\AReading[ ]configuration[ ]from:[ ]\Q${other}\E$/mx,
    '~/.update_config: --dir takes precedence');
}

{
  my $t = UpdateConfigTest->new;
  my $dir = catfile($t->root, 'other_dir');
  UpdateConfigTest::write_file(catfile($dir, 'file'), "content\n");
  $t->add_fragment('ignored', "content\n");
  my $r = $t->run('--dir', $dir);
  like(
    $r->{stdout},
    qr/\AReading[ ]configuration[ ]from:[ ]\Q${dir}\E$/mx,
    '--dir: directory printed');
  is($t->read_home_file('file'), guarded("content\n"), '--dir: fragment applied');
  is($t->read_home_file('ignored'), undef, '--dir: default directory ignored');
}

{
  my $t = UpdateConfigTest->new;
  my $dir = catfile($t->root, 'missing');
  my $r = $t->run({env => {XDG_CONFIG_HOME => $dir}});
  is($r->{exit}, 0, 'missing directory: success');
}

{
  my $t = UpdateConfigTest->new;
  my $r = $t->run('--pack');
  is($r->{stderr}, q{}, '--pack: directory not printed');
  like($r->{stdout}, qr/\A#!/x, '--pack: STDOUT starts with the script');
}

done_testing;
