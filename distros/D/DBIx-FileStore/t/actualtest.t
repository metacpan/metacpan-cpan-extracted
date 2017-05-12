#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
#use Test::More tests=>4;

if ( $ENV{RELEASE_TESTING} ) {
    plan( tests=>4 );
} else {
    plan( skip_all => "Author tests not required for installation, use env var RELEASE_TESTING to enable" );
}



#unless ( $ENV{RELEASE_TESTING} ) {
#    plan( skip_all => "Author tests not required for installation" );
#}
#
#eval "use Test::CheckManifest 0.9";
#plan skip_all => "Test::CheckManifest 0.9 required" if $@;
#ok_manifest();

#$ENV{PATH} = "/usr/bin:/bin";

my $perl = "$^X -w -Mstrict";   # warnings and strict on
#1) TEST fdbls: no files in /testfolder
my @out = btick( "$perl bin/fdbls /testfolder/" );
ok( scalar(@out) == 0, "fdbls: no files in /testfolder/ (@out)" );

#2) test fdbput - put a file in /testfolder/
mysystem( "$perl bin/fdbput -l bin/fdbput /testfolder/fdbput" );
my @files = btick( "$perl bin/fdbls /testfolder/fdbput" );
ok( scalar(@files) == 1, "fdbput: file in /testfolder/ (@files)" );

#3) test fdbmv - rename a file in /testfolder/
mysystem( "$perl bin/fdbmv /testfolder/fdbput /testfolder/fdbput-was" );
@files = btick( "$perl bin/fdbls /testfolder/fdbput-was" );
ok( scalar(@files) == 1, "fdbmv: fdbput-was in /testfolder/ (@files)" );

#4) test fdbrm - remove a file in /testfolder/
mysystem( "$perl bin/fdbrm /testfolder/fdbput-was" );
@files = btick( "$perl bin/fdbls /testfolder/" );
ok( scalar(@files) == 0, "fdbrm: no file /testfolder/ (@files)" );
        
sub mysystem {
    my $ret = system( @_ );
    if ($ret) {
        warn "$0: Error from system(@_): $!\n";
    } 
}

# like backtick, but auto-testing, and prettier
sub btick {
    my @lines = `@_`;
    if ($?) {
        warn "@_\n";
    }

    # $? : The status returned by the last pipe close, backtick(``) 
    # command or system operator. Note that this is the status 
    # word returned by the wait() system call, so the exit value 
    # of the subprocess is actually ($? >>*). $? & 255 gives 
    # which signal, if any, the process died from, and whether 
    # there was a core dump. 
    chomp(@lines);
    return @lines;
}
            
