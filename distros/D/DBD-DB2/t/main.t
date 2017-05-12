#!/usr/local/bin/perl -w

use DBI;

print "1..$tests\n";

print "ok 1\n";

BEGIN { $tests = 1 }
exit 0;


# ----------------------------------------------------------

#  engn/perldb2/t/main.t, engn_perldb2, db2_v82fp9, 1.2 98/10/01 09:41:37
#
# Copyright (c) 1994, Tim Bunce
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

# This is just my DBI test script, it's not as clean as it could be :-)

BEGIN {
	print "$0 @ARGV\n";
	print q{DBI test application $Revision: 0.2 $}."\n";
	$| = 1;  # chop($cwd = `pwd`); unshift(@INC, ".");
}

use DBI;

use Getopt::Long;
use strict;

$main::opt_d = 1;
$main::opt_h = 0;
$main::opt_dbname = 'crgs';

GetOptions('d=i', 'h=i', 'dbname=s')
	or die "Usage: $0 [-d n] [-h n] [drivername]\n";

my($driver) = $ARGV[0] || 'Oracle';
print "opt_d=$main::opt_d\n" if $main::opt_d;
print "opt_h=$main::opt_h\n" if $main::opt_h;

# Now ask for some information from the DBI Switch
my($switch) = DBI->internal;
$switch->debug($main::opt_h); # 2=detailed handle trace

print "Switch: $switch->{'Attribution'}, $switch->{'Version'}\n";

$switch->{'DebugDispatch'} = $main::opt_d; # 2=detailed trace of all dispatching
print "DebugDispatch: $switch->{'DebugDispatch'}\n";

print "Available Drivers: ",join(", ",DBI->available_drivers()),"\n";

my($dbh);   # first, get connected using either of these methods:
if (0){
	$dbh = DBI->connect($::opt_dbname, '', '', $driver);
}else{
	my($drh) = DBI->install_driver($driver);
	print "Driver installed as $drh\n";
	$dbh = $drh->connect($::opt_dbname, 'system', 'manager');
}
die "Unable for connect to $::opt_dbname: $DBI::errstr"
    unless $dbh;

$dbh->debug($main::opt_h);

eval { run_test($dbh); };
print "run_test($dbh) failed: '$@'\n";

print "$0 Done. (global destruction will follow)\n\n";
exit 0;


sub run_test{
    my($dbh) = @_;

    print "Connected as $dbh\n\n";

    $dbh->commit;

    my($cursor_a) = $dbh->prepare("select SYSDATE from DUAL");
    die "Prepare failed ($DBI::err): $DBI::errstr\n" unless $cursor_a;

    print "Prepared as $cursor_a\n";
    # $cursor_a->debug(2);

    my($cursor_b) = $dbh->prepare("select SYSDATE+1 from DUAL");
	die "Prepare failed ($DBI::err): $DBI::errstr\n" unless $cursor_b;

    print "Prepared as $cursor_b\n";
    # $cursor_b->debug(2);

    # Test object attributes

    print "Number of fields: $cursor_a->{'NUM_OF_FIELDS'}\n";
    print "Number of fields: $cursor_a->{'NUM_OF_FIELDS'}\n"; # now cached

die "Test not fully implemented yet";

    print "Data type of first field: $cursor_a->{'DATA_TYPE'}->[0]\n";
    print "Driver name: $cursor_a->{'Database'}->{'Driver'}->{'Name'}\n";


    $cursor_a->execute('/usr');
    $cursor_b->execute('/usr/spool');

    print "Fetching data from both cursors:\n";
    my(@row_a, @row_b);
    while((@row_a = $cursor_a->fetchrow)
       && (@row_b = $cursor_b->fetchrow)){
	    print "@row_a, @row_b\n";
    }

	print "\nAutomatic method parameter usage check:\n";
    eval { $dbh->commit('dummy') };
	warn "$@\n";

    print "Preparing new \$cursor_a to replace current \$cursor_a:\n";

	print "(we enable debugging on current to watch it's destruction)\n";
    $cursor_a->debug(2);

    $cursor_a = $dbh->prepare("select mtime,name from ?");
    $cursor_a->execute('../..');

    print "Fetching one row from new \$cursor_a:\n";
    print join(' ',$cursor_a->fetchrow),"\n";
    $cursor_a->finish;

    print "test done (scoped objects will be destroyed now)\n";
}

# end.
