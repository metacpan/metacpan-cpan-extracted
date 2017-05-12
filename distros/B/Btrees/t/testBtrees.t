# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests $debug $found);

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use Btrees;
$loaded = 1;
ok(1, 'compile');

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

########################################
#
# Method: _testBtrees
#
# Run a series of tests depending on the
# test_num passed in. Sets up a btree of
# squares for testing 2-4. Tests 5 and 6
# exploit a custom compare function and
# value tokens. Reasonable balance is
# checked.
#

sub _testBtrees {
    my $test_num = shift;	# Get the test number
    my $tree = undef;		# Tree starts out empty
    my $node;
    my $ret = 1;		# Passed == 1, Failed == 0
    local $debug = 0;
    local $found = 0;

    sub debug {
	my $tree = shift;
	local $^W = 0;
	print "val: $tree->{val}\thgt: $tree->{height} ",
	    "$tree $tree->{left} $tree->{right}", "\n" if ($debug);
	local $^W = 1;
    }

    sub check_25 {
	my $tree = shift;
	$found++ if ( $tree->{val} == 25 );
    }

    sub check_49 {
	my $tree = shift;
	$found++ if ( $tree->{val} == 49 );
    }

    sub check_height {
	my $tree = shift;
	$found = $tree->{height} if ( $tree->{height} > $found );
    }


    foreach ( 1..8 ) {
	($tree, $node) = bal_tree_add( $tree, $_ * $_ );
    }

    my @bytes;
    my $func = \&debug;
    my $ck25 = \&check_25;
    my $ck49 = \&check_49;
    my $ckht = \&check_height;

    if ( $test_num == 2 ) {		### Check for duplicate adds
	print "Check for duplicate add\n" if ($debug);
	traverse( $tree, $func );
	$node = bal_tree_find( $tree, 7*7 );
	$ret = 0 if ( $node->{val} != 49 );

	$found = 0;			### Add a second time
	($tree, $node) = bal_tree_add( $tree, 7*7 );
	print "added 7x7 again: " if ($debug); debug($node);
	traverse( $tree, $ck49 );
	$ret = 0 if (!$found);

	$found = 0;			### Check for duplicate
	($tree, $node) = bal_tree_del( $tree, 7*7 );
	print "delete node 7x7: " if ($debug); debug($node);
	traverse( $tree, $ck49 );
	$ret = 0 if ($found);

    } elsif ( $test_num == 3 ) {	### Check for duplicate deletes

	print "Check for duplicate deletes\n" if ($debug);
	traverse( $tree, $func );
	$node = bal_tree_find( $tree, 5*5 );
	$ret = 0 if ( $node->{val} != 25 );

	$found = 0;			### Delete a first time
	traverse( $tree, $ck25 );
	$ret = 0 if (!$found);
	($tree, $node) = bal_tree_del( $tree, 5*5 );

	$found = 0;			### Delete a second time
	traverse( $tree, $ck25 );
	$ret = 0 if ($found);
	($tree, $node) = bal_tree_del( $tree, 5*5 );
	$ret = 0 if ( defined($node) );
	
	foreach ( 1..8 ) {		### Check if anything missing
	    if ($_ != 5 ) {
		($tree, $node) = bal_tree_del( $tree, $_ * $_ );
		$ret = 0 if ( $node->{val} != ($_ * $_) );
	    }
	}

    } elsif ( $test_num == 4 ) {	### Check for emptied tree

	print "Check for emptied tree\n" if ($debug);
	foreach ( 1..8 ) {
	    ($tree, $node) = bal_tree_del( $tree, $_ * $_ );
	}
	$ret = 0 if ( defined($tree) );
	traverse( $tree, $func ) if ($debug);

    } elsif ( $test_num == 5 ) {	### Check passed function argument

	print "Check passed function argument\n" if ($debug);
	my $size  = 0xFF;
	my $mask  = 0xFF;
	my $tsize = $size;
	my $isize = $size/2;

	while ( $tsize ) {
	    $isize = int( rand($tsize/2) ) + 1;
	    $isize = $tsize if ( $isize >= $tsize );
	    push( @bytes, $isize );
	    $tsize -= $isize;
	    print "bytes: ", $bytes[$#bytes], " tsize: $tsize isize: $isize\n"
		if ($debug);
	}
	$tree = _uniqueAddrs( undef, 0xFFFFFFFF, $size*2, @bytes );
	traverse( $tree, $func ) if ($debug);
	### If it doesn't hang, its working.

    } elsif ( $test_num == 6 ) {	### Check for a balanced tree

	print "Check for a balanced tree\n" if ($debug);
	my $size  = 0xFFFF;
	my $mask  = 0xFFFF;
	my $tsize = $size;
	my $isize = $size/2;

	while ( $tsize ) {
	    $isize = int( rand($tsize/2) ) + 1;
	    $isize = $tsize if ( $isize >= $tsize );
	    push( @bytes, $isize );
	    $tsize -= $isize;
	    print "bytes: ", $bytes[$#bytes], " tsize: $tsize isize: $isize\n"
		if ($debug);
	}
	$tree = _uniqueAddrs( undef, 0xFFFFFFFF, $size*2, @bytes );
	traverse( $tree, $ckht );
	print "height: $found\n" if ($debug);
	$ret = 0 if $found > 8;

    }
    $ret;
}

#########################################
#
# Method: _addrRangeCompare
#
# _addrRangeCompare( $tree, $val );
#
# Compare relation used in btree call for the _uniqueAddrs method.
# Refer to Btrees.pm for further reference.
#
sub _addrRangeCompare {
    my $val1 = shift || "0:0";
    my $val2 = shift || "0:0";

    my( $min1, $max1 ) = split( ':', $val1 );
    my( $min2, $max2 ) = split( ':', $val2 );
    return $max1 < $min2 ? -1 : $min1 > $max2 ?  1 : 0;
}

#########################################
#
# Method: _uniqueAddrs
#
# _uniqueAddrs( $tree, $mask, $maxSdramSize, @bytes );
#
# Insures no address fragment overlaps with any others address.
# Mask is used for alinged address requests of any alignment.
#
sub _uniqueAddrs {
    my ( $tree, $mask, $maxSdramSize, @bytes ) = @_;

    my ( $loc, $val, $add, $node );
    while ( @bytes ) {
        do {
	    $loc = ( int(rand($maxSdramSize)) & $mask );
	    $add = $loc + $bytes[0];
	    $val = $loc.":".$add;
        } until( ($add < $maxSdramSize) &&
		!defined(bal_tree_find($tree, $val, \&_addrRangeCompare)) );
        ($tree, $node) = bal_tree_add( $tree, $val, \&_addrRangeCompare );
	shift(@bytes);
    }
    return $tree;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 7 }

::ok( _testBtrees(1) );
::ok( _testBtrees(2) );
::ok( _testBtrees(3) );
::ok( _testBtrees(4) );
::ok( _testBtrees(5) );
::ok( _testBtrees(6) );
