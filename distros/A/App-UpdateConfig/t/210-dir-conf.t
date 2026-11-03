#!/usr/bin/perl

# Tests the .update_config files, whose directives apply to all the fragments
# of their directory.

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
  $t->add_fragment('.update_config', "REM The root.\n\nPERM 600\n");
  $t->add_fragment('app/.update_config', "DIR .config/app\nCOMMENTS CHAR ;\n");
  $t->add_fragment('app/file', "file\n");
  $t->add_fragment('app/sub/nested', "nested\n");
  $t->add_fragment('app/sub/.update_config', "COMMENTS CHAR %\n");
  $t->add_fragment('app/own', "DIR .own\nPERM 640\nCOMMENTS CHAR !\nown\n");
  $t->add_fragment('other', "other\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'directory directives: success');
  is($t->read_home_file('.config/app/file'), guarded("file\n", ';'), 'directives inherited');
  is(
    $t->read_home_file('.config/app/nested'),
    guarded("nested\n", '%'),
    'directives inherited from all the directories, deeper ones win');
  is($t->read_home_file('.own/own'), guarded("own\n", '!'), 'own directives win');
  is((stat $t->home_path('.config/app/file'))[2] & oct('7777'), oct('600'), 'root directives');
  is((stat $t->home_path('.own/own'))[2] & oct('7777'), oct('640'), 'own directive over root');
  is($t->read_home_file('other'), guarded("other\n"), 'root directives without DIR');
  is($t->read_home_file('.update_config'), undef, 'directives file is not a fragment');
  unlike($r->{stdout}, qr/^(?:Updated|Nothing).*update_config/mx,
    'directives file is not reported');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('a/.update_config', "REQUIRE 1\n");
  $t->add_fragment('a/yes', "REQUIRE 1\nyes\n");
  $t->add_fragment('a/no', "REQUIRE 0 # own reason\nno\n");
  $t->add_fragment('a/b/.update_config', "REQUIRE 0 # dir reason\n");
  $t->add_fragment('a/b/c/skipped', "REQUIRE 1\nskipped\n");
  my $r = $t->run();
  is($t->read_home_file('yes'), guarded("yes\n"), 'REQUIRE: all true');
  is($t->read_home_file('no'), undef, 'REQUIRE: own guard still applies');
  is($t->read_home_file('skipped'), undef, 'REQUIRE: guard from a directory applies');
  like(
    $r->{stdout},
    qr/^Skipping[ ]skipped[ ]due[ ]to[ ]require[ ]guard:[ ]dir[ ]reason$/mx,
    'REQUIRE: reason from the directory printed');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('profile/.update_config', "FILENAME .profile\n");
  $t->add_fragment('profile/path [path]', "path\n");
  $t->add_fragment('profile/editor [editor]', "editor\n");
  $t->add_fragment('profile/own', "FILENAME .own\nown\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'FILENAME in a directory: success');
  is(
    $t->read_home_file('.profile'),
    guarded("editor\n", undef, 'EDITOR').guarded("path\n", undef, 'PATH'),
    'FILENAME in a directory: fragments in the same file');
  is($t->read_home_file('.own'), guarded("own\n"), 'FILENAME in a directory: overridden');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('[top]/dir [d]/.update_config', "GUARD SUFFIX g\n");
  $t->add_fragment('[top]/dir [d]/file [f]', "file\n");
  $t->add_fragment('[top]/dir [d]/sub [s]/nested', "nested\n");
  $t->add_fragment('[top]/dir [d]/sub [s]/own [o]', "GUARD SUFFIX own\nown\n");
  $t->add_fragment('[top]/sibling', "sibling\n");
  $t->run();
  is(
    $t->read_home_file('file'),
    guarded("file\n", undef, 'G-F'),
    'GUARD SUFFIX: replaces the suffixes of its directory and above');
  is(
    $t->read_home_file('nested'),
    guarded("nested\n", undef, 'G-S'),
    'GUARD SUFFIX: suffixes of lower directories added');
  is($t->read_home_file('own'), guarded("own\n", undef, 'OWN'), 'GUARD SUFFIX: own one wins');
  is($t->read_home_file('sibling'), guarded("sibling\n", undef, 'TOP'), 'GUARD SUFFIX: siblings');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('.update_config', "COMMENTS CHAR ;\nMERGE ARRAYS union\n");
  $t->add_fragment('plain', "plain\n");
  $t->add_fragment('merged', "FILENAME data.json\nMERGE\n{\"list\": [1]}\n");
  $t->write_home_file('data.json', qq({"list": [0]}\n));
  my $r = $t->run();
  is($r->{exit}, 0, 'inherited COMMENTS CHAR and MERGE ARRAYS: success');
  is($t->read_home_file('plain'), guarded("plain\n", ';'), 'inherited COMMENTS CHAR: used');
  like($t->read_home_file('data.json'), qr/0,\s*1/x, 'inherited MERGE ARRAYS: used with MERGE');

  $t->add_fragment('sub/.update_config', "MERGE json\nCOMMENTS CHAR %\n");
  $t->add_fragment('sub/other', "FILENAME other.json\n{}\n");
  $r = $t->run();
  isnt($r->{exit}, 0, 'COMMENTS CHAR with MERGE in a directory: failure');
  like($r->{stderr}, qr/MERGE[ ]cannot[ ]be[ ]used[ ]with[ ]COMMENTS[ ]CHAR/x, 'message');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "MERGE ARRAYS union\ncontent\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'own MERGE ARRAYS without MERGE: failure');
}

{
  my $t = UpdateConfigTest->new;
  my $abs = catfile($t->root, 'absolute');
  $t->add_fragment('.update_config', "DIR dir\n");
  $t->add_fragment('abs', "FILENAME ${abs}\nabs\n");
  $t->add_fragment('cmd', "FILENAME cat ${abs},cat > ${abs}.out\nGUARD SUFFIX c\ncmd\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'absolute FILENAME with an inherited DIR: success');
  is(UpdateConfigTest::read_file($abs), guarded("abs\n"), 'absolute FILENAME: DIR ignored');
  is(
    UpdateConfigTest::read_file("${abs}.out"),
    guarded("abs\n").guarded("cmd\n", undef, 'C'),
    'commands: DIR ignored');

}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('.update_config', "DIR dir\nFILENAME /etc/file\n");
  $t->add_fragment('file', "content\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'absolute FILENAME with DIR in the same file: failure');
  like($r->{stderr}, qr/FILENAME[ ]cannot[ ]be[ ]an[ ]absolute[ ]path[ ]with[ ]DIR/x, 'message');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('dir/.update_config', "PERM 600\nsome content\n");
  $t->add_fragment('dir/file', "content\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'content in a directives file: failure');
  like(
    $r->{stderr},
    qr{Invalid[ ]directive[ ]in[ ]'dir/[.]update_config':[ ]'some[ ]content'}x,
    'content in a directives file: message');
  is($t->read_home_file('file'), undef, 'content in a directives file: nothing applied');
}

done_testing;
