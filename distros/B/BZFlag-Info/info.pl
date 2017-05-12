#!/usr/bin/perl -w

use Data::Dumper;
use BZFlag::Info;

my $bzinfo = new BZFlag::Info;
my $serverlist = $bzinfo->serverlist;
print Dumper $serverlist;

foreach(keys(%{ $serverlist->{servers} })) {
    my $serverinfo = $bzinfo->queryserver(Server => $_);
    print "\n## $_\n";
    if ($serverinfo) {
	print Dumper $serverinfo;
    } else {
	print $bzinfo->geterror."\n";
    }
}
