use strict;
use Test::More tests => 15;
use Cwd;
use File::Spec;
use File::Temp qw/tempdir/;

BEGIN {
  use_ok('Archive::Rar');
}

# temp dir
my $tmpdir = tempdir( CLEANUP => 1 );

my $olddir = cwd();
END { chdir($olddir) }
$SIG{__DIE__} = sub { chdir($olddir); die @_;};
chdir($tmpdir);

my $datafile = 'add_test.rar';
my $textfile = 'mytext.txt';
open my $fh, '>', $textfile or die $!;
print $fh <<HERE;
I am a nice little text file!
HERE
close $fh;

ok(not(-f $datafile), "output rar file does not exist yet");

my $rar = Archive::Rar->new(-verbose=>1);
isa_ok($rar, 'Archive::Rar');

is($rar->Add(-files => [$textfile], -archive => $datafile), 0, "Add() command succeeds for file '$textfile' and archive '$datafile'");
ok(-f $datafile, 'Add() creates a rar file');


TODO: {
  local $TODO = "Seems to currently fail with the legacy Archive::Rar.";

  my $archivename = $rar->{"-archive"};
  # Here, the archive name is already curropted.
  # So it seems to be that Add() puts a broken archive name in the object
  is($rar->List(), 0, "List() succeeded");
  is($rar->{"-archive"}, $archivename, "List() does not change archive name.");
  ok(-f $archivename, 'archive exists');

  my $list = $rar->{list};
  my $okay = ref($list) eq 'ARRAY' && @$list==1 && ref($list->[0]) eq 'HASH';
  ok($okay , "List structure is defined and array ref and length 1");

  if ($okay) {
    is($list->[0]{name}, $textfile, "File name is '$textfile'");
    is($list->[0]{size}, -s $textfile, "File size is correct");
  }
  else { fail; fail; } # I know...
}

is($rar->List(-archive => $datafile), 0, "List(-archive) succeeded");

my $list = $rar->{list};
my $okay = ref($list) eq 'ARRAY' && @$list==1 && ref($list->[0]) eq 'HASH';
ok($okay , "List structure is defined and array ref and length 1");

if ($okay) {
  is($list->[0]{name}, $textfile, "File name is '$textfile'");
  is($list->[0]{size}, -s $textfile, "File size is correct");
}
else { fail; fail; } # I know...


1;
