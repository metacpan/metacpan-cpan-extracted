#!/usr/bin/perl

# Tests the BASE, MIRROR and MIRROR CONTENTS directives, which set the base
# directory of the targets and use the structure of the configuration directory
# for them.

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
  my $abs = catfile($t->root, 'abs');
  $t->add_fragment('some_dir/.update_config', "BASE bar\nMIRROR\n");
  $t->add_fragment('some_dir/top', "top\n");
  $t->add_fragment('some_dir/foo/bin.yaml', "bin\n");
  $t->add_fragment('some_dir/foo [linux]/x [work]', "x\n");
  $t->add_fragment('some_dir/foo/a', "FILENAME other\na\n");
  $t->add_fragment('some_dir/foo/b', "DIR etc\nb\n");
  $t->add_fragment('some_dir/foo/c', "DIR ${abs}\nc\n");
  $t->add_fragment('some_dir/foo/d', "FILENAME ${abs}/d\nd\n");
  $t->add_fragment('some_dir/foo/e', "FILENAME ~/e\ne\n");
  $t->add_fragment('some_dir/foo/f', "DIR ~/home_dir\nf\n");
  $t->add_fragment('some_dir/dot_config/dot_file [g]', "file\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'MIRROR: success');
  is($t->read_home_file('bar/some_dir/top'),
    guarded("top\n"), 'MIRROR: top-level fragment, in the directory where MIRROR is set');
  is($t->read_home_file('bar/some_dir/foo/bin.yaml'), guarded("bin\n"), 'MIRROR: directory kept');
  is(
    $t->read_home_file('bar/some_dir/foo/x'),
    guarded("x\n", undef, 'LINUX-WORK'),
    'MIRROR: guard suffixes removed from the directories and the name');
  is($t->read_home_file('bar/some_dir/foo/other'),
    guarded("a\n"), 'MIRROR: FILENAME replaces the name');
  is($t->read_home_file('bar/etc/b'), guarded("b\n"), 'MIRROR: DIR relative to BASE');
  is(UpdateConfigTest::read_file(catfile($abs, 'c')), guarded("c\n"), 'MIRROR: absolute DIR');
  is(UpdateConfigTest::read_file(catfile($abs, 'd')), guarded("d\n"), 'MIRROR: absolute FILENAME');
  is($t->read_home_file('e'), guarded("e\n"), 'MIRROR: FILENAME relative to the home directory');
  is($t->read_home_file('home_dir/f'), guarded("f\n"),
    'MIRROR: DIR relative to the home directory');
  is(
    $t->read_home_file('bar/some_dir/.config/.file'),
    guarded("file\n", undef, 'G'),
    'MIRROR: dot_ prefixes replaced');
  like(
    $r->{stdout},
    qr{^Updated:[ ]bar/some_dir/foo/x[ ][(]LINUX-WORK[)]$}mx,
    'MIRROR: target reported');
}

{
  my $t = UpdateConfigTest->new;
  my $abs = catfile($t->root, 'abs');
  $t->add_fragment('.update_config', "BASE .config\n");
  $t->add_fragment('root', "root\n");
  $t->add_fragment('fish', "FILENAME fish/config.fish\nfish\n");
  $t->add_fragment('a/.update_config', "BASE app\n");
  $t->add_fragment('a/nested', "nested\n");
  $t->add_fragment('a/b/.update_config', "BASE sub\n");
  $t->add_fragment('a/b/deeper', "BASE deeper\ndeeper\n");
  $t->add_fragment('a/home/.update_config', "BASE ~/home\n");
  $t->add_fragment('a/home/home', "home\n");
  $t->add_fragment('a/abs/.update_config', "BASE ${abs}\n");
  $t->add_fragment('a/abs/abs', "DIR dir\nabs\n");
  $t->add_fragment('a/tilde/.update_config', "BASE ~\n");
  $t->add_fragment('a/tilde/tilde', "tilde\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'BASE: success');
  is($t->read_home_file('.config/root'), guarded("root\n"), 'BASE: default name');
  is($t->read_home_file('.config/fish/config.fish'), guarded("fish\n"), 'BASE: FILENAME');
  is($t->read_home_file('.config/app/nested'), guarded("nested\n"), 'BASE: relative to BASE');
  is($t->read_home_file('.config/app/sub/deeper/deeper'),
    guarded("deeper\n"), 'BASE: nested several times');
  is($t->read_home_file('home/home'), guarded("home\n"), 'BASE: relative to the home directory');
  is($t->read_home_file('tilde'), guarded("tilde\n"), 'BASE: the home directory');
  is(UpdateConfigTest::read_file(catfile($abs, 'dir', 'abs')), guarded("abs\n"), 'BASE: absolute');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('.update_config', "MIRROR\n");
  $t->add_fragment('dir/file', "file\n");
  $t->add_fragment('sub/.update_config', "DIR fixed\n");
  $t->add_fragment('sub/x/file', "FILENAME fixed_file\nfile\n");
  $t->add_fragment('sub/x/y/.update_config', "MIRROR\n");
  $t->add_fragment('sub/x/y/z/file', "FILENAME mirrored_file\nfile\n");
  $t->add_fragment('own/a/file', "MIRROR\nFILENAME own_file\nfile\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'DIR and MIRROR: success');
  is($t->read_home_file('dir/file'),
    guarded("file\n"), 'MIRROR from the root, which is not mirrored');
  is($t->read_home_file('fixed/fixed_file'), guarded("file\n"), 'DIR replaces MIRROR');
  is($t->read_home_file('y/z/mirrored_file'), guarded("file\n"), 'MIRROR replaces DIR');
  is($t->read_home_file('a/own_file'),
    guarded("file\n"), 'MIRROR in a fragment, with the directory of the fragment');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('[linux]/.update_config', "MIRROR CONTENTS\n");
  $t->add_fragment('[linux]/file', "file\n");
  $t->add_fragment('m/.update_config', "MIRROR\n");
  $t->add_fragment('m/[linux]/own', "DIR dir\nown\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'MIRROR with a directory that is only a guard suffix: success');
  is($t->read_home_file('file'), guarded("file\n", undef, 'LINUX'),
    'directory where MIRROR is set');
  is($t->read_home_file('dir/own'), guarded("own\n", undef, 'LINUX'), 'mirrored path unused');

  $t->add_fragment('m/[linux]/file', "file\n");
  $r = $t->run();
  isnt($r->{exit}, 0, 'MIRROR with a directory that is only a guard suffix: failure');
  like(
    $r->{stderr},
    qr{Cannot[ ]use[ ]'\[linux\]'[ ]in[ ]the[ ]target[ ]of[ ]'m/\[linux\]/file'}x,
    'MIRROR with a directory that is only a guard suffix: message');

  $t->add_fragment('m/[linux]/file', "DIR dir\nfile\n");
  $t->add_fragment('[linux]/.update_config', "MIRROR\n");
  $r = $t->run();
  isnt($r->{exit}, 0, 'MIRROR set in a directory that is only a guard suffix: failure');
  like(
    $r->{stderr},
    qr{Cannot[ ]use[ ]'\[linux\]'[ ]in[ ]the[ ]target[ ]of[ ]'\[linux\]/file'}x,
    'MIRROR set in a directory that is only a guard suffix: message');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('dir/.update_config', "DIR x\nMIRROR\n");
  $t->add_fragment('dir/file', "file\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'DIR and MIRROR in the same file: failure');
  like(
    $r->{stderr},
    qr{DIR[ ]and[ ]MIRROR[ ]cannot[ ]be[ ]used[ ]together[ ]in[ ]'dir/[.]update_config'}x,
    'DIR and MIRROR in the same file: message');

  $t->add_fragment('dir/.update_config', "MIRROR CONTENTS\nDIR x\n");
  $r = $t->run();
  like(
    $r->{stderr},
    qr{DIR[ ]and[ ]MIRROR[ ]cannot[ ]be[ ]used[ ]together[ ]in[ ]'dir/[.]update_config'}x,
    'DIR and MIRROR CONTENTS in the same file: message');

  $t->add_fragment('dir/.update_config', "MIRROR\nFILENAME /etc/file\n");
  $r = $t->run();
  like(
    $r->{stderr},
    qr/FILENAME[ ]cannot[ ]be[ ]an[ ]absolute[ ]path[ ]with[ ]MIRROR/x,
    'MIRROR with an absolute FILENAME in the same file: message');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('dot_config [c]/.update_config', "MIRROR\n");
  $t->add_fragment('dot_config [c]/app/rc', "rc\n");
  $t->add_fragment('dot_config [c]/contents/.update_config', "MIRROR CONTENTS\n");
  $t->add_fragment('dot_config [c]/contents/sub/file', "file\n");
  $t->add_fragment('dot_config [c]/contents/top', "top\n");
  $t->add_fragment('dot_config [c]/contents/own/a/file', "MIRROR\nown\n");
  $t->add_fragment('cfg/.update_config', "BASE .cfg\nMIRROR CONTENTS\n");
  $t->add_fragment('cfg/fish/config.fish', "fish\n");
  $t->add_fragment('cfg/own/b/file', "MIRROR CONTENTS\nown\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'MIRROR CONTENTS: success');
  is(
    $t->read_home_file('.config/app/rc'),
    guarded("rc\n", undef, 'C'),
    'MIRROR: guard suffix and dot_ prefix removed from the directory where it is set');
  is(
    $t->read_home_file('sub/file'),
    guarded("file\n", undef, 'C'),
    'MIRROR CONTENTS replaces MIRROR');
  is(
    $t->read_home_file('top'),
    guarded("top\n", undef, 'C'),
    'MIRROR CONTENTS: fragment in the directory where it is set');
  is($t->read_home_file('a/file'), guarded("own\n", undef, 'C'), 'MIRROR replaces MIRROR CONTENTS');
  is($t->read_home_file('.cfg/fish/config.fish'), guarded("fish\n"), 'MIRROR CONTENTS with BASE');
  is($t->read_home_file('.cfg/file'), guarded("own\n"), 'MIRROR CONTENTS in a fragment');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('dir/dot_bashrc', "bashrc\n");
  $t->add_fragment('dot_dir/dot_profile [p]', "profile\n");
  $t->add_fragment('dot_other', "FILENAME dot_named\nother\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'dot_ without MIRROR: success');
  is($t->read_home_file('.bashrc'), guarded("bashrc\n"), 'dot_ prefix replaced in the name');
  is(
    $t->read_home_file('.profile'),
    guarded("profile\n", undef, 'P'),
    'dot_ prefix replaced in a name with a guard suffix');
  is($t->read_home_file('dot_named'), guarded("other\n"), 'dot_ prefix kept in FILENAME');
  like($r->{stdout}, qr/^Updated:[ ][.]bashrc$/mx, 'dot_ prefix: target reported');
}

done_testing;
