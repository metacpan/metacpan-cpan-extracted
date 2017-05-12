use strict;
use Test::More tests => 9;
use Cwd;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Copy qw/copy/;

BEGIN {
  use_ok('Archive::Rar');
}

my $datadir = File::Spec->catdir("t", "data");
my $datafilename = 'test.rar';
my $datafile = File::Spec->catfile($datadir, $datafilename);
if (not -f $datafile) {
  $datadir = 'data';
  $datafile = File::Spec->catfile($datadir, $datafilename);
}
ok(-f $datafile, "Test archive found");

# temp dir for extraction test
my $tmpdir = tempdir( CLEANUP => 1 );
copy($datafile, $tmpdir) or die "Copying of test archive failed: $!";

my $olddir = cwd();
END { chdir($olddir) }
$SIG{__DIE__} = sub { chdir($olddir); die @_;};
chdir($tmpdir);

$datafile = $datafilename;
ok(-f $datafile, "Test archive in temp dir found.");

my $rar = Archive::Rar->new(-archive => $datafile);
isa_ok($rar, 'Archive::Rar');

is($rar->Extract(), 0, "Extract() command succeeds");
ok(-f 'README', "README was extracted");
ok(-s 'README' == 890, "README has right size"); # is this different on windows?
ok(-f 'COPYRIGHT', "COPYRIGHT was extracted");
ok(-s 'COPYRIGHT' == 183, "COPYRIGHT has right size");

1;
