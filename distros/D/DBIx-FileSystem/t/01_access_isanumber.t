#!/usr/bin/perl -w
#
# Last Update:            $Author: marvin $
# Update Date:            $Date: 2007/12/12 15:24:54 $
# Source File:            $Source: /home/cvsroot/tools/FileSystem/t/01_access_isanumber.t,v $
# CVS/RCS Revision:       $Revision: 1.4 $
# Status:                 $State: Exp $
#
use strict;
use Test::More tests => 40;
use POSIX;

# load your module...
use DBIx::FileSystem;

my @tests = (
	     [ undef,   0 ],
	     [ "",      0 ],
	     [ " ",     0 ],
	     [ "   ",   0 ],
	     [ ".",     0 ],
	     [ "-",     0 ],
	     [ "-a",    0 ],
	     [ "1",     1 ],
	     [ " 1",    0 ],
	     [ "1 ",    0 ],
	     [ "123",   1 ],
	     [ "0123",  1 ],
	     [ " 123",  0 ],
	     [ "123 ",  0 ],
	     [ "-123",  1 ],
	     [ "0e0",   1 ],
	     [ "0E0",   1 ],
	     [ "123e",  0 ],
	     [ "1e2",   1 ],
	     [ "-1e2",  1 ],
	     [ "-1e-2", 1 ],
	     [ "infinity",0 ],
	     [ "INFINITY",0 ],
	     [ "nan",   0 ],
	     [ "NAN",   0 ],
	     [ "e",     0 ],
	     [ "E",     0 ],
	     [ "abcd",  0 ],
	     [ "10.20.30.40",   0 ],
	    );

my @tests_float = (
		   [ "X123",  1 ],
		   [ "-X123", 1 ],
		   [ "0X123", 1 ],
		   [ "-0X123",1 ],
		   [ "-1X0e-2",1 ],
		   [ "1X0e-2",1 ],
		   [ "1X0e2", 1 ],
		  );

my @tests_hex = (
		 [ "0x123e",1 ],
		 [ "0x01",  1 ],
		 [ " 0x01", 0 ],
		 [ "0x123k",0 ],
		);

foreach my $test ( @tests ) {
  is( DBIx::FileSystem->isanumber( $test->[0] ), $test->[1],
      defined $test->[0] ? "value '$test->[0]'" : "value *undef*" );
}

my $delim = POSIX::localeconv()->{decimal_point};
foreach my $test ( @tests_float ) {
  $test->[0] =~ s/X/$delim/;
  is( DBIx::FileSystem->isanumber( $test->[0] ), $test->[1],
      defined $test->[0] ? "value '$test->[0]'" : "value *undef*" );
}

SKIP: {
  skip "POSIX::strtod() dislikes hex on this platform", 4 
    if DBIx::FileSystem->isanumber( "0x1" ) == 0;

  foreach my $test ( @tests_hex ) {
    is( DBIx::FileSystem->isanumber( $test->[0] ), $test->[1],
	defined $test->[0] ? "value '$test->[0]'" : "value *undef*" );
  }
}
