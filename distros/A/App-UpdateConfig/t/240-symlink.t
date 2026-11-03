#!/usr/bin/perl

# Tests the SYMLINK directive, which makes the target of a fragment a symbolic
# link.

use strict;
use warnings;

use Test2::V0;

use File::Path 'make_path';
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest 'guarded';

our $VERSION = 0.01;

{
  my $t = UpdateConfigTest->new;
  my $link = $t->home_path('.link');
  $t->add_fragment('dot_link', "SYMLINK dest/one\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'new link: success');
  is(readlink $link, 'dest/one', 'new link: created with a relative destination');
  like($r->{stdout}, qr/^Updated:[ ][.]link$/mx, 'new link: reported');

  $r = $t->run();
  like($r->{stdout}, qr/^Nothing[ ]to[ ]do[ ]for:[ ][.]link$/mx, 'same link: nothing to do');

  $t->add_fragment('dot_link', "SYMLINK ~/dest/two\n");
  $r = $t->run('--test', '--diff');
  my $new_dest = $t->home_path('dest/two');
  like(
    $r->{stdout},
    qr/^--> [ ] dest\/one$ .* ^\+-> [ ] \Q$new_dest\E$/msx,
    '--diff: old and new destinations printed');
  is(readlink $link, 'dest/one', '--test: link not changed');

  $r = $t->run();
  is(readlink $link, $new_dest, 'other link: replaced, with ~ expanded');
  like($r->{stdout}, qr/^Updated:[ ][.]link$/mx, 'other link: reported');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "FILENAME sub/file\nSYMLINK /dest\n");
  $t->add_fragment('other', "other\n");
  $t->write_home_file('sub/file', "existing\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'regular file: success');
  is($t->read_home_file('sub/file'), "existing\n", 'regular file: not overwritten');
  like(
    $r->{stderr},
    qr/^Skipping[ ]sub\/file,[ ]which[ ]is[ ]not[ ]a[ ]symbolic[ ]link[ ][(]use[ ]--force/mx,
    'regular file: reported');
  is($t->read_home_file('other'), guarded("other\n"), 'regular file: others applied');

  $r = $t->run('--force');
  is(readlink $t->home_path('sub/file'), '/dest', '--force: replaced by the link');
  like($r->{stdout}, qr/^Updated:[ ]sub\/file[ ][(]forced[)]$/mx, '--force: reported as forced');
  is($r->{stderr}, '', '--force: no warning');

  $t->add_fragment('dir', "SYMLINK /dest\n");
  make_path($t->home_path('dir'));
  $r = $t->run('--force');
  is($r->{exit}, 0, 'directory: success');
  ok(!-l $t->home_path('dir') && -d _, 'directory: not replaced, even with --force');
  like($r->{stderr}, qr/^Skipping[ ]dir,[ ]which[ ]is[ ]a[ ]directory$/mx, 'directory: reported');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('dir/.update_config', "PERM 600\nCOMMENTS CHAR ;\nMERGE\n");
  $t->add_fragment('dir/link', "SYMLINK /dest\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'inherited incompatible directives: success');
  is(readlink $t->home_path('link'), '/dest', 'inherited incompatible directives: ignored');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('link', "SYMLINK /dest\n");
  $t->add_fragment('sub/link [other]', "content\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'same target as another fragment: failure');
  like($r->{stderr}, qr/can't[ ]both[ ]be[ ]applied/mx,
    'same target as another fragment: reported');
}

my @invalid = (
  ["SYMLINK /dest\ncontent\n", qr/cannot[ ]have[ ]any[ ]content/mx, 'with content'],
  [
    "FILENAME cat,cat\nSYMLINK /dest\n",
    qr/cannot[ ]be[ ]used[ ]with[ ]commands/mx,
    'with commands'
  ],
  map {
    [
      "SYMLINK /dest\n$_->[0]\n",
      qr/cannot[ ]be[ ]used[ ]with[ ]\Q$_->[1]\E[.]/mx,
      "with $_->[1]"
    ]
  } ['COMMENTS CHAR ;', 'COMMENTS CHAR'],
  ['ENTIRE FILE', 'ENTIRE FILE'],
  ['IS PREFIX', 'IS PREFIX'],
  ['MAKE EXECUTABLE', 'MAKE EXECUTABLE'],
  ['MERGE json', 'MERGE'],
  ['MERGE ARRAYS union', 'MERGE ARRAYS'],
  ['PERM 600', 'PERM'],
);
for my $case (@invalid) {
  my ($content, $error, $name) = @{$case};
  my $t = UpdateConfigTest->new;
  $t->add_fragment('link', $content);
  my $r = $t->run();
  isnt($r->{exit}, 0, "${name}: failure");
  like($r->{stderr}, $error, "${name}: reported");
  ok(!-l $t->home_path('link'), "${name}: no link created");
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('dir/.update_config', "SYMLINK /dest\n");
  $t->add_fragment('dir/file', "content\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'in a .update_config file: failure');
  like(
    $r->{stderr},
    qr/SYMLINK[ ]cannot[ ]be[ ]used[ ]in[ ]'dir\/[.]update_config'/mx,
    'in a .update_config file: reported');
}

done_testing;
