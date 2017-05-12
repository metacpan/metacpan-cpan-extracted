#!/usr/bin/perl
##
## bench2.pl -- Simple benchmark using Apache::Mmap to get the 
## relative performance between:
##
##   * mapping two files and writing the contents to /dev/null
##   * opening a file then reading the contents and printing it to /dev/null
## 
## Mike Fletcher <lemur1@mindspring.com>
##

##
## $Id: bench3.pl,v 1.1 1997/08/29 04:08:38 fletch Exp $
##

use strict;
use Carp;

use Apache::Mmap::Handle ();
use Benchmark;

## Allow number of trials to be specified on command line
my $times = shift @ARGV || 5000; 

## Copy some files to /tmp to use.  Feel free to pick more 
## representative files.
unless( -r '/tmp/foo' and -r '/tmp/bar' ) {
  warn "Copying files to '/tmp/' to work with\n";
  system '/bin/cp', '/etc/services', '/tmp/foo';
}

## Open /dev/null to toss all output into
open( NULL, '>>/dev/null' )
  or croak "Can't open /dev/null: $!";

## Compare using mmap to open/print while(<FOO>)
timethese( $times, {
		   '2: Using Apache::Mmap::Handle' => q!
		   tie *OOF, 'Apache::Mmap::Handle', '/tmp/foo', 'r';
		   print NULL while( <OOF> );
		   untie *OOF;
		   !,
		   '1: Using open/print while(<FOO>)' => q^
		   open( FOO, '/tmp/foo' ) or carp "Can't open /tmp/foo: $!";
		   print NULL while( <FOO> );
		   close( FOO );
		   ^ } );

close( NULL );

exit 0;

__END__
