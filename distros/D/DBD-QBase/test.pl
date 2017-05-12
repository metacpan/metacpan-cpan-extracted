#!/usr/local/bin/perl -w

# $Id: test.pl,v 1.12 1995/08/26 17:23:16 timbo Rel $
#
# Copyright (c) 1994, Tim Bunce
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

# This is just my DBI test script, it's not as clean as it could be :-)

BEGIN {
	print "$0 @ARGV\n";
	print q{DBI test application $Revision: 1.12 $}."\n";
	$| = 1; chop($cwd = `pwd`); unshift(@INC, ".", "$cwd/../../lib");
}

use DBI;

use Getopt::Long;
use strict;

$::opt_d = 0;
$::opt_h = 0;
$::opt_m = 0;		# basic memory leak test: "perl test.pl -m NullP"

GetOptions('d=i', 'h=i', 'l=s', 'm')
    or die "Usage: $0 [-d n] [-h n] [-m] [drivername]\n";

print "opt_d=$::opt_d\n" if $::opt_d;
print "opt_h=$::opt_h\n" if $::opt_h;
print "opt_m=$::opt_m\n" if $::opt_m;

my $count = 0;
my $ps = (-d '/proc') ? "ps -p " : "ps -l";
my $driver = $ARGV[0] || ($::opt_m ? 'NullP' : 'ExampleP');

# Now ask for some information from the DBI Switch
my $switch = DBI->internal;
$switch->debug($::opt_h); # 2=detailed handle trace

print "Switch: $switch->{'Attribution'}, $switch->{'Version'}\n";

#$switch->{DebugDispatch} = 1;
$switch->{DebugDispatch} = $::opt_d if $::opt_d;
$switch->{DebugLog}      = $::opt_l if $::opt_l;
print "DebugDispatch: $switch->{'DebugDispatch'}\n";

print "Available Drivers: ",join(", ",DBI->available_drivers()),"\n";

print "Read DBI special variables (expect 0, 99, 99):\n";
print "err:    ";	print "$DBI::err\n";
DBI::set_err($switch, "99");
print "err:    ";	print "$DBI::err\n";
print "errstr: ";	print "$DBI::errstr\n";

print "Attempt to modify DBI special variables.\n";
print "Expect a 'Can't modify' error message:\n";
$DBI::rows = 1;
print "\n";


my($dbh);   # first, get connected using either of these methods:
if (0){
	$dbh = DBI->connect('', '', '', $driver);
}else{
	my($drh) = DBI->install_driver($driver);
	print "Driver installed as $drh\n";
	$dbh = $drh->connect('', '', '');
}
$dbh->debug($::opt_h);

if ($::opt_m) {

	mem_test($dbh) while 1;

} else {

	run_test($dbh);
}

print "$0 done (global destruction will follow)\n\n";
exit 0;


sub run_test{
    my($dbh) = @_;

    print "Connected as $dbh\n\n";

    $dbh->commit;

    print "Test error handling: prepare invalid query.\n";
    print "Expect an ERROR EVENT message:\n";
    my $cursor_e = $dbh->prepare("select unknown_field_name from ?");
    print "Error not detected!\n" if $cursor_e;
    $cursor_e = 'UNDEF' unless defined $cursor_e;
    print "prepare returned $cursor_e. \$DBI::err=$DBI::err\n\n";

    my $cursor_a = $dbh->prepare("select mode,ino,name from ?");
    print "Cursor prepare'd as $cursor_a\n";
    # $cursor_a->debug(2);

    my($cursor_b) = $dbh->prepare("select blocks,size,name from ?");
    print "Prepared as $cursor_b\n";
    # $cursor_b->debug(2);

    # Test object attributes

    print "Number of fields: $cursor_a->{'NUM_OF_FIELDS'}\n";
    print "Data type of first field: $cursor_a->{'DATA_TYPE'}->[0]\n";
    print "Driver name: $cursor_a->{'Database'}->{'Driver'}->{'Name'}\n";
    print "\n";

    $cursor_a->execute('/usr');
    $cursor_b->bind_param(1, '/usr/spool');
    $cursor_b->execute();

    print "Fetching data from both cursors.\n";
    print "Expect several rows of data:\n";
    my(@row_a, @row_b);
    while((@row_a = $cursor_a->fetchrow)
       && (@row_b = $cursor_b->fetchrow)){
	    die "fetchrow scalar context problem" if @row_a==1 or @row_b==1;
	    print "@row_a, @row_b\n";
    }

    print "\nAutomatic method parameter usage check.\n";
    print "Expect a 'DBI ... invalid' error and a 'Usage: ...' message:\n";
    eval { $dbh->commit('dummy') };
    warn "$@\n";

    print "Preparing new \$cursor_a to replace current \$cursor_a.\n";
    print "We enable debugging on current to watch it's destruction.\n";
    print "Expect several lines of DBI trace information:\n";
    $cursor_a->debug(2);
    $cursor_a = $dbh->prepare("select mtime,name from ?");

    print "\nExecuting via func redirect: \$h->func(..., 'execute')\n";
    $cursor_a->func('/tmp', 'execute');

    print "\nBinding columns of \$cursor_a to variables.\n";
    my($col0, $col1);
    $cursor_a->bind_columns(undef, \($col0, $col1));
    print "\nFetching one row from new \$cursor_a with a bound column.\n";
    print "Expect a large number follwed by a dot:\n";
    my $row_ref = $cursor_a->fetch;
    print join(' ',@$row_ref),"\n";

    print "bind_col ", ($col0 and $col0 eq $row_ref->[0]) ? "worked\n" :
		"didn't work (bound:$col0 fetched:$row_ref->[0])!\n";

    $cursor_a->finish;

    print "\nCursor tests done (scoped objects will be destroyed now)\n";
}

sub mem_test{
    my($dbh) = @_;

	system("echo $count; $ps$$") if (($count++ % 1000) == 0);

    my $cursor_a = $dbh->prepare("select mode,ino,name from ?");
    $cursor_a->execute('/usr');
    my @row_a = $cursor_a->fetchrow;
    $cursor_a->finish;
}

# end.
