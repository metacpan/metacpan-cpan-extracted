#!/usr/local/bin/perl

use File::Basename;

use warnings;
use strict;

eval "use Time::HiRes qw(gettimeofday tv_interval);";
die ( "Time::HiRes module needed for benchmark script.\n" ) if ( $@ );

eval "use File::Spec;";
die ( "File::Spec module needed for benchmark script.\n" ) if ( $@ );

our $filecount = 0;

$| = 1;

chdir ( dirname ( $0 ) );

use lib qw(lib);

use Data::Filter;

my %files = %{ constructDataSet ( @ARGV ) };

print "Got me a dataset.\n";

# get a filter
my $filter = [
  '>',
  'size',
  1_000_000,
];

my @startTime = gettimeofday ();

my %filtered = %{ filterData ( \%files, $filter ) };
my $time = tv_interval ( \@startTime );

foreach ( keys %filtered )
{
  print "\n", $filtered { $_ } { 'filename' }, " is ",
    $filtered { $_ } { 'size' }, " bytes\n";
}

print "\nTook ", $time, " seconds to filter " . $filecount . " records\n",
    "Approxmately " . ( $filecount / $time ) . " records/second.\n";

# construct a large data set (all files on the hard disk)
sub constructDataSet
{
  my @locations = @_;
  my $files = {};

  print "Construct file list ...\n";

  # construct a list of all files, including their file size, owner, etc.
  foreach ( @locations )
  {
    print "  ", $_, "\n";
    _constructFileList ( $_, $files );
  }

  print "\nDiscovered ", $filecount, " files\n",
    "Restructuring data to fit into Data::Filter ...\n";

  # restructure the data set
  my %data;
  my $index = 0;
  my %files = %$files;

  foreach ( keys %files )
  {
    $files { $_ } { 'filename' } = $_;
    $data { $index++ } = $files { $_ };
  }

  return \%data;
}

sub _findFiles
{
  my ( $location, $files ) = @_;

  foreach ( <$location/*> )
  {
    print ( "* ", $_, "\n" );
    _findFiles ( $_, $files ) if -d;
    push @$files, $_ if -f;
  }
}

sub _constructFileList
{
  my ( $location, $files ) = @_;

  return $files if -l $location;

  my @files;
  _findFiles ( $location, \@files );

  foreach my $filename ( @files )
  {
    chomp $filename;

    next if defined $files->{ $filename };

    ++$filecount;

    my ( $dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime,
      $ctime, $blksize, $blocks ) = stat ( $filename );

    $files->{ $filename } = {
      dev         => $dev,
      inode       => $ino,
      mode        => $mode,
      nlink       => $nlink,
      uid         => $uid,
      gid         => $gid,
      rdev        => $rdev,
      size        => $size,
      atime       => $atime,
      mtime       => $mtime,
      ctime       => $ctime,
      blksize     => $blksize,
      blocks      => $blocks,
    };
  }

  return $files;
}

# vim:ft=perl:sw=2:ts=2:et
