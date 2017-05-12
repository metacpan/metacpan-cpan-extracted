#!/usr/bin/perl -w 
#
# $Id: 03-index.t,v 1.4 1999/08/10 09:46:26 andrew Exp $
#
# Index handling tests for CodeBase module
# ========================================
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
use vars qw($fh $table $filename @recnos @taginfo $debug);
use CodeBase;
use CodeBaseTestsubs;
$table = 'test1';
$filename = table_filename($table);

drop_table($table);


# Creating a database file and index with 3 tags

$fh = CodeBase::create($filename, ("F1" => "N5",
				   "F2" => "N5",
				   "F3" => "C10",
				   "F4" => "M"));


{
    local($^W) = 0; # turn off warning about use of undefined value
    
    ok ($fh->create_index(undef, [ { name => "TAG1", expression => "F1", unique => "YES" },
				   { name => "TAG2", expression => "F2", order => "descending" },
				   { name => "TAG3", expression => "UPPER(F3)" }
				 ] ));
}

# Check the information from taginfo

@taginfo = $fh->taginfo;

ok (    $taginfo[0]->{"name"}       eq "TAG1"
    and $taginfo[0]->{"expression"} eq "F1"
    and $taginfo[1]->{"name"}       eq "TAG2"
    and $taginfo[2]->{"name"}       eq "TAG3");


# Adding a couple  of records

$fh->new_record(3, 1, "Smith, A", "memo field 1");
$fh->new_record(2, 3, "Smith, B", "memo field 2");
$fh->new_record(1, 2, "Jones, X", "memo field 3");

# Run through records in tag order

ok (     $fh->set_tag("TAG1")
    and ($fh->goto("TOP"))
    and ($fh->field("F1") == 1)
    and ($fh->skip)
    and ($fh->field("F1") == 2)
    and ($fh->skip)
    and ($fh->field("F1") == 3));

# Run through records in tag order (descending)

ok (    $fh->set_tag("TAG2")
    and ($fh->goto("TOP"))
    and ($fh->field("F2") == 3)
    and ($fh->skip)
    and ($fh->field("F2") == 2)
    and ($fh->skip)
    and ($fh->field("F2") == 1));


# Attempting to add duplicate keys (should not work)

ok (    !$fh->new_record(3, 1, "")
    and !$fh->new_record(2, 3, "")
    and !$fh->new_record(1, 2, ""));


