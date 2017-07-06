BEGIN { $ENV{GIT_SHIP_SILENT} //= 1 }

package t::Util;

use strict;
use warnings;
use File::Path 'remove_tree';
use Test::More;
use Cwd ();

sub mock_git {
  $ENV{PATH} ||= '';

  for my $p (split /:/, $ENV{PATH}) {
    next unless -x "$p/git";
    $ENV{GIT_REAL_BIN} = "$p/git";
    $ENV{PATH} = join ':', File::Spec->catdir(Cwd::getcwd, 't/bin'), $ENV{PATH};
    return 1 unless system 'git _';    # test t/bin/git
  }

  plan skip_all => 'Could not find git in PATH';
}

sub goto_workdir {
  my ($class, $workdir, $create) = @_;
  my $base = 'workdir';

  plan skip_all => "Cannot test on $^O" if $^O eq 'MSWin32';
  $class->mock_git unless $ENV{GIT_REAL_BIN};
  $class->test_git($ENV{GIT_REAL_BIN});
  $create //= 1;

  mkdir $base unless -d $base;
  chdir $base or plan skip_all => "Could not chdir to $base";
  remove_tree $workdir if -d $workdir;

  if ($create) {
    mkdir $workdir;
    chdir $workdir or plan skip_all => "Could not chdir to $workdir";
    unlink 'git.log';
  }

  diag "Workdir is $base/$workdir";
}

sub test_file {
  my ($class, $file, @rules) = @_;
  my ($FH, $txt);

  unless (open $FH, '<', $file) {
    ok 0, "The file $file is missing";
    return;
  }

  $txt = do { local $/; <$FH>; };
  for my $rule (@rules) {
    like $txt, $rule, "File $file match $rule";
  }
}

sub test_file_lines {
  my ($class, $file) = (shift, shift);
  my ($FH, @extra, @re);
  my %lines = map { $_ => 1 } grep { ref $_ ? (push @re, $_)[2] : $_ } @_;

  unless (open $FH, '<', $file) {
    ok 0, "The file $file is missing";
    return;
  }

LINE:
  while (<$FH>) {
    chomp;
    for my $re (@re) { next LINE if $_ =~ $re; }
    delete $lines{$_} or push @extra, $_;
  }

  is_deeply \@extra, [], "The file $file has no extra lines" or diag join ', ', @extra;
  is_deeply [keys %lines], [], "The file $file has no missing lines"
    or diag join ', ', sort keys %lines;
}

sub test_git {
  my ($class, $git) = @_;
  my $output;

  $output = qx{$git --version 2>/dev/null};
  $output =~ s![\n\r]!!g;
  plan skip_all => "Invalid git: $output" unless $output =~ qr{\b\s+version\s+\d};
  plan skip_all => "Unsupported git version: $output" if $output =~ qr{\s1\.4};
  diag "git --version: $output" unless $output =~ /\b(1\.9|2\.[0123])/;
  $output = qx{git config --global --get-regexp user.* 2>/dev/null};
  $output =~ s![\n\r]!!g;
  plan skip_all => "Cannot run with unknown git user: $output"
    unless $output =~ /user\.email/ and $output =~ /user\.name/;
}

sub import {
  my $class  = shift;
  my $caller = caller;

  strict->import;
  warnings->import;
  eval "package $caller; use Test::More;1" or die $@;
}

1;
