#!/usr/bin/env perl

use strict;
use warnings;

use App::Highlander;
use Test::More;
use Test::SharedFork;

my $lockfile;
my $lockstring = 'accountid=5';
ok( $lockfile = App::Highlander::get_lock($lockstring), 
    "got an exclusive lock on '$lockfile' with '$lockstring'" );
ok( -e $lockfile, "LOCKFILE '$lockfile' exists" );

my $pid_pattern = qr/^$$/;
ok( `cat $lockfile` =~ m/$pid_pattern/, 
    "LOCKFILE '$lockfile' has correct PID" );

if ( my $pid = fork() ) { # parent process
   waitpid( $pid, 0 );
   ok( $lockfile = App::Highlander::release_lock($lockstring), 
       "released lock on '$lockfile' for '$lockstring'" );
   ok( ! -e $lockfile, "LOCKFILE '$lockfile' was removed" );
}
else { # child process
   ok( !App::Highlander::get_lock($lockstring), 
       "fails to get held lock on '$lockfile' for lockstring" );
   exit 0;
}

done_testing();
