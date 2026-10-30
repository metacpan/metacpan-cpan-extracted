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
  $t->add_fragment('vimrc', "FILENAME .vimrc\nREM A comment.\nCOMMENTS CHAR \"\n\nset nu\n");
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
  $t->add_fragment('a/file', "FILENAME .a\ncontent a\n");
  $t->add_fragment('b/file', "FILENAME .b\ncontent b\n");
  $t->run();
  is($t->read_home_file('.a'), guarded("content a\n"), 'same name in two directories: first');
  is($t->read_home_file('.b'), guarded("content b\n"), 'same name in two directories: second');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('a/file', "content a\n");
  $t->add_fragment('b/other', "FILENAME file\ncontent b\n");
  $t->add_fragment('c/skipped', "FILENAME file\nREQUIRE 0\ncontent c\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'same target and guard: failure');
  like(
    $r->{stderr},
    qr/Fragments[ ]'a\/file'[ ]and[ ]'b\/other'[ ]can't[ ]both[ ]be[ ]applied[ ]to[ ]'.*file'/x,
    'same target and guard: message');
  unlike($r->{stderr}, qr/c\/skipped/x, 'same target and guard: skipped fragment ignored');
  is($t->read_home_file('file'), undef, 'same target and guard: nothing applied');

  $t->add_fragment('b/other', "FILENAME file\nENTIRE FILE\nGUARD SUFFIX b\ncontent b\n");
  $r = $t->run();
  like($r->{stderr}, qr/can't[ ]both[ ]be[ ]applied/x, 'ENTIRE FILE on a shared target: failure');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('target [anything]', "content\n");
  $t->add_fragment('z [x]', "FILENAME target\nGUARD SUFFIX y\nother\n");
  $t->add_fragment('empty []', "empty\n");
  my $r = $t->run();
  is(
    $t->read_home_file('target'),
    guarded("content\n", undef, 'anything').guarded("other\n", undef, 'y'),
    'bracket suffix removed from the target name and used as default guard suffix');
  like($r->{stdout}, qr/^Updated:[ ]target[ ][(]anything[)]$/mx, 'default guard suffix reported');
  is($t->read_home_file('empty'), guarded("empty\n"), 'empty brackets: no guard suffix');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('[a]/plain', "plain\n");
  $t->add_fragment('dir [a]/sub/sub [b]/nested [c]', "nested\n");
  $t->add_fragment('[a]/other [b]/overridden', "GUARD SUFFIX own\noverridden\n");
  $t->run();
  is($t->read_home_file('plain'), guarded("plain\n", undef, 'a'), 'guard suffix from a directory');
  is(
    $t->read_home_file('nested'),
    guarded("nested\n", undef, 'a-b-c'),
    'guard suffixes from directories and name joined');
  is(
    $t->read_home_file('overridden'),
    guarded("overridden\n", undef, 'own'),
    'guard suffix from directories overridden');
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
  my $abs_dir = catfile($t->root, 'abs');
  $t->add_fragment('file [x]', "DIR .config/app\ncontent\n");
  $t->add_fragment('other', "DIR .config/app\nFILENAME sub/renamed\nGUARD SUFFIX y\nother\n");
  $t->add_fragment('absolute', "DIR ${abs_dir}\nabsolute\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'DIR: success');
  is(
    $t->read_home_file('.config/app/file'),
    guarded("content\n", undef, 'x'),
    'DIR: fragment name used');
  is(
    $t->read_home_file('.config/app/sub/renamed'),
    guarded("other\n", undef, 'y'),
    'DIR: FILENAME relative to DIR');
  is(UpdateConfigTest::read_file(catfile($abs_dir, 'absolute')),
    guarded("absolute\n"), 'DIR: absolute path');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "DIR dir\nFILENAME /etc/file\ncontent\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'DIR with an absolute FILENAME: failure');
  like(
    $r->{stderr},
    qr/FILENAME[ ]cannot[ ]be[ ]an[ ]absolute[ ]path[ ]with[ ]DIR[ ]in[ ]'file'/x,
    'DIR with an absolute FILENAME: message');

  $t->add_fragment('file', "DIR dir\nFILENAME crontab -l,crontab -\ncontent\n");
  $r = $t->run();
  like(
    $r->{stderr},
    qr/DIR[ ]cannot[ ]be[ ]used[ ]with[ ]commands[ ]in[ ]'file'/x,
    'DIR with commands: message');
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
