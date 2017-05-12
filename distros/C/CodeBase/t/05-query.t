#!/usr/bin/perl -w 
#
# $Id: 05-query.t,v 1.1 1999/07/13 06:49:52 andrew Exp $
#
# Index handling tests for CodeBase module
# ========================================
#

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    local($^W) = 0;
    use Test; plan tests => 8;
    eval "use blib" unless grep /blib/, @INC;
    eval { use lib qw(t); } if (defined -d 't');
}

use strict;
use vars qw($fh $table $filename @recnos @taginfo $debug $q $r);
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


# Add a few records

ok (    $fh->new_record(3, 1, "Smith, A", "memo field 1")
    and $fh->new_record(2, 3, "Smith, B", "memo field 2")
    and $fh->new_record(1, 2, "Jones, X", "memo field 3")
    and $fh->new_record(5, 6, "Jones, y", "memo field 4"));

# Test query in normal order

ok (    $q = $fh->prepare_query('F1 > 1 .AND. F2 > 1', 'F1')
    and $q->execute);

ok (   $r = $q->next
    and $r->recno == 2
    and $r = $q->next
    and $r->recno == 4
    and ! defined  $q->next);

# And re-run the query

ok (    $q->execute
    and $r = $q->next
    and $r->recno == 2
    and $r = $q->next
    and $r->recno == 4
    and ! defined  $q->next);

# descending order query

ok (    $q = $fh->prepare_query('F1 > 1 .AND. F2 > 1', 'F1', 1)
    and $q->execute);

ok (   $r = $q->next
    and $r->recno == 4
    and $r = $q->next
    and $r->recno == 2
    and ! defined  $q->next);

exit(0);
