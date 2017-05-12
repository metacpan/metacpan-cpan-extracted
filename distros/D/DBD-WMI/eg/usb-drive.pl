#!/usr/bin/perl -w
package main;
use strict;
use DBI;
use Data::Dumper;

my $dbh = DBI->connect('dbi:WMI:');

my $sth = $dbh->prepare(<<WQL);
    SELECT * FROM __instanceoperationevent
    WITHIN 5
    WHERE TargetInstance ISA 'Win32_LogicalDisk'
    and TargetInstance.Name != 'C:'
WQL
$sth->execute();

# loops forever
while (defined (my $row = $sth->fetchrow_arrayref())) {
    my $ev = $row->[0];
    
    # Windows XP only :(
    print "Class\t",$ev->Path_->Class,"\n";
    for (qw(Name DeviceID Caption MediaType )) {
        print join "\t", $_, ($ev->TargetInstance->{$_} || '<none>');
        print "\n";
        if ($ev->Path_->Class eq '__InstanceCreationEvent') {
            #my ($file) = reverse sort glob 'D:/DCIM/100CASIO/*.jpg';
            #system("start $file");
            print "Device (letter) $ev->{TargetInstance}->{Name} added\n";
        }
    }
}