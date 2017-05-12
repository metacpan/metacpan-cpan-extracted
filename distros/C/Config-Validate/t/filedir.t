#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::FileDir;

use base qw(Test::Class);
use Test::More;
use File::Temp qw(tempdir tmpnam);

use Config::Validate qw(validate);

sub missing_file :Test {
  my $filename = tmpnam;
  while (-f $filename or -l $filename) {
    $filename = tmpnam;
  }
  my $schema = { testfile => { type => 'file' }};
  my $value = { testfile => $filename };
  eval { validate($value, $schema) };
  like($@, qr/is not a file/, "Missing file fails (expected)");
  
  return;
}

sub normal_file :Test {
  my $tempfile = File::Temp->new(UNLINK => 0, 
                                 CLEANUP => 1);

  my $schema = { testfile => { type => 'file' }};
  my $value = { testfile => $tempfile->filename };
  eval { validate($value, $schema) };
  is ($@, '', 'normal file case succeeded (' . $tempfile->filename .  ')');
  
  return;
}

sub symlink_file :Test(2) {
  my $tempfile = File::Temp->new(UNLINK => 0, 
                                 CLEANUP => 1);
  my $symlink_filename = tmpnam();
  my $rc = symlink $tempfile->filename, $symlink_filename;
  ok($rc, "symlink operation succeeded");

  my $schema = { testfile => { type => 'file' }};
  my $value = { testfile => $symlink_filename };
  eval { validate($value, $schema) };
  is ($@, '', sprintf('file w/symlink case succeeded (%s -> %s)',
                      $symlink_filename, $tempfile->filename));
  unlink($symlink_filename);

  return;
}

sub missing_directory :Test {
  my $filename = tmpnam;
  while (-d $filename) {
    $filename = tmpnam;
  }
  my $schema = { testdir => { type => 'directory' }};
  my $value = { testdir => $filename };
  eval { validate($value, $schema) };
  like($@, qr/is not a directory/, "Missing directory fails (expected)");
  
  return;
}

sub normal_directory :Test {
  
  my $tempdir = tempdir("config-validate-dirtest-XXXXX",
                        CLEANUP => 1,
                        TMPDIR => 1,
                       );

  my $schema = { testdir => { type => 'directory' }};
  my $value = { testdir => $tempdir };
  eval { validate($value, $schema) };
  is ($@, '', 'directory case succeeded (' . $tempdir .  ')');

  return;
}

