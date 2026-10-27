#!/usr/bin/perl

# Tests the directives that can be specified at the beginning of a fragment.

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
  $t->add_fragment('vimrc [prefix]',
    "FILENAME .vimrc\nREM A comment.\nCOMMENTS CHAR \"\n\nset nu\n");
  my $r = $t->run();
  is($t->read_home_file('.vimrc'), guarded("set nu\n", '"'), 'FILENAME, REM and COMMENTS CHAR');
  like($r->{stdout}, qr/^Updated:[ ][.]vimrc$/mx, 'the target name is reported');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('bashrc', "FILENAME .bashrc\nbase\n");
  $t->add_fragment('bashrc [os]', "FILENAME .bashrc\nGUARD SUFFIX os\nos specific\n");
  my $r = $t->run();
  is(
    $t->read_home_file('.bashrc'),
    guarded("base\n").guarded("os specific\n", undef, 'os'),
    'GUARD SUFFIX: two fragments in the same file');
  like(
    $r->{stdout},
    qr/^Updated:[ ][.]bashrc[ ][(]os[)]$/mx,
    'GUARD SUFFIX: reported with the suffix');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('target [anything]', "content\n");
  $t->run();
  is($t->read_home_file('target'),
    guarded("content\n"), 'bracket suffix removed from the target name');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "IS PREFIX\nprefix\n");
  $t->write_home_file('file', "existing\n");
  $t->run();
  is(
    $t->read_home_file('file'),
    guarded("prefix\n")."existing\n",
    'IS PREFIX: added at the beginning');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "ENTIRE FILE\nfull content\n");
  $t->write_home_file('file', "previous content\n");
  $t->run();
  is($t->read_home_file('file'), "full content\n", 'ENTIRE FILE: file replaced, without guards');
  my $r = $t->run();
  like(
    $r->{stdout},
    qr/^Nothing[ ]to[ ]do[ ]for:[ ]file$/mx,
    'ENTIRE FILE: second run does nothing');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('script', "MAKE EXECUTABLE\necho\n");
  $t->add_fragment('secret', "PERM 600\nsecret\n");
  $t->run();
  ok(-x $t->home_path('script'), 'MAKE EXECUTABLE');
  is((stat $t->home_path('secret'))[2] & oct('7777'), oct('600'), 'PERM: mode set');

  chmod oct('644'), $t->home_path('secret');
  my $r = $t->run();
  is((stat $t->home_path('secret'))[2] & oct('7777'), oct('600'), 'PERM: mode restored');
  like($r->{stdout}, qr/^Updated:[ ]secret$/mx, 'PERM: a mode change is an update');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('yes', "REQUIRE 1\nREQUIRE which('perl')\ncontent\n");
  $t->add_fragment('no', "REQUIRE 1\nREQUIRE 0 # the reason\ncontent\n");
  $t->add_fragment('no_reason', "REQUIRE 0\ncontent\n");
  my $r = $t->run();
  is($t->read_home_file('yes'), guarded("content\n"), 'REQUIRE: all guards true');
  is($t->read_home_file('no'), undef, 'REQUIRE: one guard false');
  like(
    $r->{stdout},
    qr/^Skipping[ ]no[ ]due[ ]to[ ]require[ ]guard:[ ]the[ ]reason$/mx,
    'REQUIRE: reason printed');
  like(
    $r->{stdout},
    qr/^Skipping[ ]no_reason[ ]due[ ]to[ ]require[ ]guard$/mx,
    'REQUIRE: skipped without reason');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "REQUIRE die 'oops'\ncontent\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'REQUIRE: failure on error');
  like($r->{stderr}, qr/'require'[ ]guard[ ]for[ ]file.*oops/x, 'REQUIRE: error message');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "POST UPDATE cp \$@ \$@.copy\ncontent\n");
  $t->run();
  is($t->read_home_file('file.copy'),
    guarded("content\n"), 'POST UPDATE: executed with the target path');
  unlink $t->home_path('file.copy');
  $t->run();
  is($t->read_home_file('file.copy'), undef, 'POST UPDATE: not executed without update');
}

{
  my $t = UpdateConfigTest->new;
  my $target = catfile($t->root, 'absolute');
  $t->add_fragment('file', "FILENAME ${target}\ncontent\n");
  $t->run();
  is(UpdateConfigTest::read_file($target), guarded("content\n"), 'FILENAME with an absolute path');
}

{
  my $t = UpdateConfigTest->new;
  my $in = catfile($t->root, 'pipe_in');
  my $out = catfile($t->root, 'pipe_out');
  UpdateConfigTest::write_file($in, "from pipe\n");
  $t->add_fragment('file', "FILENAME cat ${in},cat > ${out}\ncontent\n");
  $t->run();
  is(UpdateConfigTest::read_file($out), "from pipe\n".guarded("content\n"), 'pipe mode');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('root_file', "NEED ROOT\nroot\n");
  $t->add_fragment('user_file', "user\n");
  my $r = $t->run('--no-root');
  is($t->read_home_file('root_file'), undef, 'NEED ROOT: not written without --root');
  is($t->read_home_file('user_file'), guarded("user\n"), 'NEED ROOT: other fragments written');
  unlike($r->{stdout}, qr/root_file/x, 'NEED ROOT: not reported with --no-root');

  # In the tests, --root is not actually running as root (this is done by the
  # program through sudo when needed).
  unlink $t->home_path('user_file');
  $t->run('--root');
  is($t->read_home_file('root_file'), guarded("root\n"), '--root: NEED ROOT fragment written');
  is($t->read_home_file('user_file'), undef, '--root: other fragments not written');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('flag_with_value', "IS PREFIX foo\ncontent\n");
  $t->add_fragment('value_without_value', "FILENAME\ncontent\n");
  $t->add_fragment('after_content', "content\nGUARD SUFFIX foo\n");
  $t->add_fragment('blank_lines', "\n\nREM comment\n\nPERM 600\n\n\ncontent\n\n\n");
  $t->run();
  is(
    $t->read_home_file('flag_with_value'),
    guarded("IS PREFIX foo\ncontent\n"),
    'flag directive with a value is content');
  is(
    $t->read_home_file('value_without_value'),
    guarded("FILENAME\ncontent\n"),
    'directive without its value is content');
  is(
    $t->read_home_file('after_content'),
    guarded("content\nGUARD SUFFIX foo\n"),
    'directive after the content is content');
  is($t->read_home_file('blank_lines'),
    guarded("content\n"), 'empty lines around directives and content are removed');
}

done_testing;
