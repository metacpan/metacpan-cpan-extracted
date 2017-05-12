#!/usr/bin/env perl

use strict;
use warnings;

use App::Highlander;
use Test::More;
use Test::SharedFork;

my $lockfile;
ok( $lockfile = App::Highlander::get_lock(), "got an exclusive lock on '$lockfile'" );
ok( -e $lockfile, "LOCKFILE '$lockfile' exists" );

my $pid_pattern = qr/^$$/;
ok( `cat $lockfile` =~ m/$pid_pattern/, "LOCKFILE '$lockfile' has correct PID" );


if ( my $pid = fork() ) { # parent process
   waitpid( $pid, 0 );
   ok( $lockfile = App::Highlander::release_lock(), "released lock on '$lockfile'" );
   ok( ! -e $lockfile, "LOCKFILE '$lockfile' was removed" );
}
else { # child process
   ok( !App::Highlander::get_lock(), "fails to get held lock on '$lockfile'" );
   exit 0;
}

done_testing();
