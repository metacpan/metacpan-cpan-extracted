#!/usr/local/bin/perl

# cjm@fruitfly.org

use strict;
use Carp;
use Getopt::Long;

my $bindir = $ENV{DBSTAG_TEMPLATE_BINDIR};
my $force;
my $quiet;
my $chmod = "777";
GetOptions("bindir|b=s"=>\$bindir,
	   "force"=>\$force,
	   "quiet|q"=>\$quiet,
	   "chmod=s"=>\$chmod,
	  );

if (!$bindir) {
    $bindir = "/usr/local/bin";
    unless ($force) {
	print "You did not specify -b (path to template generated binaries) on the command line\n or in \$DBSTAG_TEMPLATE_BINDIR";
	print "I will use this: $bindir\n";
	print "\nOK? [yes/no] ";
	my $ok = <STDIN>;
	if ($ok !~ /^y/i) {
	    print "Bye!\n";
	    exit 0;
	}
    }
}

foreach my $f (@ARGV) {
    my @parts = split(/\//, $f);
    my $name = $parts[-1];
    if ($name =~ s/\.stg$//) {
	my $bin = "$bindir/$name";
	open(F, ">$bin") || die("can't write to $bin");
	print F "#!/bin/sh\n";
	print F "selectall_xml.pl -t $name \$\@\n";
	close(F);
	system("chmod $chmod $bin");
	print "$bin\n" unless $quiet;
    }
    else {
	"$f doesn't look like a template (no .stg suffix)";
    }
}
