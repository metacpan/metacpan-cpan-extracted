#!/usr/bin/perl -w
#
# $Id: 02-records.t,v 1.4 1999/08/03 10:47:31 andrew Exp $
#
# Record handling tests for CodeBase module
#

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    local($^W) = 0;
    use Test; plan tests => 5;
    eval "use blib" unless grep /blib/, @INC;
    eval { use lib qw(t); } if (defined -d 't');
}

use strict;
use vars qw($fh $table @temp $filename $rc);
use CodeBase;
use CodeBaseTestsubs;

$table = 'test1';
$filename = table_filename($table);

# Create table

drop_table($table);
$fh = CodeBase::create($filename, ("F1" => "N5",
				   "F2" => "N5",
				   "F3" => "C10",
				   "F4" => "M")); 


# Test using new_record with hash refs (fields exist)

ok (    $fh->new_record({F1 => 10,
			 F2 => 11,
			 F3 => "Smith, C"
			})
    and $fh->new_record({F1 => 12,
			 F2 => 13, 
			 F3 => "Smith, D", 
			 F4 => "memo field 2"}));


# Test using new_record with hash refs (non-existant fields)

ok(    !defined($fh->new_record({FXX => 12}))
   and (CodeBase::errno() == -210));


# Attempt to add duplicate keys (should work)",

ok($fh->new_record({F1 => 10, F2 => 11, F3 => "Smith C"}));


# Replace records with existing hash refs",

ok (    $fh->goto(1)
    and $fh->replace_record({F1 => 123,
			     F2 => 13, 
			     F3 => "Smith, D", 
			     F4 => "memo field 2"}));


ok (    $fh->zap(1, $fh->reccount)
    and $fh->pack
    and $fh->reccount == 0);


#print "recno: ",  $fh->recno, "\n";
#print "position: ",  $fh->position, "\n";
#$fh->skip(2);
#print "position: ",  $fh->position, "\n";



exit(0);
