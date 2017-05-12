use strict;
use Test::More tests => 3;
use Cwd;
use File::Spec;

BEGIN {
  use_ok('Archive::Rar');
}

my $rar = Archive::Rar->new();
diag("The following test fails if the 'rar' command isn't found.");
isa_ok($rar, 'Archive::Rar');

my $datadir = File::Spec->catdir("t", "data");
my $datafile = File::Spec->catfile($datadir, 'test.rar');
if (not -f $datafile) {
  $datadir = 'data';
  $datafile = File::Spec->catfile($datadir, 'test.rar');
}
ok(-f $datafile, "Test archive found");




1;
