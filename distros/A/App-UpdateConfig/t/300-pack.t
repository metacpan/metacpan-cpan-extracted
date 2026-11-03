#!/usr/bin/perl

# Tests the --pack and --export flags, where fragments are embedded in the
# script itself.

use strict;
use warnings;

use Test2::V0;

use File::Path 'make_path';
use File::Spec::Functions 'catfile';
use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest 'guarded';

our $VERSION = 0.01;

# Returns the path of a packed script containing the given fragments.
sub pack_fragments {
  my (%fragments) = @_;
  my $t = UpdateConfigTest->new;
  $t->add_fragment($_, $fragments{$_}) for keys %fragments;
  # We run from another directory to check that the script finds itself.
  my $r = $t->run({cwd => $t->home}, '--pack');
  is($r->{exit}, 0, '--pack: success');
  is($t->read_home_file($_), undef, "--pack: ${_} not written") for keys %fragments;
  my $packed = catfile($t->root, 'packed.pl');
  UpdateConfigTest::write_file($packed, $r->{stdout});
  return ($packed, $t);
}

{
  my ($packed) = pack_fragments(
    'file' => "content\n",
    'dir [d]/guarded' => "guarded\n",
    'sub/other' => "FILENAME .other\nother\n",
    'overridden' => "packed\n");
  my $t = UpdateConfigTest->new;
  $t->add_fragment('overridden', "local\n");
  my $r = $t->run({stdin => $packed});
  is($r->{exit}, 0, 'packed script: success');
  is($t->read_home_file('file'), guarded("content\n"), 'packed fragment applied');
  is($t->read_home_file('.other'),
    guarded("other\n"), 'packed fragment from a sub-directory applied');
  is(
    $t->read_home_file('guarded'),
    guarded("guarded\n", undef, 'D'),
    'packed fragment with a guard suffix from its directory');
  is($t->read_home_file('overridden'),
    guarded("local\n"), 'local fragment overrides packed fragment');
}

{
  my ($packed) = pack_fragments('root_file' => "NEED ROOT\nroot\n");
  my $t = UpdateConfigTest->new;
  my $r = $t->run({stdin => $packed});
  is($r->{exit}, 0, 'NEED ROOT from stdin: success');
  like(
    $r->{stdout},
    qr/^Skipping[ ]NEED_ROOT[ ]fragments[ ]for[ ]an[ ]execution/mx,
    'NEED ROOT from stdin: skipped');
  is($t->read_home_file('root_file'), undef, 'NEED ROOT from stdin: not written');
  $r = $t->run({stdin => $packed}, '--pack');
  isnt($r->{exit}, 0, '--pack from stdin: failure');
}

{
  my ($packed, $t) = pack_fragments(
    'in,out' => "content\n",
    'other [x]' => "FILENAME .bar\nother\n",
    'dir [d]/sub' => "sub\n",
    'dir [d]/own [o]' => "GUARD SUFFIX own\nown\n",
    'no_newline' => 'last line');
  my $export_dir = catfile($t->root, 'export');
  make_path($export_dir);
  my $r = $t->run({script => $packed, cwd => $export_dir}, '--export');
  is($r->{exit}, 0, '--export: success');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'in_out')),
    "FILENAME in,out\ncontent\n",
    '--export: FILENAME added and name cleaned');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'other [x]')),
    "FILENAME .bar\nGUARD SUFFIX X\nother\n",
    '--export: existing FILENAME kept and GUARD SUFFIX added');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'dir [d]_sub')),
    "FILENAME sub\nGUARD SUFFIX D\nsub\n",
    '--export: GUARD SUFFIX from the directory added');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'dir [d]_own [o]')),
    "FILENAME own\nGUARD SUFFIX own\nown\n",
    '--export: existing GUARD SUFFIX kept');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'no_newline')),
    "FILENAME no_newline\nlast line\n",
    '--export: final newline added when packing');
}

{
  my ($packed, $t) = pack_fragments(
    '.update_config' => "REQUIRE 1\nPERM 600\n",
    'app [a]/.update_config' => "DIR .app\nGUARD SUFFIX g\nCOMMENTS CHAR ;\nREQUIRE 2\n",
    'app [a]/sub [s]/file' => "REM own\nREQUIRE 3\nPERM 644\nfile\n",
    'app [a]/abs' => "FILENAME /tmp/abs\nCOMMENTS CHAR %\nabs\n");
  my $u = UpdateConfigTest->new;
  my $r = $u->run({stdin => $packed});
  is($r->{exit}, 0, 'packed directory directives: success');
  is(
    $u->read_home_file('.app/file'),
    guarded("file\n", ';', 'G-S'),
    'packed directory directives: applied');

  my $export_dir = catfile($t->root, 'export');
  make_path($export_dir);
  $r = $t->run({script => $packed, cwd => $export_dir}, '--export');
  is($r->{exit}, 0, '--export with directory directives: success');
  ok(!-e catfile($export_dir, 'update_config'), '--export: directory directives not exported');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'app [a]_sub [s]_file')),
    "FILENAME .app/file\nGUARD SUFFIX G-S\nCOMMENTS CHAR ;\nREQUIRE 1\nREQUIRE 2\nREM own\n"
        ."REQUIRE 3\nPERM 644\nfile\n",
    '--export: inherited directives written');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'app [a]_abs')),
    "FILENAME /tmp/abs\nGUARD SUFFIX G\nPERM 600\nREQUIRE 1\nREQUIRE 2\nCOMMENTS CHAR %\nabs\n",
    '--export: inherited target replaced');
}

{
  my ($packed, $t) = pack_fragments(
    'cfg/.update_config' => "BASE .config\nMIRROR\n",
    'cfg/app [a]/dot_rc' => "BASE sub\nrc\n",
    'cfg/app [a]/own' => "DIR other\nFILENAME renamed\nown\n",
    'cnt/.update_config' => "MIRROR CONTENTS\n",
    'cnt/x/file' => "file\n",
    'cnt/x/own' => "MIRROR CONTENTS\nown\n");
  my $export_dir = catfile($t->root, 'export');
  make_path($export_dir);
  my $r = $t->run({script => $packed, cwd => $export_dir}, '--export');
  is($r->{exit}, 0, '--export with BASE and MIRROR: success');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'cfg_app [a]_dot_rc')),
    "FILENAME .config/sub/cfg/app/.rc\nGUARD SUFFIX A\nrc\n",
    '--export: BASE and MIRROR resolved');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'cfg_app [a]_own')),
    "FILENAME .config/other/renamed\nGUARD SUFFIX A\nown\n",
    '--export: BASE, DIR and FILENAME resolved');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'cnt_x_file')),
    "FILENAME x/file\nfile\n",
    '--export: MIRROR CONTENTS resolved');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'cnt_x_own')),
    "FILENAME own\nown\n",
    '--export: own MIRROR CONTENTS resolved');
}

done_testing;
