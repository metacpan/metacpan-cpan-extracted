#!/usr/bin/perl
##
## bench2.pl -- Simple benchmark using Apache::Mmap to get the 
## relative performance between:
##
##   * mapping two files and writing the contents to /dev/null
##   * opening a file then reading the contents and printing it to /dev/null
##

##
## $Id: bench2.pl,v 1.2 1997/11/25 03:42:17 fletch Exp $
##

use strict;
use Carp;

use Apache::Mmap;
use Benchmark;

my $times = shift @ARGV || 5000;

unless( -r '/tmp/foo' and -r '/tmp/bar' ) {
  warn "Copying files to '/tmp/' to work with\n";
  system '/bin/cp', '/etc/services', '/tmp/foo';
  system '/bin/cp', '/etc/inetd.conf', '/tmp/bar';
}

open( NULL, '>>/dev/null' )
  or croak "Can't open /dev/null: $!";

timethese( $times, {
		   'Using Apache::Mmap on two files' => q!
		   my $ref = Apache::Mmap::mmap '/tmp/foo';
		   print NULL $$ref;
		   my $ref2 = Apache::Mmap::mmap '/tmp/bar';
		   print NULL $$ref2;
		   !,
		   'Using open|while(<FOO>)' => q^
		   open( FOO, '/tmp/foo' ) or carp "Can't open /tmp/foo: $!";
		   print NULL while( <FOO> );
		   close( FOO );
		   ^ } );

close( NULL );

exit 0;

__END__
