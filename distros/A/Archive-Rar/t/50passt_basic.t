use strict;
use Test::More tests => 3;
use Cwd;
use File::Spec;

BEGIN {
  use_ok('Archive::Rar::Passthrough');
}

my $rar = Archive::Rar::Passthrough->new();
SKIP: {
  skip "'rar' command not found. Skipping tests.", 1, if not defined $rar;

  isa_ok($rar, 'Archive::Rar::Passthrough');
}

my $datadir = File::Spec->catdir("t", "data");
my $datafile = File::Spec->catfile($datadir, 'test.rar');
if (not -f $datafile) {
  $datadir = 'data';
  $datafile = File::Spec->catfile($datadir, 'test.rar');
}
ok(-f $datafile, "Test archive found");



1;
