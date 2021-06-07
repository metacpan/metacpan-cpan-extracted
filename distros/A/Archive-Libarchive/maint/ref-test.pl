#!/usr/bin/env perl

use strict;
use warnings;
use LibarchiveRef;
use File::Spec;
use File::chdir;
use 5.020;
use experimental qw( signatures );

my $exit = 0;

foreach my $version (ref_config->{OLDEST},ref_config->{LATEST})
{
  {
    local $CWD = "/opt/libarchive/$version/lib";
    my $so = "libarchive.so";
    $so = readlink $so if -l $so;
    say "libarchive $version, so=$so";
    $ENV{ARCHIVE_LIBARCHIVE_LIB_DLL} = File::Spec->rel2abs($so);
  }

  system 'prove', '-lvm';
  $exit = 2 if $?;
}

exit $exit;
