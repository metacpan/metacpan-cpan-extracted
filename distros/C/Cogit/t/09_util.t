#!perl
use strict;
use warnings;
use Test::More;
use Cogit;
use Path::Class;

use Cogit::Util qw( find_git_dir current_git_dir );

for my $directory (qw(test-project test-project-packs test-project-packs2)) {
   my $dir = dir($directory);
   my $gd  = find_git_dir(dir($directory));

   is(
      $gd->absolute->stringify,
      dir($directory)->subdir('.git')->absolute->stringify,
      "Correctly resolves an .git from a repo( $directory )"
   );

}

for my $directory (qw(
   test-util/deep
   test-util/deep/.git
   test-util/deep/stage1
   test-util/deep/stage1/stage2/
   )
  ) {
   is(
      find_git_dir(dir($directory))->absolute->stringify,
      dir('test-util/deep/.git')->absolute->stringify,
      "finding .git dirs works at all tree levels ( $directory )"
   );
}

for my $directory (qw(
   test-util/bare
   test-util/bare/info
   test-util/bare/objects
   test-util/bare/refs
   test-util/bare/refs/heads
   )
  ) {
   is(
      find_git_dir(dir($directory))->absolute->stringify,
      dir('test-util/bare')->absolute->stringify,
      "finding bare dirs works at all tree levels ( $directory )"
   );
}

use Cwd qw( getcwd );

my $old_dir = getcwd;

chdir "test-util/deep/stage1";

is(
   current_git_dir()->absolute->stringify,
   dir('.')->parent->subdir('.git')->absolute->stringify,
   "Can work with CWD"
);

done_testing;
