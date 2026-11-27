use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

{
  package Test::TempDirConsumer;
  use Role::Tiny::With;
  with 'CLI::Simple::TempDir';
  sub new { my ($class) = @_; return bless {}, $class; }
}

{
  package Test::TempDirNoAccessor;
  use Role::Tiny::With;
  with 'CLI::Simple::TempDir';
  sub new { my ($class) = @_; return bless {}, $class; }
}

subtest 'accessors, directory ownership and recursive cleanup' => sub {
  my $obj = Test::TempDirConsumer->new;
  my $path = $obj->create_temp_dir(accessor => 'workspace');
  ok(-d $path, 'directory created');
  is($obj->get_workspace, $path, 'accessor exposes path');
  my $nested = File::Spec->catdir($path, 'nested');
  make_path($nested);
  my $child = File::Spec->catfile($nested, 'data.txt');
  open my $fh, '>', $child or die $!;
  print {$fh} "test\n";
  close $fh;
  ok(-f $child, 'directory contains application-created file');
  $obj->set_workspace('other');
  undef $obj;
  ok(!-e $path, 'original directory and contents removed after destruction');
};

subtest 'multiple directories, independent cleanup flags' => sub {
  my $obj = Test::TempDirConsumer->new;
  my $a = $obj->create_temp_dir(accessor => 'first');
  my $b = $obj->create_temp_dir(accessor => 'second', cleanup => 0);
  isnt($a, $b, 'different paths');
  is($obj->get_first, $a, 'first accessor');
  is($obj->get_second, $b, 'second accessor');
  undef $obj;
  ok(!-e $a, 'cleaned directory removed');
  ok(-d $b, 'persistent directory remains');
  rmdir $b or die $!;
};

subtest 'no accessors on hash-based object' => sub {
  my $obj = Test::TempDirNoAccessor->new;
  my $path = $obj->create_temp_dir(no_accessors => 1);
  ok(-d $path, 'created');
  ok(!$obj->can('get_temp_dir'), 'no accessor generated');
  undef $obj;
  ok(!-e $path, 'directory removed');
};

subtest 'creation in configured parent' => sub {
  my $parent = tempdir(CLEANUP => 1);
  my $obj = Test::TempDirConsumer->new;
  my $path = $obj->create_temp_dir(dir => $parent, template => 'work-XXXXXXXX');
  like($path, qr{\Q$parent\E/work-[^/]+\z}, 'path uses specified parent and template');
  undef $obj;
  ok(!-e $path, 'cleanup removes child but not parent');
  ok(-d $parent, 'parent preserved');
};

subtest 'validation and collision' => sub {
  my $obj = Test::TempDirConsumer->new;
  eval { $obj->create_temp_dir(accessor => 'bad-name') };
  like($@, qr/Invalid accessor name/, 'invalid accessor');
  eval { $obj->create_temp_dir(accessor => 'x', no_accessors => 1) };
  like($@, qr/cannot be combined/, 'conflicting settings');
  eval { $obj->create_temp_dir(cleanup => 2) };
  like($@, qr/cleanup must be/, 'cleanup validation');
  eval { $obj->create_temp_dir(rogue => 1) };
  like($@, qr/Unknown temporary directory attribute/, 'unknown field');
};

subtest 'per-instance ownership' => sub {
  my $one = Test::TempDirConsumer->new;
  my $two = Test::TempDirConsumer->new;
  my $a = $one->create_temp_dir;
  my $b = $two->create_temp_dir;
  undef $one;
  ok(!-e $a, 'first removed');
  ok(-d $b, 'second still present');
  undef $two;
  ok(!-e $b, 'second removed');
};

done_testing;
1;
