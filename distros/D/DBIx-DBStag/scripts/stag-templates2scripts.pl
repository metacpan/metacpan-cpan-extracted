#!/usr/local/bin/perl

# cjm@fruitfly.org

use strict;
use Carp;
use Getopt::Long;

my $bindir = $ENV{DBSTAG_TEMPLATE_BINDIR};
GetOptions("bindir|b"=>\$bindir);

my @dirs = @ARGV;
if (!@dirs) {
    @dirs = split(/:/, $ENV{DBSTAG_TEMPLATE_DIRS});
    print "You did not specify directories on the command line\n";
    print "I will use these\n";
    print "$_\n" foreach @dirs;
    print "\nOK? [yes/no] ";
    my $ok = <STDIN>;
    if ($ok !~ /^y/i) {
	print "Bye!\n";
	exit 0;
    }
}
if (!$bindir) {
    $bindir = "/usr/local/bin";
    print "You did not specify -b (path to template generated binaries) on the command line\n or in \$DBSTAG_TEMPLATE_BINDIR";
    print "I will use this: $bindir\n";
    print "$_\n" foreach @dirs;
    print "\nOK? [yes/no] ";
    my $ok = <STDIN>;
    if ($ok !~ /^y/i) {
	print "Bye!\n";
	exit 0;
    }
}

foreach my $dir (@dirs) {

}
