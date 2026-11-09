#!/usr/bin/perl

# Tests the APPEND directive, which appends the content of a fragment to the
# ENTIRE FILE fragment with the same target.

use strict;
use warnings;

use Test2::V0;

use FindBin;
use lib "${FindBin::Bin}/lib";
use UpdateConfigTest 'guarded';

our $VERSION = 0.01;

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('AGENTS.md', "ENTIRE FILE\n\n# Main\n\nmain\n");
  $t->add_fragment('AGENTS.md [work]', "APPEND\n\n# Work\n\nwork\n");
  $t->add_fragment('sub/AGENTS.md [style]', "APPEND\n\n# Style\n\nstyle\n");
  $t->add_fragment('sub/AGENTS.md [empty]', "APPEND\n");
  $t->add_fragment('sub/AGENTS.md [skipped]', "APPEND\nREQUIRE 0\n\nskipped\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'appended: success');
  is(
    $t->read_home_file('AGENTS.md'),
    "# Main\n\nmain\n\n# Style\n\nstyle\n\n# Work\n\nwork\n",
    'appended: in the order of the fragments, separated by empty lines');
  is(() = $r->{stdout} =~ m/^Updated:/mg, 1, 'appended: a single update reported');

  $r = $t->run();
  like($r->{stdout}, qr/^Nothing[ ]to[ ]do[ ]for:[ ]AGENTS[.]md$/mx, 'second run: nothing to do');

  $t->add_fragment('AGENTS.md [work]', "APPEND\nREQUIRE 0\n\n# Work\n\nwork\n");
  $r = $t->run();
  is(
    $t->read_home_file('AGENTS.md'),
    "# Main\n\nmain\n\n# Style\n\nstyle\n",
    'fragment removed: file updated');
  is($r->{stderr}, '', 'fragment removed: not seen as a modification of the target');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "ENTIRE FILE\n\nmain");
  $t->add_fragment('file [a]', "APPEND\n\na\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'no final newline: success');
  is($t->read_home_file('file'), "main\n\na\n", 'no final newline: added before the empty line');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "ENTIRE FILE\n");
  $t->add_fragment('file [a]', "APPEND\n\na\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'empty ENTIRE FILE fragment: success');
  is($t->read_home_file('file'), "a\n", 'empty ENTIRE FILE fragment: no empty line added');
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('.update_config', "PERM 600\n");
  $t->add_fragment('file', "ENTIRE FILE\n\nmain\n");
  $t->add_fragment('extra/.update_config', "FILENAME file\nAPPEND\n");
  $t->add_fragment('extra/one', "one\n");
  $t->add_fragment('extra/two', "two\n");
  my $r = $t->run();
  is($r->{exit}, 0, 'in a .update_config file: success');
  is($t->read_home_file('file'), "main\n\none\n\ntwo\n", 'in a .update_config file: appended');
  ok(!-e $t->home_path('one'), 'in a .update_config file: not applied separately');
}

for my $case (
  [{}, 'without ENTIRE FILE fragment'],
  [{'file' => "REQUIRE 0\nENTIRE FILE\n\nmain\n"}, 'with a skipped ENTIRE FILE fragment'],
  [{'file' => "main\n"}, 'with a fragment without ENTIRE FILE'],
) {
  my ($fragments, $name) = @{$case};
  my $t = UpdateConfigTest->new;
  $t->add_fragment($_, $fragments->{$_}) for keys %{$fragments};
  $t->add_fragment('file [a]', "APPEND\n\na\n");
  $t->add_fragment('other', "other\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, "${name}: failure");
  like(
    $r->{stderr},
    qr/^Fragment[ ]'file[ ]\[a\]'[ ]uses[ ]APPEND,[ ]but[ ]there[ ]is[ ]no[ ]ENTIRE[ ]FILE/mx,
    "${name}: reported");
  ok(!-e $t->home_path('other'), "${name}: no fragment applied");
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "ENTIRE FILE\n\nmain\n");
  $t->add_fragment('sub/.update_config', "COMMENTS CHAR ;\nMAKE EXECUTABLE\nNEED ROOT\n");
  $t->add_fragment('sub/inner/file [a]', "APPEND\n\na\n");
  my $r = $t->run('--no-root');
  is($r->{exit}, 0, 'inherited incompatible directives: success');
  is($t->read_home_file('file'), "main\n\na\n", 'inherited incompatible directives: appended');
  ok(!-x $t->home_path('file'), 'inherited incompatible directives: ignored');
}

for my $case (
  ['COMMENTS CHAR ;', 'COMMENTS CHAR'],
  ['ENTIRE FILE', 'ENTIRE FILE'],
  ['IS PREFIX', 'IS PREFIX'],
  ['MAKE EXECUTABLE', 'MAKE EXECUTABLE'],
  ['MERGE', 'MERGE'],
  ['MERGE ARRAYS union', 'MERGE ARRAYS'],
  ['NEED ROOT', 'NEED ROOT'],
  ['PERM 600', 'PERM'],
  ['POST UPDATE true', 'POST UPDATE'],
) {
  my ($directive, $name) = @{$case};
  my $t = UpdateConfigTest->new;
  $t->add_fragment('file', "ENTIRE FILE\n\nmain\n");
  $t->add_fragment('file [a]', "APPEND\n${directive}\n\na\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, "with ${name}: failure");
  like(
    $r->{stderr},
    qr/APPEND[ ]cannot[ ]be[ ]used[ ]with[ ]\Q${name}\E[.]/mx,
    "with ${name}: reported");
  ok(!-e $t->home_path('file'), "with ${name}: nothing applied");
}

{
  my $t = UpdateConfigTest->new;
  $t->add_fragment('link', "APPEND\nSYMLINK /dest\n");
  my $r = $t->run();
  isnt($r->{exit}, 0, 'with SYMLINK: failure');
  like(
    $r->{stderr},
    qr/SYMLINK[ ]cannot[ ]be[ ]used[ ]with[ ]APPEND[.]/mx,
    'with SYMLINK: reported');
}

done_testing;
