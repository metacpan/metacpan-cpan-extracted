#!/usr/bin/env perl
use strict;
use warnings;

use File::chdir;
use File::Temp ();
use Net::FTP;

my $olson_version;
my $tempdir = File::Temp::tempdir( CLEANUP => 1 );
{
    local $CWD = $tempdir;

    my $ftp = Net::FTP->new( 'elsie.nci.nih.gov' ) # , Passive => 1 )
        or die "Cannot connect to elsie.nci.nih.gov: $@";
    $ftp->login()
        or die 'Cannot login: ', $ftp->message;
    $ftp->cwd('/pub')
        or die 'Cannot cwd to /pub: ', $ftp->message;
    $ftp->binary();

    for my $f ( $ftp->ls )
    {
        if ( $f =~ /^tz(?:code|data)/ )
        {
            print "Getting $f\n";
            $ftp->get($f) or die "get failed" . $ftp->message;
            system( 'tar', '-xzf', $f ) == 0 or exit 1;

            ($olson_version) = $f =~ /(\d\d\d\d\w)/;
        }
    }

    die "Did not retrieve anything from elsie"
        unless $olson_version;

    print "Running make...\n";
    if ($^O eq 'darwin') {
        if ($ENV{CPPFLAGS}) {
            $ENV{CPPFLAGS} .= ' -DSTD_INSPIRED';
        } else {
            $ENV{CPPFLAGS} = ' -DSTD_INSPIRED';
        }
    }
        
    system( 'make' )
        and die "Cannot run make: $!";

    for my $f ( qw( africa antarctica asia australasia
                    europe northamerica pacificnew
                    southamerica backward
                  )
                )
    {
        print "Running zic on zoneinfo file $f...\n";
        system( 'sudo', './zic', '-d', '/usr/share/zoneinfo', $f )
            and die "Cannot run zic on $f";
    }

}

{
    system( './tools/timezone/parse_olson.pl',
            '--clean',
            '--version', $olson_version,
            '--dir', $tempdir,
          )
        and die "Cannot run parse_olson: $!";

#    print "Generating tests from zdump\n";
#    system( './tools/tests_from_zdump' )
#        and die "Cannot run tests_from_zdump: $!";
}