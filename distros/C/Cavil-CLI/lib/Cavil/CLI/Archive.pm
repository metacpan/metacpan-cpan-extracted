# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

package Cavil::CLI::Archive;
use Mojo::Base -base, -signatures;

use Cavil::CLI::Util qw(have_tool md5_file);
use Mojo::File       qw(path);

has 'dir';
has excludes          => sub { [] };    # extra tar exclude patterns (from --exclude-path and .cavilignore)
has respect_gitignore => 0;

# Reproducible archive: identical content must produce identical bytes, so the same tree re-checked hashes the
# same and Cavil dedups it instead of opening a second review. Normalize the entry order and the metadata that
# otherwise varies between checkouts (mtimes, uid/gid), and use the GNU format to avoid pax headers that would
# smuggle in atime/ctime. GNU tar's own gzip is deterministic once these are set.
my @REPRODUCIBLE = qw(--format=gnu --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner);

# Pack the working tree into a gzip tarball and return its MD5. The tree is taken as it sits on disk, including
# vendored subcomponents (node_modules and the like) that .gitignore usually hides but a full legal review must
# cover; only .git and explicit excludes are dropped. --respect-gitignore is opt-in for the leaner case.
sub build ($self, $out) {
  my $dir = path($self->dir);
  die "Not a directory: $dir\n"                                                unless -d $dir;
  die "cavil-cli needs the 'tar' command, but it was not found in your PATH\n" unless have_tool('tar');

  my @cmd    = ('tar', @REPRODUCIBLE, '-czf', "$out", '--exclude=.git');
  my $ignore = $dir->child('.cavilignore');
  push @cmd, "--exclude-from=$ignore" if -f $ignore;
  push @cmd, "--exclude=$_" for @{$self->excludes};

  # Honour .gitignore through git itself: tar's own ignore handling does not understand full gitignore syntax
  # (a trailing-slash directory pattern, for one), so it would silently keep files git means to hide.
  if ($self->respect_gitignore) {
    die "cavil-cli needs the 'git' command for --respect-gitignore, but it was not found in your PATH\n"
      unless have_tool('git');
    my $q     = quotemeta "$dir";
    my @files = split /\0/, `git -C $q ls-files -z --cached --others --exclude-standard`;
    die "--respect-gitignore needs a git repository in $dir\n" if $? != 0;
    my $list = path("$out.files");
    $list->spew(join "\0", @files);
    push @cmd, '-C', "$dir", '--null', "--files-from=$list";
    my $status = system(@cmd);
    $list->remove;
    die "Failed to package $dir (tar exited @{[$status >> 8]})\n" if $status != 0;
  }
  else {
    push @cmd, '-C', "$dir", '.';
    die "Failed to package $dir (tar exited @{[$? >> 8]})\n" if system(@cmd) != 0;
  }

  return md5_file($out);
}

1;
