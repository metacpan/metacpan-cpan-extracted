#!/usr/bin/perl -w
package main;
use strict;
use DBI;
use Data::Dumper;

my $dbh = DBI->connect('dbi:WMI:');

my $sth = $dbh->prepare(<<WQL);
    SELECT * FROM __instanceoperationevent
    WITHIN 1
    WHERE TargetInstance ISA 'Win32_DiskDrive'
WQL
$sth->execute();

# loops forever
while (defined (my $row = $sth->fetchrow_arrayref())) {
    my $ev = $row->[0];
    
    # Windows XP only :(
    print join "\t", $ev->{DeviceID}, $ev->{Caption}, $ev->{MediaType};
    print join "\t", $ev->{InterfaceType}; #, $ev->{Caption}, $ev->{MediaType};
    print $ev->Path_->Class,"\n";
    print $ev->TargetInstance->Name, $ev->TargetInstance->Caption,"\n";
}