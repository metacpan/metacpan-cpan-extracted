use strict;
use Test::More tests => 9+14+28;
use Cwd;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Copy qw/copy/;
use File::Basename qw/basename/;

BEGIN {
  use_ok('Archive::Rar::Passthrough');
}

sub test_passthrough_extraction {
  my $rar = shift;
  my $archive = shift;
  my $files = shift;
  
  # temp dir for extraction test
  my $tmpdir = tempdir( CLEANUP => 1 );
  copy($archive, $tmpdir) or die "Copying of test archive failed: $!";

  my $olddir = cwd();
  local $SIG{__DIE__} = sub { chdir($olddir); die @_;};
  chdir($tmpdir);

  my $localarchive = basename($archive);
  ok(-f $localarchive, "temporary copy of archive exists");

  my $errcode = $rar->run(
    command => 'e',
    archive => $localarchive,
  );
  ok(!$errcode, 'rar extract succeeded');
  
  my $out = $rar->get_stdout();
  ok(defined $out, 'get_stdout() return value defined');
  
  my $err = $rar->get_stderr();
  ok(defined $err, 'get_stderr() return value defined');

  $rar->clear_buffers();
  is($rar->get_stdout(), '', 'clear_buffers() erased stdout');
  is($rar->get_stderr(), '', 'clear_buffers() erased stderr');

  check_files_exist($files);
  delete_files($files);

  # check that specific extraction path works
  $errcode = $rar->run(
    command => 'e',
    archive => $localarchive,
    path => '.',
  );
  ok(!$errcode, 'rar extract succeeded');
  check_files_exist($files);

  # check that overwrite works
  overwrite_files_with_garbage($files);
  my $ages = get_file_ages($files);

  sleep 1;

  $errcode = $rar->run(
    command => 'e',
    archive => $localarchive,
    switches => ['-y', '-o+'],
    path => '.',
  );
  ok(!$errcode, 'rar extract succeeded');
  check_files_exist($files);

  my $new_ages = get_file_ages($files);

  foreach (0..@$new_ages-1) {
    my $old = $ages->[$_];
    my $new = $new_ages->[$_];
    my $eps = 1e-15;
    ok($new+$eps < $old || $new-$eps > $old, "File " . ($_+1) . " was overwritten.");
  }
  
  chdir($olddir);
  return;
}

sub check_files_exist {
  my $files = shift;
  my @filescopy = @$files;
  while (@filescopy) {
    my $name = shift @filescopy;
    my $size = shift @filescopy;
    ok(-f $name, "$name was extracted");
    is(-s $name, $size, "$name has right size"); # is this different on windows?
  }
}

sub delete_files {
  my $files = shift;
  my @filescopy = @$files;
  while (@filescopy) {
    my $name = shift @filescopy;
    my $size = shift @filescopy;
    unlink($name) or die "Could not delete file '$name': $!";
    ok(!-f $name, "$name was deleted");
  }
}

sub get_file_ages {
  my $files = shift;
  my @filescopy = @$files;
  my @ages;
  while (@filescopy) {
    my $name = shift @filescopy;
    my $size = shift @filescopy;
    ok(-f $name, "File $name exists.");
    push @ages, -M $name;
  }
  return \@ages;
}


sub overwrite_files_with_garbage {
  my $files = shift;
  my @filescopy = @$files;
  while (@filescopy) {
    my $name = shift @filescopy;
    my $size = shift @filescopy;
    open my $fh, '>', $name or die $!;
    print $fh "OVERWRITTEN\n";
    close $fh;
  }
}


my $datadir = File::Spec->catdir("t", "data");
my @datafilenames = ('test.rar', 'funny.rar');
my @datafilecontents = (
  [qw/COPYRIGHT 183 README 890/],
  ['funny file name(blah).txt', '28'],
);

foreach my $datafileno (0..$#datafilenames) {
  my $datafilename = $datafilenames[$datafileno];
  my $datafilecontent = $datafilecontents[$datafileno];

  my $datafile = File::Spec->catfile($datadir, $datafilename);
  if (not -f $datafile) {
    $datadir = 'data';
    $datafile = File::Spec->catfile($datadir, $datafilename);
  }
  ok(-f $datafile, "Test archive found");

  my $rar = Archive::Rar::Passthrough->new();
  isa_ok($rar, 'Archive::Rar::Passthrough');

  test_passthrough_extraction(
    $rar, $datafile, $datafilecontent
  );
}

1;
