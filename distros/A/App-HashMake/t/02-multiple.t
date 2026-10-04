#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

use autodie;

my $cmd = 'bin/hashmake';

my $other_makefile   = 'other.makefile';
my $work_dir         = tempdir ( CLEANUP => 1 );

{
    #  Test that we can handle multiple targets (no continuation lines yet).

    #  I'm going to use a temporary directory and create a temporary
    #  Hash_Makefile with 1, 2 and 3 files, and also create those three files.

    my @list = qw/foo.txt bar.txt baz/;

    my $stderr_file   = File::Spec->catfile ( $work_dir, 'stderr.out' );
    my $hash_makefile = File::Spec->catfile ( $work_dir, $other_makefile );
    my $indexfile     = File::Spec->catfile ( $work_dir, '.hash_index' );

    foreach my $c ( 1..3 ) {

      #  Touch the last file so that the module finds a file to look at.

      open ( my $fh, '>', $list[ ($c-1) ] );
      print $fh "Something something\n";
      close ( $fh );

      my $targets = join ( ' ', @list[ 0..($c-1) ] );

      open ( $fh, '>', $hash_makefile );
      print $fh join ( "\n", $targets, "  echo \"Targets are $targets\"", '' );
      close ( $fh );

      common_test_block ( $indexfile, $cmd, $hash_makefile, $stderr_file );
    }

    #  Now, with the same list of filenames, let's test the glob functionality.

    {
      my $glob = '*.txt';
      my $targets = join ( ' ', grep { $glob } @list );

      open ( my $fh, '>', $hash_makefile );
      print $fh join ( "\n", $glob, "  echo \"Targets are $targets\"", '' );
      close ( $fh );

      common_test_block ( $indexfile, $cmd, $hash_makefile, $stderr_file, $targets );
    }

    #  Clean up temporary files.

    is ( unlink ( @list ), scalar @list, "Temporary files deleted" );

    done_testing;
}

sub common_test_block
{
    my ( $indexfile, $cmd, $hash_makefile, $stderr_file, $targets ) = @_;

    #  Before the run .. check there's no index file.

    ok ( ! -e $indexfile, "Index file doesn't exiat before first run" );

    #  First run: Should see all Targets.

    my $line = join ( ' ', $cmd, "-f $hash_makefile" );
    my @result = qx/$line 2>$stderr_file/;
 
    ok (  @result, "There is output after first run" );
    ok ( -z $stderr_file, "No errors from first run" );

    ok ( -e $indexfile, "Index file exiata after first run" );

    #  Only relevant for the second call where we test for glob functionality.

    if ( defined $targets ) {

      like ( $result[ 0 ], qr/Targets are $targets/, "Target message seea in outputn" );
    }

    #  Second run: Should do nothing.

    @result = qx/$line 2>$stderr_file/;

    ok ( ! @result, "There is no output after second run" );
    ok ( -z $stderr_file, "No errors after second runs" );

    #  Here we need to do cleanup so that the index file isn't here the
    #  next time through the loop. Except make(1) doesn't have a command
    #  line option to clean, and the module I'm calling also doesn't have a
    #  method to clean. So maybe I need to add that later. TODO

    ok ( unlink ( $indexfile ), "Index file deleted successfully" );
}
