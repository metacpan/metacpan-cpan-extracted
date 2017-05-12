#!/usr/bin/perl -w
#
# $Id: check-space.pl,v 1.1 2001/12/13 01:05:26 mpeppler Exp $
#
# List the spaceusage of a database, and the space usage of each
# user table in the DB.

use strict;
use DBI;

use Getopt::Long;

my %args;

GetOptions(\%args, '-U=s', '-P=s', '-S=s', '-D=s');

my $dbh = DBI->connect("dbi:Sybase:server=$args{S};database=$args{D}", $args{U}, $args{P});

$dbh->{syb_do_proc_status} = 1;

my $dbinfo;

# First check space in the DB:
my $sth = $dbh->prepare("sp_spaceused");
$sth->execute;
do {
    while(my $d = $sth->fetch) {
	if($d->[0] =~ /$args{D}/) {
	    $d->[1] =~ s/[^\d.]//g;
	    $dbinfo->{size} = $d->[1];
	} else {
	    foreach (@$d) {
		s/\D//g;
	    }
	    $dbinfo->{reserved} = $d->[0] / 1024;
	    $dbinfo->{data} = $d->[1] / 1024;
	    $dbinfo->{index} = $d->[2] / 1024;
	}
#	print "@$d\n";
    }
} while($sth->{syb_more_results});

# Get the actual device usage from sp_helpdb to get the free log space
$sth = $dbh->prepare("sp_helpdb $args{D}");
$sth->execute;
do {
    while(my $d = $sth->fetch) {
	#print "@$d\n";
	if($d->[2] && $d->[2] =~ /log only/) {
	    $d->[1] =~ s/[^\d\.]//g;
	    $dbinfo->{log} += $d->[1];
	}
	if($d->[0] =~ /log only .* (\d+)/) {
	    $dbinfo->{logfree} = $1 / 1024;
	}
    }
} while($sth->{syb_more_results});

$dbinfo->{size} -= $dbinfo->{log};
#if(($dbinfo->{reserved} / $dbinfo->{size}) > 0.75) {
#    warn "WARNING: smlive free space is below 25%\n";
#}

my $freepct = ($dbinfo->{size} - $dbinfo->{reserved}) / $dbinfo->{size};

print "$args{S}/$args{D} spaceusage report\n\n";
printf "Database size: %10.2f MB\n", $dbinfo->{size};
printf "Log size:      %10.2f MB\n", $dbinfo->{log};
printf "Free Log:      %10.2f MB\n", $dbinfo->{logfree}; 
printf "Reserved:      %10.2f MB\n", $dbinfo->{reserved};
printf "Data:          %10.2f MB\n", $dbinfo->{data};
printf "Indexes:       %10.2f MB\n", $dbinfo->{index};
printf "Free space:    %10.2f %%\n", $freepct * 100;

if($freepct < .25) {
    printf "**WARNING**: Free space is below 25%% (%.2f%%)\n\n", $freepct * 100;
}

print "\nTable information (in MB):\n\n";
printf "%15s %15s %10s %10s %10s\n\n", "Table", "Rows", "Reserved", "Data", "Indexes";

my @tables = getTables($dbh);

foreach (@tables) {
    my $sth = $dbh->prepare("sp_spaceused $_");
    $sth->execute;
    do {
	while(my $d = $sth->fetch) {
	    foreach (@$d) {
		s/KB//;
		s/\s//g;
	    }
	    printf("%15.15s %15d %10.2f %10.2f %10.2f\n",
		   $d->[0], $d->[1], $d->[2] / 1024, $d->[3] / 1024,
		   $d->[4] / 1024);
#	    print "@$d\n";
	}
    } while($sth->{syb_more_results});
}


sub getTables {
    my $dbh = shift;

    my $sth = $dbh->table_info;
    my @tables;
    do {
	while(my $d = $sth->fetch) {
	    push(@tables, $d->[2]) unless $d->[3] =~ /SYSTEM|VIEW/;
	}
    } while($sth->{syb_more_results});

    @tables;
}

