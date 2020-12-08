use strict;
use warnings;
use Test::More;

use App::Aphra;
use App::Aphra::File;

my $app = App::Aphra->new;

my $file = App::Aphra::File->new({
  app  => $app,
  path => 'foo/bar',
  name => 'test',
  extension => 'txt',
});

is($file->path, 'foo/bar', 'Path is correct');
is($file->name, 'test', 'Name is correct');
is($file->extension, 'txt', 'Extension is correct');
is($file->destination_dir, 'foo/bar', 'Destination directory is correct');
is($file->template_name, 'foo/bar/test.txt', 'Template name is correct');
is($file->output_name, 'foo/bar/test', 'Output name is correct');
is($file->full_name, 'foo/bar/test.txt', 'Full name is correct');

ok(!$file->is_template, 'File 1 is not a template');

my $file2 = App::Aphra::File->new({
  app => $app,
  filename => 'foo/bar/test.tt'
});

is($file2->path, 'foo/bar', 'Path is correct');
is($file2->name, 'test', 'Name is correct');
is($file2->extension, 'tt', 'Extension is correct');
is($file->destination_dir, 'foo/bar', 'Destination directory is correct');
is($file->template_name, 'foo/bar/test.txt', 'Template name is correct');
is($file->output_name, 'foo/bar/test', 'Output name is correct');
is($file->full_name, 'foo/bar/test.txt', 'Full name is correct');

ok($file2->is_template, 'File 2 is a template');

done_testing;
