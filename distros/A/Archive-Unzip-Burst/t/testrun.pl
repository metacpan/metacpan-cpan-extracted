use File::Spec;
use File::Temp qw(tempdir);

# runs 4 tests
sub testrun {
  my $file = shift;
  setup_filetemp();
  $file = File::Spec->catfile(File::Spec->updir, $file)
    unless File::Spec->file_name_is_absolute($file);
  is Archive::Unzip::Burst::unzip($file, "blah"), 0, "unzip retval";
  ok -d("blah"), "specified dir exists";
  ok -d(File::Spec->catdir("blah", "t2")), "expected subdir exists";
  my $outfile = File::Spec->catfile("blah", "t2", "Archive-InfoUnzip.t");
  ok -f($outfile), "expected file exists";
}

sub setup_filetemp {
  chdir 't';
  my $tmpdir = tempdir( DIR => '../t', CLEANUP => 1 );
  use Cwd; my $cwd = getcwd; END { chdir $cwd } # so File::Temp can cleanup
  chdir $tmpdir;
}

1;
