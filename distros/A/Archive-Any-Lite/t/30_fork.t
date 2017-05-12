use strict;
use warnings;
use FindBin;
use Test::More;

BEGIN {
  eval "require Parallel::ForkManager; 1" or plan skip_all => 'this test requires Parallel::ForkManager';
}

plan 'no_plan';

use Archive::Any::Lite;
use File::Temp qw/tempdir/;
use File::Path;

my $pm = Parallel::ForkManager->new(5);
my ($pass, $fail);
$pm->run_on_finish(sub {
  my ($pid, $exit, $ident, $signal, $dump, $data) = @_;
  if (ref $data eq ref []) {
    $pass += $data->[0];
    $fail += $data->[1];
  }
  else {
    $fail++;
  }
});

my $tmp = "$FindBin::Bin/tmp";
mkpath $tmp;
for my $i (1..100) {
  $pm->start and next;
  my $dir = tempdir(DIR => $tmp, CLEANUP => 1);
  my $type = qw(lib)[int(rand(1))];
  my $ext = qw(tar.gz tar.bz2 tgz zip)[int(rand(4))];

  my ($ok, $not_ok) = (0, 0);
  if (my $archive = Archive::Any::Lite->new("$FindBin::Bin/$type.$ext")) {
    note "extracting $dir/$type.$ext";
    $archive->extract($dir);
    my @files = $archive->files;
    for (@files) {
      my $file = File::Spec->catfile($dir, $_);
      if (-e $file) {
        $ok++;
      }
      else {
        $not_ok++;
        diag "[$i] $type: $file does not exist";
      }
    }
  }
  else {
    $not_ok = 1;
  }
  $pm->finish($not_ok, [$ok, $not_ok]);
}
$pm->wait_all_children;

ok !$fail, "pass: $pass fail: $fail";

rmtree $tmp;