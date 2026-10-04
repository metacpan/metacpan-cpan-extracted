#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

my $cmd = 'bin/hashmake';

my $default_makefile = 'Hash.Makefile';     #  Duplicated from module :/
my $other_makefile   = 'other.makefile';
my $env_makefile     = 'env.makefile';
my $work_dir         = tempdir ( CLEANUP => 1 );

{
    ok ( -e $cmd, "Script found" );
    ok ( -x $cmd, "Script is executable" );

    #  I want to just test that argument parsing is working, so that means
    #  debug is always set.

    my $d = 1;

    #  Use a temporary file for STDERR so that it doesn't mess up the display
    #  during tests.

    my $stderr_file = File::Spec->catfile ( $work_dir, 'stderr.out' );

    foreach my $n ( 0..1 ) {                #  Print Only

      foreach my $f ( 0..1 ) {              #  Specify makefile

        foreach my $e ( 0..1 ) {            #  Environment has makefile

          foreach my $y ( 0..1 ) {          #  Working directory specified

            foreach my $B ( 0..1 ) {        #  Force rebuild

              foreach my $s ( 0..1 ) {      #  Silent operation

                foreach my $t ( 0..1 ) {    #  Touch only

                  my ( @args, @env );

                  if ( $d ) { push ( @args, '-d' ); }
                  if ( $n ) { push ( @args, '-n' ); }
                  if ( $f ) { push ( @args, "-f $other_makefile" ); }
                  if ( $e ) { push ( @env,  "HASH_MAKEFILE=$env_makefile" ); }
                  if ( $y ) { push ( @args, "-y $work_dir" ); }
                  if ( $B ) { push ( @args, '-B' ); }
                  if ( $s ) { push ( @args, '-s' ); }
                  if ( $t ) { push ( @args, '-t' ); }

                  my $line = join ( ' ', @env, $cmd, @args );
                  my @result = qx/$line 2>$stderr_file/;
                  my $return_code = $?;

                  if ( $return_code ) { diag ( "Return code was $return_code" ); }

                  #  If we asked for silent operation, there should be no output.
                  #  This checks before we gather the STDERR output, because we
                  #  display errors no matter what.

                  if ( $s ) {

                    is ( @result, 0, "There was no output during silent operation" );
                    if ( @result ) {

                      diag ( "Unexpected output was @result" );
                    }
                    next;     #  Skip everything else.
                  }

                  #  If anything came out of STDERR, add it to the output list.

                  if ( ! -z $stderr_file ) {

                    open ( my $fh, '<', $stderr_file );
                    push ( @result, <$fh> );
                    close $fh;
                  }

                  #  Since this filename is reused each time through the loop, it's
                  #  not necessary to delete it at this point.

                  my $last_make_file;
                  foreach my $l ( @result ) {

                    unlike ( $l, qr/Unknown option:/, "Did not see 'unknown option'" ); 

                    if ( $l =~ /debug: 1/ ) {

                      ok ( 1, "Debug flag always set in these tests" );
                      next;
                    }

                    if ( $l =~ /print_only: (\d)/ ) {

                      my $value = $1;
                      is ( $value, $n, "Printing value matches" );

                      next;
                    }

                    if ( $l =~ /makefile: (\S+)/ ) {

                      #  The order of precedence is 1) command line, 2)
                      #  environment, and 3) default.

                      $last_make_file = $1;
                      if ( $f ) {

                        is ( $last_make_file, $other_makefile, "Other makefile" );

                      }
                      elsif ( $e ) {

                        is ( $last_make_file, $env_makefile, "Env makefile" );

                      } else
                      {

                        is ( $last_make_file, $default_makefile, "Default makefile" );
                      }

                      next;
                    }

                    if ( $l =~ /Makefile (\S+) not found/ ) {

                      ok ( ! -e $last_make_file, "Makefile $last_make_file not found" );

                      next;
                    }

                    if ( $y && $l =~ /working_dir: (\S+)/ ) {

                      my $value = $1;
                      is ( $value, $work_dir, "Working directory requested" );

                      next;
                    }

                    if ( $l =~ /Settings:/ ) {

                      next;
                    }

                    if ( $l =~ /force_rebuild: (\d)/ ) {

                      my $value = $1;
                      is ( $value, $B, "Force rebuild value matches" );

                      next;
                    }
                    
                    if ( $l =~ /touch_only: (\d)/ ) {

                      my $value = $1;
                      is ( $value, $t, "Touch only value matches" );

                      next;
                    }

                    #  If there was something that I wasn't expecting, complain.

                    fail ( "Unexpected output: $l" );
                  }
                }
              }
            }
          }
        }
      }
    }

    done_testing;
}
