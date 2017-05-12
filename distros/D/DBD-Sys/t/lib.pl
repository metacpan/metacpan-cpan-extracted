#!/usr/pkg/bin/perl

use strict;
use warnings;

sub proveRequirements
{
    my %requirements;
    my %recommends;

    {
        my @req = qw(DBI SQL::Statement Module::Pluggable);
        $^O eq "MSWin32" and push( @req, "Win32::pwent" );
        my @eval = map { qq{require $_;\n\$requirements{"$_"} = $_->VERSION ()} } @req;
        eval $_ for @eval;

        if ($@)
        {
            my @missing = grep { !exists $requirements{$_} } @req;
            if ( $INC{'Test/More.pm'} )
            {
                Test::More::BAIL_OUT "YOU ARE MISSING REQUIRED MODULES: [ @missing ]";
            }
            else
            {
                print STDERR "\n\nYOU ARE MISSING REQUIRED MODULES: [ @missing ]\n\n";
                exit 0;
            }
        }
    }
    {
        my @req =
          $_[0]
          ? @{ $_[0] }
          : (
              qw(Sys::Filesystem Filesys::DfPortable Win32::DriveInfo),
              qw(Proc::ProcessTable Win32::Process::Info Win32::Process::CommandLine),
              qw(Net::Interface Socket6 Net::Ifconfig::Wrapper NetAddr::IP),
              qw(Sys::Utmp),
              qw(Unix::Lsof Sys::Filesystem::MountPoint),
            );
        my @eval = map { qq{require $_;\n\$recommends{"$_"} = $_->VERSION ()} } @req;
        eval $_ for @eval;
    }

    return ( \%requirements, \%recommends );
}

sub showRequirements
{
    my @proveRequirements = @_;

    if ( $INC{'Test/More.pm'} )
    {
        Test::More::diag("Using required:") if ( $proveRequirements[0] );
        Test::More::diag( "  $_: " . $proveRequirements[0]->{$_} ) for sort keys %{ $proveRequirements[0] };
        Test::More::diag("Using recommended:") if ( $proveRequirements[1] );
        Test::More::diag( "  $_: " . $proveRequirements[1]->{$_} ) for sort keys %{ $proveRequirements[1] };
    }
    else
    {
        print("Using required:\n") if ( $proveRequirements[0] );
        print( "  $_: " . $proveRequirements[0]->{$_} . "\n" ) for sort keys %{ $proveRequirements[0] };
        print("Using recommended:\n") if ( $proveRequirements[1] );
        print( "  $_: " . $proveRequirements[1]->{$_} . "\n" ) for sort keys %{ $proveRequirements[1] };
    }
}
