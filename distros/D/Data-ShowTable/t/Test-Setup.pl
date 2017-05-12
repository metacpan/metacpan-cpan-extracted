#!/usr/bin/env perl

use Carp;

($DIR,$PROG) = $0 =~ m=^(.*/)?([^/]+)$=;
$DIR =~ s=/$== || chop($DIR = `pwd`);

$testdir = -d 't' ? 't' : '.';

# Setup these globals

@Titles = ("Index", "Name", "Phone", "Address", "Date");
@Types  = ("int",   "char", "char",  "char",    "date");
@Widths = (  3,  20, 15, 25, 10 );
@Data   = ( [ 1, "Alan Stebbens", "555-1234", "1234 Something St., CA", "1998-10-22" ],
	    [ 2, "Bob Frankel",   "555-1235", "9234 Nowhere Way, WA",   "2001-01-02" ],
	    [ 3, "Mr. Goodwrench","555-9432", "1238 Car Lane Pl., NY",  "2004-04-20" ],
	    [ 4, "Mr. Ed",	  "555-3215", "9876 Cowbarn Home, VA",  "2008-09-12" ],
            [ 5, "Gunther Sveborg", "44-55-555-5555", "Kartophelhause 345, Munich, Germany", "2013.10.22"],
	  );

sub talk { print STDERR @_; }

sub start_tests($) {
    my $count = shift;		# how many tests?
    mkdir("$testdir/out",0755)  unless -d "$testdir/out";
    print "1..$count\n";	# tell harness how many tests
    $| = 1;			# flush the output
}

sub copy_test_output($) {
    my $kind = shift;
    print "*** \U$kind ***\n";
    open(IN, "<$testdir/out/test.$kind");
    while (<IN>) { print; }
    close IN;
    unlink "$testdir/out/test.$kind";
}

sub showDataRow {
     &ShowRow( $_[0], \$theRow, \@Data ); 
}

sub showDataRowOnce($) {
    my $rewindable = shift;
    if ($rewindable) {
	&ShowRow( 1, \$theRow, \@Data );
	return 0;
    }
    &ShowRow( 0, \$theRow, \@Data );
}

# run_test $num, \&sub;

sub run_test($&) {
    my $num = shift;
    my $sub = shift;

    ref($sub) eq 'CODE' or croak "Need sub reference as second argument.\n";

    open(savSTDOUT, ">&STDOUT");	# redirect STDOUT
    #open(savSTDERR, ">&STDERR");

    open(STDOUT,">$testdir/out/test.stdout");
    #open(STDERR,">$testdir/out/test.stderr");
    select(STDOUT);

    local($theRow) = 0;		# initialize the row pointer

    &$sub;			# run the test

    close STDOUT;
    #close STDERR;

    # Copy stdout & stderr to the test.out file
    $testname = "$testdir/out/$PROG-$num";
    $testout  = "$testname.out";
    $testref  = "$testname.ref";
    $testdiff = "$testname.diff";
    unlink $testout;
    open(TESTOUT,">$testout");
    select(TESTOUT);
    copy_test_output 'stdout';
    #copy_test_output 'stderr';
    close TESTOUT;

    open(STDOUT, ">&savSTDOUT");	# reopen STDOUT, STDERR
    #open(STDERR, ">&savSTDERR");
    select(STDOUT); $|=1;

    if (! -f $testref) {			# any existing reference?
	system("cp $testout $testref");	# no, copy
    }

    system("diff $testref $testout >$testdiff");

    if ($?>>8) {
	print "not ok $num\n";
    } else {
	print "ok $num\n";
	unlink $testout;
	unlink $testdiff;
    }
}
