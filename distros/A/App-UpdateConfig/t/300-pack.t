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
    guarded("guarded\n", undef, 'd'),
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
    "GUARD SUFFIX x\nFILENAME .bar\nother\n",
    '--export: existing FILENAME kept and GUARD SUFFIX added');
  is(
    UpdateConfigTest::read_file(catfile($export_dir, 'dir [d]_sub')),
    "FILENAME sub\nGUARD SUFFIX d\nsub\n",
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

done_testing;
