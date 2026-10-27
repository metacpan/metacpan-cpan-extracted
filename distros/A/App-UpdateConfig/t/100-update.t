#!/usr/bin/perl

# Tests the core behavior of update_config: how fragments are written in the
# target files and the main command line flags.

use strict;
use warnings;

use Test2::V0;

use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest 'guarded';

our $VERSION = 0.01;

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('new_file', "content\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'new file: success');
  is($t->read_home_file('new_file'), guarded("content\n"), 'new file: created with guards');
  like($r->{stdout}, qr/^Updated:[ ]new_file$/mx, 'new file: reported as updated');

  $r = $t->run();
  like($r->{stdout}, qr/^Nothing[ ]to[ ]do[ ]for:[ ]new_file$/mx, 'second run: nothing to do');
  is($t->read_home_file('new_file'), guarded("content\n"), 'second run: file unchanged');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('existing', "content\n");
  $t->write_home_file('existing', "user line\n");
  $t->run();
  is(
    $t->read_home_file('existing'),
    "user line\n".guarded("content\n"),
    'appended to existing file');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('existing', "new content\n");
  $t->write_home_file('existing', "before\n".guarded("old content\n")."after\n");
  $t->run();
  is(
    $t->read_home_file('existing'),
    "before\n".guarded("new content\n")."after\n",
    'guarded content replaced, rest of the file kept');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('broken', "content\n");
  $t->write_home_file('broken', "###AUTO-CONFIG START###\nfoo\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'missing closing tag: failure');
  like($r->{stderr}, qr/Missing[ ]closing[ ]tag/x, 'missing closing tag: error message');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('a', "content a\n");
  $t->add_fragment('sub/dir/b', "content b\n");
  $t->add_fragment('.hidden', "hidden\n");
  $t->add_fragment('.hidden_dir/c', "hidden\n");
  $t->run();
  is($t->read_home_file('a'), guarded("content a\n"), 'fragment at the top-level');
  is($t->read_home_file('b'), guarded("content b\n"), 'fragment in a sub-directory');
  is($t->read_home_file('.hidden'), undef, 'hidden fragment ignored');
  is($t->read_home_file('c'), undef, 'fragment in hidden directory ignored');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "new\n");
  $t->write_home_file('file', guarded("old\n"));
  my $r = $t->run('--test', '--diff');
  is($t->read_home_file('file'), guarded("old\n"), '--test: file unchanged');
  like($r->{stdout}, qr/^Updated:[ ]file$/mx, '--test: reported as updated');
  like($r->{stdout}, qr/^Diff[ ]for:[ ]file\n.*^-old\n\+new$/msx, '--diff: diff printed');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "content\n");
  my $r = $t->run('--silent');
  is($r->{stdout}, q{}, '--silent: no output');
  is($t->read_home_file('file'), guarded("content\n"), '--silent: file written');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "content\n");
  $t->add_fragment('other', "FILENAME some/path\ncontent\n");
  my $r = $t->run('--list', '--silent');
  is(
    $r->{stdout},
    $t->home_path('file')."\n".$t->home_path('some/path')."\n",
    '--list: list of targets');
  is($t->read_home_file('file'), undef, '--list: nothing written');
}

{
  my $t = UpdateConfigTest->new;
  my $r = $t->run('--help');
  is($r->{exit}, 0, '--help: success');
  like($r->{stdout}, qr/--pack/x, '--help: prints the options');
  $r = $t->run('--unknown-flag');
  is($r->{exit}, 2, 'unknown flag: failure');
  $r = $t->run('argument');
  is($r->{exit}, 2, 'positional argument: failure');
}

done_testing;
